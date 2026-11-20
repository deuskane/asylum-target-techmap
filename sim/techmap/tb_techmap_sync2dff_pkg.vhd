-------------------------------------------------------------------------------
-- Title      : tb_techmap_sync2dff_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_techmap_sync2dff_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario sync2dff of tb_techmap : 2-edge latency in both
--              directions (rising edges only : q_o unchanged after the
--              falling edge), a 1-cycle pulse lasts 1 cycle on q_o
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

package tb_techmap_sync2dff_pkg is

  -- 2-edge latency, 1-cycle pulse (no reset : the chain is flushed with 0)
  procedure run
    (signal   clk      : in    std_logic
    ;signal   ci       : out   tb_in_t
    ;signal   co       : in    tb_out_t
    );

end package tb_techmap_sync2dff_pkg;

package body tb_techmap_sync2dff_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   ci       : out   tb_in_t
    ;signal   co       : in    tb_out_t
    ) is
  begin
    log(ID_SEQUENCER, "sync2dff : 2-edge latency", C_TB_SCOPE);
    wait until falling_edge(clk);
    ci.sy_d <= '0';
    wait_edges(3, clk);
    check_value(co.sy_q, '0', ERROR, "sync2dff: chain flushed with 0", C_TB_SCOPE);
    for v in std_logic range '0' to '1' loop
      wait until falling_edge(clk);
      ci.sy_d <= not v;
      wait_edges(1, clk);
      check_value(co.sy_q, v    , ERROR, "sync2dff: unchanged after 1 edge", C_TB_SCOPE);
      wait until falling_edge(clk);
      wait for 1 ns;
      check_value(co.sy_q, v    , ERROR, "sync2dff: unchanged after the falling edge", C_TB_SCOPE);
      wait_edges(1, clk);
      check_value(co.sy_q, not v, ERROR, "sync2dff: new value after 2 edges", C_TB_SCOPE);
    end loop;

    log(ID_SEQUENCER, "sync2dff : 1-cycle pulse", C_TB_SCOPE);
    wait until falling_edge(clk);
    ci.sy_d <= '1';
    wait until falling_edge(clk);
    ci.sy_d <= '0';
    wait_edges(1, clk);
    check_value(co.sy_q, '1', ERROR, "sync2dff: 1-cycle pulse, 2 edges later", C_TB_SCOPE);
    wait_edges(1, clk);
    check_value(co.sy_q, '0', ERROR, "sync2dff: 1-cycle pulse lasts 1 cycle", C_TB_SCOPE);
  end procedure;

end package body tb_techmap_sync2dff_pkg;
