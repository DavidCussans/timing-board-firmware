-- pdts_defs
--
-- Constants and types for PDTS
--
-- Dave Newbold, October 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package pdts_defs is

-- L0 constants

	constant SCLK_RATIO: integer := 1; -- Ratio of IO clock to base clock (5 = 250Mb/s IO)
	
-- L1 constants
	
	constant CCHAR: std_logic_vector(7 downto 0) := X"BC"; -- K28.5
	constant CCHAR_PD: std_logic_vector(9 downto 0) := "1010000011"; -- K28.5 encoded RD = +1
	constant CCHAR_ND: std_logic_vector(9 downto 0) := "0101111100"; -- K28.5 encoded RD = -1
	constant SCHAR: std_logic_vector(7 downto 0) := X"3C"; -- K28.1

-- L2	constants
	
	constant GRP_W: natural := 2; -- Bitwidth of group ID
	constant ADDR_WDS: positive := 1; -- Number of address words	
--	constant ADDR_FLD_W: natural := 8; -- Add fancier address matching later
	constant SCMD_W: natural := 4; -- Bitwidth of sync cmd
	constant CSUM_WDS : positive := 2; -- Number of checksum words (CRC16)
	constant ACMD_LEN_MIN: natural := ADDR_WDS * 2 + 1 + CSUM_WDS;
	constant IDLE_DATA_WDS: natural := 16; -- Number of data words in idle packet
	constant CMD_LEN_MAX: natural := IDLE_DATA_WDS + ACMD_LEN_MIN; -- Maximum command length
	constant COMMA_TIMEOUT_W: natural := 8; -- Bitwidth of timeout counter
	
-- L3 constants

	constant TSTAMP_WDS: natural := 8; -- Number of words in timestamp
	constant EVTCTR_WDS: natural := 4; -- Number of words in event counter
	constant EVTCTR_MASK: std_logic_vector(15 downto 0) := X"0001"; -- Which sync cmds cause evt ctr update
	constant TS_RATE_RADIX: positive :=  26; -- Issue TS at a rate of 50MHz/(2^26) = 0.75Hz per partition

	type SCMD_LEN_T is array(0 to 2 ** SCMD_W - 1) of natural; -- Data words for each sync cmd
	constant SCMD_LEN: SCMD_LEN_T := (1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 + TSTAMP_WDS + EVTCTR_WDS);
	
-- Types

	type cmd_w is
		record
			d: std_logic_vector(7 downto 0);
			valid: std_logic;
			last: std_logic;
		end record;

	type cmd_w_array is array(natural range <>) of cmd_w;
	
	type cmd_r is
		record
			ack: std_logic;
			ren: std_logic;
		end record;

	type cmd_r_array is array(natural range <>) of cmd_r;
	
end pdts_defs;
