#!/usr/bin/python

# -*- coding: utf-8 -*-
import uhal
import time

uhal.setLogLevelTo(uhal.LogLevel.NOTICE)
manager = uhal.ConnectionManager("file://connections.xml")
hw_list = [manager.getDevice("DUNE_FMC_SIM")]

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
