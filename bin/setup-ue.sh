#!/bin/bash
# =============================================================================
# setup-ue.sh — Install and start one OAI nrUE instance on a UE node
#
# Usage: setup-ue.sh <UE_INDEX>
# =============================================================================

set -e

# ------------------------------------------------------------------ #
# 0. Arguments and logging
# ------------------------------------------------------------------ #
UE_INDEX=${1:-1}

mkdir -p /local/logs
exec >> /local/logs/setup-ue.log 2>&1

echo "============================================"
echo "[UE${UE_INDEX}] setup-ue.sh started at $(date)"
echo "============================================"

# ------------------------------------------------------------------ #
# 1. IMSI assignment
# ------------------------------------------------------------------ #
IMSI_BASE="20895000000003"
IMSI="${IMSI_BASE}${UE_INDEX}"
KEY="0C0A34601D4F07677303652C0462535B"
OPC="63bfa50ee6523365ff14c1f45f88737d"

echo "[UE${UE_INDEX}] IMSI: ${IMSI}"

# ------------------------------------------------------------------ #
# 2. Install Docker
# ------------------------------------------------------------------ #
echo "[UE${UE_INDEX}] Installing Docker..."

apt-get update -y
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    iproute2 \
    iputils-ping

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

echo "[UE${UE_INDEX}] Docker installed."

# ------------------------------------------------------------------ #
# 3. Add route to CN Docker network
# ------------------------------------------------------------------ #
echo "[UE${UE_INDEX}] Adding route to CN Docker network..."
ip route add 192.168.70.128/26 via 10.10.0.10 || true
echo "[UE${UE_INDEX}] Route added."

# ------------------------------------------------------------------ #
# 4. Pull OAI nrUE image
# ------------------------------------------------------------------ #
echo "[UE${UE_INDEX}] Pulling OAI nrUE image..."
docker pull oaisoftwarealliance/oai-nr-ue:2024.w25
echo "[UE${UE_INDEX}] Image pulled."

# ------------------------------------------------------------------ #
# 5. Wait for gNB RFsim port 4043 to be reachable
# ------------------------------------------------------------------ #
echo "[UE${UE_INDEX}] Waiting for gNB RFsim at 10.10.0.10:4043..."

MAX_WAIT=600
ELAPSED=0
INTERVAL=15

until bash -c "echo > /dev/tcp/10.10.0.10/4043" 2>/dev/null; do
    if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
        echo "[UE${UE_INDEX}] ERROR: gNB RFsim port 4043 not reachable after ${MAX_WAIT}s."
        exit 1
    fi
    echo "[UE${UE_INDEX}] gNB not ready yet, waiting ${INTERVAL}s... (${ELAPSED}s elapsed)"
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
done

echo "[UE${UE_INDEX}] gNB RFsim port 4043 is reachable."

# ------------------------------------------------------------------ #
# 6. Start the nrUE container
# ------------------------------------------------------------------ #
echo "[UE${UE_INDEX}] Starting nrUE container..."

docker run -d \
  --name oai-nr-ue \
  --net host \
  --privileged \
  -v /local/repository/etc/nr-ue.conf:/opt/oai-nr-ue/etc/nr-ue.conf:ro \
  -e TZ=Europe/Paris \
  -e USE_ADDITIONAL_OPTIONS="-r 106 -C 3619200000 --sa --nokrnmod --numerology 1 --band 78 --rfsim --rfsimulator.serveraddr 10.10.0.10 --uicc0.imsi ${IMSI}" \
  oaisoftwarealliance/oai-nr-ue:2024.w25

echo "[UE${UE_INDEX}] nrUE container started."

# ------------------------------------------------------------------ #
# 7. Wait for tunnel interface to appear
# ------------------------------------------------------------------ #
echo "[UE${UE_INDEX}] Waiting for oaitun_ue1 tunnel interface..."

MAX_WAIT=180
ELAPSED=0

until ip link show oaitun_ue1 > /dev/null 2>&1; do
    if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
        echo "[UE${UE_INDEX}] WARNING: oaitun_ue1 did not appear within ${MAX_WAIT}s."
        echo "[UE${UE_INDEX}] Check: docker logs oai-nr-ue"
        break
    fi
    sleep 10
    ELAPSED=$((ELAPSED + 10))
done

if ip link show oaitun_ue1 > /dev/null 2>&1; then
    UE_IP=$(ip addr show oaitun_ue1 | grep 'inet ' | awk '{print $2}')
    echo "[UE${UE_INDEX}] Tunnel UP. UE IP: ${UE_IP}"
    echo "[UE${UE_INDEX}] Testing end-to-end connectivity..."
    ping -I oaitun_ue1 -c 4 192.168.70.135 && \
        echo "[UE${UE_INDEX}] End-to-end ping SUCCESS." || \
        echo "[UE${UE_INDEX}] End-to-end ping FAILED."
fi

# ------------------------------------------------------------------ #
# Done
# ------------------------------------------------------------------ #
echo "============================================"
echo "[UE${UE_INDEX}] setup-ue.sh completed at $(date)"
echo "============================================"