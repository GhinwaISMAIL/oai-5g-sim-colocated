#!/usr/bin/env python3

"""
OAI 5G SA RFsim Scale-Out Profile
-----------------------------------
Topology:
  - 1 CN node   : OAI Core Network (AMF, SMF, UPF, NRF, UDM, UDR, AUSF) via Docker
  - 1 gNB node  : OAI gNB in RFsim server mode via Docker
  - N UE nodes  : OAI nrUE in RFsim client mode via Docker

Experimental LAN: 10.10.0.0/24
  cn   -> 10.10.0.10
  gnb  -> 10.10.0.20
  ue1  -> 10.10.0.30
  ue2  -> 10.10.0.31
  ...
"""

import geni.portal as portal
import geni.rspec.pg as rspec
import geni.rspec.igext as IG

# ----------------------------------------------------------------- #
# Portal context and parameters
# ------------------------------------------------------------------ #
pc = portal.context

pc.defineParameter(
    "ue_count",
    "Number of UE nodes",
    portal.ParameterType.INTEGER,
    2,
    longDescription="How many nrUE nodes to create. Min 1, max 8."
)

pc.defineParameter(
    "hwtype",
    "Hardware type for all nodes",
    portal.ParameterType.NODETYPE,
    "d430",
    longDescription="All nodes use the same hardware type. d430 is the default."
)

params = pc.bindParameters()

# ------------------------------------------------------------------ #
# Parameter validation
# ------------------------------------------------------------------ #
if params.ue_count < 1 or params.ue_count > 8:
    pc.reportError(
        portal.ParameterError(
            "Choose between 1 and 8 UE nodes.",
            ["ue_count"]
        )
    )

pc.verifyParameters()

# ------------------------------------------------------------------ #
# Request and base image
# ------------------------------------------------------------------ #
request = pc.makeRequestRSpec()

# Clean Ubuntu 20.04 — we install everything via startup scripts
IMAGE = "urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU20-64-STD"
MASK  = "255.255.255.0"

# ------------------------------------------------------------------ #
# Helper: attach a node to the experimental LAN
# ------------------------------------------------------------------ #
def attach(lan, node, ifname, ip):
    iface = node.addInterface(ifname)
    iface.addAddress(rspec.IPv4Address(ip, MASK))
    lan.addInterface(iface)

# ------------------------------------------------------------------ #
# Experimental LAN
# ------------------------------------------------------------------ #
simlan = request.LAN("simnet")
simlan.best_effort    = True
simlan.vlan_tagging   = False

# ------------------------------------------------------------------ #
# CN node
# ------------------------------------------------------------------ #
cn = request.RawPC("cn")
cn.hardware_type = params.hwtype
cn.disk_image    = IMAGE
cn.addService(rspec.Execute(
    shell="bash",
    command="/local/repository/bin/setup-cn.sh >> /local/logs/setup-cn.log 2>&1"
))
attach(simlan, cn, "if-cn", "10.10.0.10")

# ------------------------------------------------------------------ #
# gNB node
# ------------------------------------------------------------------ #
gnb = request.RawPC("gnb")
gnb.hardware_type = params.hwtype
gnb.disk_image    = IMAGE
gnb.addService(rspec.Execute(
    shell="bash",
    command="/local/repository/bin/setup-gnb.sh >> /local/logs/setup-gnb.log 2>&1"
))
attach(simlan, gnb, "if-gnb", "10.10.0.20")

# ------------------------------------------------------------------ #
# UE nodes
# ------------------------------------------------------------------ #
for i in range(params.ue_count):
    ue = request.RawPC(f"ue{i+1}")
    ue.hardware_type = params.hwtype
    ue.disk_image    = IMAGE
    ue.addService(rspec.Execute(
        shell="bash",
        command=f"/local/repository/bin/setup-ue.sh {i+1} >> /local/logs/setup-ue.log 2>&1"
    ))
    attach(simlan, ue, f"if-ue{i+1}", f"10.10.0.{30+i}")

# ------------------------------------------------------------------ #
# Tour (shown in POWDER UI)
# ------------------------------------------------------------------ #
tour = IG.Tour()

tour.Description(IG.Tour.MARKDOWN, """
## OAI 5G SA RFsim Scale-Out

This profile deploys a fully automated OAI 5G Standalone simulator on POWDER using RFsim.

**Topology:**
- `cn` node — Core Network (AMF, SMF, UPF, NRF, UDM, UDR, AUSF) via Docker Compose
- `gnb` node — OAI gNB in RFsim server mode
- `ueN` nodes — OAI nrUE instances, one per node, each with a unique IMSI

**Experimental LAN:** `10.10.0.0/24`

All components start automatically at boot. Check `/local/logs/` on each node for progress.
""")
