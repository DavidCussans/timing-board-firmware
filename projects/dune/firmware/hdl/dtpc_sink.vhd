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
use work.ipbus_reg_types.all;
use work.dtpc_stream_defs.all;

library unisim;
use unisim.VComponents.all;

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
	signal ctrl_en: std_logic;
	signal full, empty, rden, rderr, wren, wrerr, err, rden_d, rden_c: std_logic;
	signal rdcount: std_logic_vector(12 downto 0);
	signal d_fifo, q_fifo: std_logic_vector(31 downto 0);
	
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
	stat(0) <= X"0000000" & '0' & err & full & empty;
	
-- Buffer
	
	fifo: FIFO18E2
		generic map(
			WRITE_WIDTH => 18,
			READ_WIDTH => 18,
			FIRST_WORD_FALL_THROUGH => "TRUE",
			RDCOUNT_TYPE => "SIMPLE_DATACOUNT"
		)
		port map(
			din => d_fifo,
			dinp => "0000",
			dout => q_fifo,
			empty => empty,
			full => full,
			rdclk => ipb_clk,
			rdcount => rdcount,
			rden => rden,
			rderr => rderr,
			regce => '1',
			rst => rst,
			rstreg => '0',
			sleep => '0',
			wrclk => clk,
			wren => wren,
			wrerr => wrerr,
			casdin => (others => '0'),
			casdinp => (others => '0'),
			casprvempty => '0',
			casnxtrden => '0',
			casoregimux => '0',
			casoregimuxen => '0',
			casdomux => '0',
			casdomuxen => '0'
		);
		
	wren <= d.h_valid or d.c_valid;
	d_fifo <= (31 downto DTPC_STREAM_D_W + 1 => '0') & d.h_valid & d.c_valid & d.d;
	q.ack <= not full;

	err <= (err or wrerr) and not rst when rising_edge(clk);
	
	rden <= ipb_in.ipb_strobe and not ipb_in.ipb_write and not ipb_in.ipb_addr(0);
	rden_d <= rden when rising_edge(clk);
	rden_c <= ipb_in.ipb_strobe and not ipb_in.ipb_write and ipb_in.ipb_addr(0);
	
	ipb_out.ipb_rdata <= (31 downto rdcount'left + 1 => '0') & rdcount when rden_c = '1' else q_fifo;
	ipb_out.ipb_ack <= (rden_d and not rderr and not ipb_in.ipb_addr(0)) or rden_c;
	ipb_out.ipb_err <= (rden_d and rderr) or (ipb_in.ipb_strobe and ipb_in.ipb_write);

end rtl;
