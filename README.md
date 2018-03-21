### What is this repository for? ###

* This repository holds the firmware components and test software for the ProtoDUNE-SP timing system
* Current version is v4a4 (clone from tags/v4a4)

### How do I get set up? ###

The master firmware uses the [ipbb](https://github.com/ipbus/ipbb) build tool, and requires the ipbus system firmware.
The following example procedure should build a board image for testing of the timing FMC. Note that a reasonably up-to-date
operating system (e.g. Centos7) is required.  You will need to run the scripts using python2.7 (not python3).  If you are 
going to build on a computer outside of the CERN network, then you will need to run kerberos (kinit username@CERNNOSPAM.CH)).
These instructions assume that you have your Xilinx Vivado licensing already setup for your enviroment.

	mkdir work
	cd work
	curl -L https://github.com/ipbus/ipbb/archive/v0.3.0.tar.gz | tar xvz
	source ipbb-0.3.0/env.sh
	ipbb init build
	cd build
	ipbb add git https://github.com/ipbus/ipbus-firmware.git
	ipbb add git https://:@gitlab.cern.ch:8443/protoDUNE-SP-DAQ/timing-board-firmware.git -b v4a6
	ipbb proj create vivado fmc_test timing-board-firmware:projects/test/fmc_test -t top_master_a35.dep
	cd proj/fmc_test
	ipbb vivado project
	ipbb vivado impl
	ipbb vivado bitfile
	ipbb vivado package
	deactivate

### Who do I talk to? ###

* Dave Newbold (dave.newbold@cern.ch)
* David Cussans (david.cussans@bristol.ac.uk)
* Sudan Paramesvaran (sudan@cern.ch)
