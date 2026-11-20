-------------------------------------------------------------------------------
-- Title      : tb_techmap_cbufg_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_techmap_cbufg_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario cbufg of tb_techmap : d_o = d_i for '0' and '1', a
--              clock passes without delay
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

package tb_techmap_cbufg_pkg is

  -- d_o = d_i for '0' and '1', a clock passes without delay
  procedure run
    (signal   clk      : in    std_logic
    ;signal   ci       : out   tb_in_t
    ;signal   co       : in    tb_out_t
    );

end package tb_techmap_cbufg_pkg;

package body tb_techmap_cbufg_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   ci       : out   tb_in_t
    ;signal   co       : in    tb_out_t
    ) is
  begin
    log(ID_SEQUENCER, "cbufg : pass-through", C_TB_SCOPE);
    for v in std_logic range '0' to '1' loop
      ci.cb_d_i <= v;
      wait for 1 ns;
      check_value(co.cb_d_o, v, ERROR, "cbufg: d_o = d_i", C_TB_SCOPE);
    end loop;

    log(ID_SEQUENCER, "cbufg : clock", C_TB_SCOPE);
    wait until rising_edge(clk);
    wait for 1 ns;
    check_value(co.cb_clk_o, '1', ERROR, "cbufg: clock high", C_TB_SCOPE);
    wait until falling_edge(clk);
    wait for 1 ns;
    check_value(co.cb_clk_o, '0', ERROR, "cbufg: clock low", C_TB_SCOPE);
    wait until rising_edge(co.cb_clk_o);
    check_value(clk'last_event, 0 ns, ERROR, "cbufg: clock edge not delayed", C_TB_SCOPE);
  end procedure;

end package body tb_techmap_cbufg_pkg;
