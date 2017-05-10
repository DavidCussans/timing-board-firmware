#!/usr/bin/python

# -*- coding: utf-8 -*-
import uhal
import time

uhal.setLogLevelTo(uhal.LogLevel.NOTICE)
manager = uhal.ConnectionManager("file://connections.xml")
hw_list = [manager.getDevice("DUNE_FMC_MASTER")]

for hw in hw_list:

    print hw.id()

    reg = hw.getNode("io.csr.stat").read()
    hw.getNode("io.csr.ctrl.soft_rst").write(1)
    hw.dispatch()
    print hex(reg)

    hw.getNode("io.csr.ctrl.rst").write(1)
    hw.getNode("io.csr.ctrl.rst").write(0)
    hw.dispatch()
    print hex(reg)

    m_v = hw.getNode("master.global.version").read()
    e_v = hw.getNode("endpoint.version").read()
    hw.dispatch()
    print "Versions:", hex(m_v), hex(e_v)

    hw.getNode("endpoint.csr.ctrl.ep_en").write(1)
    hw.getNode("master.partition.csr.ctrl.part_en").write(1)
    hw.dispatch()

    time.sleep(4)

    m_t = hw.getNode("master.global.tstamp").readBlock(2)
    hw.dispatch()
    m_stat = hw.getNode("master.global.csr.stat").read()
    hw.dispatch()
    e_stat = hw.getNode("endpoint.csr.stat").read()
    hw.dispatch()
    print "m_t / m_stat / e_stat:", hex(int(m_t[0]) + (int(m_t[1]) << 32)), hex(m_stat), hex(e_stat)
