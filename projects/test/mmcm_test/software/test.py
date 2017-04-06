#!/usr/bin/python

import uhal
from time import sleep
import sys

uhal.setLogLevelTo(uhal.LogLevel.ERROR)
board = uhal.getDevice("board", "ipbusudp-2.0://192.168.200.31:50001", "file://top.xml")
#board.getClient().setTimeoutPeriod(10000)

board.getNode("csr.ctrl.sync_en").write(0)

for i in range(8):

	board.getNode("csr.ctrl.mmcm_rst_1").write(1)
	board.getNode("csr.ctrl.mmcm_rst_1").write(0)
	board.dispatch()

	sleep(0.1)

	v = board.getNode("csr.stat").read()
	board.dispatch()
	print hex(v)

board.getNode("csr.ctrl.sync_en").write(1)

for i in range(8):

	board.getNode("csr.ctrl.mmcm_rst_1").write(1)
	board.getNode("csr.ctrl.mmcm_rst_1").write(0)
	board.dispatch()

	sleep(0.1)

	v = board.getNode("csr.stat").read()
	board.dispatch()
	print hex(v)
