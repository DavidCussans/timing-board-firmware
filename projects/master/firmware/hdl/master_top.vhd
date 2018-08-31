-- master_top
--
-- The top-level timing master design
--
-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.ipbus.all;
use work.ipbus_decode_master_top.all;

use work.pdts_defs.all;

entity master_top is
	generic(
		SIM: boolean := false
	);
	port(
		ipb_clk: in std_logic; -- IPbus connection
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		mclk: in std_logic; -- The serial IO clock
		clk: in std_logic; -- The system clock
		rst: in std_logic; -- Sync reset (clk domain)
		spill_start: in std_logic;
		spill_end: in std_logic;
		q: out std_logic; -- Output (mclk domain)
		d: in std_logic -- Input from trigger
	);

end master_top;

architecture rtl of master_top is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal scmd_in: cmd_w;
	signal scmd_out: cmd_r;
	
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
      sel => ipbus_sel_master_top(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );
    
-- The master

	master: entity work.master
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_MASTER),
			ipb_out => ipbr(N_SLV_MASTER),
			mclk => mclk,
			clk => clk,
			rst => rst,
			spill_start => spill_start,
			spill_end => spill_end,
			q => q,
			scmd_in => scmd_in,
			scmd_out => scmd_out
		);

-- Trigger receiver

	trig: entity work.trig_rx
		generic map(
			SIM => SIM
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_TRIG),
			ipb_out => ipbr(N_SLV_TRIG),
			mclk => mclk,
			clk => clk,
			d => d,
			scmd_out => scmd_in,
			scmd_in => scmd_out
		);
 
end rtl;
