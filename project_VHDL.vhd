----------------------------------------------------------
-- Progetto di Reti Logiche
-- SCACCABAROZZI MATTEO - ALEXANDER TENEMAYA
--
-- A.A. 2020/2- Prof. Palermo Gianluca
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
    type state is (IDLE, SAVE_COLUMN, START, RESET, GET_COLUMN, GET_ROW, NUM_PIXELS1, GET_PIXELS, MAX_MIN, DELTA1, DELTA2, SHIFT, EQUALIZATION1, EQUALIZATION1_1, EQUALIZATION1_2, EQUALIZATION1_3, EQUALIZATION2, EQUALIZATION3, EQUALIZATION3_1, EQUALIZATION3_2, EQUALIZATION4, WRITE_OUT, WRITE_OUT1, WRITE_OUT2, DONE, LAST);
    
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
    signal state_next: state := IDLE;
    -- Delta corrente
    signal delta: std_logic_vector(7 downto 0);
    -- Shift_value corrente
    signal shift_value: integer := 0;
    -- Variabili: EQUALIZZATA, MAX, MIN e OLD dei pixel
    signal new_pixel_value, max_pixel_value, min_pixel_value, current_pixel_value: std_logic_vector(7 downto 0);
    signal curr_min: unsigned(7 downto 0) := (others => '0');
    
    -- Contatore per lettura di ogni pixel
    signal counter: std_logic_vector(15 downto 0);
    signal num_pixels: integer range 0 to 16383;
    signal address_curr, address_new: std_logic_vector(15 downto 0);
    signal temp_add, temp_pixel_value: unsigned(15 downto 0);
    
    -- Dimensioni immagine
    signal row, column: integer range 0 to 127 := 0;
    
    -- Segnali di check
    signal all_pixel, min_settato: boolean := false;
    
    signal temporary: std_logic_vector(15 downto 0);
    
    
    
    
