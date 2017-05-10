#!/usr/bin/python

# -*- coding: utf-8 -*-
import uhal
import time

uhal.setLogLevelTo(uhal.LogLevel.NOTICE)
manager = uhal.ConnectionManager("file://connections.xml")
hw_list = [manager.getDevice("DUNE_FMC_MASTER")]

for hw in hw_list:

    print hw.id()

    m_v = hw.getNode("master.global.version").read()
    hw.dispatch()
    print "Version:", hex(m_v)

    m_t = hw.getNode("master.global.tstamp").readBlock(2)
    m_stat = hw.getNode("master.global.csr.stat").read()
    hw.dispatch()
    print "m_ts / m_stat:", hex(int(m_t[0]) + (int(m_t[1]) << 32)), hex(m_stat)

	hw.getNode("master.partition.csr.ctrl.part_en").write(1) # Enable partition 0
    hw.getNode("master.partition.csr.ctrl.buf_en").write(1) # Enable buffer in partition 0
    hw.getNode("master.partition.csr.ctrl.cmd_mask").write(0x000f) # Set command mask in partition 0
    hw.dispatch()

    time.sleep(4)

    hw.getNode("master.scmd_gen.ctrl.en").write(1) # Enable sync command generators
    hw.getNode("master.scmd_gen.chan_ctrl.type").write(3) # Set type=3 for generator 0
    hw.getNode("master.scmd_gen.chan_ctrl.rate_div").write(0xe) # Set about 1Hz rate for generator 0
    hw.getNode("master.scmd_gen.chan_ctrl.patt").write(1) # Set Poisson mode for generator 0
    hw.getNode("master.scmd_gen.chan_ctrl.en").write(1) # Start the command stream
    hw.dispatch()
