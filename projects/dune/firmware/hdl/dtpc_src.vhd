-- dtpc_src
--
-- Data source
--
-- Dave Newbold, July 2018

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_decode_dtpc_src.all;
use work.ipbus_reg_types.all;
use work.dtpc_stream_defs.all;

entity dtpc_src is
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
		q: out dtpc_stream_w_array(N_PORTS - 1 downto 0);
		d: in dtpc_stream_r_array(N_PORTS - 1 downto 0)
	);

end dtpc_src;

architecture rtl of dtpc_src is
	
	constant MASTER_CONF: std_logic_vector(31 downto 0) := X"0000" & std_logic_vector(to_unsigned(N_MUX, 8)) & std_logic_vector(to_unsigned(N_PORTS, 8));

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(0 downto 0);
	signal ctrl_en, ctrl_ts_rst: std_logic;
	signal ctrl_sel: std_logic_vector(7 downto 0);
	signal ctrl_cnt: std_logic_vector(15 downto 0);
	signal go: std_logic;
	signal done: std_logic_vector(N_PORTS - 1 downto 0);
	signal ipbw_m: ipb_wbus_array(N_PORTS - 1 downto 0);
	signal ipbr_m: ipb_rbus_array(N_PORTS - 1 downto 0);

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
      sel => ipbus_sel_dtpc_src(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );

-- Config

	config: entity work.ipbus_roreg_v
		generic map(
			N_REG => 1,
			DATA => MASTER_CONF
		)
		port map(
			ipb_in => ipbw(N_SLV_CONFIG),
			ipb_out => ipbr(N_SLV_CONFIG)
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
			d => stat,
			q => ctrl
		);
		
	ctrl_en <= ctrl(0)(0);
	ctrl_ts_rst <= ctrl(0)(1);
	ctrl_sel <= ctrl(0)(15 downto 8);
	ctrl_cnt <= ctrl(0)(31 downto 16);
	stat(0) <= (others => '0');
	
-- Memories
		
	mfabric: entity work.ipbus_fabric_sel
		generic map(
			NSLV => N_PORTS,
			SEL_WIDTH => 8
		)
		port map(
			ipb_in => ipbw(N_SLV_BUF),
			ipb_out => ipbr(N_SLV_BUF),
			sel => ctrl_sel,
			ipb_to_slaves => ipbw_m,
			ipb_from_slaves => ipbr_m
		);
	
	mgen: for i in N_PORTS - 1 downto 0 generate
	
		mem: entity work.dtpc_wbuf
			generic map(
				N_MUX => N_MUX,
				BLOCK_RADIX => BLOCK_RADIX
			)
			port map(
				ipb_clk => ipb_clk,
				ipb_rst => ipb_rst,
				ipb_in => ipbw_m(i),
				ipb_out => ipbr_m(i),
				clk => clk,
				rst => rst,
				q => q(i),
				d => d(i),
				go => go,
				done => done(i)
			);
			
	end generate;
	
	go <= '0';
	
end rtl;
