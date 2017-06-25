#!/usr/bin/python

import uhal
import time

uhal.setLogLevelTo(uhal.LogLevel.NOTICE)
manager = uhal.ConnectionManager("file://connections.xml")
hw_list = [manager.getDevice(i) for i in sys.argv[1:]]

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
        r2 = hw.getNode("csr.stat.zflag").read()
        cyc_l = hw.getNode("csr.cyc_ctr_l").read()
        cyc_h = hw.getNode("csr.cyc_ctr_h").read()
        sfp_l = hw.getNode("csr.sfp_ctr_l").read()
        sfp_h = hw.getNode("csr.sfp_ctr_h").read()
        hw.dispatch()
        print i, hw.id(), hex(reg), hex(r2), hex(int(cyc_l) + (int(cyc_h) << 32)), hex(int(sfp_l) +(int(sfp_h) << 32))
