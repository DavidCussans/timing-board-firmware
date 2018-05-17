-- pdts_ep_startup
--
-- The timing endpoint design
--
-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.pdts_defs.all;

entity pdts_ep_startup is
	generic(
		SCLK_FREQ: real;
		SIM: boolean := false
	);
	port(
		sclk: in std_logic; -- Free-running system clock
		srst: in std_logic; -- System reset (sclk domain)
		stat: out std_logic_vector(3 downto 0); -- Status output (sclk domain)
		sfp_los: in std_logic; -- SFP LOS line (async, sampled in sclk domain)
		cdr_los: in std_logic; -- CDR LOS line (asnc, sampled in sclk domain)
		cdr_lol: in std_logic; -- CDR LOL line (async, sampled in sclk domain)
		rec_clk: in std_logic; -- CDR recovered clock
		rec_rst: out std_logic; -- Reset out (rec_clk domain)
		rxphy_aligned: in std_logic; -- RX phy is aligned
		clk: in std_logic; -- 50MHz clock input
		rxphy_rst: out std_logic; -- RX phy reset
		rxphy_locked: in std_logic; -- RX phy locked
		rst: out std_logic; -- 50MHz reset
		rx_err: in std_logic_vector(2 downto 0); -- RX decoder error status 
		rdy: in std_logic -- Timestamp ready
	);

end pdts_ep_startup;

architecture rtl of pdts_ep_startup is

	type state_t is (W_RST, W_SFP, W_CDR, W_FREQ, W_ALIGN, W_LOCK, W_RDY, RUN, ERR_R, ERR_T);
	signal state: state_t;
	signal rctr: unsigned(4 downto 0);
	signal f_ok, t, td: std_logic;
	signal sctr, cctr, cctr_rnd: unsigned(15 downto 0);
	signal sfp_los_ctr, cdr_ctr: unsigned(7 downto 0);
	signal cdr_bad, sfp_los_ok, cdr_ok, f_en: std_logic;
	signal rxphy_aligned_i, rxphy_locked_i, rx_err_f, rx_err_i, rdy_i: std_logic;
	signal rec_rst_i, rxphy_rst_i, rst_i, rst_u: std_logic;

begin

	process(sclk)
	begin
		if rising_edge(sclk) then
			if srst = '1' then
				state <= W_RST;
			else
				case state is
				when W_RST =>
					if SIM then
						state <= W_ALIGN;
					else
						state <= W_SFP;
					end if;
-- Startup; wait for SFP signal
				when W_SFP =>
					if sfp_los_ok = '1' then
						state <= W_CDR;
					end if;
-- Wait for CDR lock
				when W_CDR =>
					if cdr_ok = '1' then
						state <= W_FREQ;
					end if;
-- Wait for frequency match
				when W_FREQ =>
					if sfp_los_ok = '0' or cdr_ok = '0' then
						state <= W_SFP;
					elsif f_ok = '1' then -- Don't want simulation to wait for freq lock
						state <= W_ALIGN;
					end if;
-- Wait for rxphy alignment
				when W_ALIGN =>
					if sfp_los_ok = '0' or cdr_ok = '0' then
						state <= W_SFP;
					elsif rxphy_aligned_i = '1' then
						state <= W_LOCK;
					end if;
-- Wait for rxphy lock
				when W_LOCK =>
					if sfp_los_ok = '0' or cdr_ok = '0' then
						state <= W_SFP;
					elsif rxphy_locked_i = '1' then
						state <= W_RDY;
					end if;
-- Wait for ready flag
				when W_RDY =>
					if sfp_los_ok = '0' or cdr_ok = '0' then
						state <= W_SFP;
					elsif rxphy_locked_i = '0' then
						state <= W_ALIGN;
					elsif rx_err_i = '1' then
						state <= ERR_R;
					elsif rdy_i = '1' then
						state <= RUN;
					end if;
-- Running state
				when RUN =>
					if sfp_los_ok = '0' or cdr_ok = '0' then
						state <= W_SFP;
					elsif rxphy_locked_i = '0' then
						state <= W_ALIGN;
					elsif rx_err_i = '1' then
						state <= ERR_R;
					elsif rdy_i = '0' then
						state <= ERR_T;
					end if;
