#!/usr/bin/python

# -*- coding: utf-8 -*-
import uhal
from I2CuHal import I2CCore
import time
from si5344 import si5344

uhal.setLogLevelTo(uhal.LogLevel.NOTICE)
manager = uhal.ConnectionManager("file://connections.xml")
hw_tx = manager.getDevice("DUNE_FMC_TX")
hw_rx = manager.getDevice("DUNE_FMC_RX")

for hw in [hw_tx, hw_rx]:
    print hw.id()
    reg = hw.getNode("io.csr.stat").read()
    hw.dispatch()
    print hex(reg)
