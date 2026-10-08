-------------------------------------------------------------------------------
-- Title      : 
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : tb_dummy.vhd
-- Author     : Mathieu Rosière
-- Company    : 
-- Created    : 2025-01-06
-- Last update: 2025-09-06
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Instance of techno cells
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2025-01-06  2.0      mrosiere Created
-- 2026-10-05  2.1      mrosiere Add ibuf, obuf and iobuf instances
--                               (elaboration only, see tb_techmap for checks)
-------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.numeric_std.ALL;
library asylum;
use     asylum.techmap_pkg.all;

entity tb_dummy is
end tb_dummy;

architecture rtl of tb_dummy is
  signal pad_i  : std_logic;
  signal pad_o  : std_logic;
  signal pad_io : std_logic;
begin
  
  ins_cbufg : cbufg
  port map (
    d_i   => '0',
    d_o   => open
    );
  
  ins_cgate : cgate
  port map (
    clk_i    => '0',
    cke_i    => '0',
    dft_te_i => '0',
    clk_o    => open
    );

  ins_sync2dff : sync2dff
  port map (
    clk_i => '0',
    d_i   => '0',
    q_o   => open
    );

  ins_sync2dffrn : sync2dffrn
  port map (
    clk_i    => '0',
    arst_b_i => '0',
    d_i      => '0',
    q_o      => open
    );

  ins_ibuf : ibuf
  port map (
    buf_io   => pad_i,
    d_o      => open,
    ie_i     => '0'
    );

  ins_obuf : obuf
  port map (
    buf_io   => pad_o,
    d_i      => '0',
    oe_i     => '0'
    );

  ins_iobuf : iobuf
  port map (
    buf_io   => pad_io,
    d_i      => '0',
    d_o      => open,
    oe_i     => '0',
    ie_i     => '0'
    );

end rtl;
