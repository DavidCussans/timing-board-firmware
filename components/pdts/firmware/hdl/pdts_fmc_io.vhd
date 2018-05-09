-- pdts_fmc_io
--
-- Various functions for talking to the FMC board chipset
--
-- Dave Newbold, March 2018

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_pdts_fmc_io.all;

library unisim;
use unisim.VComponents.all;

entity pdts_fmc_io is
	generic(
		CARRIER_TYPE: std_logic_vector(7 downto 0);
		DESIGN_TYPE: std_logic_vector(7 downto 0);
		LOOPBACK: boolean := false
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
		cdr_lol: in std_logic;
		cdr_los: in std_logic;
		sfp_los: in std_logic;
		sfp_tx_dis: out std_logic;
		sfp_flt: in std_logic;
		userled: out std_logic;
		fmc_clk_p: in std_logic;
		fmc_clk_n: in std_logic;
		fmc_clk: out std_logic;
		rec_clk_p: in std_logic;
		rec_clk_n: in std_logic;
		rec_clk: out std_logic;
		rec_d_p: in std_logic;
		rec_d_n: in std_logic;
		rec_d: out std_logic;
		clk_out_p: out std_logic;
		clk_out_n: out std_logic;
		rj45_din_p: in std_logic;
		rj45_din_n: in std_logic;
		rj45_din: out std_logic;
		rj45_dout: in std_logic;
		rj45_dout_p: out std_logic;
		rj45_dout_n: out std_logic;
		sfp_dout: in std_logic;
		sfp_dout_p: out std_logic;
		sfp_dout_n: out std_logic;
		uid_scl: out std_logic;
		uid_sda: inout std_logic;
		sfp_scl: out std_logic;
		sfp_sda: inout std_logic;
		pll_scl: out std_logic;
		pll_sda: inout std_logic;
		pll_rstn: out std_logic;
		gpin_0_p: in std_logic;
		gpin_0_n: in std_logic;
		gpout_0_p: out std_logic;
		gpout_0_n: out std_logic;
		gpout_1_p: out std_logic;
		gpout_1_n: out std_logic		
	);

end pdts_fmc_io;

architecture rtl of pdts_fmc_io is

	constant BOARD_TYPE: std_logic_vector(7 downto 0) := X"00";

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(0 downto 0);
	signal fmc_clk_i, fmc_clk_u, rec_clk_i, rec_clk_u, clkout, gp0out, gp1out, sfp_dout_r, rj45_dout_r: std_logic;
	signal gpin, rj45_din_u, rec_d_u, rec_d_i, rec_d_il, rj45_din_i, rj45_din_il: std_logic;
	signal mmcm_bad, mmcm_ok, mmcm_lm: std_logic;
	signal clkdiv: std_logic_vector(1 downto 0);
	signal uid_sda_o, pll_sda_o, sfp_sda_o: std_logic;
	
	attribute IOB: string;
	attribute IOB of sfp_dout_r, rj45_dout_r, rec_d_u, rj45_din_u: signal is "TRUE";

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
      sel => ipbus_sel_pdts_fmc_io(ipb_in.ipb_addr),
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
		
	stat(0) <= X"000000" & "00" & mmcm_lm & mmcm_ok & cdr_lol & cdr_los & sfp_flt & sfp_los;
	
	soft_rst <= ctrl(0)(0);
	nuke <= ctrl(0)(1);
	rst <= ctrl(0)(2);
	sfp_tx_dis <= ctrl(0)(3);
	pll_rstn <= not ctrl(0)(4);
	
	userled <= not (cdr_lol or cdr_los or sfp_los);
	
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
	
-- Unused signals

	ibufds_gpin_0: IBUFDS
		port map(
			i => gpin_0_p,
			ib => gpin_0_n,
			o => gpin
		);

-- Clocks
			
	ibufg_in: IBUFGDS
		port map(
			i => fmc_clk_p,
			ib => fmc_clk_n,
			o => fmc_clk_u
		);
		
	bufg_in: BUFG
		port map(
			i => fmc_clk_u,
			o => fmc_clk_i
		);
		
	fmc_clk <= fmc_clk_i;
	
	ibufds_rec_clk: IBUFDS
		port map(
			i => rec_clk_p,
			ib => rec_clk_n,
			o => rec_clk_u
		);
		
	bufh_rec_clk: BUFG
		port map(
			i => rec_clk_u,
			o => rec_clk_i
		);
		
	rec_clk <= rec_clk_i when not LOOPBACK else fmc_clk_i;
	
