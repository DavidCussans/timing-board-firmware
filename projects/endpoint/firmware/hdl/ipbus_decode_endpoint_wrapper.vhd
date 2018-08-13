-- Address decode logic for ipbus fabric
-- 
-- This file has been AUTOGENERATED from the address table - do not hand edit
-- 
-- We assume the synthesis tool is clever enough to recognise exclusive conditions
-- in the if statement.
-- 
-- Dave Newbold, February 2011

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

package ipbus_decode_endpoint_wrapper is

  constant IPBUS_SEL_WIDTH: positive := INSERT_SEL_WIDTH_HERE;
  subtype ipbus_sel_t is std_logic_vector(IPBUS_SEL_WIDTH - 1 downto 0);
  function ipbus_sel_endpoint_wrapper(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t;

-- START automatically  generated VHDL the Mon Aug 13 13:56:16 2018 
  constant N_SLV_VERSION: integer := 0;
  constant N_SLV_CSR: integer := 1;
  constant N_SLV_TSTAMP: integer := 2;
  constant N_SLV_EVTCTR: integer := 3;
  constant N_SLV_BUF: integer := 4;
  constant N_SLV_FREQ: integer := 5;
  constant N_SLV_CTRS: integer := 6;
  constant N_SLV_SCMD_GEN: integer := 7;
  constant N_SLAVES: integer := 8;
-- END automatically generated VHDL

    
end ipbus_decode_endpoint_wrapper;

package body ipbus_decode_endpoint_wrapper is

  function ipbus_sel_endpoint_wrapper(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t is
    variable sel: ipbus_sel_t;
  begin

-- START automatically  generated VHDL the Mon Aug 13 13:56:16 2018 
    if    std_match(addr, "-------------------------0-0000-") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_VERSION, IPBUS_SEL_WIDTH)); -- version / base 0x00000000 / mask 0x0000005e
    elsif std_match(addr, "-------------------------0-0001-") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_CSR, IPBUS_SEL_WIDTH)); -- csr / base 0x00000002 / mask 0x0000005e
    elsif std_match(addr, "-------------------------0-0010-") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_TSTAMP, IPBUS_SEL_WIDTH)); -- tstamp / base 0x00000004 / mask 0x0000005e
    elsif std_match(addr, "-------------------------0-0011-") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_EVTCTR, IPBUS_SEL_WIDTH)); -- evtctr / base 0x00000006 / mask 0x0000005e
    elsif std_match(addr, "-------------------------0-0100-") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_BUF, IPBUS_SEL_WIDTH)); -- buf / base 0x00000008 / mask 0x0000005e
    elsif std_match(addr, "-------------------------0-0101-") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_FREQ, IPBUS_SEL_WIDTH)); -- freq / base 0x0000000a / mask 0x0000005e
    elsif std_match(addr, "-------------------------0-1----") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_CTRS, IPBUS_SEL_WIDTH)); -- ctrs / base 0x00000010 / mask 0x00000050
    elsif std_match(addr, "-------------------------1------") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_SCMD_GEN, IPBUS_SEL_WIDTH)); -- scmd_gen / base 0x00000040 / mask 0x00000040
-- END automatically generated VHDL

    else
        sel := ipbus_sel_t(to_unsigned(N_SLAVES, IPBUS_SEL_WIDTH));
    end if;

    return sel;

  end function ipbus_sel_endpoint_wrapper;

end ipbus_decode_endpoint_wrapper;

