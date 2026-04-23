#!/bin/bash
# =============================================================================
# setup-gnb.sh — Install and start the OAI gNB on the gNB node
#
# What it does:
#   1. Creates log directory
#   2. Installs Docker
#   3. Adds route to CN Docker network via CN node (10.10.0.10)
#   4. Pulls OAI gNB Docker image
#   5. Waits until AMF is reachable (SCTP port 38412)
#   6. Starts the gNB container in RFsim server mode
# =============================================================================

set -e

# ------------------------------------------------------------------ #
# 0. Logging setup
# ------------------------------------------------------------------ #
mkdir -p /local/logs
exec >> /local/logs/setup-gnb.log 2>&1

echo "============================================"
echo "[gNB] setup-gnb.sh started at $(date)"
echo "============================================"

# ------------------------------------------------------------------ #
# 1. Install Docker
# ------------------------------------------------------------------ #
echo "[gNB] Installing Docker..."

apt-get update -y
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    netcat \
    iproute2

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

echo "[gNB] Docker installed."

# ------------------------------------------------------------------ #
# 2. Add route to CN Docker network
# ------------------------------------------------------------------ #
# The OAI CN containers live on 192.168.70.128/26 inside the CN node.
# We tell this node: to reach that subnet, go via the CN node's LAN IP.
# This is standard IP routing — no NAT, no tunnels.
# ------------------------------------------------------------------ #
echo "[gNB] Adding route to CN Docker network..."

ip route add 192.168.70.128/26 via 10.10.0.10 dev $(ip route | grep 10.10.0 | awk '{print $3}') || true

# Make it persistent across reboots
echo "192.168.70.128/26 via 10.10.0.10" >> /etc/network/interfaces.d/cn-route.conf || true

echo "[gNB] Route added."

# ------------------------------------------------------------------ #
# 3. Pull OAI gNB image
# ------------------------------------------------------------------ #
echo "[gNB] Pulling OAI gNB image..."

docker pull oaisoftwarealliance/oai-gnb:2024.w25

echo "[gNB] Image pulled."

# ------------------------------------------------------------------ #
# 4. Wait for AMF to be reachable on SCTP 38412
# ------------------------------------------------------------------ #
echo "[gNB] Waiting for AMF at 192.168.70.132:38412..."

MAX_WAIT=600
ELAPSED=0
INTERVAL=15

until nc -z -w5 192.168.70.132 38412 2>/dev/null; do
    if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
        echo "[gNB] ERROR: AMF not reachable after ${MAX_WAIT}s. Aborting."
        exit 1
    fi
    echo "[gNB] AMF not reachable yet, waiting ${INTERVAL}s... (${ELAPSED}s elapsed)"
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
done

echo "[gNB] AMF is reachable."

# ------------------------------------------------------------------ #
# 5. Start the gNB container
# ------------------------------------------------------------------ #
echo "[gNB] Starting OAI gNB container..."

# Get this node's experimental LAN IP (10.10.0.20)
GNB_IP=$(ip addr show | grep '10.10.0.' | awk '{print $2}' | cut -d/ -f1)
echo "[gNB] gNB experimental IP: $GNB_IP"

docker run -d \
  --name oai-gnb \
  --net host \
  --privileged \
  -e TZ=Europe/Paris \
  -e USE_ADDITIONAL_OPTIONS="--sa --rfsim --log_config.global_log_options level,nocolor,time" \
  -e GNB_ID=1 \
  -e GNB_NAME=gNB-OAI \
  -e MCC=208 \
  -e MNC=95 \
  -e MNC_LENGTH=2 \
  -e TAC=1 \
  -e NSSAI_SST=1 \
  -e NSSAI_SD=1 \
  -e AMF_IP_ADDRESS=192.168.70.132 \
  -e GNB_NGA_IF_NAME=lo \
  -e GNB_NGA_IP_ADDRESS=${GNB_IP} \
  -e GNB_NGU_IF_NAME=lo \
  -e GNB_NGU_IP_ADDRESS=${GNB_IP} \
  -e RFSIM_SERVER=1 \
  -e THREAD_PARALLEL_CONFIG=PARALLEL_SINGLE_THREAD \
  -e PDSCH_TARGET_COMP_0=45 \
  -e PUSCH_TARGET_COMP_0=20 \
  oaisoftwarealliance/oai-gnb:2024.w25

echo "[gNB] gNB container started."

# ------------------------------------------------------------------ #
# 6. Wait for gNB to register with AMF
# ------------------------------------------------------------------ #
echo "[gNB] Waiting for NG Setup to complete..."

MAX_WAIT=120
ELAPSED=0

until docker logs oai-gnb 2>&1 | grep -q "Registered with AMF"; do
    if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
        echo "[gNB] WARNING: Could not confirm AMF registration within ${MAX_WAIT}s."
        echo "[gNB] Check logs: docker logs oai-gnb"
        break
    fi
    sleep 10
    ELAPSED=$((ELAPSED + 10))
done

echo "[gNB] gNB setup complete."

# ------------------------------------------------------------------ #
# Done
# ------------------------------------------------------------------ #
echo "============================================"
echo "[gNB] setup-gnb.sh completed at $(date)"
echo "============================================"