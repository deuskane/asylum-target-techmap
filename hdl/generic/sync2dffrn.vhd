-------------------------------------------------------------------------------
-- Title      : 2 FF synchronizer with asynchronous reset
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : sync2dffrn.vhd
-- Author     : Mathieu Rosière
-- Company    : 
-- Created    : 2025-01-06
-- Last update: 2025-08-11
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2025-01-06  1.0      mrosiere Created
-------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.numeric_std.ALL;

entity sync2dffrn is
  port   (
    clk_i    : in  std_logic; -- Input  Clock
    arst_b_i : in  std_logic; -- Input  Asychronous Reset active low
    d_i      : in  std_logic; -- Input  data
    q_o      : out std_logic  -- Output data
    );
end sync2dffrn;

architecture rtl of sync2dffrn is

  constant WIDTH : natural := 2;
  signal   q_r   : std_logic_vector(WIDTH-1 downto 0);  -- Synchronization chain

  -- Synthesis attributes of the synchronization chain: keep both flip-flops
  -- (no shift register extraction, no retiming, duplication or merging with
  -- other logic) and place them close together. The path to q_r(0) is
  -- asynchronous: declare it as a false path in the design constraints.
  --   ASYNC_REG     : Xilinx Vivado / ISE
  --   SHREG_EXTRACT : Xilinx Vivado / XST (no SRL inference)
  --   syn_preserve  : Synplify, NanoXplore NXmap (preserve registers)
  attribute ASYNC_REG     : string;
  attribute SHREG_EXTRACT : string;
  attribute syn_preserve  : boolean;
  attribute ASYNC_REG     of q_r : signal is "TRUE";
  attribute SHREG_EXTRACT of q_r : signal is "NO";
  attribute syn_preserve  of q_r : signal is true;
  
begin

  process (clk_i,arst_b_i) is
  begin  -- process
    if    arst_b_i = '0'
    then
      q_r <= (others => '0');
      
    elsif rising_edge(clk_i)
    then

      q_r <= q_r(WIDTH-2 downto 0)  & d_i;
      
    end if;
  end process;

  -- Output
  q_o <= q_r(WIDTH-1);
  
end rtl;
