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


architecture Behavioral of project_reti_logiche is
-- Indica gli stati della FSM 
    type state is (RESET, DIMENSIONS, GET_PIXELS );
    
    -- Stato corrente e prossimo FSM
    signal state_current, state_next: state;
    -- Indirizzo corrente I/O
    signal address: std_logic_vector(15 downto 0);
    -- Delta corrente
    signal delta: std_logic_vector(7 downto 0);
    -- Shift_value corrente
    signal shift_value: std_logic_vector(2 downto 0);
    -- Temp_pixel value corrente. Il pixel può essere shiftato al più di 8, quindi vettore di 16 bit
    signal temp_pixel_value: std_logic_vector(15 downto 0);
    -- Variabili: EQUALIZZATA, MAX, MIN e OLD dei pixel
    signal new_pixel_value, max_pixel_value, min_pixel_value, current_pixel_value: std_logic_vector(7 downto 0);
    
    -- Contatore per lettura di ogni pixel
    signal counter: integer range 0 to 16383;
    signal num_pixels: integer range 0 to 16383;
    
    -- Dimensioni immagine
    signal row, column: integer range 0 to 127 := 0;
    
    -- Segnali di check
    signal get_row, get_column, get_pixel: boolean := false;
    
    
    
    
begin
    process (i_clk) 
    begin
      if(i_clk'event and i_clk = '1') then
        if (i_rst = '1') then
            state_current <= RESET;
        else
            state_current <= state_next;
        end if;
        
        case state_current is
            when RESET =>   delta <= "00000000";
                            address <= "0000000000000000";
                            shift_value <= "00000000";
                            temp_pixel_value <= "00000000";
                            counter <= 1;
                            num_pixels <= 0;
                            
                            o_en <= '0';
                            o_we <= '0';
                            o_data <= "00000000";
                            o_done <= '0';
                            -----------------------------
                            state_next <= DIMENSIONS;
                            
            when DIMENSIONS =>   o_en <= '1';
                                 o_we <= '0';
            
                           if (not get_column) then
                                   address <= "0000000000000000";
                                   column <= conv_integer(i_data);
                                   get_column <= false;
                                   state_next <= DIMENSIONS;
                                   
                               elsif (not get_row) then
                                   address <= "0000000000000001";
                                   row <= conv_integer(i_data);
                                   get_row <= false;
                                   state_next <= GET_PIXELS;
                                   address <= address + "000000000000000001";
                                   num_pixels <= column * row;
                                   
                               end if;                 
            
            when GET_PIXELS =>    o_en <= '1';
                                  o_we <= '0';
                                  
                                  if (not get_pixel) then
                                    current_pixel_value <= i_data;
                                    counter <= counter + 1;
                                    address <= address + "000000000000000001";
                                    state_next <= GET_PIXELS;
                                    
                                        if (counter > num_pixels) then
                                            get_pixel <= true;  
                                            state_next <= CALCULATE;
                                    
                                                
                            
                            
                            
                            
                            
                            
                            
                            
        end case;
     end if;
end process;

end Behavioral;
