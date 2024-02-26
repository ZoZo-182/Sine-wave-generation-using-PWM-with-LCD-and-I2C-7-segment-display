LIBRARY ieee;
   USE ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use ieee.std_logic_unsigned.all;
	
entity PWM_Controller is 
generic (
	N: integer :=0
--	PWM_COUNTER_MAX : integer :=256
 );
port (
	clk : in std_logic;
--	frequencyM : in integer:=0; 
	PWMstate : in std_logic_vector(3 downto 0);
	iData : in std_logic_vector(N-1 downto 0); -- 8-6 bit data from SRAMtrunc
	rst : in std_logic;
	PWMSCL : out std_logic
);
end PWM_Controller;

Architecture Behavioral OF PWM_Controller is

signal counter : std_logic_vector(N-1 downto 0);
signal PWMstatesig : std_logic_vector(3 downto 0);

begin

process(clk)
begin
if rising_edge(Clk) then
PWMstatesig <= PWMstate;
end if;
end process;

-- pwm counter
process(clk, PWMstate)
begin
	if PWMstatesig /= PWMstate then
		counter <= (others => '0'); 
	elsif rising_edge(clk)  then 
			counter <= counter + '1'; -- +
	end if;            
end process; 

-- comparator
PWMSCL <= '0' when  iData < counter else '1'; -- check this later

end Behavioral;
