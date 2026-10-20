-------------------------------------------------------------------------------
-- Title      : techmap_synth_top
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : techmap_synth_top.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description:
-- Synthesis check top (lint_ghdl, lint_ghdl_synth) : one instance of each
-- generic cell of techmap_pkg (cbufg, cgate, sync2dff, sync2dffrn, ibuf, obuf,
-- iobuf), every port of every cell on a top-level port (tb_dummy ties the
-- inputs to '0' and leaves the outputs open : nothing would be synthesized).
-- The generics of the I/O buffers are forwarded (shared by ibuf, obuf, iobuf).
-- cgate latches its clock enable by design : WITH_CGATE = false removes it
-- (cgate_clk_o tied to '0') for the synthesis checks without latch.
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-20  1.0      mrosiere Created
-------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
library asylum;
use     asylum.techmap_pkg.all;

entity techmap_synth_top is
  generic
  (WITH_CGATE           : boolean   := true -- false : no cgate instance
  ;INPUT_VALUE_DISABLED : std_logic := '0' -- ibuf, iobuf
  ;INVERT_D_I           : std_logic := '0' -- obuf, iobuf
  ;INVERT_D_O           : std_logic := '0' -- ibuf, iobuf
  ;INVERT_OE_I          : std_logic := '0' -- obuf, iobuf
  ;INVERT_IE_I          : std_logic := '0' -- ibuf, iobuf
  );
  port
  (clk_i                : in    std_logic
  ;arst_b_i             : in    std_logic
  -- cbufg
  ;cbufg_d_i            : in    std_logic
  ;cbufg_d_o            : out   std_logic
  -- cgate
  ;cgate_cke_i          : in    std_logic
  ;cgate_dft_te_i       : in    std_logic
  ;cgate_clk_o          : out   std_logic
  -- sync2dff
  ;sync2dff_d_i         : in    std_logic
  ;sync2dff_q_o         : out   std_logic
  -- sync2dffrn
  ;sync2dffrn_d_i       : in    std_logic
  ;sync2dffrn_q_o       : out   std_logic
  -- ibuf
  ;ibuf_buf_io          : inout std_logic
  ;ibuf_d_o             : out   std_logic
  ;ibuf_ie_i            : in    std_logic
  -- obuf
  ;obuf_buf_io          : inout std_logic
  ;obuf_d_i             : in    std_logic
  ;obuf_oe_i            : in    std_logic
  -- iobuf
  ;iobuf_buf_io         : inout std_logic
  ;iobuf_d_i            : in    std_logic
  ;iobuf_d_o            : out   std_logic
  ;iobuf_oe_i           : in    std_logic
  ;iobuf_ie_i           : in    std_logic
  );
end techmap_synth_top;

architecture rtl of techmap_synth_top is
begin

  ins_cbufg : cbufg
  port map
  (d_i      => cbufg_d_i
  ,d_o      => cbufg_d_o
  );

  gen_cgate : if WITH_CGATE = true
  generate
    ins_cgate : cgate
    port map
    (clk_i    => clk_i
    ,cke_i    => cgate_cke_i
    ,dft_te_i => cgate_dft_te_i
    ,clk_o    => cgate_clk_o
    );
  end generate;

  gen_cgate_b : if WITH_CGATE = false
  generate
    cgate_clk_o <= '0';
  end generate;

  ins_sync2dff : sync2dff
  port map
  (clk_i    => clk_i
  ,d_i      => sync2dff_d_i
  ,q_o      => sync2dff_q_o
  );

  ins_sync2dffrn : sync2dffrn
  port map
  (clk_i    => clk_i
  ,arst_b_i => arst_b_i
  ,d_i      => sync2dffrn_d_i
  ,q_o      => sync2dffrn_q_o
  );

  ins_ibuf : ibuf
  generic map
  (INPUT_VALUE_DISABLED => INPUT_VALUE_DISABLED
  ,INVERT_D_O           => INVERT_D_O
  ,INVERT_IE_I          => INVERT_IE_I
  )
  port map
  (buf_io   => ibuf_buf_io
  ,d_o      => ibuf_d_o
  ,ie_i     => ibuf_ie_i
  );

  ins_obuf : obuf
  generic map
  (INVERT_D_I           => INVERT_D_I
  ,INVERT_OE_I          => INVERT_OE_I
  )
  port map
  (buf_io   => obuf_buf_io
  ,d_i      => obuf_d_i
  ,oe_i     => obuf_oe_i
  );

  ins_iobuf : iobuf
  generic map
  (INPUT_VALUE_DISABLED => INPUT_VALUE_DISABLED
  ,INVERT_D_I           => INVERT_D_I
  ,INVERT_D_O           => INVERT_D_O
  ,INVERT_OE_I          => INVERT_OE_I
  ,INVERT_IE_I          => INVERT_IE_I
  )
  port map
  (buf_io   => iobuf_buf_io
  ,d_i      => iobuf_d_i
  ,d_o      => iobuf_d_o
  ,oe_i     => iobuf_oe_i
  ,ie_i     => iobuf_ie_i
  );

end rtl;
