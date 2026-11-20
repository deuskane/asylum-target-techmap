-------------------------------------------------------------------------------
-- Title      : tb_techmap_cgate_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_techmap_cgate_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario cgate of tb_techmap : clock gated / running, cke_i
--              changing (or a glitch) during the high phase has no effect
--              until the clock is low, cke_i changing during the low phase
--              acts on the next pulse, dft_te_i forces the clock (also
--              latched). The monitor of tb_techmap checks every clk_o
--              pulse (full half period, starts on a rising edge of clk_i)
--              and counts them
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

library work;
use     work.tb_techmap_bfm_pkg.all;

package tb_techmap_cgate_pkg is

  -- Clock gating, enable latch, test enable
  procedure run
    (signal   clk      : in    std_logic
    ;signal   ci       : out   tb_in_t
    ;signal   co       : in    tb_out_t
    );

end package tb_techmap_cgate_pkg;

package body tb_techmap_cgate_pkg is

  -- Count the clk_o pulses during n clock periods (starts on a falling edge)
  procedure check_pulses
    (constant n        : in    natural
    ;constant exp      : in    natural
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   co       : in    tb_out_t
    ) is
    variable v_start   : natural;
  begin
    wait until falling_edge(clk);
    wait for 1 ns;                     -- pulse ending on this edge not counted
    v_start := co.cg_pulses;
    for k in 1 to n loop
      wait until falling_edge(clk);
    end loop;
    wait for 1 ns;
    check_value(co.cg_pulses - v_start, exp, ERROR, msg, C_TB_SCOPE);
  end procedure;

  procedure run
    (signal   clk      : in    std_logic
    ;signal   ci       : out   tb_in_t
    ;signal   co       : in    tb_out_t
    ) is
  begin
    log(ID_SEQUENCER, "cgate : clock gated, then running", C_TB_SCOPE);
    ci.cg_cke <= '0';
    ci.cg_te  <= '0';
    check_pulses(4, 0, "cgate: cke_i = 0, clock gated", clk, co);
    check_value(co.cg_clk_o, '0', ERROR, "cgate: gated clock is low", C_TB_SCOPE);

    ci.cg_cke <= '1';
    check_pulses(4, 4, "cgate: cke_i = 1, clock running", clk, co);

    log(ID_SEQUENCER, "cgate : cke_i changing during the high phase", C_TB_SCOPE);
    -- Disable in the middle of the high phase : the current pulse completes
    wait until rising_edge(clk);
    wait for C_PERIOD/8;
    check_value(co.cg_clk_o, '1', ERROR, "cgate: pulse in progress", C_TB_SCOPE);
    ci.cg_cke <= '0';
    wait for C_PERIOD/8;
    check_value(co.cg_clk_o, '1', ERROR, "cgate: cke_i falling while clk_i high does not cut the pulse", C_TB_SCOPE);
    check_pulses(3, 0, "cgate: no pulse after cke_i falling", clk, co);

    -- Enable in the middle of the high phase : no partial pulse
    wait until rising_edge(clk);
    wait for C_PERIOD/8;
    ci.cg_cke <= '1';
    wait for C_PERIOD/8;
    check_value(co.cg_clk_o, '0', ERROR, "cgate: cke_i rising while clk_i high does not start a partial pulse", C_TB_SCOPE);
    wait until falling_edge(clk);
    wait for 1 ns;
    check_value(co.cg_clk_o, '0', ERROR, "cgate: still low until the next rising edge", C_TB_SCOPE);
    wait until rising_edge(clk);
    wait for 1 ns;
    check_value(co.cg_clk_o, '1', ERROR, "cgate: first pulse on the next rising edge", C_TB_SCOPE);

    -- Short enable glitch during the high phase is filtered by the latch
    ci.cg_cke <= '0';
    wait until falling_edge(clk);
    wait until rising_edge(clk);
    wait for C_PERIOD/8;
    ci.cg_cke <= '1';
    wait for 1 ns;
    ci.cg_cke <= '0';
    check_pulses(2, 0, "cgate: cke_i glitch while clk_i high is filtered", clk, co);

    log(ID_SEQUENCER, "cgate : cke_i changing during the low phase", C_TB_SCOPE);
    wait until falling_edge(clk);
    wait for C_PERIOD/8;
    ci.cg_cke <= '1';
    wait until rising_edge(clk);
    wait for 1 ns;
    check_value(co.cg_clk_o, '1', ERROR, "cgate: cke_i set during the low phase enables the next pulse", C_TB_SCOPE);
    wait until falling_edge(clk);
    wait for C_PERIOD/8;
    ci.cg_cke <= '0';
    wait until rising_edge(clk);
    wait for 1 ns;
    check_value(co.cg_clk_o, '0', ERROR, "cgate: cke_i cleared during the low phase gates the next pulse", C_TB_SCOPE);

    log(ID_SEQUENCER, "cgate : test enable", C_TB_SCOPE);
    -- dft_te_i goes through the latch as cke_i : no partial pulse
    wait until rising_edge(clk);
    wait for C_PERIOD/8;
    ci.cg_te  <= '1';
    wait for C_PERIOD/8;
    check_value(co.cg_clk_o, '0', ERROR, "cgate: dft_te_i rising while clk_i high does not start a partial pulse", C_TB_SCOPE);
    ci.cg_cke <= '1';
    ci.cg_te  <= '1';
    check_pulses(4, 4, "cgate: cke_i = 1 and dft_te_i = 1, clock running", clk, co);
    ci.cg_cke <= '0';
    check_pulses(4, 4, "cgate: dft_te_i = 1 forces the clock", clk, co);
    ci.cg_te  <= '0';
    check_pulses(4, 0, "cgate: dft_te_i = 0, cke_i = 0 gates the clock", clk, co);
  end procedure;

end package body tb_techmap_cgate_pkg;
