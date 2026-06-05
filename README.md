# OAI 5G SA RFSim — Single-Node POWDER Profile

Single-node 5G Standalone emulation running entirely in Docker Compose on one POWDER d430 node.
Full stack: Core Network (CN) + gNB + up to 12 UEs, all connected via OAI RFsimulator (no real radio).

---

## Architecture

```
UE1–12 (oaitun_ue1, 12.1.1.x)
   |  rfsim (TCP)
   gNB  192.168.71.140
   |  N2 (NGAP)     N3 (GTP-U)
   AMF              UPF ── ext-dn ── internet
   SMF ── N4 (PFCP) ─┘     NAT
   UDR / UDM / AUSF
   MySQL
```

**Networks**

| Bridge | Subnet | Purpose |
|--------|--------|---------|
| `rfsim5g-public` | 192.168.71.128/26 | Control plane + RFsim (all NFs, gNB, UEs) |
| `rfsim5g-traffic` | 192.168.72.128/26 | Data plane (UPF ↔ ext-dn) |

**Container IPs**

| Container | public_net IP | traffic_net IP |
|-----------|--------------|----------------|
| mysql | .131 | — |
| oai-udr | .136 | — |
| oai-udm | .137 | — |
| oai-ausf | .138 | — |
| oai-amf | .132 | — |
| oai-smf | .133 | — |
| oai-upf | .134 | .134 (72.x) |
| oai-ext-dn | — | .135 (72.x) |
| oai-gnb | .140 | — |
| oai-nr-ue1–12 | .150–.161 | — |

**UE IPs (PDU session, assigned by UPF)**

| UE | IMSI | PDU IP |
|----|------|--------|
| UE1 | 208990100001100 | 12.1.1.x (dynamic) |
| UE2 | 208990100001101 | 12.1.1.x |
| … | … | … |
| UE12 | 208990100001111 | 12.1.1.x |

---

## Deploying the Profile

