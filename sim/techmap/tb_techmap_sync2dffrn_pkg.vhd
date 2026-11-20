-------------------------------------------------------------------------------
-- Title      : tb_techmap_sync2dffrn_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_techmap_sync2dffrn_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario sync2dffrn of tb_techmap : q_o held at 0 during the
--              reset, 2-edge latency (rising edges only : q_o unchanged
--              after the falling edge), an asynchronous reset between two
--              edges clears the whole chain
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

package tb_techmap_sync2dffrn_pkg is

  -- Reset held, 2-edge latency, asynchronous reset of the whole chain
  procedure run
    (signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic
    ;signal   ci       : out   tb_in_t
    ;signal   co       : in    tb_out_t
    );

end package tb_techmap_sync2dffrn_pkg;

package body tb_techmap_sync2dffrn_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic
    ;signal   ci       : out   tb_in_t
    ;signal   co       : in    tb_out_t
    ) is
  begin
    log(ID_SEQUENCER, "sync2dffrn : reset held with d_i = 1", C_TB_SCOPE);
    arst_b   <= '0';
    ci.syr_d <= '1';
    wait_edges(3, clk);
    check_value(co.syr_q, '0', ERROR, "sync2dffrn: held at 0 during reset", C_TB_SCOPE);

    log(ID_SEQUENCER, "sync2dffrn : 2-edge latency", C_TB_SCOPE);
    wait until falling_edge(clk);
    arst_b   <= '1';
    wait_edges(1, clk);
    check_value(co.syr_q, '0', ERROR, "sync2dffrn: 0 after 1 edge", C_TB_SCOPE);
    wait until falling_edge(clk);
    wait for 1 ns;
    check_value(co.syr_q, '0', ERROR, "sync2dffrn: unchanged after the falling edge", C_TB_SCOPE);
    wait_edges(1, clk);
    check_value(co.syr_q, '1', ERROR, "sync2dffrn: 1 after 2 edges", C_TB_SCOPE);
    wait until falling_edge(clk);
    ci.syr_d <= '0';
    wait_edges(1, clk);
    check_value(co.syr_q, '1', ERROR, "sync2dffrn: unchanged after 1 edge", C_TB_SCOPE);
    wait until falling_edge(clk);
    wait for 1 ns;
    check_value(co.syr_q, '1', ERROR, "sync2dffrn: unchanged after the falling edge", C_TB_SCOPE);
    wait_edges(1, clk);
    check_value(co.syr_q, '0', ERROR, "sync2dffrn: new value after 2 edges", C_TB_SCOPE);

    log(ID_SEQUENCER, "sync2dffrn : asynchronous reset between two edges", C_TB_SCOPE);
    wait until falling_edge(clk);
    ci.syr_d <= '1';
    wait_edges(2, clk);
    check_value(co.syr_q, '1', ERROR, "sync2dffrn: 1 before reset", C_TB_SCOPE);
    wait for C_PERIOD/4;
    arst_b   <= '0';
    wait for 1 ns;
    check_value(co.syr_q, '0', ERROR, "sync2dffrn: asynchronous reset clears q_o without clock edge", C_TB_SCOPE);
    wait until falling_edge(clk);
    arst_b   <= '1';
    wait_edges(1, clk);
    check_value(co.syr_q, '0', ERROR, "sync2dffrn: whole chain cleared by the reset", C_TB_SCOPE);
    wait_edges(1, clk);
    check_value(co.syr_q, '1', ERROR, "sync2dffrn: 2 edges after reset release", C_TB_SCOPE);
  end procedure;

end package body tb_techmap_sync2dffrn_pkg;
