#!/bin/bash
# =============================================================================
# setup-cn.sh — Install and start the OAI 5G Core Network + gNB on the CN node
#
# What it does:
#   1. Creates log directory
#   2. Installs Docker
#   3. Pulls OAI CN + gNB images
#   4. Enables IP forwarding
#   5. Starts the core network
#   6. Waits for AMF to be healthy
#   7. Pre-populates the subscriber database
#   8. Adds iptables rules for UE traffic
#   9. Starts the gNB container
#   10. Waits for gNB to register with AMF
# =============================================================================

set +e

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

echo "[CN] Docker installed."
docker --version

# ------------------------------------------------------------------ #
# 2. Pull OAI CN + gNB images
# ------------------------------------------------------------------ #
echo "[CN] Pulling OAI CN images..."

docker pull mysql:8.0
docker pull oaisoftwarealliance/oai-nrf:v2.1.10
docker pull oaisoftwarealliance/oai-amf:v2.1.10
docker pull oaisoftwarealliance/oai-smf:v2.1.10
docker pull oaisoftwarealliance/oai-upf:v2.1.10
docker pull oaisoftwarealliance/oai-udm:v2.1.10
docker pull oaisoftwarealliance/oai-udr:v2.1.10
docker pull oaisoftwarealliance/oai-ausf:v2.1.10
docker pull oaisoftwarealliance/trf-gen-cn5g:latest
docker pull oaisoftwarealliance/oai-gnb:2024.w25
docker pull oaisoftwarealliance/oai-nr-ue:2024.w25

echo "[CN] All images pulled."

# ------------------------------------------------------------------ #
# 3. Enable IP forwarding
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
echo "[CN] Waiting for AMF to be ready..."

MAX_WAIT=600
ELAPSED=0
INTERVAL=10

until docker logs oai-amf 2>&1 | grep -q "HTTP2 server started"; do
    if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
        echo "[CN] WARNING: AMF readiness not confirmed within ${MAX_WAIT}s, continuing anyway."
        break
    fi
    echo "[CN] AMF not ready yet, waiting ${INTERVAL}s... (${ELAPSED}s elapsed)"
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
done

echo "[CN] AMF is ready."

# ------------------------------------------------------------------ #
# 6. Pre-populate subscriber database
# ------------------------------------------------------------------ #
echo "[CN] Populating subscriber database..."

until docker exec oai-mysql mysqladmin ping -h localhost --silent 2>/dev/null; do
    echo "[CN] Waiting for MySQL..."
    sleep 5
done

docker exec oai-mysql mysql -u root -plinux oai_db << 'SQL'
DELETE FROM AuthenticationSubscription WHERE ueid LIKE '20895000000003%';
DELETE FROM SessionManagementSubscriptionData WHERE ueid LIKE '20895000000003%';
DELETE FROM AccessAndMobilitySubscriptionData WHERE ueid LIKE '20895000000003%';
DELETE FROM SmfSelectionSubscriptionData WHERE ueid LIKE '20895000000003%';

