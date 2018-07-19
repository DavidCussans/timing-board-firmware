-- dtpc_sink
--
-- Data sink
--
-- Dave Newbold, July 2018

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_decode_dtpc_sink.all;
use work.dtpc_stream_defs.all;

entity dtpc_sink is
	generic(
		N_PORTS: positive := 1;
		N_MUX: positive := 1;
		BLOCK_RADIX: positive := 8
	);
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk: in std_logic;
		rst: in std_logic;
		d: in dtpc_stream_w;
		q: out dtpc_stream_r
	);

end dtpc_sink;

architecture rtl of dtpc_sink is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(0 downto 0);
	
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
      sel => ipbus_sel_dtpc_sink(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );
    
-- CSR

	csr: entity work.ipbus_syncreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 1
		)
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_CSR),
			ipb_out => ipbr(N_SLV_CSR),
			slv_clk => clk,
			q => ctrl
		);
		
	ctrl_en <= ctrl(0)(0);
	stat(0) <= X"0000000" & "00" & full & empty;
	
-- Buffer
	
	ipbr(N_SLV_BUF) <= IPB_RBUS_NULL;

end rtl;
