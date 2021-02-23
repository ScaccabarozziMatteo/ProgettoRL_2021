----------------------------------------------------------
-- Progetto di Reti Logiche
-- SCACCABAROZZI MATTEO - ALEXANDER TENEMAYA
--
-- A.A. 2020/2021
-- Prof. Palermo Gianluca
-- 
----------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
    port (
      i_clk : in std_logic;
      i_rst : in std_logic;
      i_start : in std_logic;
      i_data : in std_logic_vector(7 downto 0);
      o_address : out std_logic_vector(15 downto 0);
      o_done : out std_logic;
      o_en : out std_logic;
      o_we : out std_logic;
      o_data : out std_logic_vector (7 downto 0)
    );
end project_reti_logiche;
