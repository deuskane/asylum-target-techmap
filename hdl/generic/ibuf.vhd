-------------------------------------------------------------------------------
-- Title      : Input Buffer
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : ibuf.vhd
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

entity ibuf is
  generic
  (INPUT_VALUE_DISABLED : std_logic := '0' -- d_o value when input is disabled
  ;INVERT_D_O           : std_logic := '0' -- Invert d_o value
  ;INVERT_IE_I          : std_logic := '0' -- Invert ie_i value
  );
  port 
  (buf_io   : inout std_logic -- I/O Buffer
  ;d_o      : out   std_logic -- Output Data
  ;ie_i     : in    std_logic -- Input Enable
  );
end ibuf;

architecture rtl of ibuf is

  signal d_o_int  : std_logic;
  signal ie_i_int : std_logic;

begin
  d_o_int  <= buf_io   when INVERT_D_O  = '0' else not buf_io;
  ie_i_int <= ie_i     when INVERT_IE_I = '0' else not ie_i;

  d_o      <= d_o_int  when (ie_i_int = '1') else INPUT_VALUE_DISABLED;
  
end rtl;
