-------------------------------------------------------------------------------
-- Title      : Gated Clock
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : cgate.vhd
-- Author     : Mathieu Rosière
-- Company    : 
-- Created    : 2026-10-17
-- Last update: 2026-10-17
-- Platform   : NanoXplore NG-MEDIUM
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Clock Gate on the NX_CKS clock switch of the clock network
--              (the generic latch + AND would take the clock out of the
--              clock network and build the latch in the fabric)
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-17  1.0      mrosiere Created
-------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.numeric_std.ALL;

library nx;
use     nx.nxPackage.all;

entity cgate is
  port   (
    clk_i    : in  std_logic; -- Input Clock
    cke_i    : in  std_logic; -- Clock command (active high)
                              --   0 disable clock
                              --   1 enable  clock
    clk_o    : out std_logic; -- Output Clock
    dft_te_i : in  std_logic  -- Test enable (active high)
    );
end cgate;

architecture rtl of cgate is
  signal cke   : std_logic; -- Clock enable
begin

  -- Command depends of cke_i and test mode
  -- (must be synchronous to clk_i, as for the generic cell)
  cke <= cke_i or dft_te_i;

  -- Glitch-free clock switch: clk_o = clk_i when cke = 1, stopped otherwise
  ins_clock_switch : NX_CKS
    generic map(
        ck_edge      => '0'
    )
    port map(
        CKI          => clk_i,
        CMD          => cke,
        CKO          => clk_o
    );

end rtl;
