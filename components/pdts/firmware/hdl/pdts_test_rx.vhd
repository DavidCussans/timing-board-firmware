-- pdts_test_rx
--
-- Test block to provide stimulus for pdts_rx under ipbus control
--
-- Dave Newbold, October 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;

entity pdts_test_rx is
	port(
		clk_ipb: in std_logic; -- ipbus clock
		rst_ipb: in std_logic; -- ipbus reset
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk: in std_logic; -- 50MHz system clock
		rst: in std_logic; -- synchronous reset
		s_cmd_d: in std_logic_vector(7 downto 0);
		s_cmd_valid: in std_logic;
		a_cmd_d: in std_logic_vector(7 downto 0);
		a_cmd_last: in std_logic;
		a_cmd_valid: in std_logic
	);

end pdts_test_rx;

architecture rtl of pdts_test_rx is

begin
	
	ipb_out <= IPB_RBUS_NULL;

end rtl;
