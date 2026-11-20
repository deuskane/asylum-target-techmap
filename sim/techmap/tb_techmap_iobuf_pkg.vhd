-------------------------------------------------------------------------------
-- Title      : tb_techmap_iobuf_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_techmap_iobuf_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario iobuf of tb_techmap : pad and d_o of the NB_IOBUF
--              instances (every generic combination) for every oe_i / ie_i /
--              d_i / external pad value (loopback when the output is
--              enabled), 'Z' on the pad when the output is disabled, d_o
--              reads the pad when the testbench fights the cell
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

package tb_techmap_iobuf_pkg is

  -- Every generic combination, every oe_i / ie_i / d_i / external pad value
  procedure run
    (signal   ci       : out   tb_in_t
    ;signal   co       : in    tb_out_t
    );

end package tb_techmap_iobuf_pkg;

package body tb_techmap_iobuf_pkg is

  procedure run
    (signal   ci       : out   tb_in_t
    ;signal   co       : in    tb_out_t
    ) is
    variable v_exp     : std_logic;
    variable v_pad     : std_logic;
    variable v_drv     : std_logic_vector(0 to NB_IOBUF-1);
  begin
    log(ID_SEQUENCER, "iobuf : every generic combination", C_TB_SCOPE);
    -- The testbench drives the pad with ext only when the iobuf output is
    -- disabled; when it is enabled, the pad carries d_i and d_o reads it back
    for oe in std_logic range '0' to '1' loop
      for ie in std_logic range '0' to '1' loop
        for d in std_logic range '0' to '1' loop
          for ext in std_logic range '0' to '1' loop
            for i in 0 to NB_IOBUF-1 loop
              if (oe xor bit_of(i,4)) = '1'
              then
                v_drv(i) := 'Z';
              else
                v_drv(i) := ext;
              end if;
            end loop;
            ci.iob_oe      <= oe;
            ci.iob_ie      <= ie;
            ci.iob_d_i     <= d;
            ci.iob_pad_drv <= v_drv;
            wait for 1 ns;
            for i in 0 to NB_IOBUF-1 loop
              -- Pad
              if (oe xor bit_of(i,4)) = '1'
              then
                v_pad := d xor bit_of(i,3);
              else
                v_pad := ext;
              end if;
              check_value(co.iob_pad(i), v_pad, MATCH_EXACT, ERROR,
                          "iobuf " & integer'image(i) & " oe_i=" & to_string(oe) & " ie_i=" & to_string(ie) & " d_i=" & to_string(d) & " ext=" & to_string(ext) & " : pad", C_TB_SCOPE);
              -- Input path
              if (ie xor bit_of(i,2)) = '1'
              then
                v_exp := v_pad xor bit_of(i,1);
              else
                v_exp := bit_of(i,0);
              end if;
              check_value(co.iob_d_o(i), v_exp, ERROR,
                          "iobuf " & integer'image(i) & " oe_i=" & to_string(oe) & " ie_i=" & to_string(ie) & " d_i=" & to_string(d) & " ext=" & to_string(ext) & " : d_o", C_TB_SCOPE);
            end loop;
          end loop;
        end loop;
      end loop;
    end loop;

    log(ID_SEQUENCER, "iobuf : 'Z' on the pad when the output is disabled", C_TB_SCOPE);
    ci.iob_pad_drv <= (others => 'Z');
    for oe in std_logic range '0' to '1' loop
      ci.iob_oe <= oe;
      wait for 1 ns;
      for i in 0 to NB_IOBUF-1 loop
        if (oe xor bit_of(i,4)) = '0'
        then
          check_value(co.iob_pad(i), 'Z', MATCH_EXACT, ERROR, "iobuf " & integer'image(i) & " oe_i=" & to_string(oe) & " : output disabled, pad is 'Z'", C_TB_SCOPE);
        end if;
      end loop;
    end loop;

    log(ID_SEQUENCER, "iobuf : contention on the pad, d_o reads the pad (not d_i)", C_TB_SCOPE);
    ci.iob_oe      <= '1';
    ci.iob_ie      <= '1';
    ci.iob_d_i     <= '0';
    ci.iob_pad_drv <= (others => '1');
    wait for 1 ns;
    for i in 0 to NB_IOBUF-1 loop
      if (('1' xor bit_of(i,4)) = '1' and
          ('1' xor bit_of(i,2)) = '1' and
          bit_of(i,3)           = '0')
      then
        check_value(co.iob_pad(i), 'X', MATCH_EXACT, ERROR, "iobuf " & integer'image(i) & " : pad driven to 0 by the cell and to 1 outside", C_TB_SCOPE);
        check_value(co.iob_d_o(i), 'X', MATCH_EXACT, ERROR, "iobuf " & integer'image(i) & " : d_o reads the pad in contention", C_TB_SCOPE);
      end if;
    end loop;
  end procedure;

end package body tb_techmap_iobuf_pkg;
