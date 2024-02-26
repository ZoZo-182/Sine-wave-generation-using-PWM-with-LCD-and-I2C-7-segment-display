LIBRARY ieee;
   USE ieee.std_logic_1164.all;
	use ieee.numeric_std.all;	
	
entity Counter2SRAM is 
generic(N: integer := 5; N2: integer := 32; N1: integer := 0);
port (
	clk : in std_logic;
	M : integer:=0; -- Tuning Word M. This is decimal 
	state: in std_logic_vector(3 downto 0);
	rst : in std_logic;
	Q : OUT std_logic_vector(7 downto 0)
);
end Counter2SRAM;

Architecture Behavioral OF Counter2SRAM is

signal counter : unsigned(N2-1 downto 0):=X"00000000";
	constant M1               : integer:= 5153;
	constant M2               : integer:= 10307;
	constant M3               : integer:= 85899;
begin

-- counter2SRAM (phase register?)
process(clk, rst, state, counter)
begin
	if rising_edge(clk) then 
	case state is 
		when "1001" =>
				counter <= counter + M1;
				Q <= std_logic_vector(counter(31 downto 24));
		when "1010" =>
				counter <= counter + M2;
				Q <= std_logic_vector(counter(31 downto 24));
		when "1011" =>
				counter <= counter + M3;
				Q <= std_logic_vector(counter(31 downto 24));
		when others =>
				counter <= counter + M1;
				Q <= std_logic_vector(counter(31 downto 24));	
	end case;
	end if;
end process;	

end Behavioral;

--LIBRARY ieee;
--   USE ieee.std_logic_1164.all;
--	use ieee.numeric_std.all;	
--	
--entity Counter2SRAM is 
--port (
--	clk : in std_logic;
--	M : integer:=0; -- Tuning Word M. This is decimal 
--	state: in std_logic_vector(3 downto 0);
--	rst : in std_logic;
--	Q : OUT std_logic_vector(31 downto 0)
--);
--end Counter2SRAM;
--
--Architecture Behavioral OF Counter2SRAM is
--
--signal counter : integer :=0;
--
--begin
--
---- counter2SRAM (phase register?)
--process(clk)
--begin
--	if rising_edge(clk) then 
--	   if rst = '1' then
--	    counter <= 0; 
--		else
--			counter <= counter + M; --  not incrementing by 1 anymore; its by M.
--		end if; 
--	end if;
--Q <= std_logic_vector(to_unsigned(counter, Q'length)); 
--end process; 
--end Behavioral;