-- Clock lock monitor

	mmcm_bad <= not locked;

	chk: entity work.pdts_chklock
		generic map(
			N => 1
		)
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			los(0) => mmcm_bad,
			ok(0) => mmcm_ok,
			ok_sticky(0) => mmcm_lm
		);

-- Outputs
		
	oddr_clkout: ODDR -- Feedback clock, not through MMCM
		port map(
			q => clkout,
			c => fmc_clk_i,
			ce => '1',
			d1 => '0',
			d2 => '1',
			r => '0',
			s => '0'
		);
		
	obuf_clkout: OBUFDS
		port map(
			i => clkout,
			o => clk_out_p,
			ob => clk_out_n
		);
		
	oddr_gp0: ODDR -- Monitoring pin
		port map(
			q => gp0out,
			c => fmc_clk_i,
			ce => '1',
			d1 => '0',
			d2 => '1',
			r => '0',
			s => '0'
		);
		
	obuf_gp0: OBUFDS
		port map(
			i => gp0out,
			o => gpout_0_p,
			ob => gpout_0_n
		);
		
	oddr_gp1: ODDR -- Monitoring pin
		port map(
			q => gp1out,
			c => fmc_clk_i,
			ce => '1',
			d1 => '0',
			d2 => '1',
			r => '0',
			s => '0'
		);
		
	obuf_gp1: OBUFDS
		port map(
			i => gp1out,
			o => gpout_1_p,
			ob => gpout_1_n
		);

	sfp_dout_r <= sfp_dout when rising_edge(fmc_clk_i);
		
	obuf_sfp_dout: OBUFDS
		port map(
			i => sfp_dout_r,
			o => sfp_dout_p,
			ob => sfp_dout_n
		);
		
	rj45_dout_r <= rj45_dout when falling_edge(fmc_clk_i);

	obuf_rj45_dout: OBUFDS
		port map(
			i => rj45_dout_r,
			o => rj45_dout_p,
			ob => rj45_dout_n
		);
		
-- Inputs

	ibufds_rec_d: IBUFDS
		port map(
			i => rec_d_p,
			ib => rec_d_n,
			o => rec_d_u
		);
		
	rec_d_i <= rec_d_u when rising_edge(rec_clk_i); -- Register CDR data on CDR recovered clock
	rec_d_il <= sfp_dout when rising_edge(fmc_clk_i);
	rec_d <= rec_d_i when not LOOPBACK else rec_d_il;
	
	ibufds_rj45: IBUFDS
		port map(
			i => rj45_din_p,
			ib => rj45_din_n,
			o => rj45_din_u
		);
		
	rj45_din_i <= rj45_din_u when falling_edge(fmc_clk_i); -- Register RJ45 data on tx clock
	rj45_din_il <= rj45_dout when falling_edge(fmc_clk_i);
	rj45_din <= rj45_din_i when not LOOPBACK else rj45_din_il;

-- Frequency measurement

	div: entity work.freq_ctr_div
		generic map(
			N_CLK => 2
		)
		port map(
			clk(0) => fmc_clk_i,
			clk(1) => rec_clk_i,
			clkdiv => clkdiv
		);

	ctr: entity work.freq_ctr
		generic map(
			N_CLK => 2
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
			ipb_in => ipbw(N_SLV_UID_I2C),
			ipb_out => ipbr(N_SLV_UID_I2C),
			scl => uid_scl,
			sda_o => uid_sda_o,
			sda_i => uid_sda
		);
	
	uid_sda <= '0' when uid_sda_o = '0' else 'Z';
	
	i2c_sfp: entity work.ipbus_i2c_master
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_SFP_I2C),
			ipb_out => ipbr(N_SLV_SFP_I2C),
			scl => sfp_scl,
			sda_o => sfp_sda_o,
			sda_i => sfp_sda
		);
	
	sfp_sda <= '0' when sfp_sda_o = '0' else 'Z';

	i2c_pll: entity work.ipbus_i2c_master
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_PLL_I2C),
			ipb_out => ipbr(N_SLV_PLL_I2C),
			scl => pll_scl,
			sda_o => pll_sda_o,
			sda_i => pll_sda
		);
	
	pll_sda <= '0' when pll_sda_o = '0' else 'Z';
				
end rtl;
