-------------------------------------------------------------------------------
-- Title      : tb_techmap_tests_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_techmap_tests_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenarios of tb_techmap : names (valid items of TESTS_LIST)
--              and dispatch (run_test) to the package of each scenario
--              (tb_techmap_<name>_pkg), one scenario per cell
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

library asylum;
use     asylum.string_pkg.all;

library work;
use     work.tb_techmap_bfm_pkg.all;

package tb_techmap_tests_pkg is

  -- Names of the scenarios (valid items of TESTS_LIST)
  constant C_TESTS : string := "cbufg,cgate,sync2dff,sync2dffrn,ibuf,obuf,iobuf";

  -- Run the scenario name
  procedure run_test
    (constant name     : in    string
    ;signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic
    ;signal   ci       : out   tb_in_t
    ;signal   co       : in    tb_out_t
    );

end package tb_techmap_tests_pkg;

package body tb_techmap_tests_pkg is

  procedure run_test
    (constant name     : in    string
    ;signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic
    ;signal   ci       : out   tb_in_t
    ;signal   co       : in    tb_out_t
    ) is
  begin
    if    string_eq(name, "cbufg")
    then
      work.tb_techmap_cbufg_pkg.run(clk, ci, co);
    elsif string_eq(name, "cgate")
    then
      work.tb_techmap_cgate_pkg.run(clk, ci, co);
    elsif string_eq(name, "sync2dff")
    then
      work.tb_techmap_sync2dff_pkg.run(clk, ci, co);
    elsif string_eq(name, "sync2dffrn")
    then
      work.tb_techmap_sync2dffrn_pkg.run(clk, arst_b, ci, co);
    elsif string_eq(name, "ibuf")
    then
      work.tb_techmap_ibuf_pkg.run(ci, co);
    elsif string_eq(name, "obuf")
    then
      work.tb_techmap_obuf_pkg.run(ci, co);
    elsif string_eq(name, "iobuf")
    then
      work.tb_techmap_iobuf_pkg.run(ci, co);
    else
      alert(TB_ERROR, "Unknown test " & name, C_TB_SCOPE);
    end if;
  end procedure;

end package body tb_techmap_tests_pkg;
