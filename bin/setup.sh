#!/bin/bash
# =============================================================================
# setup.sh — Single-node OAI 5G SA RFsim emulation
#
# Deploys: mysql + udr + udm + ausf + amf + smf + upf + ext-dn + gnb + 12 UEs
# All containers on a shared Docker bridge network
# No cross-node timing issues, no --net host
# =============================================================================

set +e

mkdir -p /local/logs
exec >> /local/logs/setup.log 2>&1

echo "============================================"
echo "[SETUP] started at $(date)"
echo "============================================"

# ------------------------------------------------------------------ #
# 1. Install Docker
# ------------------------------------------------------------------ #
echo "[SETUP] Installing Docker..."

apt-get update -y
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

echo "[SETUP] Docker installed."
docker --version

# ------------------------------------------------------------------ #
# 2. Enable IP forwarding
# ------------------------------------------------------------------ #
echo "[SETUP] Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# ------------------------------------------------------------------ #
# 3. Pull all images
# ------------------------------------------------------------------ #
echo "[SETUP] Pulling images..."

docker pull mysql:8.0
docker pull oaisoftwarealliance/oai-udr:v2.0.0
docker pull oaisoftwarealliance/oai-udm:v2.0.0
docker pull oaisoftwarealliance/oai-ausf:v2.0.0
docker pull oaisoftwarealliance/oai-amf:v2.0.0
docker pull oaisoftwarealliance/oai-smf:v2.0.0
docker pull oaisoftwarealliance/oai-upf:v2.0.0
docker pull oaisoftwarealliance/trf-gen-cn5g:focal
docker pull oaisoftwarealliance/oai-gnb:develop
docker pull oaisoftwarealliance/oai-nr-ue:develop

echo "[SETUP] All images pulled."

# ------------------------------------------------------------------ #
# 4. Start everything
# ------------------------------------------------------------------ #
echo "[SETUP] Starting containers..."

MGEN_BIN="/local/repository/bin/mgen"
if [ ! -f "$MGEN_BIN" ] || [ ! -x "$MGEN_BIN" ]; then
    echo "[SETUP] ERROR: $MGEN_BIN is missing or not executable. Aborting."
    exit 1
fi

cd /local/repository/etc
docker compose -f docker-compose-rfsim.yaml up -d

echo "[SETUP] Docker Compose launched."

# ------------------------------------------------------------------ #
# 5. Wait for AMF
# ------------------------------------------------------------------ #
echo "[SETUP] Waiting for AMF..."
MAX_WAIT=600
ELAPSED=0
until docker logs rfsim5g-oai-amf 2>&1 | grep -q "HTTP2 server started\|Waiting for"; do
    if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
        echo "[SETUP] WARNING: AMF timeout, continuing..."
        break
    fi
    echo "[SETUP] Waiting... (${ELAPSED}s)"
    sleep 10
    ELAPSED=$((ELAPSED + 10))
done
echo "[SETUP] AMF ready."

# ------------------------------------------------------------------ #
# 6. Wait for gNB to register
# ------------------------------------------------------------------ #
echo "[SETUP] Waiting for gNB to register..."
MAX_WAIT=300
ELAPSED=0
until docker logs rfsim5g-oai-gnb 2>&1 | grep -q "NGAP_REGISTER_GNB_CNF"; do
    if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
        echo "[SETUP] WARNING: gNB registration timeout."
        break
    fi
    sleep 10
    ELAPSED=$((ELAPSED + 10))
done
echo "[SETUP] gNB registered."

# ------------------------------------------------------------------ #
# 7. Wait for all UEs to attach (3 minutes)
# ------------------------------------------------------------------ #
echo "[SETUP] Waiting for UEs to attach (180s)..."
sleep 180

# ------------------------------------------------------------------ #
# 8. Check and restart any stuck UEs
# ------------------------------------------------------------------ #
echo "[SETUP] Checking UE registration status..."

IMSI_LIST=(
    "208990100001100"
    "208990100001101"
    "208990100001102"
    "208990100001103"
    "208990100001104"
    "208990100001105"
    "208990100001106"
    "208990100001107"
    "208990100001108"
    "208990100001109"
    "208990100001110"
    "208990100001111"
)

STUCK_UES=""
for i in "${!IMSI_LIST[@]}"; do
    UE_NUM=$((i + 1))
    IMSI="${IMSI_LIST[$i]}"
    IS_STUCK=$(docker logs rfsim5g-oai-amf 2>&1 | grep "5GMM-REG-INITIATED" | grep -c "$IMSI")
    if [ "$IS_STUCK" -gt "0" ]; then
        echo "[SETUP] UE${UE_NUM} (${IMSI}) stuck in REG-INITIATED, restarting..."
        docker restart rfsim5g-oai-nr-ue${UE_NUM}
        STUCK_UES="$STUCK_UES UE${UE_NUM}"
    fi
done

if [ -z "$STUCK_UES" ]; then
    echo "[SETUP] All UEs registered successfully on first attempt."
else
    echo "[SETUP] Restarted stuck UEs:$STUCK_UES. Waiting 90s..."
    sleep 90

    echo "[SETUP] Final registration check..."
    for i in "${!IMSI_LIST[@]}"; do
        UE_NUM=$((i + 1))
        IMSI="${IMSI_LIST[$i]}"
        IS_REGISTERED=$(docker logs rfsim5g-oai-amf 2>&1 | grep "5GMM-REGISTERED" | grep -c "$IMSI")
        if [ "$IS_REGISTERED" -gt "0" ]; then
            echo "[SETUP] UE${UE_NUM} (${IMSI}): REGISTERED"
        else
            echo "[SETUP] WARNING: UE${UE_NUM} (${IMSI}): still not registered"
        fi
    done
fi

# ------------------------------------------------------------------ #
# 9. Route the DN subnet through each UE's PDU-session tunnel.
#    Without this, the kernel sends app traffic out eth0 (control net),
#    bypassing the 5G stack. Lost if a UE container is recreated; the
#    MGEN deploy script should re-assert it before each run.
# ------------------------------------------------------------------ #
echo "[SETUP] Adding DN route (192.168.72.128/26) via oaitun_ue1 on all UEs..."
for i in $(seq 1 12); do
    TUNNEL_WAIT=0
    TUNNEL_MAX=120
    until docker exec rfsim5g-oai-nr-ue${i} ip link show oaitun_ue1 >/dev/null 2>&1; do
        if [ "$TUNNEL_WAIT" -ge "$TUNNEL_MAX" ]; then
            echo "[SETUP] WARNING: UE${i}: oaitun_ue1 not present after ${TUNNEL_MAX}s — skipping"
            break
        fi
        sleep 5
        TUNNEL_WAIT=$((TUNNEL_WAIT + 5))
    done
    if docker exec rfsim5g-oai-nr-ue${i} ip link show oaitun_ue1 >/dev/null 2>&1; then
        docker exec rfsim5g-oai-nr-ue${i} ip route replace 192.168.72.128/26 dev oaitun_ue1 \
            && echo "[SETUP] UE${i}: DN route added" \
            || echo "[SETUP] WARNING: UE${i}: failed to add DN route"
    fi
done

# ------------------------------------------------------------------ #
# Done
# ------------------------------------------------------------------ #
echo "============================================"
echo "[SETUP] completed at $(date)"
echo "============================================"
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'