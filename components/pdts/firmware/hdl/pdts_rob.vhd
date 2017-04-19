-- pdts_rob
--
-- Readout buffer
--
-- size of buffer is 1k words * N_FIFO
-- last must be asserted on same cycle as final write enable
-- data counter is updated only on last word of event; never try to write an event bigger than the FIFO depth!
-- write on full is an error, and is ignored.
--
-- Dave Newbold, April 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity pdts_rob is
	generic(
		N_FIFO => 1
	);
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		rst: in std_logic; -- Buffer enable / nreset
		d: in std_logic_vector(31 downto 0); -- data in 
		we: in std_logic; -- write enable in
		last: in std_logic; -- last flag in
		full: out std_logic; -- full flag out
		empty: out std_logic -- empty flag out
	);

end pdts_rob;

architecture rtl of pdts_rob is

	signal re, lastw: std_logic;
	signal ectr, ctr: unsigned(15 downto 0);
	signal d_fifo, q_fifo: std_logic_vector(35 downto 0);
	signal empty_i: std_logic;

begin
	
	re <= ipb_in.ipb_strobe and not ipb_in.ipb_addr(0) and not ipb_in.ipb_write and not empty_i;
	lastw <= last and we;
	
	process(ipb_clk)
	begin
		if rising_edge(ipb_clk) then
			if rst = '1' or lastw = '1' then
				ectr <= (others => '0');
			elsif we = '1' then
				ectr <= ectr + 1;
			end if;
			if rst = '1' then
				ctr <= (others => '0');
			elsif re = '1' then
				if lastw = '1' then
					ctr <= ctr + ectr;
				else
					ctr <= ctr - 1;
				end if;
			elsif lastw = '1' then
				ctr <= ctr + ectr + 1;
			end if;
		end if;
	end if;
	
	d_fifo <= X"0" & d;
	
	buf: entity work.big_fifo_36
		generic map(
			N_FIFO => N_FIFO
		)
		port map(
			clk => clk,
			rst => rst,
			d => d_fifo,
			wen => we,
			full => full,
			empty => empty_i,
			ctr => open,
			ren => re,
			q => q_fifo,
			valid => valid
		);
		
	empty <= empty_i;
		
	ipb_out.ipb_rdata <= q_fifo(31 downto 0) when ipb_in.ipb_addr(0) = '0' else X"0000" & std_logic_vector(ctr);
	ipb_out.ipb_ack <= ipb_in.ipb_strobe and not ipb_in.ipb_write and not (empty_i and not ipb_in.ipb_addr(0));
	ipb_out.ipb_err <= ipb_in.ipb_strobe and (ipb_in.ipb_write or (empty_i and not ipb_in.ipb_addr(0)));
	
end rtl;
