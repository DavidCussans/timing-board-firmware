#!/usr/bin/python

# -*- coding: utf-8 -*-
import uhal
from I2CuHal import I2CCore
import time
from si5344 import si5344

manager = uhal.ConnectionManager("file://dave.xml")
hw = manager.getDevice("DUNE_FMC_RX")

reg = hw.getNode("csr.stat").read()
hw.dispatch()
print hex(reg)

# #Third I2C core
print ("Instantiating clock I2C core:")
clock_I2C= I2CCore(hw, 10, 5, "pll_i2c", None)
clock_I2C.state()

zeClock=si5344(clock_I2C)
res= zeClock.getDeviceVersion()
zeClock.setPage(0, True)
zeClock.getPage()
regCfgList=zeClock.parse_clk("Si5344_cfg50_tx_lowbw.txt")
zeClock.writeConfiguration(regCfgList)

hw.getNode("csr.ctrl.sfp_tx_dis").write(0)
hw.dispatch()

for i in range(2):
    hw.getNode("freq.ctrl.chan_sel").write(i);
    hw.getNode("freq.ctrl.en_crap_mode").write(0);
    hw.dispatch()
    time.sleep(2)
    fq = hw.getNode("freq.freq.count").read();
    fv = hw.getNode("freq.freq.valid").read();
    hw.dispatch()
    print "Freq:", i, int(fv), int(fq) * 119.20928 / 1000000;

r1 = zeClock.readRegister(0x000c, 4)
print hex(r1[0]), hex(r1[1]), hex(r1[2]), hex(r1[3])
r1 = zeClock.readRegister(0x0012, 2)
print hex(r1[0]), hex(r1[1])
r1 = zeClock.readRegister(0x0507, 1)
print hex(r1[0])
