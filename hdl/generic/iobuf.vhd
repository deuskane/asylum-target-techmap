-------------------------------------------------------------------------------
-- Title      : I/O Buffer
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : iobuf.vhd
-- Author     : Mathieu Rosière
-------------------------------------------------------------------------------
-- Description: I/O Buffer
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-08-02  1.0      mrosiere Created
-------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.numeric_std.ALL;

entity iobuf is
  generic
  (INPUT_VALUE_DISABLED : std_logic := '0' -- d_o value when input is disabled
  ;INVERT_D_I           : std_logic := '0' -- Invert d_i value
  ;INVERT_D_O           : std_logic := '0' -- Invert d_o value
  ;INVERT_OE_I          : std_logic := '0' -- Invert oe_i value
  ;INVERT_IE_I          : std_logic := '0' -- Invert ie_i value
  );
  port 
  (buf_io   : inout std_logic -- I/O Buffer
  ;d_i      : in    std_logic -- Input Data
  ;d_o      : out   std_logic -- Output Data
  ;oe_i     : in    std_logic -- Output Enable
  ;ie_i     : in    std_logic -- Input Enable
  );
end iobuf;

architecture rtl of iobuf is

  signal d_i_int  : std_logic;
  signal d_o_int  : std_logic;
  signal oe_i_int : std_logic;
  signal ie_i_int : std_logic;

begin
  d_i_int  <= d_i      when INVERT_D_I  = '0' else not d_i   ;
  d_o_int  <= buf_io   when INVERT_D_O  = '0' else not buf_io;
  oe_i_int <= oe_i     when INVERT_OE_I = '0' else not oe_i;
  ie_i_int <= ie_i     when INVERT_IE_I = '0' else not ie_i;

  buf_io   <= d_i_int  when (oe_i_int = '1') else 'Z';
  d_o      <= d_o_int  when (ie_i_int = '1') else INPUT_VALUE_DISABLED;
  
end rtl;
