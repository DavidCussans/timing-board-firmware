#!/usr/bin/python

# -*- coding: utf-8 -*-
import uhal
from I2CuHal import I2CCore
import time
from si5344 import si5344

uhal.setLogLevelTo(uhal.LogLevel.NOTICE)
manager = uhal.ConnectionManager("file://connections.xml")
hw_tx = manager.getDevice("DUNE_FMC_TX")
hw_rx = manager.getDevice("DUNE_FMC_RX")

for hw in [hw_tx, hw_rx]:

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
    print "Unique ID PROM: " , [hex(no) for no in res]

    clock_I2C = I2CCore(hw, 10, 5, "io.pll_i2c", None)
    zeClock=si5344(clock_I2C)
    res= zeClock.getDeviceVersion()
    zeClock.setPage(0, True)
    zeClock.getPage()
    regCfgList=zeClock.parse_clk("SI5344/PDTS0000.txt")
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

for hw in [hw_tx, hw_rx]:

    print hw.id()
    reg = hw.getNode("io.csr.stat").read()
    hw.dispatch()
    print hex(reg)
