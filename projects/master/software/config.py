#!/usr/bin/python

# -*- coding: utf-8 -*-
import uhal
import time

uhal.setLogLevelTo(uhal.LogLevel.NOTICE)
manager = uhal.ConnectionManager("file://connections.xml")
hw_list = [manager.getDevice("SIM")]

for hw in hw_list:

    print hw.id()

    m_v = hw.getNode("master.global.version").read()
    hw.dispatch()
    print "Version:", hex(m_v)

    m_t = hw.getNode("master.global.tstamp").readBlock(2)
    hw.dispatch()
    m_stat = hw.getNode("master.global.csr.stat").read()
    hw.dispatch()
    print "m_t / m_stat / e_stat:", hex(int(m_t[0]) + (int(m_t[1]) << 32)), hex(m_stat)

    hw.getNode("master.partition.csr.ctrl.part_en").write(1)
    hw.dispatch()

    time.sleep(4)

    m_t = hw.getNode("master.global.tstamp").readBlock(2)
    hw.dispatch()
    m_stat = hw.getNode("master.global.csr.stat").read()
    hw.dispatch()
    print "m_t / m_stat / e_stat:", hex(int(m_t[0]) + (int(m_t[1]) << 32)), hex(m_stat)
