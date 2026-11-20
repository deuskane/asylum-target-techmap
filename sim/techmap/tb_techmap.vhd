-------------------------------------------------------------------------------
-- Title      : tb_techmap
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_techmap.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Self-checking UVVM testbench of the generic technology cells
--              TESTS_LIST : scenarios run in sequence, separated by ','
--                           (tb_techmap_tests_pkg, one scenario per cell),
--                           each one after a reset pulse ; "" : build and
--                           elaboration only
--              DUTs : every cell of techmap_pkg ; the I/O buffers once per
--              combination of their generics (tb_techmap_bfm_pkg)
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-05  1.0      mrosiere Created
-- 2026-11-20  1.1      mrosiere TESTS_LIST, one package per scenario
--                               (tb_techmap_<name>_pkg), helpers in
--                               tb_techmap_bfm_pkg, reset pulse before each
--                               scenario
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.techmap_pkg.all;
use     asylum.string_pkg.all;

library work;
use     work.tb_techmap_bfm_pkg.all;
use     work.tb_techmap_tests_pkg.all;

entity tb_techmap is
  generic (
    TESTS_LIST : string := ""  -- Scenarios, e.g. "cgate,iobuf"
  );
end entity tb_techmap;

architecture sim of tb_techmap is

  constant C_SCOPE  : string := "TB_TECHMAP";

  signal   clk      : std_logic := '0';
  signal   clk_ena  : boolean   := true;
  signal   arst_b   : std_logic := '0';

  signal   ci       : tb_in_t   := C_IN_IDLE;
  signal   co       : tb_out_t;

begin

  clock_generator(clk, clk_ena, C_PERIOD, "TB Clock");

  -----------------------------------------------------------------------------
  -- DUTs
  -----------------------------------------------------------------------------
  dut_cbufg : cbufg
    port map
    (d_i      => ci.cb_d_i
    ,d_o      => co.cb_d_o
    );

  dut_cbufg_clk : cbufg
    port map
    (d_i      => clk
    ,d_o      => co.cb_clk_o
    );

  dut_cgate : cgate
    port map
    (clk_i    => clk
    ,cke_i    => ci.cg_cke
    ,clk_o    => co.cg_clk_o
    ,dft_te_i => ci.cg_te
    );

  dut_sync2dff : sync2dff
    port map
    (clk_i    => clk
    ,d_i      => ci.sy_d
    ,q_o      => co.sy_q
    );

  dut_sync2dffrn : sync2dffrn
    port map
    (clk_i    => clk
    ,arst_b_i => arst_b
    ,d_i      => ci.syr_d
    ,q_o      => co.syr_q
    );

  -- Pads : testbench driver and I/O buffer, resolved
  co.ib_pad  <= ci.ib_pad_drv;
  co.iob_pad <= ci.iob_pad_drv;

  gen_ibuf : for i in 0 to NB_IBUF-1
  generate
    dut_ibuf : ibuf
      generic map
      (INPUT_VALUE_DISABLED => bit_of(i,0)
      ,INVERT_D_O           => bit_of(i,1)
      ,INVERT_IE_I          => bit_of(i,2)
      )
      port map
      (buf_io               => co.ib_pad(i)
      ,d_o                  => co.ib_d_o(i)
      ,ie_i                 => ci.ib_ie
      );
  end generate gen_ibuf;

  gen_obuf : for i in 0 to NB_OBUF-1
  generate
    dut_obuf : obuf
      generic map
      (INVERT_D_I           => bit_of(i,0)
      ,INVERT_OE_I          => bit_of(i,1)
      )
      port map
      (buf_io               => co.ob_pad(i)
      ,d_i                  => ci.ob_d_i
      ,oe_i                 => ci.ob_oe
      );
  end generate gen_obuf;

  gen_iobuf : for i in 0 to NB_IOBUF-1
  generate
    dut_iobuf : iobuf
      generic map
      (INPUT_VALUE_DISABLED => bit_of(i,0)
      ,INVERT_D_O           => bit_of(i,1)
      ,INVERT_IE_I          => bit_of(i,2)
      ,INVERT_D_I           => bit_of(i,3)
      ,INVERT_OE_I          => bit_of(i,4)
      )
      port map
      (buf_io               => co.iob_pad(i)
      ,d_i                  => ci.iob_d_i
      ,d_o                  => co.iob_d_o(i)
      ,oe_i                 => ci.iob_oe
      ,ie_i                 => ci.iob_ie
      );
  end generate gen_iobuf;

  -----------------------------------------------------------------------------
  -- cgate monitor : every pulse on clk_o starts on a rising edge of clk_i and
  -- lasts a full high phase (no glitch, no truncated pulse) ; the pulses are
  -- counted for the cgate scenario
  -----------------------------------------------------------------------------
  p_cgate_mon : process
    variable v_rise : time;
  begin
    co.cg_pulses <= 0;
    loop
      wait until rising_edge(co.cg_clk_o);
      v_rise := now;
      check_value(clk, '1', ERROR, "cgate: clk_o rises while clk_i is high", C_SCOPE, ID_NEVER);
      check_value(clk'last_event, 0 ns, ERROR, "cgate: clk_o rises on a rising edge of clk_i", C_SCOPE, ID_NEVER);
      wait until falling_edge(co.cg_clk_o);
      check_value(now - v_rise, C_PERIOD/2, ERROR, "cgate: clk_o high pulse lasts a full half period", C_SCOPE, ID_NEVER);
      check_value(clk, '0', ERROR, "cgate: clk_o falls with clk_i", C_SCOPE, ID_NEVER);
      co.cg_pulses <= co.cg_pulses + 1;
    end loop;
  end process p_cgate_mon;

  -----------------------------------------------------------------------------
  -- Sequencer
  -----------------------------------------------------------------------------
  p_sequencer : process
  begin
    log(ID_LOG_HDR, "Technology cells (generic implementation), TESTS_LIST : " & TESTS_LIST, C_SCOPE);

    -- Every name is checked before the first scenario
    for i in 1 to list_length(TESTS_LIST) loop
      if not list_contains(C_TESTS, list_item(TESTS_LIST, i))
      then
        alert(TB_ERROR, "Unknown test """ & list_item(TESTS_LIST, i) & """ (tests : " & C_TESTS & ")", C_SCOPE);
      end if;
    end loop;

    for i in 1 to list_length(TESTS_LIST) loop
      -- Reset pulse, inputs idle : each scenario starts from reset
      ci <= C_IN_IDLE;
      do_reset(clk, arst_b);
      log(ID_LOG_HDR, "TEST " & integer'image(i) & "/" & integer'image(list_length(TESTS_LIST)) & " : " & list_item(TESTS_LIST, i), C_SCOPE);
      run_test(list_item(TESTS_LIST, i), clk, arst_b, ci, co);
    end loop;

    clk_ena <= false;
    wait for C_PERIOD;
    report_alert_counters(FINAL);
    std.env.stop;
    wait;
  end process p_sequencer;

end architecture sim;
