#!/usr/bin/python

# -*- coding: utf-8 -*-
import sys
import uhal
import time
import random

def status(hw):
    m_t = hw.getNode("master.global.tstamp").readBlock(2)
    m_stat = hw.getNode("master.global.csr.stat").read()
    e_stat = hw.getNode("endpoint.csr.stat").read()
    s_a = hw.getNode("master.scmd_gen.actrs").readBlock(N_SCHAN)
    s_r = hw.getNode("master.scmd_gen.rctrs").readBlock(N_SCHAN)
    p_a = hw.getNode("master.partition.actrs").readBlock(N_TYPE)
    p_r = hw.getNode("master.partition.rctrs").readBlock(N_TYPE)
    e_a = hw.getNode("endpoint.ctrs").readBlock(N_TYPE)
    hw.dispatch()
    print hw.id()
    print "m_t / m_stat / e_stat:", hex(int(m_t[0]) + (int(m_t[1]) << 32)), hex(m_stat), hex(e_stat)
    print "s_a", "|".join(["{0:08x}".format(int(i)) for i in s_a])
    print "s_r", "|".join(["{0:08x}".format(int(i)) for i in s_r])
    print "p_a", "|".join(["{0:08x}".format(int(i)) for i in p_a])
    print "p_r", "|".join(["{0:08x}".format(int(i)) for i in p_r])
    print "e_a", "|".join(["{0:08x}".format(int(i)) for i in e_a])

uhal.setLogLevelTo(uhal.LogLevel.NOTICE)
manager = uhal.ConnectionManager("file://connections.xml")
hw_list = [manager.getDevice(i) for i in sys.argv[1:]]

if len(hw_list) == 0:
	print "No targets specified - I'm done"
	sys.exit()

N_SCHAN = 1
N_TYPE = 5

for hw in hw_list:

    hw.getNode("endpoint.csr.ctrl.ep_en").write(1)
    hw.getNode("master.scmd_gen.ctrl.en").write(1)
    hw.getNode("master.partition.csr.ctrl.cmd_mask").write(0x000f)
    hw.getNode("master.scmd_gen.chan_ctrl.type").write(1)
    hw.getNode("master.partition.csr.ctrl.trig_en").write(1)
    hw.getNode("master.partition.csr.ctrl.part_en").write(1)
    hw.dispatch()

    status(hw)

while True:

    for i in range(256):

        for hw in hw_list:

            hw.getNode("master.scmd_gen.chan_ctrl.type").write(random.randrange(N_TYPE - 1))
            hw.getNode("master.scmd_gen.chan_ctrl.force").write(1)
            hw.getNode("master.scmd_gen.chan_ctrl.force").write(0)
            hw.dispatch()

    for hw in hw_list:
        status(hw)

    time.sleep(1)
