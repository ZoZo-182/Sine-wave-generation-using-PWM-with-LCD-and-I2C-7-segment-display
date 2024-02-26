LIBRARY ieee;
   USE ieee.std_logic_1164.all;

ENTITY Wrapper IS
   PORT (
 -- 			Clock Input	 	     
      CLOCK_50    : IN STD_LOGIC;							-- On Board 50 MHz

-- 			Push Button		      
      KEY         : IN STD_LOGIC_VECTOR(3 DOWNTO 0);		-- Pushbutton[3:0]
-- 			DPDT Switch		      
      SW          : IN STD_LOGIC_VECTOR(17 DOWNTO 0);		-- Toggle Switch[17:0]
  	  
-- 			SRAM Interface		      
      SRAM_DQ     : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);	-- SRAM Data bus 16 Bits
      SRAM_ADDR   : OUT STD_LOGIC_VECTOR(19 DOWNTO 0);		-- SRAM Address bus 18 Bits
      SRAM_UB_N   : OUT STD_LOGIC;							-- SRAM High-byte Data Mask
      SRAM_LB_N   : OUT STD_LOGIC;							-- SRAM Low-byte Data Mask
      SRAM_WE_N   : OUT STD_LOGIC;							-- SRAM Write Enable
      SRAM_CE_N   : OUT STD_LOGIC;							-- SRAM Chip Enable
      SRAM_OE_N   : OUT STD_LOGIC;							-- SRAM Output Enable

-- 			LCD Module 16X2		            
      LCD_ON      : OUT STD_LOGIC;							-- LCD Power ON/OFF
      LCD_BLON    : OUT STD_LOGIC;							-- LCD Back Light ON/OFF
      LCD_RW      : OUT STD_LOGIC;							-- LCD Read/Write Select, 0 = Write, 1 = Read
      LCD_EN      : OUT STD_LOGIC;							-- LCD Enable
      LCD_RS      : OUT STD_LOGIC;							-- LCD Command/Data Select, 0 = Command, 1 = Data
      LCD_DATA    : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);		-- LCD Data bus 8 bits
    
-- 			I2C		      
      I2C_SDAT     : INOUT STD_LOGIC;						-- I2C Data
      I2C_SCLK     : OUT STD_LOGIC;							-- I2C Clock

-- 			GPIO	      
      GPIO         : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0)	-- GPIO Connection                                                                                                
   );
END Wrapper;

ARCHITECTURE structural OF Wrapper IS

-- TOP LEVEL COMPONENT

component top_level is
		port (
		iClk					: in std_logic;
      KEY0 					: in STD_LOGIC;
		KEY1 					: in STD_LOGIC;  
		KEY2 					: in STD_LOGIC;  		
		KEY3 					: in STD_LOGIC;  
		
		-- PWM
		PWMSCL				: out std_LOGIC;
		
		-- SRAM 
		SRAM_IO 				: INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);	
		SRAM_addr2SRAM		: OUT STD_LOGIC_VECTOR(19 DOWNTO 0);
		SRAM_ce 				: OUT STD_LOGIC:='0';
		SRAM_ub 				: OUT STD_LOGIC:='0';
		SRAM_lb				: OUT STD_LOGIC:='0';
		SRAM_we 				: OUT STD_LOGIC;
		SRAM_oe 				: OUT STD_LOGIC;
		scl			: INOUT STD_LOGIC;
	   sda			: INOUT STD_LOGIC;
		LCD_DATA : out  STD_LOGIC_VECTOR (7 downto 0);
      LCD_EN   : out  STD_LOGIC;
      LCD_RS   : out  STD_LOGIC;
		LCD_ON      : OUT STD_LOGIC;					-- LCD Power ON/OFF
      LCD_BLON    : OUT STD_LOGIC;							-- LCD Back Light ON/OFF
      LCD_RW      : OUT STD_LOGIC 						-- LCD Read/Write Select, 0 = Write, 1 = Read
		);
		
end component top_level;

BEGIN
   
-- INSTANTIATION OF THE TOP LEVEL COMPONENT

Inst_top_level: top_level 
		port map (
		KEY0				 	=> KEY(0),
		KEY1				 	=> KEY(1),
		KEY2				 	=> KEY(2),
		KEY3				 	=> KEY(3),	
		iClk			 		=> CLOCK_50, 
		PWMSCL				=> GPIO(18), -- assign to a pin
		
			--to SRAM
		SRAM_IO => SRAM_DQ,
		--SRAM_ready=>  ---?????
		SRAM_addr2SRAM=>SRAM_ADDR,
		SRAM_ce =>SRAM_CE_N,
		SRAM_ub => SRAM_UB_N,
		SRAM_lb => SRAM_LB_N,
		SRAM_we => SRAM_WE_N,
		SRAM_oe => SRAM_OE_N,
		
		-- To 7Seg
		scl			=> GPIO(6),
	   sda			=> GPIO(5),
		
		-- To LCD
		 LCD_DATA => LCD_DATA,
       LCD_EN   => LCD_EN,
       LCD_RS   => LCD_RS,
		 LCD_ON      => LCD_ON,						-- LCD Power ON/OFF
       LCD_BLON    => LCD_BLON,								-- LCD Back Light ON/OFF
       LCD_RW     => LCD_RW							-- LCD Read/Write Select, 0 = Write, 1 = Read
		);

END structural;
