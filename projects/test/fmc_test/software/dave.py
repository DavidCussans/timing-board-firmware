#!/usr/bin/python

# -*- coding: utf-8 -*-
import uhal
from I2CuHal import I2CCore
import time
from si5344 import si5344

manager = uhal.ConnectionManager("file://connections.xml")
hw = manager.getDevice("DUNE_FMC_TX")

reg = hw.getNode("csr.stat").read()
hw.dispatch()
print hex(reg)

# #Third I2C core
print ("Instantiating clock I2C core:")
clock_I2C = I2CCore(hw, 10, 5, "pll_i2c", None)
clock_I2C.state()

zeClock=si5344(clock_I2C)
res= zeClock.getDeviceVersion()
zeClock.setPage(0, True)
zeClock.getPage()
regCfgList=zeClock.parse_clk("SI5344/Si5344_revd_cfg50_freerun.txt")
zeClock.writeConfiguration(regCfgList)

uid_I2C = I2CCore(hw, 10, 5, "uid_i2c", None)
uid_I2C.state()
uid_I2C.write(0x21, [0x01, 0x7f], True)
uid_I2C.write(0x21, [0x01], False)
res = uid_I2C.read(0x21, 1)
print "I2c enable lines: " , res
uid_I2C.write(0x53, [0xfa], False)
res = uid_I2C.read(0x53, 6)
print "Unique ID PROM: " , [hex(no) for no in res]

hw.getNode("csr.ctrl.sfp_tx_dis").write(0)
hw.dispatch()

time.sleep(1)

#hw.getNode("csr.ctrl.cdr_rst").write(1)
#hw.dispatch()
#hw.getNode("csr.ctrl.cdr_rst").write(0)
#hw.dispatch()

#time.sleep(1)

for i in range(2):
    hw.getNode("freq.ctrl.chan_sel").write(i);
    hw.getNode("freq.ctrl.en_crap_mode").write(0);
    hw.dispatch()
    time.sleep(2)
    fq = hw.getNode("freq.freq.count").read();
    fv = hw.getNode("freq.freq.valid").read();
    hw.dispatch()
    print "Freq:", i, int(fv), int(fq) * 119.20928 / 1000000;

reg = hw.getNode("csr.stat").read()
hw.dispatch()
print hex(reg)

r1 = zeClock.readRegister(0x0012, 2)
print hex(r1[0]), hex(r1[1])
zeClock.writeRegister(0x0012, [0x0])
zeClock.writeRegister(0x0013, [0x0])
r1 = zeClock.readRegister(0x0012, 2)
print hex(r1[0]), hex(r1[1])
r1 = zeClock.readRegister(0x0507, 1)
print hex(r1[0])


time.sleep(0.5)

hw.getNode("csr.ctrl.prbs_init").write(1);
hw.dispatch()
hw.getNode("csr.ctrl.prbs_init").write(0);
hw.dispatch()

time.sleep(0.5)

for i in range(1):

    reg = hw.getNode("csr.stat").read()
    cyc_l = hw.getNode("csr.cyc_ctr_l").read()
    cyc_h = hw.getNode("csr.cyc_ctr_h").read()
    sfp_l = hw.getNode("csr.sfp_ctr_l").read()
    sfp_h = hw.getNode("csr.sfp_ctr_h").read()
    rj45_l = hw.getNode("csr.rj45_ctr_l").read()
    rj45_h = hw.getNode("csr.rj45_ctr_h").read()
    sfp_f_l = hw.getNode("csr.sfp_f_ctr_l").read()
    sfp_f_h = hw.getNode("csr.sfp_f_ctr_h").read()
    rj45_f_l = hw.getNode("csr.rj45_f_ctr_l").read()
    rj45_f_h = hw.getNode("csr.rj45_f_ctr_h").read()
    hw.dispatch()
    print i, hex(reg), hex(int(cyc_l) + (int(cyc_h) << 32)), hex(int(sfp_l) +(int(sfp_h) << 32)), hex(int(rj45_l) +(int(rj45_h) << 32)), hex(int(sfp_f_l) +(int(sfp_f_h) << 32)), hex(int(rj45_f_l) +(int(rj45_f_h) << 32))
