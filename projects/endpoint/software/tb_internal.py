#!/usr/bin/python

import uhal
import time

manager = uhal.ConnectionManager("file://connections.xml")
hw = manager.getDevice("DUNE_FMC_TX")

r = hw.getNode("csr.stat").read()
hw.getNode("csr.ctrl.soft_rst").write(1)
hw.dispatch()
print hex(r)

r = hw.getNode("csr.stat").read()
hw.dispatch()
print hex(r)

hw.getNode("csr.ctrl.rst").write(1)
hw.dispatch()
hw.getNode("csr.ctrl.rst").write(0)
hw.dispatch()

hw.getNode("csr.ctrl.rx_en").write(1)
hw.dispatch()

r = hw.getNode("csr.stat").read()
hw.dispatch()
print hex(r)


for i in range(100):
	hw.getNode("csr.ctrl.tx_en").write(1)
	hw.dispatch()
	time.sleep(5)
	hw.getNode("csr.ctrl.tx_en").write(0)
	hw.dispatch()
	tx = hw.getNode("tx_ctrs").readBlock(16)
	rx = hw.getNode("rx_ctrs").readBlock(16)
	stat = hw.getNode("csr.stat").read()
	hw.dispatch()
	for j in range(16):
		print hex(i), hex(tx[j]), hex(rx[j]), hex(stat)
		if int(tx[j]) != int(rx[j]):
			print "Ouch"