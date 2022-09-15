-- Matteo Spreafico
-- Codice Persona: 10669138
-- Matricola: 932096

-- Ludovica Tassini
-- Codice Persona: 10663137
-- Matricola: 938238
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
    port (
        -- Inputs
        i_clk : in STD_LOGIC;                           -- Clock signal
        i_rst : in STD_LOGIC;                           -- Reset signal
        i_start : in STD_LOGIC;                         -- Start signal
        i_data : in STD_LOGIC_VECTOR(7 downto 0);       -- Input data
        -- Outputs
        o_address : out STD_LOGIC_VECTOR(15 downto 0);  -- Output data address
        o_done : out STD_LOGIC;                         -- Done signal
        o_en : out STD_LOGIC;                           -- Memory enable signal
        o_we : out STD_LOGIC;                           -- Memory mode signal: 0 read, 1 write
        o_data : out STD_LOGIC_VECTOR(7 downto 0)       -- Output data
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

    type STATE_TYPE is (
       
        START,           -- Initial and reset state 
        
        ENABLE_MEMORY,   -- Sets o_en = '1' if reading from memory is required
       
        WAITING_STATE,   -- Waiting state
       
        READ_SIZE,       -- Reads the number of words to process
       
        READ_WORD,       -- Reads the word to process
       
        CONV_CONTROLLER, -- Controls the convolution process 
       
        CONVOLUTION_00,  -- Convolution state
       
        CONVOLUTION_01,  -- Convolution state
       
        CONVOLUTION_10,  -- Convolution state
       
        CONVOLUTION_11,  -- Convolution state
       
        WRITE_WORD,      -- Writes the word onto the memory
       
        DONE             -- Final state
       
    );
    
    -- Current state register
    signal state : STATE_TYPE := START; -- contains the machine's current state
    
    -- I/O stream address registers
    signal i_stream_address : STD_LOGIC_VECTOR(15 downto 0) := (others => '0'); -- address to read from
    signal o_stream_address : STD_LOGIC_VECTOR(15 downto 0) := "0000001111101000"; -- address to write to
   
    -- Words registers
    signal has_words_number : BOOLEAN := false; 
    signal words_number : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal current_word : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    
    -- Convolution registers
    signal i : INTEGER range 0 to 8 := 0;
    signal u : STD_LOGIC := '0';
    signal Z : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal state_backup : STATE_TYPE := CONVOLUTION_00;
    
    -- Writing process register
    signal word_switch : BOOLEAN := false;
   
    begin
       
        main: process(i_clk)
       
        begin
        
            if rising_edge(i_clk) then
            
                if i_rst = '1' then
                    state <= START;
                else
                
                    case state is
                       
                        when START =>
                        
                            -- Default signals
                            o_en <= '0';
                            o_we <= '0';
                            o_done <= '0';                                  
                            o_data <= (others => '0');
                            o_address <= (others => '0');
                            i_stream_address <= "0000000000000001";    
                            o_stream_address <= "0000001111101000"; 
                            has_words_number <= false;                         
                            words_number <= (others => '0');
                            current_word <= (others => '0');                                                
                            i <= 0;                                         
                            u <= '0';                          
                            Z <= (others => '0');                   
                            state_backup <= CONVOLUTION_00;
                            word_switch <= false;
                            
                            if(i_start = '1') then                          
                                state <= ENABLE_MEMORY;
                            end if;
                       
                        when ENABLE_MEMORY => 
                                                          
                            o_we <= '0';                           
                            if has_words_number = false then
                                o_en <= '1';            
                                state <= WAITING_STATE;
                            elsif words_number > 0 then
                                o_en <='1';
                                o_address <= i_stream_address;
                                state <= WAITING_STATE;
                            else
                                o_done <= '1';
                                state <= DONE;
                            end if;
                           
                        when WAITING_STATE =>
                            
                            if word_switch = true then
                                state <= WRITE_WORD;
                            elsif has_words_number = false then
                                state <= READ_SIZE;
                            else
                                state <= READ_WORD;
                            end if;
                       
                        when READ_SIZE =>
                        
                            words_number <= i_data;    
                            has_words_number <= true;                         
                            state <= ENABLE_MEMORY;
                           
                        when READ_WORD =>
                        
                            current_word <= i_data;
                            words_number <= words_number - 1;
                            i_stream_address <= i_stream_address + 1;
                            i <= 0;
                            state <= CONV_CONTROLLER;
                           
                        when CONV_CONTROLLER =>
                        
                            o_en <= '0';                                    
                            o_we <= '0';
                            if i > 7 then
                                state <= WRITE_WORD;
                            else
                                u <= current_word(7-i);
                                state <= state_backup;
                            end if;
                       
                        when CONVOLUTION_00 =>    
                        
                            if u = '0' then
                                state_backup <= CONVOLUTION_00;
                                Z(15-(2*i)) <= '0';
                                Z(15-((2*i)+1)) <= '0';
                            else
                                state_backup <= CONVOLUTION_10;
                                Z(15-(2*i)) <= '1';
                                Z(15-((2*i)+1)) <= '1';
                            end if;
                            i <= i + 1;
                            state <= CONV_CONTROLLER;
                       
                        when CONVOLUTION_01 =>
                        
                            if u = '0' then
                                state_backup <= CONVOLUTION_00;
                                Z(15-(2*i)) <= '1';
                                Z(15-((2*i)+1)) <= '1';
                            else
                                state_backup <= CONVOLUTION_10;
                                Z(15-(2*i)) <= '0';
                                Z(15-((2*i)+1)) <= '0';
                            end if;
                            i <= i + 1;
                            state <= CONV_CONTROLLER;
                       
                        when CONVOLUTION_10 =>
                        
                            if u = '0' then
                                state_backup <= CONVOLUTION_01;
                                Z(15-(2*i)) <= '0';
                                Z(15-((2*i)+1)) <= '1';
                            else
                                state_backup <= CONVOLUTION_11;
                                Z(15-(2*i)) <= '1';
                                Z(15-((2*i)+1)) <= '0';
                            end if;
                            i <= i + 1;
                            state <= CONV_CONTROLLER;
                       
                        when CONVOLUTION_11 =>
                        
                            if u = '0' then
                                state_backup <= CONVOLUTION_01;
                                Z(15-(2*i)) <= '1';
                                Z(15-((2*i)+1)) <= '0';
                            else
                                state_backup <= CONVOLUTION_11;
                                Z(15-(2*i)) <= '0';
                                Z(15-((2*i)+1)) <= '1';
                            end if;
                            i <= i + 1;
                            state <= CONV_CONTROLLER;
                         
                        when WRITE_WORD =>
                        
                            o_en <= '1';
                            o_we <= '1';
                            o_address <= o_stream_address;
                            o_stream_address <= o_stream_address + 1;
                            if word_switch = false then
                                o_data <= Z(15 downto 8);
                                word_switch <= true;
                                state <= WAITING_STATE;
                            elsif words_number > 0 then
                                o_data <= Z(7 downto 0);
                                word_switch <= false;
                                state <= ENABLE_MEMORY;
                            else
                                o_data <= Z(7 downto 0);
                                o_done <= '1';
                                state <= DONE;
                            end if;
                       
                        when DONE =>
                        
                            if i_start = '0' then
                                o_done <= '0';
                                state <= START;
                            end if;  
                       
                    end case;
                    
                end if;
                
            end if;
            
        end process;
   
end Behavioral;
