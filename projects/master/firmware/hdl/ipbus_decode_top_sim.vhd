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

package ipbus_decode_top_sim is

  constant IPBUS_SEL_WIDTH: positive := 5; -- Should be enough for now?
  subtype ipbus_sel_t is std_logic_vector(IPBUS_SEL_WIDTH - 1 downto 0);
  function ipbus_sel_top_sim(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t;

-- START automatically  generated VHDL the Fri Sep  1 09:50:35 2017 
  constant N_SLV_IO: integer := 0;
  constant N_SLV_MASTER: integer := 1;
  constant N_SLAVES: integer := 2;
-- END automatically generated VHDL

    
end ipbus_decode_top_sim;

package body ipbus_decode_top_sim is

  function ipbus_sel_top_sim(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t is
    variable sel: ipbus_sel_t;
  begin

-- START automatically  generated VHDL the Fri Sep  1 09:50:35 2017 
    if    std_match(addr, "----------------------0---------") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_IO, IPBUS_SEL_WIDTH)); -- io / base 0x00000000 / mask 0x00000200
    elsif std_match(addr, "----------------------1---------") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_MASTER, IPBUS_SEL_WIDTH)); -- master / base 0x00000200 / mask 0x00000200
-- END automatically generated VHDL

    else
        sel := ipbus_sel_t(to_unsigned(N_SLAVES, IPBUS_SEL_WIDTH));
    end if;

    return sel;

  end function ipbus_sel_top_sim;

end ipbus_decode_top_sim;

