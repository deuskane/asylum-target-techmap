-------------------------------------------------------------------------------
-- Title      : Output Buffer
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : obuf.vhd
-- Author     : Mathieu Rosière
-------------------------------------------------------------------------------
-- Description: I/O Buffer
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-08-24  1.0      mrosiere Created
-------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.numeric_std.ALL;

entity obuf is
  generic
  (INVERT_D_I           : std_logic := '0' -- Invert d_i value
  ;INVERT_OE_I          : std_logic := '0' -- Invert oe_i value
  );
  port 
  (buf_io   : inout std_logic -- I/O Buffer
  ;d_i      : in    std_logic -- Input Data
  ;oe_i     : in    std_logic -- Output Enable
  );
end obuf;

architecture rtl of obuf is

  signal d_i_int  : std_logic;
  signal oe_i_int : std_logic;

begin
  d_i_int  <= d_i      when INVERT_D_I  = '0' else not d_i   ;
  oe_i_int <= oe_i     when INVERT_OE_I = '0' else not oe_i;

  buf_io   <= d_i_int  when (oe_i_int = '1') else 'Z';
  
end rtl;
