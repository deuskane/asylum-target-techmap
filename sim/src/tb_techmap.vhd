-------------------------------------------------------------------------------
-- Title      : tb_techmap
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_techmap.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Self-checking UVVM testbench of the generic technology cells
--              * cbufg      : pass-through (static values and clock)
--              * cgate      : clock gating with enable latch, dft_te_i, only
--                             full clock pulses on clk_o (glitch-free)
--              * sync2dff   : 2-cycle latency
--              * sync2dffrn : 2-cycle latency, asynchronous reset
--              * ibuf / obuf / iobuf : every combination of the INVERT_* and
--                INPUT_VALUE_DISABLED generics, oe / ie behaviour, 'Z' on the
--                pad when the output is disabled, iobuf loopback
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-05  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.techmap_pkg.all;

entity tb_techmap is
end entity tb_techmap;

architecture sim of tb_techmap is

  constant C_SCOPE  : string := "TB_TECHMAP";
  constant C_PERIOD : time   := 20 ns;

  -- Generic values of the I/O buffer instances : instance i uses bit k of i
  function bit_of(i : natural; k : natural) return std_logic is
  begin
    if (i / 2**k) mod 2 = 1 then
      return '1';
    else
      return '0';
    end if;
  end function;

  -- ibuf  : bit 0 INPUT_VALUE_DISABLED, bit 1 INVERT_D_O, bit 2 INVERT_IE_I
  -- obuf  : bit 0 INVERT_D_I,           bit 1 INVERT_OE_I
  -- iobuf : bit 0 INPUT_VALUE_DISABLED, bit 1 INVERT_D_O, bit 2 INVERT_IE_I,
  --         bit 3 INVERT_D_I,           bit 4 INVERT_OE_I
  constant NB_IBUF  : natural := 8;
  constant NB_OBUF  : natural := 4;
  constant NB_IOBUF : natural := 32;

  -- Clock
  signal clk          : std_logic := '0';
  signal clk_ena      : boolean   := true;

  -- cbufg
  signal cb_d_i       : std_logic := '0';
  signal cb_d_o       : std_logic;
  signal cb_clk_o     : std_logic;

  -- cgate
  signal cg_cke       : std_logic := '0';
  signal cg_te        : std_logic := '0';
  signal cg_clk_o     : std_logic;
  signal cg_pulses    : natural   := 0;

  -- sync2dff / sync2dffrn
  signal sy_d         : std_logic := '0';
  signal sy_q         : std_logic;
  signal syr_d        : std_logic := '0';
  signal syr_arst_b   : std_logic := '0';
  signal syr_q        : std_logic;

  -- I/O buffers : pads (resolved) and the testbench driver on each pad
  signal ib_pad       : std_logic_vector(0 to NB_IBUF -1);
  signal ib_pad_drv   : std_logic_vector(0 to NB_IBUF -1) := (others => 'Z');
  signal ib_d_o       : std_logic_vector(0 to NB_IBUF -1);
  signal ib_ie        : std_logic := '0';

  signal ob_pad       : std_logic_vector(0 to NB_OBUF -1);
  signal ob_d_i       : std_logic := '0';
  signal ob_oe        : std_logic := '0';

  signal iob_pad      : std_logic_vector(0 to NB_IOBUF-1);
  signal iob_pad_drv  : std_logic_vector(0 to NB_IOBUF-1) := (others => 'Z');
  signal iob_d_o      : std_logic_vector(0 to NB_IOBUF-1);
  signal iob_d_i      : std_logic := '0';
  signal iob_oe       : std_logic := '0';
  signal iob_ie       : std_logic := '0';

