#!/usr/bin/python

# -*- coding: utf-8 -*-
import sys
import uhal
import time

def dump(buf):
    c = buf.getNode("count").read()
    hw.dispatch()
    print buf.getPath(), hex(c)
    d = buf.getNode("data").readBlock(6 * (int(c) // 6))
    hw.dispatch()
    if len(d) != 0:
        e = [int(i) for i in d]
        for j in range(0, len(d), 6):
            print "{0:04x}".format(j), "|".join(["{0:08x}".format(int(i)) for i in e[j:j+6]])

uhal.setLogLevelTo(uhal.LogLevel.NOTICE)
manager = uhal.ConnectionManager("file://connections.xml")
hw_list = [manager.getDevice(i) for i in sys.argv[1:]]

if len(hw_list) == 0:
	print "No targets specified - I'm done"
	sys.exit()

for hw in hw_list:

    print hw.id()

    m_v = hw.getNode("master.global.version").read()
    hw.dispatch()
    print "FW version:", hex(m_v)

    m_t = hw.getNode("master.global.tstamp").readBlock(2)
    m_stat = hw.getNode("master.global.csr.stat").read()
    hw.dispatch()
    print "m_ts / m_stat:", hex(int(m_t[0]) + (int(m_t[1]) << 32)), hex(m_stat)

    hw.getNode("master.partition.csr.ctrl.trig_en").write(1)
	hw.getNode("master.partition.csr.ctrl.part_en").write(1) # Enable partition 0
    hw.getNode("master.partition.csr.ctrl.buf_en").write(1) # Disable buffer in partition 0
    hw.getNode("master.partition.csr.ctrl.cmd_mask").write(0x000f) # Set command mask in partition 0
    hw.dispatch()

    time.sleep(1) # Allow endpoint time to sync

    hw.getNode("master.scmd_gen.ctrl.en").write(1) # Enable sync command generators
    hw.dispatch()
    
    hw.getNode("master.scmd_gen.chan_ctrl.type").write(1) # Set command type = 1 for generator 0
    hw.getNode("master.scmd_gen.chan_ctrl.force").write(1) # Issue a single command
    hw.dispatch()
    
    hw.getNode("master.scmd_gen.chan_ctrl.type").write(3) # Set command type = 3 for generator 0
    hw.getNode("master.scmd_gen.chan_ctrl.rate_div").write(0xe) # Set about 1Hz rate for generator 0
    hw.getNode("master.scmd_gen.chan_ctrl.patt").write(1) # Set Poisson mode for generator 0
    hw.getNode("master.scmd_gen.chan_ctrl.en").write(1) # Start the command stream
    hw.dispatch()
    
while True:

    time.sleep(1)

    for hw in hw_list:

        status(hw)
        dump(hw.getNode("master.partition.buf"))
