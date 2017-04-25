-- pdts_scmd_evt
--
-- Logs sync commands to DAQ
--
-- Dave Newbold, April 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library unisim;
use unisim.VComponents.all;

entity pdts_scmd_evt is
	generic(
		WARN_THRESH: integer := 16#300#
	);
	port(
		clk: in std_logic;
		rst: in std_logic;
		scmd: in std_logic_vector(3 downto 0);
		valid: in std_logic;
		tstamp: in std_logic_vector(63 downto 0);
		evtctr: in std_logic_vector(31 downto 0);
		empty: out std_logic;
		warn: out std_logic;
		full: out std_logic;
		rob_clk: in std_logic; -- readout buffer clock
		rob_rst: in std_logic;
		rob_q: out std_logic_vector(31 downto 0);
		rob_we: out std_logic;
		rob_last: out std_logic;
		rob_full: in std_logic
	);

end pdts_scmd_evt;

architecture rtl of pdts_scmd_evt is

	signal rst_ctr: unsigned(3 downto 0);
	signal rsti, rst_f, wen: std_logic;
	type d_t is array(5 downto 0) of std_logic_vector(31 downto 0);
	signal d, q: d_t;
	signal empty_f, full_f, warn_f: std_logic_vector(5 downto 0) := (others => '0');
	signal rctr: unsigned(2 downto 0);
	signal done, empty_i, full_i, v: std_logic;
	
begin

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				rst_ctr <= "0000";
			elsif rsti = '1' then
				rst_ctr <= rst_ctr + 1;
			end if;
		end if;
	end process;
	
	rsti <= '0' when rst_ctr = "1111" else '1';
	rst_f <= rsti and rst_ctr(3);
	wen <= valid and not rsti and not full_i;

	d(0) <= X"aa000600"; -- DAQ word 0
	d(1) <= X"0000000" & scmd; -- DAQ word 1
	d(2) <= tstamp(31 downto 0); -- DAQ word 2
	d(3) <=	tstamp(63 downto 32); -- DAQ word 3
	d(4) <= evtctr; -- DAQ word 4
	d(5) <= X"00000000"; -- Dummy checksum (not implemented yet)
	
	fgen: for i in 4 downto 1 generate
	
	   signal ren: std_logic;
	   signal ql: std_logic_vector(63 downto 0);
	   
	begin
	
	   ren <= '1' when rctr = i and v = '1' else '0';
	
		fifo: FIFO36E1
			generic map(
				DATA_WIDTH => 36,
				FIRST_WORD_FALL_THROUGH => true,
				ALMOST_FULL_OFFSET => to_bitvector(std_logic_vector(to_unsigned(WARN_THRESH, 16)))
			)
			port map(
				di(63 downto 32) => (others => '0'),
				di(31 downto 0) => d(i),
				dip => X"00",
				do => ql,
				dop => open,
				empty => empty_f(i),
				full => full_f(i),
				almostfull => warn_f(i),
				injectdbiterr => '0',
				injectsbiterr => '0',
				rdclk => rob_clk,
				rden => ren,
				regce => '1',
				rst => rst_f,
				rstreg => '0',
				wrclk => clk,
				wren => wen
			);
			
		q(i) <= ql(31 downto 0);
		
	end generate;

	q(0) <= d(0);
	q(5) <= d(5);
	
	empty_i <= or_reduce(empty_f);
	empty <= empty_i;
	warn <= or_reduce(warn_f);
	full_i <= or_reduce(full_f);
	full <= full_i;
	
	v <= not (rob_full or full_i) when rctr /= 0 or empty_i = '0' else '0'; -- Once full, we're stuck until reset
	done <= '1' when rctr = 5 else '0';
	
	process(rob_clk)
	begin
		if rising_edge(rob_clk) then
			if rob_rst = '1' then
				rctr <= (others => '0');
			elsif v = '1' then
				if done = '1' then
					rctr <= (others => '0');
				else
					rctr <= rctr + 1;
				end if;
			end if;
		end if;
	end process;
	
	rob_q <= q(to_integer(rctr));
	rob_we <= v;
	rob_last <= done;
	
end rtl;
