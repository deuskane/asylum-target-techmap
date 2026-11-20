-------------------------------------------------------------------------------
-- Title      : tb_techmap_ibuf_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_techmap_ibuf_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario ibuf of tb_techmap : d_o of the NB_IBUF instances
--              (every generic combination) for every ie_i / pad value, the
--              input buffer never drives the pad
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

package tb_techmap_ibuf_pkg is

  -- Every generic combination, every ie_i / pad value ; pad never driven
  procedure run
    (signal   ci       : out   tb_in_t
    ;signal   co       : in    tb_out_t
    );

end package tb_techmap_ibuf_pkg;

package body tb_techmap_ibuf_pkg is

  procedure run
    (signal   ci       : out   tb_in_t
    ;signal   co       : in    tb_out_t
    ) is
    variable v_exp     : std_logic;
  begin
    log(ID_SEQUENCER, "ibuf : every generic combination", C_TB_SCOPE);
    for ie in std_logic range '0' to '1' loop
      for pad in std_logic range '0' to '1' loop
        ci.ib_ie      <= ie;
        ci.ib_pad_drv <= (others => pad);
        wait for 1 ns;
        for i in 0 to NB_IBUF-1 loop
          if (ie xor bit_of(i,2)) = '1'
          then
            v_exp := pad xor bit_of(i,1);
          else
            v_exp := bit_of(i,0);
          end if;
          check_value(co.ib_d_o(i), v_exp, ERROR,
                      "ibuf(INPUT_VALUE_DISABLED=" & to_string(bit_of(i,0)) & ",INVERT_D_O=" & to_string(bit_of(i,1)) & ",INVERT_IE_I=" & to_string(bit_of(i,2)) &
                      ") ie_i=" & to_string(ie) & " pad=" & to_string(pad) & " : d_o", C_TB_SCOPE);
        end loop;
      end loop;
    end loop;

    log(ID_SEQUENCER, "ibuf : the input buffer never drives the pad", C_TB_SCOPE);
    ci.ib_pad_drv <= (others => 'Z');
    for ie in std_logic range '0' to '1' loop
      ci.ib_ie <= ie;
      wait for 1 ns;
      for i in 0 to NB_IBUF-1 loop
        check_value(co.ib_pad(i), 'Z', MATCH_EXACT, ERROR, "ibuf " & integer'image(i) & " ie_i=" & to_string(ie) & " does not drive the pad", C_TB_SCOPE);
      end loop;
    end loop;
  end procedure;

end package body tb_techmap_ibuf_pkg;
