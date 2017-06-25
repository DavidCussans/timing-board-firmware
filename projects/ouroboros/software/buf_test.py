#!/usr/bin/python

# -*- coding: utf-8 -*-
import sys
import uhal
import time
import random

def status(hw):
    m_t = hw.getNode("master.global.tstamp").readBlock(2)
    m_e = hw.getNode("master.partition.evtctr").read()
    e_t = hw.getNode("endpoint.tstamp").readBlock(2)
    e_e = hw.getNode("endpoint.evtctr").read()
    m_c = hw.getNode("master.partition.buf.count").read()
    e_c = hw.getNode("endpoint.buf.count").read()
    m_stat = hw.getNode("master.global.csr.stat").read()
    p_stat = hw.getNode("master.partition.csr.stat").read()
    e_stat = hw.getNode("endpoint.csr.stat").read()
    s_a = hw.getNode("master.scmd_gen.actrs").readBlock(N_SCHAN)
    s_r = hw.getNode("master.scmd_gen.rctrs").readBlock(N_SCHAN)
    p_a = hw.getNode("master.partition.actrs").readBlock(N_TYPE)
    p_r = hw.getNode("master.partition.rctrs").readBlock(N_TYPE)
    e_a = hw.getNode("endpoint.ctrs").readBlock(N_TYPE)
    hw.dispatch()
    print hw.id()
    print "m_stat / p_stat / e_stat:", hex(m_stat), hex(p_stat), hex(e_stat)
    print "m_t / m_e / m_c", hex(int(m_t[0]) + (int(m_t[1]) << 32)), hex(m_e), hex(m_c)
    print "e_t / e_e / e_c:", hex(int(e_t[0]) + (int(e_t[1]) << 32)), hex(e_e), hex(e_c)
    print "s_a", "|".join(["{0:08x}".format(int(i)) for i in s_a])
    print "s_r", "|".join(["{0:08x}".format(int(i)) for i in s_r])
    print "p_a", "|".join(["{0:08x}".format(int(i)) for i in p_a])
    print "p_r", "|".join(["{0:08x}".format(int(i)) for i in p_r])
    print "e_a", "|".join(["{0:08x}".format(int(i)) for i in e_a])

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

N_SCHAN = 1
N_TYPE = 5

for hw in hw_list:

    hw.getNode("endpoint.csr.ctrl.ep_en").write(1)
    hw.getNode("master.scmd_gen.ctrl.en").write(1)
    hw.getNode("master.partition.csr.ctrl.cmd_mask").write(0x000f)
    hw.getNode("master.partition.csr.ctrl.trig_en").write(1)
    hw.getNode("master.partition.csr.ctrl.part_en").write(1)
    hw.getNode("master.scmd_gen.chan_ctrl.type").write(3)
    hw.getNode("master.scmd_gen.chan_ctrl.rate_div").write(0xb)
    hw.getNode("master.scmd_gen.chan_ctrl.patt").write(1)
    hw.getNode("master.partition.csr.ctrl.buf_en").write(1)
    hw.getNode("endpoint.csr.ctrl.buf_en").write(1)
    hw.dispatch()

    status(hw)

    hw.getNode("master.scmd_gen.chan_ctrl.en").write(1)
    hw.dispatch()

for i in range(256):

    time.sleep(1)

    for hw in hw_list:

        status(hw)
        dump(hw.getNode("master.partition.buf"))
        dump(hw.getNode("endpoint.buf"))
