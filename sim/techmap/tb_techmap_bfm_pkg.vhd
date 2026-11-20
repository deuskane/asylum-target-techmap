-------------------------------------------------------------------------------
-- Title      : tb_techmap_bfm_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_techmap_bfm_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Helpers of the tb_techmap scenarios : clock period, generics of
--              the I/O buffer instances, signals of the cells as two records
--              (tb_in_t driven by the testbench, tb_out_t read by it), waits
--              and reset pulse
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (split of tb_techmap)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

package tb_techmap_bfm_pkg is

  constant C_TB_SCOPE : string := "TB_TECHMAP";
  constant C_PERIOD   : time   := 20 ns;

  -- I/O buffer instances : instance i uses bit k of i as generic
  --   ibuf  : bit 0 INPUT_VALUE_DISABLED, bit 1 INVERT_D_O, bit 2 INVERT_IE_I
  --   obuf  : bit 0 INVERT_D_I,           bit 1 INVERT_OE_I
  --   iobuf : bit 0 INPUT_VALUE_DISABLED, bit 1 INVERT_D_O, bit 2 INVERT_IE_I,
  --           bit 3 INVERT_D_I,           bit 4 INVERT_OE_I
  constant NB_IBUF    : natural := 8;
  constant NB_OBUF    : natural := 4;
  constant NB_IOBUF   : natural := 32;

  -- Bit k of i
  function bit_of
    (constant i        : in    natural
    ;constant k        : in    natural
    ) return std_logic;

  -- Inputs of the cells, driven by the testbench (pads : testbench driver)
  type tb_in_t is record
    cb_d_i       : std_logic;                               -- cbufg
    cg_cke       : std_logic;                               -- cgate
    cg_te        : std_logic;
    sy_d         : std_logic;                               -- sync2dff
    syr_d        : std_logic;                               -- sync2dffrn
    ib_pad_drv   : std_logic_vector(0 to NB_IBUF -1);       -- ibuf
    ib_ie        : std_logic;
    ob_d_i       : std_logic;                               -- obuf
    ob_oe        : std_logic;
    iob_pad_drv  : std_logic_vector(0 to NB_IOBUF-1);       -- iobuf
    iob_d_i      : std_logic;
    iob_oe       : std_logic;
    iob_ie       : std_logic;
  end record tb_in_t;

  -- Idle inputs, driven before the reset pulse of each scenario
  constant C_IN_IDLE : tb_in_t :=
    (cb_d_i      => '0'
    ,cg_cke      => '0'
    ,cg_te       => '0'
    ,sy_d        => '0'
    ,syr_d       => '0'
    ,ib_pad_drv  => (others => 'Z')
    ,ib_ie       => '0'
    ,ob_d_i      => '0'
    ,ob_oe       => '0'
    ,iob_pad_drv => (others => 'Z')
    ,iob_d_i     => '0'
    ,iob_oe      => '0'
    ,iob_ie      => '0'
    );

  -- Outputs of the cells and resolved pads
  type tb_out_t is record
    cb_d_o       : std_logic;                               -- cbufg (d_i = cb_d_i)
    cb_clk_o     : std_logic;                               -- cbufg (d_i = clock)
    cg_clk_o     : std_logic;                               -- cgate
    cg_pulses    : natural;                                 -- cgate : clk_o pulses seen by the monitor
    sy_q         : std_logic;                               -- sync2dff
    syr_q        : std_logic;                               -- sync2dffrn
    ib_pad       : std_logic_vector(0 to NB_IBUF -1);       -- ibuf
    ib_d_o       : std_logic_vector(0 to NB_IBUF -1);
    ob_pad       : std_logic_vector(0 to NB_OBUF -1);       -- obuf
    iob_pad      : std_logic_vector(0 to NB_IOBUF-1);       -- iobuf
    iob_d_o      : std_logic_vector(0 to NB_IOBUF-1);
  end record tb_out_t;

  -- Wait for the n-th next rising edge then 1 ns (registers settled)
  procedure wait_edges
    (constant n        : in    positive
    ;signal   clk      : in    std_logic
    );

  -- Reset pulse (4 rising edges), released on a falling edge
  procedure do_reset
    (signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic
    );

end package tb_techmap_bfm_pkg;

package body tb_techmap_bfm_pkg is

  function bit_of
    (constant i        : in    natural
    ;constant k        : in    natural
    ) return std_logic is
  begin
    if (i / 2**k) mod 2 = 1
    then
      return '1';
    else
      return '0';
    end if;
  end function;

  procedure wait_edges
    (constant n        : in    positive
    ;signal   clk      : in    std_logic
    ) is
  begin
    for k in 1 to n loop
      wait until rising_edge(clk);
    end loop;
    wait for 1 ns;
  end procedure;

  procedure do_reset
    (signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic
    ) is
  begin
    arst_b <= '0';
    for k in 1 to 4 loop
      wait until rising_edge(clk);
    end loop;
    wait until falling_edge(clk);
    arst_b <= '1';
  end procedure;

end package body tb_techmap_bfm_pkg;
