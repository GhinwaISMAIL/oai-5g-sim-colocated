#!/bin/bash
# =============================================================================
# setup-cn.sh — Install and start the OAI 5G Core Network on the CN node
#
# This script runs automatically at boot via the POWDER profile startup hook.
# All output is logged to /local/logs/setup-cn.log
#
# What it does:
#   1. Creates log directory
#   2. Installs Docker + Docker Compose
#   3. Pulls OAI CN Docker images
#   4. Starts the core network using our docker-compose-cn.yaml
#   5. Waits for AMF to be healthy
#   6. Pre-populates the subscriber database with UE IMSIs
# =============================================================================

set -e  # exit on any error

# ------------------------------------------------------------------ #
# 0. Logging setup
# ------------------------------------------------------------------ #
mkdir -p /local/logs
exec >> /local/logs/setup-cn.log 2>&1

echo "============================================"
echo "[CN] setup-cn.sh started at $(date)"
echo "============================================"

# ------------------------------------------------------------------ #
# 1. Install Docker
# ------------------------------------------------------------------ #
echo "[CN] Installing Docker..."

apt-get update -y
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    python3-pip

# Add Docker's official GPG key and repo
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

# Install docker-compose v1 CLI as well (some OAI scripts use it)
pip3 install docker-compose

echo "[CN] Docker installed."
docker --version

# ------------------------------------------------------------------ #
# 2. Pull OAI CN images
# ------------------------------------------------------------------ #
echo "[CN] Pulling OAI CN images..."

docker pull mysql:8.0
docker pull oaisoftwarealliance/oai-nrf:v2.0.0
docker pull oaisoftwarealliance/oai-amf:v2.0.0
docker pull oaisoftwarealliance/oai-smf:v2.0.0
docker pull oaisoftwarealliance/oai-upf:v2.0.0
docker pull oaisoftwarealliance/oai-udm:v2.0.0
docker pull oaisoftwarealliance/oai-udr:v2.0.0
docker pull oaisoftwarealliance/oai-ausf:v2.0.0
docker pull oaisoftwarealliance/trf-gen-cn5g:latest

echo "[CN] All images pulled."

# ------------------------------------------------------------------ #
# 3. Enable IP forwarding (needed for UPF routing)
# ------------------------------------------------------------------ #
echo "[CN] Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# ------------------------------------------------------------------ #
# 4. Start the Core Network
# ------------------------------------------------------------------ #
echo "[CN] Starting OAI Core Network..."

cd /local/repository/etc
docker compose -f docker-compose-cn.yaml up -d

echo "[CN] Docker Compose launched."

# ------------------------------------------------------------------ #
# 5. Wait for AMF to be healthy
# ------------------------------------------------------------------ #
echo "[CN] Waiting for AMF to become healthy..."

MAX_WAIT=300   # 5 minutes max
ELAPSED=0
INTERVAL=10

until docker ps --filter "name=oai-amf" --filter "health=healthy" \
      --format "{{.Names}}" | grep -q "oai-amf"; do
    if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
        echo "[CN] ERROR: AMF did not become healthy within ${MAX_WAIT}s. Check logs."
        docker logs oai-amf || true
        exit 1
    fi
    echo "[CN] AMF not ready yet, waiting ${INTERVAL}s... (${ELAPSED}s elapsed)"
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
done

echo "[CN] AMF is healthy."

# ------------------------------------------------------------------ #
# 6. Pre-populate subscriber database
# ------------------------------------------------------------------ #
echo "[CN] Populating subscriber database..."

# Wait for MySQL to be ready
until docker exec oai-mysql mysqladmin ping -h localhost \
      --silent 2>/dev/null; do
    echo "[CN] Waiting for MySQL..."
    sleep 5
done

# Insert IMSIs for 8 UEs (ue1..ue8)
# IMSI format: 208950000000031 .. 208950000000038
# Key/OPC values match the ue.conf.template we will create in Step 5

docker exec oai-mysql mysql -u root -plinux oai_db << 'SQL'

