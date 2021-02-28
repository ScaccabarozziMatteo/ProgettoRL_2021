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
use IEEE.MATH_REAL.ALL;
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
    type state is (RESET, DIMENSIONS, GET_PIXELS, MAX_MIN, INDEXES, EQUALIZATION, WRITE_OUT, DONE);
    -- Definisci struttura array
    type Memory_Pixels is array (16385 downto 0) of std_logic_vector(7 downto 0);
    
    -- Stato corrente e prossimo FSM
    signal state_next: state;
    -- Array contenten indirizzo e valore del pixel corrente
    signal pixels_array: Memory_Pixels := (others => (others => '0'));
    -- Delta corrente
    signal delta: std_logic_vector(7 downto 0);
    -- Shift_value corrente
    signal shift_value: integer := 0;
    -- Temp_pixel value corrente. Il pixel può essere shiftato al più di 8, quindi vettore di 16 bit
    signal temp_pixel_value: std_logic_vector(15 downto 0);
    -- Variabili: EQUALIZZATA, MAX, MIN e OLD dei pixel
    signal new_pixel_value, max_pixel_value, min_pixel_value, current_pixel_value: std_logic_vector(7 downto 0);
    signal curr_min: unsigned;
    signal logarithm: real;
    
    -- Contatore per lettura di ogni pixel
    signal counter: integer range 0 to 16383;
    signal num_pixels: integer range 0 to 16383;
    signal address: integer range 0 to 16385;
    
    -- Dimensioni immagine
    signal row, column: integer range 0 to 127 := 0;
    
    -- Segnali di check
    signal get_row, get_column, all_pixel: boolean := false;
    
    
    
    
begin
    process(i_clk) 
    begin
      if(i_clk'event and i_clk = '0') then
        if (i_rst = '1') then
            state_next <= RESET;
            
        else
        
        case state_next is
        --se stiamo nel caso RESET perchè il counter lo metti ad 1 se non stiamo leggendo nulla, non dovrebbe rimanere a 0?
           
            when RESET =>   delta <= "00000000";
                            temp_pixel_value <= "00000000";
                            counter <= 1;
                            num_pixels <= 0;
                            
                            o_en <= '0';
                            o_we <= '0';
                            o_data <= "00000000";
                            o_done <= '0';
                     ----qua setterei il valore di column a true
                            -----------------------------
                            state_next <= DIMENSIONS;
                            
            when DIMENSIONS =>   o_en <= '1';
                                 o_we <= '0';
            
                               if (get_column) then
                                   pixels_array(0) <= i_data;
                                   column <= conv_integer(pixels_array(0));
                                   get_column <= false;
--qua setterei il valore di row a true in modo tale poi da "entrare" nell'altro ramo
                                   state_next <= DIMENSIONS;
                                   
                               elsif (get_row) then
                                   pixels_array(1) <= i_data;
                                   row <= conv_integer(pixels_array(1));
                                   get_row <= false;
                                   state_next <= GET_PIXELS;
                                   address <= 2;
                                   num_pixels <= column * row;
                                   
                               end if;               
                                 
            -- Stato GET_PIXELS salva i pixel
            when GET_PIXELS =>    o_en <= '1';
                                  o_we <= '0';
                                  
                                  if (not all_pixel) then
                                    current_pixel_value <= i_data;
                                    pixels_array(address) <= current_pixel_value;
                                    counter <= counter + 1;
                                    address <= address + 1;
                                    state_next <= MAX_MIN;
                                    
                                  else
                                    state_next <= MAX_MIN;
                                   end if;  
                                  
             -- Stato MAX_MIN calcola gli indici MAX e MIN necessari all'elaborazione dell'immagine                               
             when MAX_MIN =>      o_en <= '0';
                                  o_we <= '0';             
                                  
                                  state_next <= GET_PIXELS;
                                  if (counter > num_pixels) then
                                            all_pixel <= true;
                                            state_next <= INDEXES;
                                  end if; 
                                  --non dovrei mettere anche qui state_next<=INDEXES ? perchè se count non è > num_pixels non cambia stato
                                  if(current_pixel_value < min_pixel_value) then
                                    min_pixel_value <= current_pixel_value;
                                    
                                  elsif (current_pixel_value > max_pixel_value) then
                                    max_pixel_value <= current_pixel_value;
                                  
                                  end if;
                                  
              -- Stato INDEXES calcola gli indici per poter fare l'equalizzazione dell'istogramma                      
              when INDEXES =>
                                  o_en <= '0';
                                  o_we <= '0';
                                delta <= max_pixel_value - min_pixel_value;
                                   delta_prov <= conv_integer(delta);
                                   
                                   for i in 0 to 7 loop
                                   
                                   
                                  exit when delta(i)='1';
        
                                  end loop;
                                   case i is 
                                   when 0 =>
                                   delta_prov <=7;
                                   
                                   when 1 =>
                                   delta_prov<=6;
                                   
                                   when 2 =>
                                   delta_prov<=5;
                                   
                                   when 3 =>
                                   delta_prov<=4;
                                   
                                   when 4 =>
                                   delta_prov<=3;
                                   
                                   when 5 =>
                                   delta_prov<=2;
                          
                                   when 6 =>
                                   delta_prov<=1;
                                
                                   when 7 =>
                                     delta_prov<=0;
                                     
                                     end case;
                                           
                                      shift_value <= 8 - delta_prov;
                                  
               -- Esegui l'equalizzazione dell'istogramma di un pixel                   
               when EQUALIZATION =>
                                  o_en <= '0';
                                  o_we <= '0';
                                  
                                  current_pixel_value <= pixels_array(address);
                                  
                                  curr_min <= unsigned(current_pixel_value - min_pixel_value);                 
                                  temp_pixel_value <= std_logic_vector(curr_min sll integer(shift_value));
                                  
                                  if(temp_pixel_value < 255) then
                                    new_pixel_value <= temp_pixel_value;
                                  
                                  else
                                    new_pixel_value <= std_logic_vector(TO_UNSIGNED(255, 8));
                                  end if;
                                  
                                  state_next <= WRITE_OUT;
                                  pixels_array(address + num_pixels) <= new_pixel_value;
 
              when WRITE_OUT =>     o_en <= '1';
                                    o_we <= '1';    
                                    
                                    
                                    o_address <= std_logic_vector(TO_UNSIGNED(address + num_pixels, 16));
                                    o_data <= new_pixel_value;
                                    counter <= counter + 1;
                                    address <= address + 1;
                                    
                                    state_next <= EQUALIZATION;
                                    
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
      end if;

    end process;


end Behavioral;
