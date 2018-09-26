-- switchyard
--
-- Handling signal routing in fanout
--
-- Dave Newbold, February 2018

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;

use work.pdts_defs.all;

entity switchyard is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		d_us: in std_logic; -- From upstream port
		q_us: out std_logic; -- To upstream port
		d_master: in std_logic; -- From local master
		q_master: out std_logic; -- To local master
		d_ep: in std_logic; -- From local endpoint
		q_ep: out std_logic; -- To local endpoint
		d_cdr: in std_logic; -- From downstream ports via CDR
		q: out std_logic; -- To downstream ports
		tx_dis_in: in std_logic;
		ep_rdy: in std_logic;
		tx_dis: out std_logic;
	);

end switchyard;

architecture rtl of switchyard is

	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(4 downto 0);
	
begin

	csr: entity work.ipbus_syncreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 0
		)
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipb_in,
			ipb_out => ipb_out,
			slv_clk => clk,
			q => ctrl
		);
		
	q_us <= '0';
	q_master <= '0';
	q_ep <= '0';
	q <= '0';
	tx_dis <= '1';

end rtl;
