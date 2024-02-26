--I2C User logic
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY i2c_usrLogic IS
  PORT(
	 clk			: IN STD_LOGIC;
	 iData  		: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
	 scl			: INOUT STD_LOGIC;
	 sda			: INOUT STD_LOGIC
	 
);             
END i2c_usrLogic;

-- -----------------------------------------------------------------------------------------------------------------------------------

architecture logic of i2c_usrLogic is

component i2c_master IS
  GENERIC(
    input_clk : INTEGER := 100_000_000; --input clock speed from user logic in Hz
    bus_clk   : INTEGER := 400_000);   --speed the i2c bus (scl) will run at in Hz
  PORT(
    clk       : IN     STD_LOGIC;                    --system clock
    reset_n   : IN     STD_LOGIC;                    --active low reset
    ena       : IN     STD_LOGIC;                    --latch in command
    addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
    rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
    data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
    busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
    data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
    ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
    sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
    scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
END component;
-- -----------------------------------------------------------------------------------------------------------------------------------
type state_type is (start, writing, stop);
signal state		:state_type;
signal cont 		:integer:=16383; 
signal slave_addr: std_logic_vector(6 downto 0):="1110001";
signal i2c_addr: std_logic_vector(6 downto 0);
signal data_wr: std_logic_vector(7 downto 0);
signal newdata: std_logic_vector(15 downto 0);
signal reset_n,i2c_ena,busy,i2c_rw,oldBusy :std_logic;
signal byteSel: integer range 0 to 12;
-- -----------------------------------------------------------------------------------------------------------------------------------
begin

inst_i2cMaster: i2c_master
generic map(
	input_clk => 50_000_000, --input clock speed from user logic in Hz
	bus_clk 	 => 100_000) 	 --speed the i2c bus (scl) will run at in Hz
port map(
	 clk       =>clk,                   --system clock
    reset_n   =>reset_n,			 --active low reset
    ena       =>i2c_ena,			 --latch in command
    addr      =>i2c_addr, --address of target slave
    rw        =>'0'	,				--'0' is write, '1' is read (I am writing data ABCD)
    data_wr   =>data_wr, --data to write to slave
    busy      =>busy,--indicates transaction in progress
    data_rd   =>open,--data read from slave (e.g. a sensor)
    ack_error =>open,                    --flag if improper acknowledge from slave
    sda       =>sda,--serial data output of i2c bus
    scl       =>scl

);

process(clk)
begin 
if (clk'event and clk = '1') then 
case state is 
	when start => 
	if cont /= 0 then 
		cont <= cont - 1;
		reset_n <= '0';
		state <= start;
		i2c_ena <= '0';
	else
		reset_n <= '1';
		i2c_ena <= '1';
		i2c_addr <= slave_addr;
		i2c_rw <= '0';
		--i2c_data_wr <= data_wr;
		state <= writing;
	end if;

	when writing =>
	oldBusy <= busy;
	newData <= iData;
	if (busy = '0' and oldBusy /= busy) then--if it is not busy and the busy becomes active...
		if byteSel /= 12 then 
			byteSel <= byteSel + 1;
			state <= writing;
		else
			byteSel <= 7;
			state <= stop;
		end if;
	end if;
	
	when stop =>
		i2c_ena <= '0';
		if newdata /= iData then
		state <= start;
		else 
		state <= stop;
		end if;
	end case;
end if;
end process;
	
process(byteSel)
	begin
	case byteSel is
	when 0 => data_wr <= X"76";
	when 1 => data_wr <= X"76";
	when 2 => data_wr <= X"76";
	when 3 => data_wr <= X"7A";
	when 4 => data_wr <= X"FF";
	when 5 => data_wr <= X"77";
	when 6 => data_wr <= X"00";
	when 7 => data_wr <= X"79";
	when 8 => data_wr <= X"00";
	when 9 => data_wr <= X"0"&iData(15 downto 12);
	when 10 => data_wr <= X"0"&iData(11 downto 8);
	when 11 => data_wr <= X"0"&iData(7 downto 4);
	when 12 => data_wr <= X"0"&iData(3 downto 0);
end case;
end process;


end logic;	