INSERT INTO AuthenticationSubscription VALUES
('208950000000031','5G_AKA','0C0A34601D4F07677303652C0462535B','0C0A34601D4F07677303652C0462535B','{"sqn": "000000000020", "sqnScheme": "NON_TIME_BASED", "lastIndexes": {"ausf": 0}}','milenage',NULL,'63bfa50ee6523365ff14c1f45f88737d',NULL,NULL,NULL,NULL),
('208950000000032','5G_AKA','0C0A34601D4F07677303652C0462535B','0C0A34601D4F07677303652C0462535B','{"sqn": "000000000020", "sqnScheme": "NON_TIME_BASED", "lastIndexes": {"ausf": 0}}','milenage',NULL,'63bfa50ee6523365ff14c1f45f88737d',NULL,NULL,NULL,NULL),
('208950000000033','5G_AKA','0C0A34601D4F07677303652C0462535B','0C0A34601D4F07677303652C0462535B','{"sqn": "000000000020", "sqnScheme": "NON_TIME_BASED", "lastIndexes": {"ausf": 0}}','milenage',NULL,'63bfa50ee6523365ff14c1f45f88737d',NULL,NULL,NULL,NULL),
('208950000000034','5G_AKA','0C0A34601D4F07677303652C0462535B','0C0A34601D4F07677303652C0462535B','{"sqn": "000000000020", "sqnScheme": "NON_TIME_BASED", "lastIndexes": {"ausf": 0}}','milenage',NULL,'63bfa50ee6523365ff14c1f45f88737d',NULL,NULL,NULL,NULL),
('208950000000035','5G_AKA','0C0A34601D4F07677303652C0462535B','0C0A34601D4F07677303652C0462535B','{"sqn": "000000000020", "sqnScheme": "NON_TIME_BASED", "lastIndexes": {"ausf": 0}}','milenage',NULL,'63bfa50ee6523365ff14c1f45f88737d',NULL,NULL,NULL,NULL),
('208950000000036','5G_AKA','0C0A34601D4F07677303652C0462535B','0C0A34601D4F07677303652C0462535B','{"sqn": "000000000020", "sqnScheme": "NON_TIME_BASED", "lastIndexes": {"ausf": 0}}','milenage',NULL,'63bfa50ee6523365ff14c1f45f88737d',NULL,NULL,NULL,NULL),
('208950000000037','5G_AKA','0C0A34601D4F07677303652C0462535B','0C0A34601D4F07677303652C0462535B','{"sqn": "000000000020", "sqnScheme": "NON_TIME_BASED", "lastIndexes": {"ausf": 0}}','milenage',NULL,'63bfa50ee6523365ff14c1f45f88737d',NULL,NULL,NULL,NULL),
('208950000000038','5G_AKA','0C0A34601D4F07677303652C0462535B','0C0A34601D4F07677303652C0462535B','{"sqn": "000000000020", "sqnScheme": "NON_TIME_BASED", "lastIndexes": {"ausf": 0}}','milenage',NULL,'63bfa50ee6523365ff14c1f45f88737d',NULL,NULL,NULL,NULL);
SQL

echo "[CN] Subscriber database populated."

# ------------------------------------------------------------------ #
# 7. Add iptables rules for UE traffic into Docker network
# ------------------------------------------------------------------ #
echo "[CN] Adding iptables forwarding rules..."

sleep 5

LAN_IF=$(ip route | grep "10.10.0" | awk '{print $3}' | head -1)
BRIDGE_ID=$(docker network inspect etc_oai-public-net \
    --format '{{.Id}}' 2>/dev/null | cut -c1-12)
BRIDGE_IF="br-${BRIDGE_ID}"

echo "[CN] LAN interface: ${LAN_IF}"
echo "[CN] Docker bridge: ${BRIDGE_IF}"

iptables -I DOCKER-USER -i ${LAN_IF} -o ${BRIDGE_IF} -j ACCEPT || true
iptables -I DOCKER-USER -i ${BRIDGE_IF} -o ${LAN_IF} -j ACCEPT || true

echo "[CN] iptables rules added."

# ------------------------------------------------------------------ #
# 8. Start the gNB container
# ------------------------------------------------------------------ #
echo "[CN] Starting gNB container..."

docker run -d \
  --name oai-gnb \
  --net host \
  --privileged \
  -v /local/repository/etc/gnb.conf:/opt/oai-gnb/etc/gnb.conf:ro \
  -e TZ=Europe/Paris \
  -e USE_ADDITIONAL_OPTIONS="--sa --rfsim --rfsimulator.serveraddr server --log_config.global_log_options level,nocolor,time" \
  oaisoftwarealliance/oai-gnb:2024.w25

echo "[CN] gNB container started."

# ------------------------------------------------------------------ #
# 9. Wait for gNB to register with AMF
# ------------------------------------------------------------------ #
echo "[CN] Waiting for gNB to register with AMF..."

MAX_WAIT=120
ELAPSED=0

until docker logs oai-gnb 2>&1 | grep -q "NGAP_REGISTER_GNB_CNF"; do
    if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
        echo "[CN] WARNING: gNB registration not confirmed within ${MAX_WAIT}s."
        echo "[CN] Check: docker logs oai-gnb"
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