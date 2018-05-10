-- trig_rx
--
-- Receiver for trigger command input
--
-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_trig_rx.all;

use work.pdts_defs.all;

entity trig_rx is
	port(
		ipb_clk: in std_logic; -- IPbus connection
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		mclk: in std_logic; -- The serial IO clock
		clk: in std_logic; -- The system clock
		d: in std_logic; -- Input from trigger
		scmd_out: out cmd_w;
		scmd_in: in cmd_r
	);

end trig_rx;

architecture rtl of trig_rx is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(0 downto 0);
	signal ctrl_ep_en: std_logic;
	signal ep_stat: std_logic_vector(3 downto 0);
	signal ep_rst, ep_rdy: std_logic;
	
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
      sel => ipbus_sel_trig_rx(ipb_in.ipb_addr),
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
		
	ctrl_ep_en <= ctrl(0)(0);
	stat(0) <= X"000000" & "000" & ep_rdy & ep_stat; -- CDC on ep_rdy, don't care (pseudo static level)

-- The rx endpoint

	ep_rst <= ipb_rst or not ctrl_ep_en;

	ep: entity work.pdts_endpoint_upstream
		generic map(
			SCLK_FREQ => 31.25
		)	
		port map(
			sclk => ipb_clk,
			srst => ep_rst,
			stat => ep_stat,
			rec_clk => mclk,
			rec_d => d,
			clk => clk,
			rdy => ep_rdy,
			scmd => open,
			acmd => open
		);
		
-- outputs

	scmd_out <= CMD_W_NULL;
		
end rtl;
