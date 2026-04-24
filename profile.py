#!/usr/bin/env python3

import geni.portal as portal
import geni.rspec.pg as rspec
import geni.rspec.igext as IG

pc = portal.context

pc.defineParameter("ue_count", "Number of UE nodes", portal.ParameterType.INTEGER, 2)
pc.defineParameter("hwtype", "Hardware type", portal.ParameterType.NODETYPE, "d430")

params = pc.bindParameters()

if params.ue_count < 1 or params.ue_count > 8:
    pc.reportError(portal.ParameterError("Choose between 1 and 8 UE nodes.", ["ue_count"]))

pc.verifyParameters()

request = pc.makeRequestRSpec()

IMAGE = "urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU20-64-STD"
MASK = "255.255.255.0"

def attach(lan, node, ifname, ip):
    iface = node.addInterface(ifname)
    iface.addAddress(rspec.IPv4Address(ip, MASK))
    lan.addInterface(iface)

simlan = request.LAN("simnet")
simlan.best_effort = True
simlan.vlan_tagging = False

# CN node runs: Core Network + gNB (co-located for RFsim timing)
cn = request.RawPC("cn")
cn.hardware_type = params.hwtype
cn.disk_image = IMAGE
cn.addService(rspec.Execute(shell="bash", command="sudo mkdir -p /local/logs && sudo bash /local/repository/bin/setup-cn.sh >> /local/logs/setup-cn.log 2>&1"))
attach(simlan, cn, "if-cn", "10.10.0.10")

# UE nodes
for i in range(params.ue_count):
    ue = request.RawPC("ue" + str(i+1))
    ue.hardware_type = params.hwtype
    ue.disk_image = IMAGE
    ue.addService(rspec.Execute(shell="bash", command="sudo mkdir -p /local/logs && sudo bash /local/repository/bin/setup-ue.sh " + str(i+1) + " >> /local/logs/setup-ue.log 2>&1"))
    attach(simlan, ue, "if-ue" + str(i+1), "10.10.0." + str(30+i))

tour = IG.Tour()
tour.Description(IG.Tour.TEXT, "OAI 5G SA RFsim co-located. CN + gNB on same node + N UE nodes. PLMN 208/95 SST=1 SD=1 DNN=oai.")
tour.Instructions(IG.Tour.TEXT, "Allow 15-20 min after boot. Check /local/logs/ on each node.")
request.addTour(tour)

pc.printRequestRSpec()