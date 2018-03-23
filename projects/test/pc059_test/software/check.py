#!/usr/bin/python

import uhal
import time
import sys

uhal.setLogLevelTo(uhal.LogLevel.NOTICE)
manager = uhal.ConnectionManager("file://connections.xml")
hw_list = [manager.getDevice(i) for i in sys.argv[1:]]

if len(hw_list) == 0:
	print "No targets specified - I'm done"
	sys.exit()

for hw in hw_list:
    print hw.id()
    hw.getNode("csr.ctrl.prbs_init").write(1);
    hw.dispatch()
    hw.getNode("csr.ctrl.prbs_init").write(0);
    hw.dispatch()
    reg = hw.getNode("io.csr.stat").read()
    hw.dispatch()
    print hex(reg)

while True:

    time.sleep(1)
    for hw in hw_list:
        reg = hw.getNode("io.csr.stat").read()
        z_sfp = hw.getNode("csr.stat.zflag").read()
        z_rj45 = hw.getNode("csr.stat.zflag_rj45").read()
        cyc_l = hw.getNode("csr.cyc_ctr_l").read()
        cyc_h = hw.getNode("csr.cyc_ctr_h").read()
        sfp_l = hw.getNode("csr.sfp_ctr_l").read()
        sfp_h = hw.getNode("csr.sfp_ctr_h").read()
        rj45_l = hw.getNode("csr.rj45_ctr_l").read()
        rj45_h = hw.getNode("csr.rj45_ctr_h").read()
        hw.dispatch()
        print i, hw.id(), hex(reg), hex(z_sfp), hex(z_rj45), hex(int(cyc_l) + (int(cyc_h) << 32)), hex(int(sfp_l) +(int(sfp_h) << 32)), hex(int(rj45_l) +(int(rj45_h) << 32))
