library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity univ_bin_counter is
   generic(N: integer := 5; N2: integer := 25; N1: integer := 0);
   port(
			clk, reset				: in std_logic;
			syn_clr, load, en, up	: in std_logic;
			clk_en 					: in std_logic := '1';			
			d						: in std_logic_vector(N-1 downto 0);
			max_tick, min_tick		: out std_logic;
			q						: out std_logic_vector(N-1 downto 0)		
   );
end univ_bin_counter;

architecture arch of univ_bin_counter is
   signal r_reg				 		: unsigned(N-1 downto 0);
   signal r_next				 	: unsigned(N-1 downto 0);
   signal r_1				    	: unsigned(N-1 downto 0);
   signal r_2				    	: unsigned(N-1 downto 0);
	
begin
   -- register
   process(clk,reset)
   begin
      if (reset='1') then
         r_reg <= (others=>'0');
      elsif rising_edge(clk) and clk_en = '1' then
         r_reg <= r_next;
      end if;
   end process;
	
   -- next-state logic
   r_next <= (others=>'0') when syn_clr='1' else
             unsigned(d)   when load='1' else
			 r_1     	   when en ='1' and up='1' else
             r_2     	   when en ='1' and up='0' else
             r_reg;
             
   r_1 <=   to_unsigned(N1, r_reg'length) when r_reg = to_unsigned(N2, r_reg'length) else
            r_reg + 1; 
   r_2 <=   to_unsigned(N2, r_reg'length) when r_reg = to_unsigned(N1, r_reg'length) else
            r_reg - 1;                        
             
   -- output logic
   q        <= std_logic_vector(r_reg);
   max_tick <= '1' when r_reg=to_unsigned(N2, r_reg'length) else '0';
   min_tick <= '1' when r_reg=to_unsigned(N1, r_reg'length) else '0';
end arch;
