#!/usr/bin/env python3

import geni.portal as portal
import geni.rspec.pg as rspec
import geni.rspec.igext as IG

pc = portal.context

pc.defineParameter("hwtype", "Hardware type", portal.ParameterType.NODETYPE, "d430")

params = pc.bindParameters()
pc.verifyParameters()

request = pc.makeRequestRSpec()

IMAGE = "urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU20-64-STD"

# Single node runs everything: CN + gNB + UEs all in Docker Compose
node = request.RawPC("cn")
node.hardware_type = params.hwtype
node.disk_image = IMAGE
node.addService(rspec.Execute(
    shell="bash",
    command="sudo mkdir -p /local/logs && sudo bash /local/repository/bin/setup.sh >> /local/logs/setup.log 2>&1"
))

tour = IG.Tour()
tour.Description(IG.Tour.TEXT,
    "OAI 5G SA RFsim single-node emulation. "
    "All containers (CN + gNB + 4 UEs) run on Docker Compose on one d430 node. "
    "PLMN 208/99 TAC=1 SST=1 DNN=oai. "
    "Uses develop images for gNB/UE, v2.0.0 for CN."
)
tour.Instructions(IG.Tour.TEXT,
    "Allow 15-20 min after boot. "
    "Check /local/logs/setup.log for status. "
    "Run: sudo docker ps to see all containers. "
    "Run: sudo docker logs rfsim5g-oai-nr-ue1 to check UE attach."
)
request.addTour(tour)

pc.printRequestRSpec()