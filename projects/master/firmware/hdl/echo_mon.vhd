-- echo_mon
--
-- Send and receive echo commands
--
-- Dave Newbold, February 2018

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;

use work.pdts_defs.all;

entity echo_mon is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk: in std_logic;
		rst: in std_logic;
		tstamp: in std_logic_vector(8 * TSTAMP_WDS - 1 downto 0);
		scmd_out: out cmd_w;
		scmd_in: in cmd_r;
		rscmd_in: in cmd_w
	);

end echo_mon;

architecture rtl of echo_mon is

	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(4 downto 0);
	signal go, done, sent, go_d, pend, rxgood, done_i: std_logic;
	signal tx_ts, rx_ts: std_logic_vector(63 downto 0);

begin

	csr: entity work.ipbus_ctrlreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 5
		)
		port map(
			clk => ipb_clk,
			reset => ipb_rst,
			ipbus_in => ipb_in,
			ipbus_out => ipb_out,
			d => stat,
			q => ctrl
		);
		
	stat(0) <= (0 => done, others => '0');
	stat(1) <= tx_ts(31 downto 0); -- CDC, peseudo static signals
	stat(2) <= tx_ts(63 downto 32);
	stat(3) <= rx_ts(31 downto 0);
	stat(4) <= rx_ts(63 downto 32);

	sync_tx: entity work.pdts_synchro
		generic map(
			N => 1
		)
		port map(
			clk => ipb_clk,
			clks => clk,
			d(0) => ctrl(0)(0),
			q(0) => go
		);

	go_d <= go when rising_edge(clk);
	pend <= (pend or (go and not go_d)) and not (scmd_in.ack or rst) when rising_edge(clk);
	
-- Echo command output

	scmd_out.d <= X"0" & SCMD_ECHO;
	scmd_out.req <= pend;
	scmd_out.last <= '1';
	
-- Timestamp capture

	rxgood <= '1' when rscmd_in.d(3 downto 0) = SCMD_ECHO and rscmd_in.req = '1' else '0';

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				tx_ts <= (others => '0');
				rx_ts <= (others => '0');
			else
				if scmd_in.ack = '1' then
					tx_ts <= tstamp;
				end if;
				if rxgood = '1' then
					rx_ts <= tstamp;
				end if;
			end if;
		end if;
	end process;
	
	done <= (done or rxgood) and not (pend or rst) when rising_edge(clk);
	
	sync_rx: entity work.pdts_synchro
		generic map(
			N => 1
		)
		port map(
			clk => clk,
			clks => ipb_clk,
			d(0) => done,
			q(0) => done_i
		);

end rtl;
