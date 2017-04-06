### What is this repository for? ###

* This repository holds the firmware components and test software for the ProtoDUNE-SP timing system
* Current version is v0 (clone from tags/v0)

### How do I get set up? ###

The master firmware uses the [ipbb](https://github.com/ipbus/ipbb) build tool, and requires the ipbus system firmware.
The following example procedure should build a board image for testing of the timing FMC. Note that a reasonably up-to-date
operating system (e.g. Centos7) is required.

	mkdir work
	cd work
	curl -L https://github.com/ipbus/ipbb/archive/v0.2.3.tar.gz | tar xvz
	source ipbb-0.2.3/env.sh
	ipbb init build
	cd build
	ipbb add git https://github.com/ipbus/ipbus-firmware.git -b tags/ipbus_2_0_v1
	ipbb add git https://:@gitlab.cern.ch:8443/protoDUNE-SP-DAQ/timing-board-firmware.git -b tags/v0
	ipbb proj create vivado fmc_test pdts:projects/test/fmc_test -t top_master_a35.dep
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