begin

  clock_generator(clk, clk_ena, C_PERIOD, "TB Clock");

  -----------------------------------------------------------------------------
  -- DUTs
  -----------------------------------------------------------------------------
  ins_cbufg : cbufg
    port map (
      d_i      => cb_d_i,
      d_o      => cb_d_o
      );

  ins_cbufg_clk : cbufg
    port map (
      d_i      => clk,
      d_o      => cb_clk_o
      );

  ins_cgate : cgate
    port map (
      clk_i    => clk,
      cke_i    => cg_cke,
      clk_o    => cg_clk_o,
      dft_te_i => cg_te
      );

  ins_sync2dff : sync2dff
    port map (
      clk_i    => clk,
      d_i      => sy_d,
      q_o      => sy_q
      );

  ins_sync2dffrn : sync2dffrn
    port map (
      clk_i    => clk,
      arst_b_i => syr_arst_b,
      d_i      => syr_d,
      q_o      => syr_q
      );

  ib_pad  <= ib_pad_drv;
  iob_pad <= iob_pad_drv;
  ob_pad  <= (others => 'Z');

  gen_ibuf : for i in 0 to NB_IBUF-1 generate
    ins_ibuf : ibuf
      generic map (
        INPUT_VALUE_DISABLED => bit_of(i,0),
        INVERT_D_O           => bit_of(i,1),
        INVERT_IE_I          => bit_of(i,2)
        )
      port map (
        buf_io => ib_pad(i),
        d_o    => ib_d_o(i),
        ie_i   => ib_ie
        );
  end generate gen_ibuf;

  gen_obuf : for i in 0 to NB_OBUF-1 generate
    ins_obuf : obuf
      generic map (
        INVERT_D_I           => bit_of(i,0),
        INVERT_OE_I          => bit_of(i,1)
        )
      port map (
        buf_io => ob_pad(i),
        d_i    => ob_d_i,
        oe_i   => ob_oe
        );
  end generate gen_obuf;

  gen_iobuf : for i in 0 to NB_IOBUF-1 generate
    ins_iobuf : iobuf
      generic map (
        INPUT_VALUE_DISABLED => bit_of(i,0),
        INVERT_D_O           => bit_of(i,1),
        INVERT_IE_I          => bit_of(i,2),
        INVERT_D_I           => bit_of(i,3),
        INVERT_OE_I          => bit_of(i,4)
        )
      port map (
        buf_io => iob_pad(i),
        d_i    => iob_d_i,
        d_o    => iob_d_o(i),
        oe_i   => iob_oe,
        ie_i   => iob_ie
        );
  end generate gen_iobuf;

  -----------------------------------------------------------------------------
  -- cgate monitor : every pulse on clk_o starts on a rising edge of clk_i and
  -- lasts a full high phase (no glitch, no truncated pulse)
  -----------------------------------------------------------------------------
  p_cgate_mon : process
    variable v_rise : time;
  begin
    wait until rising_edge(cg_clk_o);
    v_rise := now;
    check_value(clk, '1', ERROR, "cgate: clk_o rises while clk_i is high", C_SCOPE, ID_NEVER);
    check_value(clk'last_event, 0 ns, ERROR, "cgate: clk_o rises on a rising edge of clk_i", C_SCOPE, ID_NEVER);
    wait until falling_edge(cg_clk_o);
    check_value(now - v_rise, C_PERIOD/2, ERROR, "cgate: clk_o high pulse lasts a full half period", C_SCOPE, ID_NEVER);
    check_value(clk, '0', ERROR, "cgate: clk_o falls with clk_i", C_SCOPE, ID_NEVER);
    cg_pulses <= cg_pulses + 1;
  end process p_cgate_mon;

  -----------------------------------------------------------------------------
  -- Sequencer
  -----------------------------------------------------------------------------
  p_main : process

    -- Wait for the n-th next rising edge then 1 ns (registers settled)
    procedure wait_edges(constant n : in positive) is
    begin
      for k in 1 to n loop
        wait until rising_edge(clk);
      end loop;
      wait for 1 ns;
    end procedure;

    -- Count the clk_o pulses during n clock periods (starts on a falling edge)
    procedure check_pulses(constant n : in natural; constant exp : in natural; constant msg : in string) is
      variable v_start : natural;
    begin
      wait until falling_edge(clk);
      wait for 1 ns;                   -- pulse ending on this edge not counted
      v_start := cg_pulses;
      for k in 1 to n loop
        wait until falling_edge(clk);
      end loop;
      wait for 1 ns;
      check_value(cg_pulses - v_start, exp, ERROR, msg, C_SCOPE);
    end procedure;

    variable v_exp     : std_logic;
    variable v_d_eff   : std_logic;
    variable v_oe_eff  : std_logic;
    variable v_ie_eff  : std_logic;
    variable v_ext     : std_logic;
    variable v_drv     : std_logic_vector(0 to NB_IOBUF-1);

  begin
    log(ID_LOG_HDR, "START: technology cells (generic implementation)", C_SCOPE);

    ---------------------------------------------------------------------------
    log(ID_LOG_HDR, "cbufg : pass-through", C_SCOPE);
    ---------------------------------------------------------------------------
    for v in std_logic range '0' to '1' loop
      cb_d_i <= v;
      wait for 1 ns;
      check_value(cb_d_o, v, ERROR, "cbufg: d_o = d_i", C_SCOPE);
    end loop;
    wait until rising_edge(clk);
    wait for 1 ns;
    check_value(cb_clk_o, '1', ERROR, "cbufg: clock high", C_SCOPE);
    wait until falling_edge(clk);
    wait for 1 ns;
    check_value(cb_clk_o, '0', ERROR, "cbufg: clock low", C_SCOPE);
    wait until rising_edge(cb_clk_o);
    check_value(clk'last_event, 0 ns, ERROR, "cbufg: clock edge not delayed", C_SCOPE);

    ---------------------------------------------------------------------------
    log(ID_LOG_HDR, "cgate : clock gating", C_SCOPE);
    ---------------------------------------------------------------------------
    cg_cke <= '0';
    cg_te  <= '0';
    check_pulses(4, 0, "cgate: cke_i = 0, clock gated");
    check_value(cg_clk_o, '0', ERROR, "cgate: gated clock is low", C_SCOPE);

    cg_cke <= '1';
    check_pulses(4, 4, "cgate: cke_i = 1, clock running");

    -- Disable in the middle of the high phase : the current pulse completes
    wait until rising_edge(clk);
    wait for C_PERIOD/8;
    check_value(cg_clk_o, '1', ERROR, "cgate: pulse in progress", C_SCOPE);
    cg_cke <= '0';
    wait for C_PERIOD/8;
    check_value(cg_clk_o, '1', ERROR, "cgate: cke_i falling while clk_i high does not cut the pulse", C_SCOPE);
    check_pulses(3, 0, "cgate: no pulse after cke_i falling");

    -- Enable in the middle of the high phase : no partial pulse
    wait until rising_edge(clk);
    wait for C_PERIOD/8;
    cg_cke <= '1';
    wait for C_PERIOD/8;
    check_value(cg_clk_o, '0', ERROR, "cgate: cke_i rising while clk_i high does not start a partial pulse", C_SCOPE);
    wait until falling_edge(clk);
    wait for 1 ns;
    check_value(cg_clk_o, '0', ERROR, "cgate: still low until the next rising edge", C_SCOPE);
    wait until rising_edge(clk);
    wait for 1 ns;
    check_value(cg_clk_o, '1', ERROR, "cgate: first pulse on the next rising edge", C_SCOPE);

    -- Short enable glitch during the high phase is filtered by the latch
    cg_cke <= '0';
    wait until falling_edge(clk);
    wait until rising_edge(clk);
    wait for C_PERIOD/8;
    cg_cke <= '1';
    wait for 1 ns;
    cg_cke <= '0';
    check_pulses(2, 0, "cgate: cke_i glitch while clk_i high is filtered");

    -- Enable changing while clk_i is low : taken at the next rising edge
    wait until falling_edge(clk);
    wait for C_PERIOD/8;
    cg_cke <= '1';
    wait until rising_edge(clk);
    wait for 1 ns;
    check_value(cg_clk_o, '1', ERROR, "cgate: cke_i set during the low phase enables the next pulse", C_SCOPE);
    wait until falling_edge(clk);
    wait for C_PERIOD/8;
    cg_cke <= '0';
    wait until rising_edge(clk);
    wait for 1 ns;
    check_value(cg_clk_o, '0', ERROR, "cgate: cke_i cleared during the low phase gates the next pulse", C_SCOPE);

    -- Test enable forces the clock
    cg_cke <= '0';
    cg_te  <= '1';
    check_pulses(4, 4, "cgate: dft_te_i = 1 forces the clock");
    cg_te  <= '0';
    check_pulses(4, 0, "cgate: dft_te_i = 0, cke_i = 0 gates the clock");

    ---------------------------------------------------------------------------
    log(ID_LOG_HDR, "sync2dff : 2-cycle latency", C_SCOPE);
    ---------------------------------------------------------------------------
    wait until falling_edge(clk);
    sy_d <= '0';
    wait_edges(3);
    check_value(sy_q, '0', ERROR, "sync2dff: initialised to 0", C_SCOPE);
    for v in std_logic range '0' to '1' loop
      wait until falling_edge(clk);
      sy_d <= not v;
      wait_edges(1);
      check_value(sy_q, v    , ERROR, "sync2dff: unchanged after 1 edge", C_SCOPE);
      wait_edges(1);
      check_value(sy_q, not v, ERROR, "sync2dff: new value after 2 edges", C_SCOPE);
    end loop;
    -- One cycle pulse
    wait until falling_edge(clk);
    sy_d <= '1';
    wait until falling_edge(clk);
    sy_d <= '0';
    wait_edges(1);
    check_value(sy_q, '1', ERROR, "sync2dff: 1-cycle pulse, 2 edges later", C_SCOPE);
    wait_edges(1);
    check_value(sy_q, '0', ERROR, "sync2dff: 1-cycle pulse lasts 1 cycle", C_SCOPE);

    ---------------------------------------------------------------------------
    log(ID_LOG_HDR, "sync2dffrn : 2-cycle latency, asynchronous reset", C_SCOPE);
    ---------------------------------------------------------------------------
    syr_arst_b <= '0';
    syr_d      <= '1';
    wait_edges(3);
    check_value(syr_q, '0', ERROR, "sync2dffrn: held at 0 during reset", C_SCOPE);
    wait until falling_edge(clk);
    syr_arst_b <= '1';
    wait_edges(1);
    check_value(syr_q, '0', ERROR, "sync2dffrn: 0 after 1 edge", C_SCOPE);
    wait_edges(1);
    check_value(syr_q, '1', ERROR, "sync2dffrn: 1 after 2 edges", C_SCOPE);
    wait until falling_edge(clk);
    syr_d <= '0';
    wait_edges(1);
    check_value(syr_q, '1', ERROR, "sync2dffrn: unchanged after 1 edge", C_SCOPE);
    wait_edges(1);
    check_value(syr_q, '0', ERROR, "sync2dffrn: new value after 2 edges", C_SCOPE);
    -- Asynchronous reset between two edges
    wait until falling_edge(clk);
    syr_d <= '1';
    wait_edges(2);
    check_value(syr_q, '1', ERROR, "sync2dffrn: 1 before reset", C_SCOPE);
    wait for C_PERIOD/4;
    syr_arst_b <= '0';
    wait for 1 ns;
    check_value(syr_q, '0', ERROR, "sync2dffrn: asynchronous reset clears q_o without clock edge", C_SCOPE);
    wait until falling_edge(clk);
    syr_arst_b <= '1';
    wait_edges(1);
    check_value(syr_q, '0', ERROR, "sync2dffrn: whole chain cleared by the reset", C_SCOPE);
    wait_edges(1);
    check_value(syr_q, '1', ERROR, "sync2dffrn: 2 edges after reset release", C_SCOPE);

    ---------------------------------------------------------------------------
    log(ID_LOG_HDR, "ibuf : every generic combination", C_SCOPE);
    ---------------------------------------------------------------------------
    for ie in std_logic range '0' to '1' loop
      for pad in std_logic range '0' to '1' loop
        ib_ie      <= ie;
        ib_pad_drv <= (others => pad);
        wait for 1 ns;
        for i in 0 to NB_IBUF-1 loop
          v_ie_eff := ie xor bit_of(i,2);
          if v_ie_eff = '1' then
            v_exp := pad xor bit_of(i,1);
          else
            v_exp := bit_of(i,0);
          end if;
          check_value(ib_d_o(i), v_exp, ERROR,
                      "ibuf(INPUT_VALUE_DISABLED=" & to_string(bit_of(i,0)) & ",INVERT_D_O=" & to_string(bit_of(i,1)) & ",INVERT_IE_I=" & to_string(bit_of(i,2)) &
                      ") ie_i=" & to_string(ie) & " pad=" & to_string(pad) & " : d_o", C_SCOPE);
        end loop;
      end loop;
    end loop;
    -- The input buffer never drives the pad
    ib_pad_drv <= (others => 'Z');
    wait for 1 ns;
    for i in 0 to NB_IBUF-1 loop
      check_value(ib_pad(i), 'Z', MATCH_EXACT, ERROR, "ibuf " & integer'image(i) & " does not drive the pad", C_SCOPE);
    end loop;

    ---------------------------------------------------------------------------
    log(ID_LOG_HDR, "obuf : every generic combination", C_SCOPE);
    ---------------------------------------------------------------------------
    for oe in std_logic range '0' to '1' loop
      for d in std_logic range '0' to '1' loop
        ob_oe  <= oe;
        ob_d_i <= d;
        wait for 1 ns;
        for i in 0 to NB_OBUF-1 loop
          v_oe_eff := oe xor bit_of(i,1);
          if v_oe_eff = '1' then
            v_exp := d xor bit_of(i,0);
          else
            v_exp := 'Z';
          end if;
          check_value(ob_pad(i), v_exp, MATCH_EXACT, ERROR,
                      "obuf(INVERT_D_I=" & to_string(bit_of(i,0)) & ",INVERT_OE_I=" & to_string(bit_of(i,1)) &
                      ") oe_i=" & to_string(oe) & " d_i=" & to_string(d) & " : pad", C_SCOPE);
        end loop;
      end loop;
    end loop;

    ---------------------------------------------------------------------------
    log(ID_LOG_HDR, "iobuf : every generic combination", C_SCOPE);
    ---------------------------------------------------------------------------
    -- The testbench drives the pad with ext only when the iobuf output is
    -- disabled; when it is enabled, the pad carries d_i and d_o reads it back
    for oe in std_logic range '0' to '1' loop
      for ie in std_logic range '0' to '1' loop
        for d in std_logic range '0' to '1' loop
          for ext in std_logic range '0' to '1' loop
            for i in 0 to NB_IOBUF-1 loop
              if (oe xor bit_of(i,4)) = '1' then
                v_drv(i) := 'Z';
              else
                v_drv(i) := ext;
              end if;
            end loop;
            iob_oe      <= oe;
            iob_ie      <= ie;
            iob_d_i     <= d;
            iob_pad_drv <= v_drv;
            wait for 1 ns;
            for i in 0 to NB_IOBUF-1 loop
              v_oe_eff := oe xor bit_of(i,4);
              v_ie_eff := ie xor bit_of(i,2);
              v_d_eff  := d  xor bit_of(i,3);
              -- Pad
              if v_oe_eff = '1' then
                v_ext := v_d_eff;
              else
                v_ext := ext;
              end if;
              check_value(iob_pad(i), v_ext, MATCH_EXACT, ERROR,
                          "iobuf " & integer'image(i) & " oe_i=" & to_string(oe) & " ie_i=" & to_string(ie) & " d_i=" & to_string(d) & " ext=" & to_string(ext) & " : pad", C_SCOPE, ID_NEVER);
              -- Input path
              if v_ie_eff = '1' then
                v_exp := v_ext xor bit_of(i,1);
              else
                v_exp := bit_of(i,0);
              end if;
              check_value(iob_d_o(i), v_exp, ERROR,
                          "iobuf " & integer'image(i) & " oe_i=" & to_string(oe) & " ie_i=" & to_string(ie) & " d_i=" & to_string(d) & " ext=" & to_string(ext) & " : d_o", C_SCOPE, ID_NEVER);
            end loop;
          end loop;
        end loop;
      end loop;
    end loop;
    -- Output disabled : 'Z' on the pad when nobody else drives it
    iob_pad_drv <= (others => 'Z');
    for oe in std_logic range '0' to '1' loop
      iob_oe <= oe;
      wait for 1 ns;
      for i in 0 to NB_IOBUF-1 loop
        if (oe xor bit_of(i,4)) = '0' then
          check_value(iob_pad(i), 'Z', MATCH_EXACT, ERROR, "iobuf " & integer'image(i) & " oe_i=" & to_string(oe) & " : output disabled, pad is 'Z'", C_SCOPE, ID_NEVER);
        else
          check_value(iob_pad(i), iob_d_i xor bit_of(i,3), MATCH_EXACT, ERROR, "iobuf " & integer'image(i) & " oe_i=" & to_string(oe) & " : output enabled", C_SCOPE, ID_NEVER);
        end if;
      end loop;
    end loop;
    log(ID_SEQUENCER, "iobuf : " & integer'image(NB_IOBUF * (16*2 + 2)) & " checks done", C_SCOPE);
    log(ID_SEQUENCER, "cgate monitor : " & integer'image(cg_pulses) & " clk_o pulses checked (4 checks each)", C_SCOPE);

    ---------------------------------------------------------------------------
    clk_ena <= false;
    wait for C_PERIOD;
    report_alert_counters(FINAL);
    std.env.stop;
    wait;
  end process p_main;

end architecture sim;
