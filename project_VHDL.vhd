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
-- use IEEE.MATH_REAL.ALL;
-- use IEEE.STD_LOGIC_ARITH.ALL;


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
    type state is (START, RESET, GET_COLUMN, GET_ROW, NUM_PIXELS1, GET_PIXELS, MAX_MIN, DELTA1, SHIFT, EQUALIZATION1, EQUALIZATION2, EQUALIZATION3, EQUALIZATION4, WRITE_OUT, DONE);
    -- Definisci struttura array
    type Memory_Pixels is array (16385 downto 0) of std_logic_vector(7 downto 0);
    
    -- LOOKUP TABLE che rappresenta il log2 dal valore 1 al valore 256
    type array_log is array (0 to 255) of integer range 0 to 8;
    constant LUT_LOG  : array_log := (
                                      0           => 0, 
                                      1   to 2    => 1,
                                      3   to 6    => 2,
                                      7   to 14   => 3,
                                      15  to 30   => 4,
                                      31  to 62   => 5,
                                      63  to 126  => 6,
                                      127 to 254  => 7,
                                      255         => 8);                                                                        
    
    -- Stato corrente e prossimo FSM
    signal state_next: state := START;
    -- Array contenten indirizzo e valore del pixel corrente
    signal pixels_array: Memory_Pixels := (others => (others => '0'));
    -- Delta corrente
    signal delta: std_logic_vector(7 downto 0);
    -- Shift_value corrente
    signal shift_value: integer := 0;
    -- Variabili: EQUALIZZATA, MAX, MIN e OLD dei pixel
    signal new_pixel_value, max_pixel_value, min_pixel_value, current_pixel_value: std_logic_vector(7 downto 0);
    signal curr_min: unsigned(15 downto 0);
    
    -- Contatore per lettura di ogni pixel
    signal counter: integer range 0 to 16383;
    signal num_pixels: integer range 0 to 16383;
    signal address: integer range 0 to 16385;
    
    -- Dimensioni immagine
    signal row, column: integer range 0 to 127 := 0;
    
    -- Segnali di check
    signal all_pixel, min_settato: boolean := false;
    
    signal temp_pixel_value: integer;
    signal temporary: std_logic_vector(7 downto 0);
    
    
    
    
begin
       process (i_clk, i_rst, i_start)
         begin
          if rising_edge(i_clk) then
            if (i_rst = '1') then
                state_next <= START;
            end if;
            if (i_start = '1') then
                    o_en <= '1';
                   state_next <= RESET;
            end if;
    
           
          case state_next is
          
            when START => 
        
            when RESET =>   

                            counter <= 0;                            
                            o_en <= '1';
                            o_we <= '0';
                            o_done <= '0';
                            min_pixel_value <= "00000000";
                            max_pixel_value <= "00000000";
                            all_pixel <= false;
                            o_address <= "0000000000000000";                            

                            state_next <= GET_COLUMN;

                            
            when GET_COLUMN =>   o_en <= '1';
                                 o_we <= '0';
            
                                   pixels_array(0) <= i_data;
                                   column <= CONV_INTEGER(i_data);
                                   state_next <= GET_ROW;
                                   address <= 1;
                                   o_address <= "0000000000000001";
                                   
            when GET_ROW =>     o_en <= '1';
                                o_we <= '0';
                                
                                   pixels_array(1) <= i_data;
                                   row <= CONV_INTEGER(i_data);
                                   state_next <= NUM_PIXELS1;
                                   address <= 2;
                                   o_address <= "0000000000000010";
           
             when NUM_PIXELS1 => num_pixels <= column * row;
                                state_next <= GET_PIXELS;
                                o_en <= '1';
             
                                 
            -- Stato GET_PIXELS salva i pixel
            when GET_PIXELS =>    
                                  if (not all_pixel) then
                                    current_pixel_value <= i_data;
                                    pixels_array(address) <= i_data;
                                    counter <= counter + 1;
                                    o_address <= std_logic_vector(TO_UNSIGNED(address + 1, 16));
                                    address <= address + 1;
                                    state_next <= MAX_MIN;
                                    
                                  else
                                    state_next <= MAX_MIN;
                                   end if;  
                                  
             -- Stato MAX_MIN calcola gli indici MAX e MIN necessari all'elaborazione dell'immagine                               
             when MAX_MIN =>                  
                                  state_next <= GET_PIXELS;
                                  
                                  if(not min_settato) then
                                    min_pixel_value <= current_pixel_value;
                                    min_settato <= true;
                                  end if;
                                  
                                  if (counter >= num_pixels) then
                                            all_pixel <= true;
                                            state_next <= DELTA1; 
                                  
                                  elsif(current_pixel_value < min_pixel_value) then
                                    min_pixel_value <= current_pixel_value;
                                    
                                  elsif (current_pixel_value > max_pixel_value) then
                                    max_pixel_value <= current_pixel_value;
                                  
                                  end if;
                                  
              -- Stato INDEXES calcola gli indici per poter fare l'equalizzazione dell'istogramma                      
              when DELTA1 =>
                                  o_en <= '0';
                                  o_we <= '0';
                                  
                                  delta <= max_pixel_value - min_pixel_value; 
                                  state_next <= SHIFT;
                                  
              -- Resetta contatore e address per dopo
                                  counter <= 0;
                                  address <= 2;
                                                                  
              when SHIFT =>       shift_value <= 8 - LUT_LOG(conv_integer(delta));
                                                                    
                                  state_next <= EQUALIZATION1;
                                  current_pixel_value <= pixels_array(address);
                                  
               -- Esegui l'equalizzazione dell'istogramma di un pixel                   
               when EQUALIZATION1 =>
                                  
                                  curr_min <= unsigned(current_pixel_value - min_pixel_value);                 
                                  state_next <= EQUALIZATION2;
                                  
               when EQUALIZATION2 =>                   
                                  temp_pixel_value <= TO_INTEGER(curr_min sll integer(shift_value));
                                  state_next <= EQUALIZATION3;
                                  
               when EQUALIZATION3 =>                   
                                  if(temp_pixel_value < 255) then
                                    new_pixel_value <= std_logic_vector(TO_UNSIGNED(temp_pixel_value, 8));
                                  
                                  else
                                    new_pixel_value <= std_logic_vector(TO_UNSIGNED(255, 8));
                                  end if;
                                  
                                  state_next <= EQUALIZATION4;
                                  
               when EQUALIZATION4 =>
                                  pixels_array(address + num_pixels) <= new_pixel_value;
                                  o_address <= std_logic_vector(TO_UNSIGNED(address + num_pixels, 16));
                                  counter <= counter + 1;
                                  address <= address + 1;
                                  
                                  -- Attiva scrittura per il prossimo stato
                                  o_en <= '1';
                                  o_we <= '1';
                                  state_next <= WRITE_OUT;
                                  
              when WRITE_OUT =>        
                                    current_pixel_value <= pixels_array(address);
                                    o_data <= new_pixel_value;
                                    
                                    state_next <= EQUALIZATION1;
                                    
                                    if(counter > num_pixels) then
                                        state_next <= DONE;
                                    end if;
                                    
               when DONE =>                               
                                    o_en <= '0';
                                    o_we <= '0';
                                    o_done <= '1';
                                    
                                    state_next <= RESET;
                            
                            
                            
                           
         end case;
        end if;
    end process;
    
end Behavioral;
