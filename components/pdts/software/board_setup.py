#!/usr/bin/python

# -*- coding: utf-8 -*-
import sys
import uhal
from I2CuHal import I2CCore
import time
from si5344 import si5344

brd_rev = {
	0xd880395e720b: 1,
	0xd880395e501a: 1,
	0xd880395e50b8: 1,
	0xd880395e501b: 1,
	0xd880395e7201: 1,
	0xd880395e4fcc: 1,
	0xd880395e5069: 1,
	0xd880395e1c86: 2,
	0xd880395e2630: 2,
	0xd880395e262b: 2,
	0xd880395e2b38: 2,
	0xd880395e1a6a: 2,
	0xd880395e36ae: 2,
	0xd880395e2b2e: 2,
	0xd880395e2b33: 2,
	0xd880395e1c81: 2
}

clk_cfg_files = {
	1: "SI5344/PDTS0000.txt",
	2: "SI5344/PDTS0000.txt"
}

uhal.setLogLevelTo(uhal.LogLevel.NOTICE)
manager = uhal.ConnectionManager("file://connections.xml")
hw_list = [manager.getDevice(i) for i in sys.argv[1:]]

for hw in hw_list:

    print hw.id()

    reg = hw.getNode("io.csr.stat").read()
    hw.getNode("io.csr.ctrl.soft_rst").write(1)
    hw.dispatch()
    print hex(reg)

    time.sleep(1)

    hw.getNode("io.csr.ctrl.pll_rst").write(1)
    hw.dispatch()
    hw.getNode("io.csr.ctrl.pll_rst").write(0)
    hw.dispatch()

    uid_I2C = I2CCore(hw, 10, 5, "io.uid_i2c", None)
    uid_I2C.write(0x21, [0x01, 0x7f], True)
    uid_I2C.write(0x21, [0x01], False)
    res = uid_I2C.read(0x21, 1)
    print "I2c enable lines: " , res
    uid_I2C.write(0x53, [0xfa], False)
    res = uid_I2C.read(0x53, 6)
    id = 0
    for i in res:
    	id = (id << 8) | int(i)
    print "Unique ID PROM:", hex(id)
    print "Board rev:", brd_rev[id]

    clock_I2C = I2CCore(hw, 10, 5, "io.pll_i2c", None)
    zeClock=si5344(clock_I2C)
    res= zeClock.getDeviceVersion()
    zeClock.setPage(0, True)
    zeClock.getPage()
    regCfgList=zeClock.parse_clk(pll_cfg_list.pop(0))
    zeClock.writeConfiguration(regCfgList)

    for i in range(2):
        hw.getNode("io.freq.ctrl.chan_sel").write(i);
        hw.getNode("io.freq.ctrl.en_crap_mode").write(0);
        hw.dispatch()
        time.sleep(2)
        fq = hw.getNode("io.freq.freq.count").read();
        fv = hw.getNode("io.freq.freq.valid").read();
        hw.dispatch()
        print "Freq:", i, int(fv), int(fq) * 119.20928 / 1000000;
        
    hw.getNode("io.csr.ctrl.sfp_tx_dis").write(0)
    hw.dispatch()

    hw.getNode("io.csr.ctrl.rst").write(1)
    hw.dispatch()
    hw.getNode("io.csr.ctrl.rst").write(0)
    hw.dispatch()

for hw in hw_list:

    print hw.id()
    reg = hw.getNode("io.csr.stat").read()
    hw.dispatch()
    print hex(reg)
