library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity LCD_Controller2 is
    Port (
        Clk    : in  STD_LOGIC;
        Rst   : in  STD_LOGIC;
        iHex : in std_logic_vector(15 downto 0);
		  iAddr : in std_logic_vector(7 downto 0);
		  state_in : in std_logic_vector(1 downto 0);
		  pwm_in : in std_logic_vector(1 downto 0);
        LCD_DATA : out  STD_LOGIC_VECTOR (7 downto 0);
        LCD_EN   : out  STD_LOGIC;
        LCD_RS   : out  STD_LOGIC
    );
end LCD_Controller2;

architecture rtl of LCD_Controller2 is
    type State_Type is (INIT, WRITE_DATA, TEST, PAUSE, PWM, IDLE, WRITE_PWM);
    signal State : State_Type := INIT;
	 signal Next_State : State_Type := INIT;
    signal Data_Index : INTEGER range 0 to 25 := 0;
    signal Update_Counter : INTEGER := 0;  -- Counter for 5ms delay
    constant Update_Period : INTEGER := 250000;  -- 5ms at 50MHz
    signal Initialized : BOOLEAN := false;  -- Flag for LCD_RS control
	 signal Display, Tested, Paused, PWMed : BOOLEAN := false;
	 
    type DATA_SEQ is array (0 to 22) of STD_LOGIC_VECTOR(7 downto 0);
    type REPEAT_SEQ is array (0 to 8) of std_logic_vector(7 downto 0);
	 type TEST_SEQ is array (0 to 11) of std_logic_vector(7 downto 0);
	 type PAUSE_SEQ is array (0 to 12) of std_logic_vector(7 downto 0);
	 type PWM_SEQ is array (0 to 10) of std_logic_vector(7 downto 0);
    --signal Repeat_Sequence : REPEAT_SEQ;
    constant Data_Sequence : DATA_SEQ := (
        x"38", x"38", x"38", x"38", x"38", x"38", x"01", x"0C", 
        x"06", x"80", x"49", x"6E", x"69", x"74", x"69", x"61", x"6C", x"69", 
        x"7A", x"69", x"6E", x"67", x"67"
    );
    signal Repeat_Sequence : REPEAT_SEQ := (
         x"C0", x"30", x"30", x"FE", x"30", x"30", x"30", x"30", x"30"
    );
	 signal PWM_Data : REPEAT_SEQ := (
			x"C0", x"36", x"30", x"FE", x"48", x"7A", x"FE", x"FE", x"FE"
    );
	 signal Test_Sequence : TEST_SEQ := (
			x"01", x"80", x"54", x"65", x"73", x"74", x"FE", x"4D", x"6F", 
			x"64", x"65", x"FE"
			
	 );
	 signal Pause_Sequence : PAUSE_SEQ := (
	      x"01", x"80", x"50", x"61", x"75", x"73", x"65", x"FE", x"4D", x"6F", 
			x"64", x"65", x"FE"
		);
    
	 signal PWM_Sequence : PWM_SEQ := (
			x"01", x"80", x"50", x"57", x"4D", x"FE", x"4D", x"6F", 
			x"64", x"65", x"FE"
	 );
	 
    signal iChar : std_logic_vector(3 downto 0);
    signal LCD_Char : std_logic_vector(7 downto 0);
    signal LCD_count_state : std_logic_vector(1 downto 0) := "00";
	 signal Temp_Repeat_Sequence : REPEAT_SEQ := Repeat_Sequence; -- Temporary variable for dynamic updates
	 signal Temp_PWM_Sequence : REPEAT_SEQ := Repeat_Sequence; -- Temporary variable for dynamic updates

    function ConvertToLCDChar(nibble : std_logic_vector(3 downto 0)) return std_logic_vector is
		variable result : std_logic_vector(7 downto 0);
		begin
			 case nibble is
				  when "0000" => 
						result := x"30"; -- 0
				  when "0001" => 
						result := x"31"; -- 1
				  when "0010" => 
						result := x"32"; -- 2
				  when "0011" => 
						result := x"33"; -- 3
				  when "0100" => 
						result := x"34"; -- 4
				  when "0101" => 
						result := x"35"; -- 5
				  when "0110" => 
						result := x"36"; -- 6
				  when "0111" => result := x"37"; -- 7
				  when "1000" => result := x"38"; -- 8
				  when "1001" => result := x"39"; -- 9
				  when "1010" => result := x"41"; -- A
				  when "1011" => result := x"42"; -- B
				  when "1100" => result := x"43"; -- C
				  when "1101" => result := x"44"; -- D
				  when "1110" => result := x"45"; -- E
				  when "1111" => result := x"46"; -- F
				  when others => result := x"20"; -- Space or default
			 end case;
			 return std_logic_vector(result);
		end function;	
	