1. Go to [POWDER](https://www.powderwireless.net), instantiate the profile `oai-5g-sim-colocated` on a **d430** node.
2. Wait **15–20 minutes** for the setup script to finish (Docker install + image pull + stack start).
3. SSH into the node: `ssh ghinwa@cn.your-experiment.powder.net`

Check setup progress:
```bash
tail -f /local/logs/setup.log
```

---

## Working Directory

All compose commands must be run from:
```bash
cd /local/repository/etc
```

---

## Container Management

### Start the full stack
```bash
sudo docker compose -f docker-compose-rfsim.yaml up -d
```

### Stop everything
```bash
sudo docker compose -f docker-compose-rfsim.yaml down
```

### Full restart (clean state)
```bash
sudo docker compose -f docker-compose-rfsim.yaml down
sudo docker compose -f docker-compose-rfsim.yaml up -d
```

### Check status of all containers
```bash
sudo docker compose -f docker-compose-rfsim.yaml ps
# or
sudo docker ps --format 'table {{.Names}}\t{{.Status}}'
```

### Expected healthy containers (22 total with 12 UEs)
```
rfsim5g-mysql          healthy
rfsim5g-oai-udr        healthy
rfsim5g-oai-udm        healthy
rfsim5g-oai-ausf       healthy
rfsim5g-oai-amf        healthy
rfsim5g-oai-smf        healthy
rfsim5g-oai-upf        healthy
rfsim5g-oai-ext-dn     healthy
rfsim5g-oai-gnb        healthy
rfsim5g-oai-nr-ue1     healthy
… (up to ue12)
```

### View logs
```bash
# Tail logs for a specific container
sudo docker logs rfsim5g-oai-gnb --tail 30
sudo docker logs rfsim5g-oai-amf --tail 30
sudo docker logs rfsim5g-oai-upf --tail 30
sudo docker logs rfsim5g-oai-nr-ue1 --tail 30

# Follow logs live
sudo docker logs -f rfsim5g-oai-gnb
```

### Restart a specific container
```bash
sudo docker compose -f docker-compose-rfsim.yaml restart oai-nr-ue1
```

---

## Connectivity Verification

### 1. Check UE tunnel interfaces (PDU sessions)
Each UE container names its tunnel `oaitun_ue1` internally:
```bash
for i in $(seq 1 12); do
  echo -n "UE$i: "
  sudo docker exec rfsim5g-oai-nr-ue$i ip addr show oaitun_ue1 2>/dev/null | grep "inet " || echo "no tunnel"
done
```

### 2. Ping internet from a UE
```bash
sudo docker exec rfsim5g-oai-nr-ue1 ping -I oaitun_ue1 -c 5 8.8.8.8
```

### 3. Ping all UEs to internet
```bash
for i in $(seq 1 12); do
  echo -n "UE$i ping: "
  sudo docker exec rfsim5g-oai-nr-ue$i ping -I oaitun_ue1 -c 2 -W 3 8.8.8.8 2>/dev/null | tail -1
done
```

### 4. Check gNB is registered with AMF
```bash
sudo docker logs rfsim5g-oai-amf 2>&1 | grep -A3 "gNBs' information" | tail -5
```
Look for `Status: Connected`.

### 5. Check UEs are registered
```bash
sudo docker logs rfsim5g-oai-amf 2>&1 | grep "5GMM-REGISTERED"
```
All 12 IMSIs should appear.

### 6. Check UPF routing (data plane health)
```bash
sudo docker exec rfsim5g-oai-upf ip route show
```
The default route **must** be via `192.168.72.135` (ext-dn):
```
default via 192.168.72.135 dev ethX   ← correct
```
If it shows `192.168.71.129` instead, restart the UPF:
```bash
sudo docker compose -f docker-compose-rfsim.yaml restart oai-upf
```

### 7. Test internal hops (no internet needed)
```bash
# UE → UPF (data plane reachable)
sudo docker exec rfsim5g-oai-nr-ue1 ping -I oaitun_ue1 -c 3 192.168.72.134

# UE → ext-dn
sudo docker exec rfsim5g-oai-nr-ue1 ping -I oaitun_ue1 -c 3 192.168.72.135
```

---

## Keeping the Node in Sync

The node clones this repo at boot. If you push changes locally, pull them on the node:
```bash
cd /local/repository
sudo git pull origin main
cd /local/repository/etc
sudo docker compose -f docker-compose-rfsim.yaml down
sudo docker compose -f docker-compose-rfsim.yaml up -d
```

---

## Troubleshooting

### UEs have no tunnel after startup
Race condition — UEs attached but PDU session failed. Restart stuck UEs one at a time:
```bash
for i in $(seq 2 12); do
  sudo docker compose -f docker-compose-rfsim.yaml restart oai-nr-ue$i
  sleep 15
done
```

### gNB exits immediately
Check for unknown options:
```bash
sudo docker logs rfsim5g-oai-gnb 2>&1 | grep -i "unknown\|error\|exit"
```
If you see `unknown option: --sa`, the node has an old repo version. Run `sudo git pull origin main` and restart.

### Ping from UE reaches UPF/ext-dn but not 8.8.8.8
UPF default route is wrong. Check and fix:
```bash
sudo docker exec rfsim5g-oai-upf ip route show
# Should show: default via 192.168.72.135
# If not, restart the UPF:
sudo docker compose -f docker-compose-rfsim.yaml restart oai-upf
sleep 20
sudo docker compose -f docker-compose-rfsim.yaml restart oai-nr-ue1 oai-nr-ue2 oai-nr-ue3 oai-nr-ue4
```

### docker compose command not found
The binary is `docker compose` (plugin), not `docker-compose`. Always use:
```bash
sudo docker compose -f docker-compose-rfsim.yaml <command>
```
And always run from `/local/repository/etc`.

### AMF shows UEs stuck in 5GMM-REG-INITIATED
```bash
sudo docker compose -f docker-compose-rfsim.yaml restart oai-nr-ue<N>
```

---

## MGEN Traffic Testing

MGEN (Multi-Generator) is installed on the host and copied into the data-plane containers automatically at startup (via `docker cp` in setup.sh). It is available in: all 12 UE containers, UPF, and ext-dn. The control-plane NFs (AMF, SMF, UDR, UDM, AUSF) do not forward user data and do not need it.

### MGEN syntax basics

```
mgen event "<time> <command> [options]" [event "<time> <command>"] ...
```

- Time is in seconds from start (float, e.g. `0.0`, `5.0`)
- `ON <flowId> <proto> DST <addr>/<port> PERIODIC [<pps> <size>]` — start a flow
- `OFF <flowId>` — stop a flow (mgen exits when all flows are off)
- `LISTEN <proto> <port>` — open a receive socket
- `IGNORE <proto> <port>` — stop listening

### Uplink test: UE → ext-dn through the full 5G path

```bash
# Step 1: add a route in the UE container so traffic exits via the 5G tunnel
sudo docker exec rfsim5g-oai-nr-ue1 ip route add 192.168.72.0/24 dev oaitun_ue1

# Step 2: start tcpdump on ext-dn to capture arriving packets (run in background)
sudo docker exec rfsim5g-oai-ext-dn timeout 15 tcpdump -i eth0 -n "udp port 5001" &
sleep 1

# Step 3: start mgen receiver on ext-dn (background)
sudo docker exec -d rfsim5g-oai-ext-dn mgen event "0.0 LISTEN UDP 5001"

# Step 4: send 5 seconds of UDP traffic from UE1 (1 pkt/s, 1024 bytes)
sudo docker exec rfsim5g-oai-nr-ue1 \
  mgen event "0.0 ON 1 UDP DST 192.168.72.135/5001 PERIODIC [1.0 1024]" \
       event "5.0 OFF 1"

wait
```

Expected tcpdump output — source IP `12.1.1.x` confirms traffic came through the tunnel:

```text
12:09:41.051 IP 12.1.1.4.38438 > 192.168.72.135.5001: UDP, length 1024
12:09:42.051 IP 12.1.1.4.38438 > 192.168.72.135.5001: UDP, length 1024
...
```

### Downlink test: ext-dn → UE

```bash
# Get UE1's PDU session IP
UE1_IP=$(sudo docker exec rfsim5g-oai-nr-ue1 ip addr show oaitun_ue1 | awk '/inet /{print $2}' | cut -d/ -f1)
echo "UE1 tunnel IP: $UE1_IP"

# Start receiver on UE1
sudo docker exec -d rfsim5g-oai-nr-ue1 mgen event "0.0 LISTEN UDP 5001"

# Send from ext-dn to UE1 (ext-dn already has route for 12.1.1.0/24 via UPF)
sudo docker exec rfsim5g-oai-ext-dn \
  mgen event "0.0 ON 1 UDP DST ${UE1_IP}/5001 PERIODIC [1.0 1024]" \
       event "5.0 OFF 1"
```

### Bidirectional test: all 12 UEs simultaneously

```bash
# Add 5G route in all UE containers
for i in $(seq 1 12); do
  sudo docker exec rfsim5g-oai-nr-ue$i ip route add 192.168.72.0/24 dev oaitun_ue1 2>/dev/null
done

# Start receiver on ext-dn
sudo docker exec -d rfsim5g-oai-ext-dn mgen event "0.0 LISTEN UDP 5001"

# All 12 UEs send uplink traffic simultaneously (10 seconds)
for i in $(seq 1 12); do
  sudo docker exec -d rfsim5g-oai-nr-ue$i \
    mgen event "0.0 ON 1 UDP DST 192.168.72.135/5001 PERIODIC [1.0 512]" \
         event "10.0 OFF 1"
done

# Watch traffic arriving at ext-dn
sudo docker exec rfsim5g-oai-ext-dn timeout 12 tcpdump -i eth0 -n "udp port 5001" -q 2>/dev/null \
  | awk '{print $3}' | sort | uniq -c | sort -rn
```

The last command shows packet counts per source IP — you should see 12 different `12.1.1.x` addresses.

### Notes

- **The `ip route add` is not persistent** — it must be re-run after each container restart. Add it to a startup script if needed.
- **mgen is not persistent** — `docker cp` is re-run by setup.sh on each node boot, but a manual `docker compose restart` of a single container will lose mgen in that container. Re-copy with: `sudo docker cp /usr/bin/mgen <container>:/usr/bin/mgen`
- **Flow IDs** must be unique per mgen instance but can overlap across containers.
- **Rate/size**: `PERIODIC [1.0 1024]` = 1 packet/sec, 1024 bytes. Increase rate (e.g. `[10.0 1024]`) to stress the data path.

---

## UE IMSI / IP Reference

| Container | IMSI | Container IP | PDU session IP |
|-----------|------|--------------|----------------|
| oai-nr-ue1 | 208990100001100 | 192.168.71.150 | 12.1.1.x |
| oai-nr-ue2 | 208990100001101 | 192.168.71.151 | 12.1.1.x |
| oai-nr-ue3 | 208990100001102 | 192.168.71.152 | 12.1.1.x |
| oai-nr-ue4 | 208990100001103 | 192.168.71.153 | 12.1.1.x |
| oai-nr-ue5 | 208990100001104 | 192.168.71.154 | 12.1.1.x |
| oai-nr-ue6 | 208990100001105 | 192.168.71.155 | 12.1.1.x |
| oai-nr-ue7 | 208990100001106 | 192.168.71.156 | 12.1.1.x |
| oai-nr-ue8 | 208990100001107 | 192.168.71.157 | 12.1.1.x |
| oai-nr-ue9 | 208990100001108 | 192.168.71.158 | 12.1.1.x |
| oai-nr-ue10 | 208990100001109 | 192.168.71.159 | 12.1.1.x |
| oai-nr-ue11 | 208990100001110 | 192.168.71.160 | 12.1.1.x |
| oai-nr-ue12 | 208990100001111 | 192.168.71.161 | 12.1.1.x |

PDU session IPs (12.1.1.x) are assigned dynamically from the 12.1.1.0/24 pool.
