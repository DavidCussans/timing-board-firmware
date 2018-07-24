-- pdts_pc059_io
--
-- Various functions for talking to the pc059 board chipset
--
-- Dave Newbold, February 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_pdts_pc059_io.all;

library unisim;
use unisim.VComponents.all;

entity pdts_pc059_io is
	generic(
		CARRIER_TYPE: std_logic_vector(7 downto 0);
		DESIGN_TYPE: std_logic_vector(7 downto 0)
	);
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		soft_rst: out std_logic;
		nuke: out std_logic;
		rst: out std_logic;
		locked: in std_logic;
		clk_p: in std_logic; -- 50MHz master clock from PLL
		clk_n: in std_logic;
		clk: out std_logic;
		rstb_clk: out std_logic; -- reset for PLL
		clk_lolb: in std_logic; -- PLL LOL
		q_hdmi: in std_logic;
		q_hdmi_0_p: out std_logic; -- output to HDMI 0
		q_hdmi_0_n: out std_logic;
		q_hdmi_1_p: out std_logic; -- output to HDMI 1
		q_hdmi_1_n: out std_logic;
		q_hdmi_2_p: out std_logic; -- output to HDMI 2
		q_hdmi_2_n: out std_logic;
		q_hdmi_3_p: out std_logic; -- output to HDMI 3
		q_hdmi_3_n: out std_logic;
		scl: out std_logic; -- main I2C
		sda: inout std_logic;
		rstb_i2c: out std_logic -- reset for I2C expanders
	);

end pdts_pc059_io;

architecture rtl of pdts_pc059_io is

	constant BOARD_TYPE: std_logic_vector(7 downto 0) := X"04";

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(0 downto 0);
	signal ctrl_rst_lock_mon: std_logic;
	signal clk_i, clk_u, q_hdmi_0_i, q_hdmi_1_i, q_hdmi_2_i, q_hdmi_3_i: std_logic;
	signal mmcm_bad, mmcm_ok, pll_bad, pll_ok, mmcm_lm, pll_lm: std_logic;
	signal clkdiv: std_logic_vector(0 downto 0);
	signal sda_o: std_logic;
	
  attribute IOB: string;
  attribute IOB of q_hdmi_0_i, q_hdmi_1_i, q_hdmi_2_i, q_hdmi_3_i: signal is "TRUE";

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
      sel => ipbus_sel_pdts_pc059_io(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );

-- CSR

	csr: entity work.ipbus_ctrlreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 1
		)
		port map(
			clk => ipb_clk,
			reset => ipb_rst,
			ipbus_in => ipbw(N_SLV_CSR),
			ipbus_out => ipbr(N_SLV_CSR),
			d => stat,
			q => ctrl
		);
		
	stat(0) <= X"000000" & pll_lm & mmcm_lm & pll_ok & mmcm_ok & "000" & not clk_lolb;
	
	soft_rst <= ctrl(0)(0);
	nuke <= ctrl(0)(1);
	rst <= ctrl(0)(2);
	rstb_clk <= not ctrl(0)(3);
	rstb_i2cmux <= not ctrl(0)(4);
	rstb_i2c <= not ctrl(0)(5);
	ctrl_rst_lock_mon <= ctrl(0)(6);
	
-- Config info

	config: entity work.ipbus_roreg_v
		generic map(
			N_REG => 1,
			DATA(31 downto 24) => X"00",
			DATA(23 downto 16) => BOARD_TYPE,
			DATA(15 downto 8) => CARRIER_TYPE,
			DATA(7 downto 0) => DESIGN_TYPE
		)
		port map(
			ipb_in => ipbw(N_SLV_CONFIG),
			ipb_out => ipbr(N_SLV_CONFIG)
		);

-- Clocks
			
	ibufg_clk: IBUFGDS
		port map(
			i => clk_p,
			ib => clk_n,
			o => clk_u
		);
		
	bufg_in: BUFG
		port map(
			i => clk_u,
			o => clk_i
		);
		
	clk <= clk_i;
	
-- Clock lock monitor

	mmcm_bad <= not locked;
	pll_bad <= not clk_lolb;

	chk: entity work.pdts_chklock
		generic map(
			N => 2
		)
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			los(0) => mmcm_bad,
			los(1) => pll_bad,
			ok(0) => mmcm_ok,
			ok(1) => pll_ok,
			ok_sticky(0) => mmcm_lm,
			ok_sticky(1) => pll_lm
		);
	
-- Data outputs

	q_hdmi_0_i <= q_hdmi when falling_edge(clk_i);

	obuf_q_hdmi_0: OBUFDS
		port map(
			i => q_hdmi_0_i,
			o => q_hdmi_0_p,
			ob => q_hdmi_0_n
		);

	q_hdmi_1_i <= q_hdmi when falling_edge(clk_i);

	obuf_q_hdmi_1: OBUFDS
		port map(
			i => q_hdmi_1_i,
			o => q_hdmi_1_p,
			ob => q_hdmi_1_n
		);
		
	q_hdmi_2_i <= q_hdmi when falling_edge(clk_i);

	obuf_q_hdmi_2: OBUFDS
		port map(
			i => q_hdmi_2_i,
			o => q_hdmi_2_p,
			ob => q_hdmi_2_n
		);
		
	q_hdmi_3_i <= q_hdmi when falling_edge(clk_i);

	obuf_q_hdmi_3: OBUFDS
		port map(
			i => q_hdmi_3_i,
			o => q_hdmi_3_p,
			ob => q_hdmi_3_n
		);

-- Frequency measurement

	div: entity work.freq_ctr_div
		generic map(
			N_CLK => 1
		)
		port map(
			clk(0) => clk_i,
			clkdiv => clkdiv
		);

	ctr: entity work.freq_ctr
		generic map(
			N_CLK => 1
		)
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_FREQ),
			ipb_out => ipbr(N_SLV_FREQ),
			clkdiv => clkdiv
		);	

-- I2C

	i2c_uid: entity work.ipbus_i2c_master
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_I2C),
			ipb_out => ipbr(N_SLV_I2C),
			scl => scl,
			sda_o => sda_o,
			sda_i => sda
		);
	
	sda <= '0' when sda_o = '0' else 'Z';
				
end rtl;
