library ieee;
use ieee.std_logic_1164.all;

entity SRAM_Controller is
port(
   clk						  : in std_logic;  
	reset                  : in std_logic;
   rw                     : in std_logic;-- read write, 1 read, 0 write,
	pulse   					  : in std_logic;
   address_in             : in std_logic_vector(7 downto 0);  --address 8 bit address 
   data_in                : in std_logic_vector(15 downto 0);  -- 8 bit data to be written to sram 
   SRAM_addr              : out std_logic_vector(19 downto 0);  -- sent to sram  
	data_out               : out std_logic_vector(15 downto 0);
   we_n 						  : out std_logic;
	oe_n                   : out std_logic;  -- sent to sram 
   io                     : inout std_logic_vector(15 downto 0);  -- goes into i/o  
   ce_n                   : out std_logic; -- tied low
   lb_n						  : out std_logic;
	ub_n						  : out std_logic
); 

end SRAM_Controller;

architecture arch of SRAM_Controller is


type state_type is (Ready, read_1, read_2, write_1, write_2);
signal state                 : state_type;
signal tri                   : std_logic;
signal oe_s                  : std_logic;
signal we_s						  : std_logic;
signal address_s				  : std_logic_vector(7 downto 0);
signal data_s					  : std_logic_vector(15 downto 0);


begin

ce_n <= '0';
lb_n <= '0';
ub_n <= '0';
io <= data_in when tri = '1' else (others => 'Z');
SRAM_addr(19 downto 8)  <= "000000000000"; 
oe_n <= oe_s;
we_n <= we_s;
SRAM_addr(7 downto 0) <= address_in;




process(clk, reset)
begin
if (reset = '1') then 
	we_s <= '1';
   oe_s <= '1';
	tri  <= '1';
elsif (clk'event and clk = '1') then

case state is

when Ready => 
  we_s <= '1';
  oe_s <= '1';
  tri  <= '0';
   if (rw = '1' )  then		--and pulse = '1'
   state <= read_1;
   end if;
   if (rw = '0')  then --and pulse = '1'
   state <= write_1;
   end if;
	
when read_1 =>
oe_s <= '0';
we_s <= '1';
tri  <= '0';
state <= read_2;


when read_2 =>
oe_s <= '1';
we_s <= '1';
tri  <= '0';
data_s <= io;
state <= Ready;

when write_1 =>
oe_s <= '1';
we_s <= '0';
tri  <= '1';
state <= write_2;

when write_2 =>
oe_s <= '1';
we_s <= '1';
tri  <= '1';
state <= Ready;

when others => 
state <= Ready;

end case;
end if;
end process;


process(clk)
begin
if rising_edge(clk) and tri = '0' then 
data_out <= data_s;
end if;
end process;

end arch;
