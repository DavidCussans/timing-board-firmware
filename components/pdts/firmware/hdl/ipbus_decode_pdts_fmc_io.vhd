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

package ipbus_decode_pdts_fmc_io is

  constant IPBUS_SEL_WIDTH: positive := 5; -- Should be enough for now?
  subtype ipbus_sel_t is std_logic_vector(IPBUS_SEL_WIDTH - 1 downto 0);
  function ipbus_sel_pdts_fmc_io(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t;

-- START automatically  generated VHDL the Mon Mar 20 18:50:16 2017 
  constant N_SLV_CSR: integer := 0;
  constant N_SLV_UID_I2C: integer := 1;
  constant N_SLV_SFP_I2C: integer := 2;
  constant N_SLV_PLL_I2C: integer := 3;
  constant N_SLV_FREQ: integer := 4;
  constant N_SLAVES: integer := 5;
-- END automatically generated VHDL

    
end ipbus_decode_pdts_fmc_io;

package body ipbus_decode_pdts_fmc_io is

  function ipbus_sel_pdts_fmc_io(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t is
    variable sel: ipbus_sel_t;
  begin

-- START automatically  generated VHDL the Mon Mar 20 18:50:16 2017 
    if    std_match(addr, "--------------------------000---") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_CSR, IPBUS_SEL_WIDTH)); -- csr / base 0x00000000 / mask 0x00000038
    elsif std_match(addr, "--------------------------001---") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_UID_I2C, IPBUS_SEL_WIDTH)); -- uid_i2c / base 0x00000008 / mask 0x00000038
    elsif std_match(addr, "--------------------------010---") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_SFP_I2C, IPBUS_SEL_WIDTH)); -- sfp_i2c / base 0x00000010 / mask 0x00000038
    elsif std_match(addr, "--------------------------011---") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_PLL_I2C, IPBUS_SEL_WIDTH)); -- pll_i2c / base 0x00000018 / mask 0x00000038
    elsif std_match(addr, "--------------------------100---") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_FREQ, IPBUS_SEL_WIDTH)); -- freq / base 0x00000020 / mask 0x00000038
-- END automatically generated VHDL

    else
        sel := ipbus_sel_t(to_unsigned(N_SLAVES, IPBUS_SEL_WIDTH));
    end if;

    return sel;

  end function ipbus_sel_pdts_fmc_io;

end ipbus_decode_pdts_fmc_io;

