-- pdts_tx
--
-- The transmit L2 block
--
-- Dave Newbold, October 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.pdts_defs.all;

entity pdts_tx is
	port(
		clk: in std_logic; -- 50MHz system clock
		rst: in std_logic; -- synchronous reset
		stb: in std_logic; -- system word strobe
		addr: in std_logic_vector((8 * ADDR_WDS) - 1 downto 0); -- address (static)
		s_d: in std_logic_vector(7 downto 0); -- sync cmd data
		s_valid: in std_logic; -- sync cmd valid
		s_rdy: out std_logic; -- ready for sync cmd
		a_d: in std_logic_vector(7 downto 0); -- async cmd data
		a_last: in std_logic; -- async cmd packet end
		a_ack: out std_logic; -- async cmd acknowledge
		q: out std_logic_vector(7 downto 0); -- data output
		k: out std_logic; -- kchar output
		stbo: out std_logic; -- stb out
		err: out std_logic -- error output
	);

end pdts_tx;

architecture rtl of pdts_tx is

	type state_t is (START, ST_K, ST_A, ST_S, ST_D, ST_C, ST_E);
	signal state: state_t;
	signal actr, actr_i: unsigned(7 downto 0);
	signal csum: std_logic_vector(15 downto 0);
	signal smode, smode_d, s_ok, astb, cclr, cstb, trans: std_logic;
	signal q_a, q_s, a_dd, s_dd, s_ddd: std_logic_vector(7 downto 0);
	signal iaddr: integer range ADDR_WDS - 1 downto 0 := 0;
	signal icsum: integer range CSUM_WDS - 1 downto 0 := 0;

begin

	astb <= stb and not (smode or smode_d); 

-- Async state machine
	
	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				state <= START;
			else
				if astb = '1' then
					trans <= '0';
					case state is
-- Start
					when START =>
						state <= ST_K;
-- Async kchar
					when ST_K =>
						state <= ST_A;
						trans <= '1';
-- Async addr
					when ST_A =>
						if actr = to_unsigned(ADDR_WDS - 1, actr'length) then
							state <= ST_S;
							trans <= '1';
						end if;
-- Async send addr
					when ST_S =>
						if actr = to_unsigned(ADDR_WDS - 1, actr'length) then
							state <= ST_D;
							trans <= '1';
						end if;
-- Async data
					when ST_D =>
						if a_last = '1' then
							state <= ST_C;
							trans <= '1';
						elsif actr = to_unsigned(CMD_LEN_MAX - CSUM_WDS - ADDR_WDS * 2 - 1, actr'length) then
							state <= ST_E;
							trans <= '1';
						end if;
-- Async cksum
					when ST_C =>
						if actr = to_unsigned(CSUM_WDS - 1, actr'length) then
							state <= ST_K;
							trans <= '1';
						end if;
-- Error condition; no escape
					when ST_E =>
					end case;
				end if;
			end if;
		end if;
	end process;
	
-- Async word counter
	
	actr <= actr_i when trans = '0' else X"00";
	actr_i <= actr + 1 when rising_edge(clk) and astb = '1';

-- Checksum

	cclr <= '1' when state = ST_K or rst = '1' else '0';
	cstb <= astb when state /= ST_K and state /= ST_C else '0';
	
	cksum: entity work.pdts_cksum
		port map(
			clk => clk,
			stb => cstb,
			clr => cclr,
			d => q_a,
			c => csum
		);
		
-- Async data

	iaddr <= ADDR_WDS - to_integer(actr) - 1 when actr < ADDR_WDS else 0; -- Address words are sent big-endian
	icsum <= CSUM_WDS - to_integer(actr) - 1 when actr < CSUM_WDS else 0; -- Checksum words are sent big-endian
	
	a_dd <= a_d when stb = '1' and rising_edge(clk);
	
	with state select q_a <=
		a_dd when ST_A,
		addr(iaddr * 8 + 7 downto iaddr * 8) when ST_S,
		a_d when ST_D,
		csum(icsum * 8 + 7 downto icsum * 8) when ST_C,
		X"00" when others;
		
-- Sync handshaking

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				s_ok <= '0';
			elsif state = ST_K and astb = '1' then
				s_ok <= '1';
			end if;
			if stb = '1' then
				s_dd <= s_d;
				s_ddd <= s_dd;
				smode <= s_valid and s_ok;
				smode_d <= smode;
			end if;
		end if;
	end process;
	
	s_rdy <= s_ok and not smode;
	q_s <= X"01" when smode = '1' and smode_d = '0' else s_ddd;
			
-- Outputs
	
	q <= q_s when (smode = '1' or smode_d = '1') else q_a;
	k <= '1' when (smode = '1' and smode_d = '0') or (smode = '0' and smode_d = '0' and state = ST_K) else '0';
	a_ack <= '1' when (state = ST_A or state = ST_D) and astb = '1' else '0';
	err <= '1' when state = ST_E else '0';
	stbo <= stb when rising_edge(clk);
	
end rtl;