-- Make sure we don't duplicate on re-runs
DELETE FROM AuthenticationSubscription WHERE ueid LIKE '20895000000003%';
DELETE FROM SessionManagementSubscriptionData WHERE ueid LIKE '20895000000003%';
DELETE FROM AccessAndMobilitySubscriptionData WHERE ueid LIKE '20895000000003%';
DELETE FROM SmfSelectionSubscriptionData WHERE ueid LIKE '20895000000003%';

-- Insert 8 UEs
SET @imsi_base = 208950000000030;

-- We loop by inserting each IMSI individually for clarity
INSERT INTO AuthenticationSubscription VALUES
('208950000000031','5G_AKA','0C0A34601D4F07677303652C0462535B','0C0A34601D4F07677303652C0462535B','{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}','milenage',NULL,'63bfa50ee6523365ff14c1f45f88737d',NULL,NULL,NULL,NULL),
('208950000000032','5G_AKA','0C0A34601D4F07677303652C0462535B','0C0A34601D4F07677303652C0462535B','{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}','milenage',NULL,'63bfa50ee6523365ff14c1f45f88737d',NULL,NULL,NULL,NULL),
('208950000000033','5G_AKA','0C0A34601D4F07677303652C0462535B','0C0A34601D4F07677303652C0462535B','{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}','milenage',NULL,'63bfa50ee6523365ff14c1f45f88737d',NULL,NULL,NULL,NULL),
('208950000000034','5G_AKA','0C0A34601D4F07677303652C0462535B','0C0A34601D4F07677303652C0462535B','{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}','milenage',NULL,'63bfa50ee6523365ff14c1f45f88737d',NULL,NULL,NULL,NULL),
('208950000000035','5G_AKA','0C0A34601D4F07677303652C0462535B','0C0A34601D4F07677303652C0462535B','{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}','milenage',NULL,'63bfa50ee6523365ff14c1f45f88737d',NULL,NULL,NULL,NULL),
('208950000000036','5G_AKA','0C0A34601D4F07677303652C0462535B','0C0A34601D4F07677303652C0462535B','{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}','milenage',NULL,'63bfa50ee6523365ff14c1f45f88737d',NULL,NULL,NULL,NULL),
('208950000000037','5G_AKA','0C0A34601D4F07677303652C0462535B','0C0A34601D4F07677303652C0462535B','{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}','milenage',NULL,'63bfa50ee6523365ff14c1f45f88737d',NULL,NULL,NULL,NULL),
('208950000000038','5G_AKA','0C0A34601D4F07677303652C0462535B','0C0A34601D4F07677303652C0462535B','{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}','milenage',NULL,'63bfa50ee6523365ff14c1f45f88737d',NULL,NULL,NULL,NULL);

SQL

echo "[CN] Subscriber database populated."


# ------------------------------------------------------------------ #
# 7. Pull OAI gNB image and start gNB container
# ------------------------------------------------------------------ #
echo "[CN] Pulling OAI gNB image..."
docker pull oaisoftwarealliance/oai-gnb:v2.0.0
echo "[CN] Starting gNB container..."

docker run -d \
  --name oai-gnb \
  --net host \
  --privileged \
  -v /local/repository/etc/gnb.conf:/opt/oai-gnb/etc/gnb.conf:ro \
  -e TZ=Europe/Paris \
  -e USE_ADDITIONAL_OPTIONS="--sa --rfsim --rfsimulator.serveraddr server --log_config.global_log_options level,nocolor,time" \
  oaisoftwarealliance/oai-gnb:v2.0.0

echo "[CN] gNB container started."

# Wait for gNB to register with AMF
echo "[CN] Waiting for gNB to register..."
MAX_WAIT=120
ELAPSED=0
until docker logs oai-gnb 2>&1 | grep -q "NGAP_REGISTER_GNB_CNF"; do
    if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
        echo "[CN] WARNING: gNB registration not confirmed. Check: docker logs oai-gnb"
        break
    fi
    sleep 10
    ELAPSED=$((ELAPSED + 10))
done
echo "[CN] gNB ready."


# ------------------------------------------------------------------ #
# Done
# ------------------------------------------------------------------ #
echo "============================================"
echo "[CN] setup-cn.sh completed successfully at $(date)"
echo "============================================"