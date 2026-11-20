-------------------------------------------------------------------------------
-- Title      : tb_techmap_obuf_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_techmap_obuf_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario obuf of tb_techmap : pad of the NB_OBUF instances
--              (every generic combination) for every oe_i / d_i value, 'Z'
--              when the output is disabled
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

package tb_techmap_obuf_pkg is

  -- Every generic combination, every oe_i / d_i value
  procedure run
    (signal   ci       : out   tb_in_t
    ;signal   co       : in    tb_out_t
    );

end package tb_techmap_obuf_pkg;

package body tb_techmap_obuf_pkg is

  procedure run
    (signal   ci       : out   tb_in_t
    ;signal   co       : in    tb_out_t
    ) is
    variable v_exp     : std_logic;
  begin
    log(ID_SEQUENCER, "obuf : every generic combination", C_TB_SCOPE);
    for oe in std_logic range '0' to '1' loop
      for d in std_logic range '0' to '1' loop
        ci.ob_oe  <= oe;
        ci.ob_d_i <= d;
        wait for 1 ns;
        for i in 0 to NB_OBUF-1 loop
          if (oe xor bit_of(i,1)) = '1'
          then
            v_exp := d xor bit_of(i,0);
          else
            v_exp := 'Z';
          end if;
          check_value(co.ob_pad(i), v_exp, MATCH_EXACT, ERROR,
                      "obuf(INVERT_D_I=" & to_string(bit_of(i,0)) & ",INVERT_OE_I=" & to_string(bit_of(i,1)) &
                      ") oe_i=" & to_string(oe) & " d_i=" & to_string(d) & " : pad", C_TB_SCOPE);
        end loop;
      end loop;
    end loop;
  end procedure;

end package body tb_techmap_obuf_pkg;
