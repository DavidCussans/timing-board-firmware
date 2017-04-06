-- pdts_test_tx
--
-- Test block to provide stimulus for pdts_tx under ipbus control
--
-- Dave Newbold, October 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;

entity pdts_test_tx is
	port(
		clk_ipb: in std_logic; -- ipbus clock
		rst_ipb: in std_logic; -- ipbus reset
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk: in std_logic; -- 50MHz system clock
		rst: in std_logic; -- synchronous reset
		mctr: out std_logic_vector(31 downto 0);
		s_cmd_q: out std_logic_vector(7 downto 0);
		s_cmd_valid: out std_logic;
		s_cmd_rdy: in std_logic;
		a_cmd_d: out std_logic_vector(7 downto 0);
		a_cmd_valid: out std_logic;
		a_cmd_ack: in std_logic
	);

end pdts_test_tx;

architecture rtl of pdts_test_tx is

begin
	
	ipb_out <= IPB_RBUS_NULL;
	mctr <= (others => '0');
	sync_q <= (others => '0');
	sync_stb <= '0';
	async_q <= (others => '0');
	async_stb <= '0';
	
end rtl;