-- Error states. Doomed.
				when ERR_R =>
				when ERR_T =>
				end case;
			end if;
		end if;
	end process;

-- Freq check

	sync_c: entity work.pdts_synchro
		generic map(
			N => 1
		)
		port map(
			clk => sclk,
			clks => clk,
			d(0) => cdr_ok,
			q(0) => f_en
		);

	process(clk) -- Predivide by 32
	begin
		if rising_edge(clk) then
			if f_en = '0' then
				rctr <= (others => '0');
			else
				rctr <= rctr + 1;
			end if;
		end if;
	end process;
	
	sync_t: entity work.pdts_synchro
		generic map(
			N => 1
		)
		port map(
			clk => clk,
			clks => sclk,
			d(0) => rctr(4),
			q(0) => t
		);

	process(sclk)
	begin
		if rising_edge(sclk) then
			td <= t;
			if srst = '1' then
				sctr <= (others => '0');
				cctr <= (others => '0');
				f_ok <= '0';
			else
				sctr <= sctr + 1;
				if sctr = X"ffff" then
					if cctr_rnd = to_unsigned(integer((CLK_FREQ / SCLK_FREQ) * 2048.0), 16) then
						f_ok <= '1';
					else
						f_ok <= '0';
					end if;
					cctr <= (others => '0');
				elsif t = '1' and td = '0' then
					cctr <= cctr + 1;
				end if;
			end if;
		end if;
	end process;
	
	cctr_rnd <= cctr when t = '0' else cctr + 1;

-- External signal debounce	

	cdr_bad <= cdr_los or cdr_lol;

	chk: entity work.pdts_chklock
		generic map(
			N => 2
		)
		port map(
			clk => sclk,
			rst => srst,
			los(0) => sfp_los,
			los(1) => cdr_bad,
			ok(0) => sfp_los_ok,
			ok(1) => cdr_ok
		);

-- CDC into sclk domain

	process(clk)
	begin
		if rising_edge(clk) then
			if rst_u = '1' then
				rx_err_f <= '0';
			elsif rx_err /= "000" then
				rx_err_f <= '1';
			end if;
		end if;
	end process;

	sync_sclk: entity work.pdts_synchro
		generic map(
			N => 4
		)
		port map(
			clk => clk,
			clks => sclk,
			d(0) => rxphy_aligned,
			d(1) => rxphy_locked,
			d(2) => rx_err_f,
			d(3) => rdy,
			q(0) => rxphy_aligned_i,
			q(1) => rxphy_locked_i,
			q(2) => rx_err_i,
			q(3) => rdy_i
		);

-- Resets

	rec_rst_i <= '1' when state = W_RST or state = W_SFP or state = W_CDR or state = W_FREQ else '0';
	rxphy_rst_i <= '1' when rec_rst_i = '1' or state = W_ALIGN else '0';
	rst_i <= '1' when rxphy_rst_i = '1' or state = W_LOCK else '0';

-- CDC into rec_clk / clk domain

	sync_rec_clk: entity work.pdts_synchro
		port map(
			clk => sclk,
			clks => rec_clk,
			d(0) => rec_rst_i,
			q(0) => rec_rst
		);
		
	sync_clk: entity work.pdts_synchro
		generic map(
			N => 2
		)
		port map(
			clk => sclk,
			clks => clk,
			d(0) => rxphy_rst_i,
			d(1) => rst_i,
			q(0) => rxphy_rst,
			q(1) => rst_u
		);
		
	rst <= rst_u;

-- State output

	with state select stat <=
		"0000" when W_RST, -- Starting state after reset
		"0001" when W_SFP, -- Waiting for SFP LOS to go low
		"0010" when W_CDR, -- Waiting for CDR lock
		"0011" when W_FREQ, -- Waiting for comma alignment, stable 50MHz phase
		"0100" when W_ALIGN, -- Waiting for good frequency check
		"0101" when W_LOCK, -- Waiting for 8b10 decoder good packet
		"0110" when W_RDY, -- Waiting for time stamp initialisation
		"1000" when RUN, -- Good to go
		"1100" when ERR_R, -- Error in rx
		"1101" when ERR_T; -- Error in time stamp check

end rtl;
