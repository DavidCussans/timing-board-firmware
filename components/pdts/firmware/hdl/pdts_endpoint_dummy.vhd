-- pdts_endpoint_dummy
--
-- A dummy version of the endpoint block, for integration purposes
--
-- Dave Newbold, October 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.pdts_defs.all;

entity pdts_endpoint_fake is
	generic(
		SYSCLK_FREQ: real := 50.0;
		SYSCLK_MULT: integer := 1
	);
	port(
		sys_clk: in std_logic; -- free-running system clock
		sys_rst: in std_logic; -- synchronous reset (sys_clk domain)
		status: out std_logic_vector(7 downto 0); -- status output (sys_clk domain)
		address: in std_logic_vector(15 downto 0); -- endpoint address (static)
		group_mask: in std_logic_vector(15 downto 0); -- Timing group mask (static)
		ser_clk: in std_logic; -- serial data clock
		ser_din: in std_logic; -- serial data in (ser_clk domain)
		ser_lock: in std_logic; -- lock flag from CDR
		ser_dout: out std_logic; -- serial data out (ser_tx_clk domain)
		ser_en: out std_logic; -- transmit enable (clk50 domain)
		clk50: out std_logic; -- deskewed 50MHz clock
		rst50: out std_logic; -- synchronous reset (clk50 domain)
		timestamp: out std_logic_vector(63 downto 0); -- timestamp counter (clk50 domain)
		sync: out std_logic_vector(3 downto 0); -- synchronous command output (clk50 domain)
		sync_stb: out std_logic; -- synchronous command strobe (clk50 domain)
		d: out std_logic_vector(7 downto 0); -- packet data output (clk50 domain)
		d_stb: out std_logic; -- packet data strobe (clk50 domain)
		d_last: out std_logic -- end-of-packet marker (clk50 domain)
	);

end pdts_endpoint_fake;

architecture rtl of pdts_endpoint_fake is

begin

	status <= X"00";
	ser_dout <= '0';
	ser_en <= '0';
	clk50 <= '0';
	rst50 <= '0';
	timestamp <= X"0000000000000000";
	sync <= X"0";
	sync_stb <= '0';
	d <= X"00";
	d_stb <= '0';
	d_last <= '0';
	
end rtl;