begin
       process (i_clk, i_rst)
         begin
          if rising_edge(i_clk) then
            if (i_rst = '1') then
                counter <= "0000000000000000"; 
                o_address <= "0000000000000000";
                address_curr <= "0000000000000000";
                address_new <= "0000000000000000";                           
                o_en <= '1';
                o_we <= '0';
                state_next <= RESET;
                
            end if;
            if (i_start = '1') then
                    o_en <= '1';
                   state_next <= START;
            elsif (i_start = '0') then
                          state_next <= IDLE;
                            counter <= "0000000000000000";                            
                            o_en <= '1';
                            o_we <= '0';
                            o_done <= '0';
                            min_pixel_value <= "00000000";
                            max_pixel_value <= "00000000";
                            all_pixel <= false;
                            min_settato <= false;
                            o_address <= "0000000000000000";
                            address_curr <= "0000000000000000";
                            address_new <= "0000000000000000";
                            shift_value <= 0;
                            state_next <= IDLE;
            end if;
    
           
            case state_next is
            
            when IDLE =>                if (i_start = '1') then
						                  state_next <= START;
					                    else
						                  state_next <= IDLE;
					                    end if;
                           
          
            when START =>               o_en <= '1';
                                        state_next <= GET_COLUMN;
        
            when RESET =>               counter <= "0000000000000000";                            
                                        o_en <= '1';
                                        o_we <= '0';
                                        o_done <= '0';
                                        min_pixel_value <= "00000000";
                                        max_pixel_value <= "00000000";
                                        all_pixel <= false;
                                        min_settato <= false;
                                        o_address <= "0000000000000000";
                                        address_curr <= "0000000000000000";
                                        address_new <= "0000000000000000";
                                        shift_value <= 0;
                                                        
                                        state_next <= START;

                            
            when GET_COLUMN =>          o_en <= '1';
                                        o_we <= '0';
                                        o_address <= "0000000000000001";
                                   
                                        column <= CONV_INTEGER(i_data);
                                        state_next <= SAVE_COLUMN;
                                        address_curr <= "0000000000000001";
           
            when SAVE_COLUMN =>         o_en <= '1';
                                        o_we <= '0';
                                   
                                        state_next <= GET_ROW; 
                                   
                                   
            when GET_ROW =>             o_en <= '1';
                                        o_we <= '0';
                                
                                        row <= CONV_INTEGER(i_data);
                                        state_next <= NUM_PIXELS1;
                                        address_curr <= "0000000000000010";
                                        o_address <= "0000000000000010";
           
             when NUM_PIXELS1 =>        o_en <= '1';
                                        o_we <= '0';
                                
                                        num_pixels <= column * row;
                                        state_next <= GET_PIXELS;
             
                                 
            -- Stato GET_PIXELS salva i pixel
            when GET_PIXELS =>          -- Converti num_pixels in Unsigned per dopo
                                        temp_add <= TO_UNSIGNED(num_pixels, 16);
                                        if (not all_pixel) then
                                            current_pixel_value <= i_data;
                                            counter <= counter + 1;
                                            o_address <= address_curr + "0000000000000001";
                                            address_curr <= address_curr + 1;
                                            state_next <= MAX_MIN;
                                    
                                        else
                                            state_next <= MAX_MIN;
                                        end if;  
                                  
             -- Stato MAX_MIN calcola gli indici MAX e MIN necessari all'elaborazione dell'immagine                               
             when MAX_MIN =>            state_next <= GET_PIXELS;
                                        o_en <= '1';
                                        o_we <= '0';
                                  
                                        if(not min_settato) then
                                            min_pixel_value <= current_pixel_value;
                                            min_settato <= true;
                                        end if;
                                  
                                        if (counter > num_pixels) then
                                            all_pixel <= true;
                                            state_next <= DELTA1; 
                                  
                                        elsif(current_pixel_value < min_pixel_value) then
                                            min_pixel_value <= current_pixel_value;
                                    
                                        elsif (current_pixel_value > max_pixel_value) then
                                            max_pixel_value <= current_pixel_value;
                                  
                                        end if;
                                  
              -- Stato INDEXES calcola gli indici per poter fare l'equalizzazione dell'istogramma                      
              when DELTA1 =>
                                        o_en <= '1';
                                        o_we <= '0';
                                  
                                        delta <= max_pixel_value - min_pixel_value; 
                                        state_next <= DELTA2;
                                  
              -- Resetta contatore e address per dopo
                                        counter <= "0000000000000000";
                                        o_address <= "0000000000000010";
                                        address_curr <= "0000000000000010";
                                  
              when DELTA2 =>            state_next <= SHIFT;
                                        o_en <= '1';
                                        o_we <= '0';
                                                                  
              when SHIFT =>             shift_value <= 8 - LUT_LOG(conv_integer(delta));
                                                                    
                                        state_next <= EQUALIZATION1;
                                        current_pixel_value <= i_data;
                                        o_en <= '1';
                                        o_we <= '0';
                                  
               -- Esegui l'equalizzazione dell'istogramma di un pixel
               when EQUALIZATION1 =>    address_new <= std_logic_vector(temp_add) + "0000000000000010";
                                        state_next <= EQUALIZATION1_1;
                                        o_en <= '1';
                                        o_we <= '0';
                                  
               when EQUALIZATION1_1 =>  current_pixel_value <= i_data;  
                                        state_next <= EQUALIZATION1_2;
                                        o_en <= '1';
                                        o_we <= '0';
               
               when EQUALIZATION1_2 =>  curr_min <= unsigned(current_pixel_value - min_pixel_value);
                                        state_next <= EQUALIZATION1_3;
                                  
               when EQUALIZATION1_3 =>  temporary <= std_logic_vector(resize(unsigned(curr_min), 16));
                                        state_next <= EQUALIZATION2;
                                        o_en <= '1';
                                        o_we <= '0';
                                  
               when EQUALIZATION2 =>    temp_pixel_value <= unsigned(temporary) sll integer(shift_value);
                                        state_next <= EQUALIZATION3;
                                        o_address <= address_new;
                                  
               when EQUALIZATION3 =>    o_en <= '1';
                                        o_we <= '0';           
                                                    
                                        if(temp_pixel_value < 255) then
                                            new_pixel_value <= std_logic_vector(resize(temp_pixel_value, 8));
                                  
                                        else
                                            new_pixel_value <= std_logic_vector(TO_UNSIGNED(255, 8));
                                        end if;
                                 
                                            state_next <= EQUALIZATION3_1;
                                 
              when EQUALIZATION3_1 =>   o_en <= '1';
                                        o_we <= '1';
                                        state_next <= EQUALIZATION3_2;
                                  
              when EQUALIZATION3_2 =>   o_data <= new_pixel_value;
                                        state_next <= EQUALIZATION4;
                                    
                                                                    
              when EQUALIZATION4 =>     counter <= counter + 1;
                                        state_next <= WRITE_OUT;
                                        o_en <= '1';
                                        o_we <= '0'; 
                                  
              when WRITE_OUT =>         state_next <= WRITE_OUT1;
                                        o_en <= '1';
                                        o_we <= '0';
                                  
              when WRITE_OUT1 =>        o_en <= '1';
                                        o_we <= '0';   
                                        o_address <= address_curr + "0000000000000001";
                                        address_curr <= address_curr + "0000000000000001";
                                        address_new <= address_new + "0000000000000001";
                                        state_next <= WRITE_OUT2;
                                    
                                        if(counter >= num_pixels) then
                                            state_next <= DONE;
                                        end if;
                                 
                                   
               when WRITE_OUT2 =>       state_next <= EQUALIZATION1_1;
                
               when DONE =>             o_en <= '0';
                                        o_we <= '0';
                                        o_done <= '1';
                                    
                                        state_next <= LAST;
                                    
               when LAST =>             o_done <= '0';
                                        state_next <= IDLE;                            
                            
                            
                           
               end case;
        end if;
    end process;
    
end Behavioral;
