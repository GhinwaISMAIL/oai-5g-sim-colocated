#!/bin/bash
# =============================================================================
# setup.sh — Single-node OAI 5G SA RFsim emulation
#
# Deploys: mysql + amf + smf + upf + ext-dn + gnb + 4 UEs
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
# 7. Wait for UE1 to attach
# ------------------------------------------------------------------ #
echo "[SETUP] Waiting for UE1 to attach..."
MAX_WAIT=300
ELAPSED=0
until docker logs rfsim5g-oai-nr-ue1 2>&1 | grep -q "PDU SESSION ESTABLISHMENT"; do
    if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
        echo "[SETUP] WARNING: UE1 attach timeout."
        break
    fi
    sleep 10
    ELAPSED=$((ELAPSED + 10))
done
echo "[SETUP] UE1 attached."

# ------------------------------------------------------------------ #
# Done
# ------------------------------------------------------------------ #
echo "============================================"
echo "[SETUP] completed at $(date)"
echo "============================================"
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'