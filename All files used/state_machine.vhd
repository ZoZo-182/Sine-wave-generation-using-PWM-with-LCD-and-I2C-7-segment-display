library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity StateMachine is
    Port (
        clk : in std_logic;
        reset : in std_logic;
		  KEY0 : in std_logic;
        KEY1 : in std_logic;
        KEY2 : in std_logic;
        KEY3 : in std_logic;
		  counter : in STD_LOGIC_VECTOR(7 downto 0);
        state_out : out std_logic_vector(3 downto 0) -- 4-bit state output
    );
end StateMachine;

architecture Behavioral of StateMachine is
    type State_Type is (Initialization, Test, Pause, PWM_GEN_60, PWM_GEN_120, PWM_GEN_1000);
    signal state, next_state : State_Type; -- current_state next_state
	 signal down : BOOLEAN := false;  	 
	 signal state_value : STD_LOGIC_VECTOR(3 downto 0); 

	 
begin 

    -- State transition process
  

    -- Next state logic
    process(clk, reset, counter)
    begin
	 if reset = '1' then
        state <= Initialization;
    elsif (counter = X"FF") then -- 
        state <= Test; 
	 elsif rising_edge(clk) then
		  if KEY1 = '1' and KEY2 = '1' and KEY3 = '1' then
				down <= false;
		  end if;
        case state is
				when Initialization =>
						if counter = X"00" and reset = '0' then --If it reaches FF and reset is NOT pressed, enter test
							state <= Test;
						end if;
		
            when Test =>
                if KEY1 = '0' and down = false then
						  down <= true;
                    state <= Pause;
                elsif KEY2 = '0' and down = false then
						  down <= true;
                    state <= PWM_GEN_60;
					 elsif KEY0 = '0' then
						 next_state <= Initialization;
                end if;
					 
            when Pause =>
                if KEY1 = '0' and down = false then
					 	  down <= true;
                    state <= Test;
					 elsif KEY0 = '0' then
						next_state <= Initialization;
                end if;
					 
            when PWM_GEN_60 =>
                if KEY2 = '0' and down = false then
						  down <= true;
                    state <= Test;
					 elsif KEY3 = '0' and down =false then
						down <= true;
						state <= PWM_GEN_120;
					 elsif KEY0 = '0' then
						next_state <= Initialization;
                end if;
					 
            when PWM_GEN_120 =>
                if KEY2 = '0' and down = false then
						  down <= true;
                    state <= Test;
					 elsif KEY3 = '0' and down = false then
					   down <= true;
						state <= PWM_GEN_1000;
					 elsif KEY0 = '0' then
						next_state <= Initialization;
                end if;
					 
            when PWM_GEN_1000 =>
                if KEY2 = '0' and down = false then
						  down <= true;
                    state <= Test;
					 elsif KEY3 = '0' and down = false then
					   down <= true;
						state <= PWM_GEN_60;
				    elsif KEY0 = '0' then
						next_state <= Initialization;
                end if;
				when others =>
					state <= Initialization;
        end case;
		  end if;
    end process;

 with state select 

    state_value <= "0011" when Initialization, 

                   "0111" when Test, 

                   "0110" when Pause, 

                   "1001" when PWM_GEN_60, 

                   "1010" when PWM_GEN_120, 
						 
						 "1011" when PWM_GEN_1000,

                   "0011" when others;  -- Default value for unknown states 

    state_out <= state_value;
	 
	 

 

end Behavioral; 
