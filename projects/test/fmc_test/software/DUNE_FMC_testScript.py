# -*- coding: utf-8 -*-
import uhal
from I2CuHal import I2CCore
import time
#import miniTLU
from si5344 import si5344



manager = uhal.ConnectionManager("file://./dune_connections.xml")
hw = manager.getDevice("DUNE_FMC")

# hw.getNode("A").write(255)
reg = hw.getNode("Test.B").read()
hw.dispatch()
print "CHECK REG= ", hex(reg)


# #First I2C core
# print ("Instantiating master I2C core:")
# master_I2C= I2CCore(hw, 10, 5, "i2c_master", None)
# master_I2C.state()
#
# mystop=True
# time.sleep(0.1)
#
# #Address of the I2C slave
# myslave= 0x21
#
# #Internal address of the slave+commands
# mycmd= [0x01]
# nwords= 1
#
# #######################################
# enableCore= True #Only need to run this once, after power-up
# if (enableCore):
#    mystop=True
#    print "  Write RegDir to set I/O[7] to output:"
#    mycmd= [0x01, 0x7F]
#    nwords= 1
#    master_I2C.write(myslave, mycmd, mystop)
#
#    time.sleep(0.1) #Needed, for some reason
#
#    mystop=False
#    mycmd= [0x01]
#    master_I2C.write(myslave, mycmd, mystop)
#    res= master_I2C.read( myslave, nwords)
#    print "\tPost RegDir: ", res
# #######################################
#
# time.sleep(0.1)
# #Read the EPROM
# mystop=False
# nwords=6
# myslave= 0x53 #DUNE EPROM 0x53 (Possibly)
# myaddr= [0xfa]#0xfa
# master_I2C.write( myslave, myaddr, mystop)
# #res= master_I2C.read( 0x50, 6)
# res= master_I2C.read( myslave, nwords)
# print "  PCB EPROM: "
# result="\t  "
# for iaddr in res:
#    result+="%02x "%(iaddr)
# print result
# #######################################


#Second I2C core
#print ("Instantiating SFP I2C core:")
#clock_I2C= I2CCore(hw, 10, 5, "i2c_sfp", None)
#clock_I2C.state()

# #Third I2C core
print ("Instantiating clock I2C core:")
clock_I2C= I2CCore(hw, 10, 5, "i2c_clk", None)
clock_I2C.state()
#
# #time.sleep(0.01)
# #Read the EPROM
# mystop=False
# nwords=2
# myslave= 0x68 #DUNE CLOCK CHIP 0x68
# myaddr= [0x02 ]#0xfa
# clock_I2C.write( myslave, myaddr, mystop)
# #time.sleep(0.1)
# res= clock_I2C.read( myslave, nwords)
# print "  CLOCK EPROM: "
# result="\t  "
# for iaddr in res:
#     result+="%02x "%(iaddr)
# print result

#
zeClock=si5344(clock_I2C)
res= zeClock.getDeviceVersion()
zeClock.setPage(0, True)
zeClock.getPage()
regCfgList=zeClock.parse_clk("Si5344_cfg.txt")
zeClock.writeConfiguration(regCfgList)