begin
    process(Clk, Rst)
    begin
        if Rst = '1' then
            State <= INIT;
            Data_Index <= 0;
            Update_Counter <= 250000;
            Initialized <= false;
            LCD_DATA <= (others => '0');
            LCD_EN <= '0';
            LCD_RS <= '0';
				Display <= false;
        elsif rising_edge(Clk) then
            if Update_Counter < Update_Period then
					 -- Conversion and assignment for iAddr
				  Temp_Repeat_Sequence(0) <= x"C0"; 
				  Temp_Repeat_Sequence(1) <= ConvertToLCDChar(iAddr(7 downto 4)); -- Convert high nibble
				  Temp_Repeat_Sequence(2) <= ConvertToLCDChar(iAddr(3 downto 0)); -- Convert low nibble
				  Temp_Repeat_Sequence(3) <= x"FE";
				  -- Conversion and assignment for iHex
				  Temp_Repeat_Sequence(4) <= ConvertToLCDChar(iHex(15 downto 12)); -- Convert highest nibble
				  Temp_Repeat_Sequence(5) <= ConvertToLCDChar(iHex(11 downto 8));
				  Temp_Repeat_Sequence(6) <= ConvertToLCDChar(iHex(7 downto 4));
				  Temp_Repeat_Sequence(7) <= ConvertToLCDChar(iHex(3 downto 0)); -- Convert lowest nibble
				  Temp_Repeat_Sequence(8) <= x"FE"; -- Convert lowest nibble

                if Update_Counter = 100000 and Display = true then
                    LCD_EN <= '1';
                elsif Update_Counter = 150000 and Display = true then
                    LCD_EN <= '0';
                end if;
                Update_Counter <= Update_Counter + 1;
            else
               Update_Counter <= 0;
					-- Update the actual signal at the end of the process
				   Repeat_Sequence <= Temp_Repeat_Sequence;
					PWM_Data <= Temp_PWM_Sequence;
					 case State is
						  when INIT =>
								if Data_Index < 22 then
									 Display <= true;
									 LCD_DATA <= Data_Sequence(Data_Index);
									 if Data_Sequence(Data_Index) = x"80" then
										  Initialized <= true;
									 end if;
									 if Initialized and Data_Sequence(Data_Index) = x"01" then
										  LCD_RS <= '0';
									 elsif Initialized then
										  LCD_RS <= '1';
									 end if;
									 Data_Index <= Data_Index + 1;
								else
									 LCD_EN <= '0';
									 Data_Index <= 0;
									 State <= IDLE;
									 Display <= false;
									 --LCD_DATA <= Repeat_Sequence(Data_Index);
								end if;	
							when WRITE_DATA => 
								if Data_Index < 9 then
									Display <= true;
									LCD_DATA <= Repeat_Sequence(Data_Index);
									if Repeat_Sequence(Data_Index) = x"C0" then
										 LCD_RS <= '0';
									else
										 LCD_RS <= '1';
									end if;
									Data_Index <= (Data_Index + 1);
								elsif state_in /= "01" then
									Display <= false;
									state <= IDLE;
								else 
									Data_Index <= 0;
								end if;		
							when WRITE_PWM =>
								if Data_Index < 9 then
									Display <= true;
									LCD_DATA <= PWM_Data(Data_Index);
									if PWM_Data(Data_Index) = x"C0" then
										 LCD_RS <= '0';
									else
										 LCD_RS <= '1';
									end if;
									Data_Index <= (Data_Index + 1);
								elsif state_in /= "11" then
									Display <= false;
									state <= IDLE;
								else 
									Data_Index <= 0;
									--Display <= false;
									--state <= IDLE;
								end if;	
							when TEST => 
								if Data_Index < 11 then
									Display <= true;
									LCD_DATA <= Test_Sequence(Data_Index);
									if Test_Sequence(Data_Index) = x"80" or Test_Sequence(Data_Index) = x"01" then
										 LCD_RS <= '0';
									else
										 LCD_RS <= '1';
									end if;
									Data_Index <= (Data_Index + 1);
								else 
									LCD_EN <= '0';
									Data_Index <= 0;
									Tested <= true;
									State <= WRITE_DATA;
								   Display <= false;
								end if;
							when PAUSE => 
								if Data_Index < 12 then
									Display <= true;
									LCD_DATA <= Pause_Sequence(Data_Index);
									if Pause_Sequence(Data_Index) = x"80" or Pause_Sequence(Data_Index) = x"01" then
										 LCD_RS <= '0';
									else
										 LCD_RS <= '1';
									end if;
									Data_Index <= (Data_Index + 1);
								else 
									LCD_EN <= '0';
									Data_Index <= 0;
									Paused <= true;
									State <= WRITE_DATA;
								   Display <= false;
								end if;
							when PWM => 
								if Data_Index < 10 then
									Display <= true;
									LCD_DATA <= PWM_Sequence(Data_Index);
									if PWM_Sequence(Data_Index) = x"80" or PWM_Sequence(Data_Index) = x"01" then
										 LCD_RS <= '0';
									else
										 LCD_RS <= '1';
									end if;
									Data_Index <= (Data_Index + 1);
								else 
									LCD_EN <= '0';
									Data_Index <= 0;
									PWMed <= true;
									State <= WRITE_PWM;
								   Display <= false;
								end if;
							when IDLE =>
								if state_in = "01" and Tested = false then
									Data_Index <= 0;
									LCD_EN <= '0';
									Update_Counter <= 250000;
									Initialized <= false;
									Paused <= false;
									PWMed <= false;
									State <= TEST;
								elsif Initialized = false and state_in = "00" then
									Data_Index <= 6;
									LCD_EN <= '0';
									Update_Counter <= 250000;
									Initialized <= false;
									LCD_RS <= '0';
									Tested <= false;
									Paused <= false;
									PWMed <= false;
									State <= INIT;
								elsif Paused = false and state_in = "10" then
									Data_Index <= 0;
									LCD_EN <= '0';
									Update_Counter <= 250000;
									Initialized <= false;
									Tested <= false;
									PWMed <= false;
									State <= PAUSE;
								elsif PWMed = false and state_in = "11" then
									Data_Index <= 0;
									LCD_EN <= '0';
									Update_Counter <= 250000;
									Initialized <= false;
									Tested <= false;
									Paused <= false;
									State <= PWM;
								else 
									LCD_EN <= '0';
								end if;
						  when others =>
								LCD_DATA <= (others => '0');
								LCD_RS <= '0';
					 end case;
			end if;
        end if;
    end process;
	 
	     -- State output logic
    process(pwm_in)
    begin
        if pwm_in = "00" then
				Temp_PWM_Sequence(0) <= x"C0"; 
				Temp_PWM_Sequence(1) <= x"36"; 
				Temp_PWM_Sequence(2) <= x"30"; 
				Temp_PWM_Sequence(3) <= x"FE"; 
				Temp_PWM_Sequence(4) <= x"48"; 
				Temp_PWM_Sequence(5) <= x"7A"; 
				Temp_PWM_Sequence(6) <= x"FE"; 
				Temp_PWM_Sequence(7) <= x"FE"; 
				Temp_PWM_Sequence(8) <= x"FE"; 
			elsif pwm_in = "01" then
				Temp_PWM_Sequence(0) <= x"C0"; 
				Temp_PWM_Sequence(1) <= x"31"; 
				Temp_PWM_Sequence(2) <= x"32"; 
				Temp_PWM_Sequence(3) <= x"30"; 
				Temp_PWM_Sequence(4) <= x"FE"; 
				Temp_PWM_Sequence(5) <= x"48"; 
				Temp_PWM_Sequence(6) <= x"7A"; 
				Temp_PWM_Sequence(7) <= x"FE"; 
				Temp_PWM_Sequence(8) <= x"FE"; 
			elsif pwm_in = "10" then
				Temp_PWM_Sequence(0) <= x"C0"; 
				Temp_PWM_Sequence(1) <= x"31"; 
				Temp_PWM_Sequence(2) <= x"30"; 
				Temp_PWM_Sequence(3) <= x"30"; 
				Temp_PWM_Sequence(4) <= x"30"; 
				Temp_PWM_Sequence(5) <= x"FE"; 
				Temp_PWM_Sequence(6) <= x"48"; 
				Temp_PWM_Sequence(7) <= x"7A"; 
				Temp_PWM_Sequence(8) <= x"FE"; 
			end if;	
    end process;
	 
end rtl;
