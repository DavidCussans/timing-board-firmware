-- payload.vhd
--
-- Dave Newbold, February 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_top.all;

library unisim;
use unisim.VComponents.all;

entity payload is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		nuke: out std_logic;
		soft_rst: out std_logic;
		userled: out std_logic;
		clk125: in std_logic;
		clk_p: in std_logic; -- 50MHz master clock from PLL
		clk_n: in std_logic;
		rstb_clk: out std_logic; -- reset for PLL
		clk_lolb: in std_logic; -- PLL LOL
		d_p: in std_logic_vector(7 downto 0); -- data from fanout SFPs
		d_n: in std_logic_vector(7 downto 0);
		q_p: out std_logic; -- output to fanout
		q_n: out std_logic;
		sfp_los: in std_logic_vector(7 downto 0); -- fanout SFP LOS
		d_cdr_p: in std_logic; -- data input from CDR
		d_cdr_n: in std_logic;
		clk_cdr_p: in std_logic; -- clock from CDR
		clk_cdr_n: in std_logic;
		cdr_los: in std_logic; -- CDR LOS
		cdr_lol: in std_logic; -- CDR LOL
		inmux: out std_logic_vector(2 downto 0); -- mux control
		rstb_i2cmux: out std_logic; -- reset for mux
		d_hdmi_p: in std_logic; -- data from upstream HDMI
		d_hdmi_n: in std_logic;	
		q_hdmi_p: out std_logic; -- output to upstream HDMI
		q_hdmi_n: out std_logic;
		d_usfp_p: in std_logic; -- input from upstream SFP
		d_usfp_n: in std_logic;		
		q_usfp_p: out std_logic; -- output to upstream SFP
		q_usfp_n: out std_logic;
		usfp_fault: in std_logic; -- upstream SFP fault
		usfp_los: in std_logic; -- upstream SFP LOS
		usfp_txdis: out std_logic; -- upstream SFP tx_dis
		usfp_sda: inout std_logic; -- upstream SFP I2C
		usfp_scl: out std_logic;
		ucdr_los: in std_logic; -- upstream CDR LOS
		ucdr_lol: in std_logic; -- upstream CDR LOL
		ledb: out std_logic_vector(2 downto 0); -- FMC LEDs
		scl: out std_logic; -- main I2C
		sda: inout std_logic;
		rstb_i2c: out std_logic; -- reset for I2C expanders
		gpio_p: out std_logic_vector(2 downto 0); -- GPIO
		gpio_n: out std_logic_vector(2 downto 0)
	);

end payload;

architecture rtl of payload is
			
begin

	ipb_out <= IPB_RBUS_NULL;
	nuke <= '0';
	soft_rst <= '0';
	useled <= '0';
	rstb_clk <= '1'; -- active low

	obufds_0: OBUFDS
		port map(
			i => '0',
			o => q_p,
			ob => q_n
		);
		
	inmux <= "000";
	rstb_i2cmux <= '1'; -- active low
	
	obufds_1: OBUFDS
		port map(
			i => '0',
			o => q_hdmi_p,
			ob => q_hdmi_n
		);
	
	obufds_2: OBUFDS
		port map(
			i => '0',
			o => q_usfp_p,
			ob => q_usfp_n
		);
	
	usfp_txdis <= '0';
	usfp_sda <= '0';
	usfp_scl <= '0';
	ledb <= "111"; -- active low
	scl <= '0';
	sda <= '0';
	rstb_i2c <= '1'; -- active low

	obufds_g0: OBUFDS
		port map(
			i => '0',
			o => gpio_p(0),
			ob => gpio_n(0)
		);

	obufds_g1: OBUFDS
		port map(
			i => '0',
			o => gpio_p(1),
			ob => gpio_n(1)
		);
		
	obufds_g2: OBUFDS
		port map(
			i => '0',
			o => gpio_p(2),
			ob => gpio_n(2)
		);
		
end rtl;
