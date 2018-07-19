-- dtpc_wbuf
--
-- Data source buffer
--
-- Dave Newbold, July 2018

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_decode_dtpc_src.all;
use work.ipbus_reg_types.all;
use work.dtpc_stream_defs.all;

entity dtpc_wbuf is
	generic(
		C_BASE: integer := 0;
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
		ts_rst: in std_logic;
		q: out dtpc_stream_w;
		d: in dtpc_stream_r;
		go: in std_logic;
		done: out std_logic
	);

end dtpc_wbuf;

architecture rtl of dtpc_wbuf is

	constant ADDR_WIDTH: integer := calc_width(N_MUX) + BLOCK_RADIX;
	signal tctr: unsigned(DTPC_STREAM_D_W * 2 - 1 downto 0);
	signal cctr: unsigned(calc_width(N_MUX) -1 downto 0);
	signal sctr: unsigned(BLOCK_RADIX - 1 downto 0);
	signal addr: unsigned(ADDR_WIDTH - 1 downto 0);
	signal addr_sl: std_logic_vector(ADDR_WIDTH - 1 downto 0);
	signal send, cend, run, c, c_r, done_i, done_p: std_logic;
	signal q_ram, hdata, hdata_r: std_logic_vector(DTPC_STREAM_D_W - 1 downto 0);
	
begin

-- RAM block

    addr_sl <= std_logic_vector(addr);

	ram: entity work.ipbus_ported_dpram
		generic map(
			ADDR_WIDTH => ADDR_WIDTH,
			DATA_WIDTH => DTPC_STREAM_D_W
		)
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipb_in,
			ipb_out => ipb_out,
			rclk => clk,
			q => q_ram,
			addr => addr_sl
		);

-- Timestamp

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' or ts_rst = '1' then
				tctr <= (others => '0');
			elsif done_i = '1' and d.ack = '1' and run = '1' then
				tctr <= tctr + 2 ** BLOCK_RADIX;
			end if;
		end if;
	end process;
		
-- Pointer control

	run <= (run or go) and not ((done_i and d.ack) or rst) when rising_edge(clk);

	process(clk)
	begin
		if falling_edge(clk) then
			if run = '0' then
				cctr <= (others => '0');
				sctr <= (others => '0');
				addr <= (others => '0');
				c <= '0';
			elsif d.ack = '1' then
				if c = '0' then
					if sctr /= 2 then
						sctr <= sctr + 1;
					else
						sctr <= (others => '0');
						c <= '1';
					end if;
				else
					sctr <= sctr + 1;
					if send = '0' then
						addr <= addr + N_MUX;
					else
						cctr <= cctr + 1;
						addr <= (ADDR_WIDTH - 1 downto cctr'left + 1 => '0') & (cctr + 1);							
					end if;
				end if;
			end if;
		end if;
	end process;
	
	send <= and_reduce(std_logic_vector(sctr));
	cend <= '1' when cctr = N_MUX - 1 else '0';
	done_i <= send and cend;
	done_p <= (done_p or (send and cend)) and not (run or go) when rising_edge(clk);
	
	with sctr select hdata <=
		std_logic_vector(resize(cctr, DTPC_STREAM_D_W) + C_BASE) when to_unsigned(0, sctr'length),
		std_logic_vector(tctr(DTPC_STREAM_D_W - 1 downto 0)) when to_unsigned(1, sctr'length),
		std_logic_vector(tctr(DTPC_STREAM_D_W * 2 - 1 downto DTPC_STREAM_D_W)) when others;
		
	hdata_r <= hdata when rising_edge(clk);
	c_r <= c when rising_edge(clk);

	q.d <= hdata_r when c_r = '0' else q_ram;
	q.h_valid <= run and (not c_r or done_i);
	q.c_valid <= run and c_r;
	
	done <= done_p;

end rtl;
