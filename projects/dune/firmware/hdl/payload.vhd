-- payload
--
-- Data source test design wrapper
--
-- Dave Newbold, July 2018

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_decode_top.all;
use work.dtpc_stream_defs.all;

entity payload is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		nuke: out std_logic;
		soft_rst: out std_logic;
		userled: out std_logic;
		clk: in std_logic;
		rst: in std_logic
	);

end payload;

architecture rtl of payload is

	constant N_PORTS: integer := 1;
	constant N_MUX: integer := 1;
	constant BLOCK_RADIX: integer := 8;
	
	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal istream_w, astream_w: dtpc_stream_w_array(N_PORTS - 1 downto 0);
	signal istream_r, astream_r: dtpc_stream_r_array(N_PORTS - 1 downto 0);
	signal ostream_w: dtpc_stream_w;
	signal ostream_r: dtpc_stream_r;
	
begin

-- ipbus address decode
		
	fabric: entity work.ipbus_fabric_sel
		generic map(
    	NSLV => N_SLAVES,
    	SEL_WIDTH => IPBUS_SEL_WIDTH
    )
    port map(
      ipb_in => ipb_in,
      ipb_out => ipb_out,
      sel => ipbus_sel_top(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );

-- Data source

	src: entity work.dtpc_src
		generic map(
			N_PORTS => N_PORTS,
			N_MUX => N_MUX,
			BLOCK_RADIX => BLOCK_RADIX
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_SRC),
			ipb_out => ipbr(N_SLV_SRC),
			clk => clk,
			rst => rst,
			q => istream_w,
			d => istream_r
		);
		
-- Summation

	sgen: for i in N_PORTS - 1 downto 0 generate

		sum: entity work.dtpc_sum
			port map(
				clk => clk,
				rst => rst,
				d => istream_w(i),
				q => istream_r(i),
				qa => astream_w(i),
				da => astream_r(i)
			);
		
	end generate;

-- Arbitrator

	arb: entity work.dtpc_arb
		generic map(
			N_PORTS => N_PORTS
		)
		port map(
			clk => clk,
			rst => rst,
			d => astream_w,
			q => astream_r,
			qa => ostream_w,
			da => ostream_r
		);
		
-- Sink

	sink: entity work.dtpc_sink
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_SINK),
			ipb_out => ipbr(N_SLV_SINK),
			clk => clk,
			rst => rst,
			d => ostream_w,
			q => ostream_r
		);
	
end rtl;
