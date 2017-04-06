#!/usr/bin/python

import uhal
from I2CuHal import I2CCore
import time
from si5344 import si5344

uhal.setLogLevelTo(uhal.LogLevel.NOTICE)
manager = uhal.ConnectionManager("file://connections.xml")
hw_tx = manager.getDevice("DUNE_FMC_TX")
hw_rx = manager.getDevice("DUNE_FMC_RX")

for hw in [hw_rx, hw_tx]:
    print hw.id()
    reg = hw.getNode("io.csr.stat").read()
    tx = hw.getNode("tx.csr.stat").read()
    rx = hw.getNode("rx.csr.stat").read()
    hw.dispatch()
    print hex(reg), hex(tx), hex(rx)

for hw in [hw_rx, hw_tx]:
    hw.getNode("rx.csr.ctrl.rst").write(1)
    hw.dispatch()
    hw.getNode("rx.csr.ctrl.rst").write(0)
    hw.dispatch()

time.sleep(0.5)

for hw in [hw_rx, hw_tx]:
    hw.getNode("tx.csr.ctrl.clr").write(1)
    hw.dispatch()
    hw.getNode("tx.csr.ctrl.clr").write(0)
    hw.dispatch()

for hw in [hw_rx, hw_tx]:
    print hw.id()
    reg = hw.getNode("io.csr.stat").read()
    tx = hw.getNode("tx.csr.stat").read()
    rx = hw.getNode("rx.csr.stat").read()
    hw.dispatch()
    print hex(reg), hex(tx), hex(rx)

for i in range(1000):
    for hw in [hw_tx, hw_rx]:
        hw.getNode("tx.csr.ctrl.en").write(1);
        hw.dispatch()
    time.sleep(10)
    for hw in [hw_tx, hw_rx]:
        hw.getNode("tx.csr.ctrl.en").write(0);
        hw.dispatch()
    txc_tx = hw_tx.getNode("tx.ctrs").readBlock(16)
    rxc_tx = hw_tx.getNode("rx.ctrs").readBlock(16)
    hw_tx.dispatch()
    txc_rx = hw_rx.getNode("tx.ctrs").readBlock(16)
    rxc_rx = hw_rx.getNode("rx.ctrs").readBlock(16)
    hw_rx.dispatch()
    for j in range(16):
        print hex(i), hex(j), hex(txc_tx[j]), hex(rxc_tx[j]), hex(txc_rx[j]), hex(rxc_rx[j])


        
