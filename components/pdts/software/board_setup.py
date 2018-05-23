#!/usr/bin/python

import sys
import uhal
import time
from I2CuHal import I2CCore
from si5344 import si5344

brd_rev = {
	0xd880395e720b: 1,
	0xd880395e501a: 1,
	0xd880395e50b8: 1,
	0xd880395e501b: 1,
	0xd880395e7201: 1,
	0xd880395e4fcc: 1,
	0xd880395e5069: 1,
	0xd880395e7206: 1,
	0xd880395e1c86: 2,
	0xd880395e2630: 2,
	0xd880395e262b: 2,
	0xd880395e2b38: 2,
	0xd880395e1a6a: 2,
	0xd880395e36ae: 2,
	0xd880395e2b2e: 2,
	0xd880395e2b33: 2,
	0xd880395e1c81: 2,
	0xd88039d980cf: 3,
	0xd88039d98adf: 3,
        0xd88039d9248e: 3
}

clk_cfg_files = {
	1: "SI5344/PDTS0000.txt",
	2: "SI5344/PDTS0003.txt",
	3: "SI5344/PDTS0005.txt"
}

uhal.setLogLevelTo(uhal.LogLevel.NOTICE)
manager = uhal.ConnectionManager("file://connections.xml")
hw_list = [manager.getDevice(i) for i in sys.argv[1:]]

if len(hw_list) == 0:
	print "No targets specified - I'm done"
	sys.exit()

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

    if "io.i2c" in hw.getNodes("io.*"):
	    uid_I2C = I2CCore(hw, 10, 5, "io.i2c", None)
	    clock_I2C = I2CCore(hw, 10, 5, "io.i2c", None)
	    eeprom_addr = 0x57
	    print "This address map is for a pc059"
    else:
	    uid_I2C = I2CCore(hw, 10, 5, "io.uid_i2c", None)
	    clock_I2C = I2CCore(hw, 10, 5, "io.pll_i2c", None)
	    eeprom_addr = 0x53
	    print "This address map is for a pc053"

    uid_I2C.write(0x0, [8 * 0x0], True) # Wake up AX3 EEPROM if present
    time.sleep(0.1)
    res = uid_I2C.read(0x64, 4)
    if res == [0x04, 0x11, 0x33, 0x43]:
        print "AX3 detected; setting I2C bus switch"
        uid_I2C.write(0x21, [0x01, 0x7f], True) # Set up AX3 bus switch
    else:
        print "Not an AX3, assuming a Xilinx KX705; setting I2C bus switch"
        uid_I2c.write(0x74, [0x10]) # Set up KC705 bus switch   

    uid_I2C.write(eeprom_addr, [0xfa], False)
    res = uid_I2C.read(eeprom_addr, 6)
    id = 0
    for i in res:
    	id = (id << 8) | int(i)
    print "Unique ID PROM / board rev:", hex(id), brd_rev[id]

    zeClock=si5344(clock_I2C)
    res= zeClock.getDeviceVersion()
    zeClock.setPage(0, True)
    zeClock.getPage()
    regCfgList=zeClock.parse_clk(clk_cfg_files[brd_rev[id]])
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
        
    hw.getNode("io.csr.ctrl.rst").write(1)
    hw.dispatch()
    hw.getNode("io.csr.ctrl.rst").write(0)
    hw.dispatch()

for hw in hw_list:

    print hw.id()
    reg = hw.getNode("io.csr.stat").read()
    hw.dispatch()
    print hex(reg)
