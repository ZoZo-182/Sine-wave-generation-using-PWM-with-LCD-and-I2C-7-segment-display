library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top_level is
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
		SRAM_ce 				: OUT STD_LOGIC;
		SRAM_ub 				: OUT STD_LOGIC;
		SRAM_lb				: OUT STD_LOGIC;
		SRAM_we 				: OUT STD_LOGIC;
		SRAM_oe 				: OUT STD_LOGIC;
		
		--to seven segment
	   scl			: INOUT STD_LOGIC;
	   sda			: INOUT STD_LOGIC;
		
		-- to LCD
		LCD_DATA : out  STD_LOGIC_VECTOR (7 downto 0);
      LCD_EN   : out  STD_LOGIC;
      LCD_RS   : out  STD_LOGIC;
		LCD_ON      : OUT STD_LOGIC := '1';						-- LCD Power ON/OFF
      LCD_BLON    : OUT STD_LOGIC;							-- LCD Back Light ON/OFF
      LCD_RW      : OUT STD_LOGIC := '0'							-- LCD Read/Write Select, 0 = Write, 1 = Read

		);
end top_level;

architecture Structural of top_level is

   component i2c_usrLogic IS
      PORT(
	      clk			: IN STD_LOGIC;
	      iData  		: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
	      scl			: INOUT STD_LOGIC;
	      sda			: INOUT STD_LOGIC
);             
END component;

	component Rom IS
		PORT
		(
			address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
			clock			: IN STD_LOGIC  := '1';
			q				: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
		);
	END component;

	component univ_bin_counter is
		generic(N: integer := 8; N2: integer := 255; N1: integer := 0);
		port(
			clk, reset					: in std_logic;
			syn_clr, load, en, up	: in std_logic;
			clk_en 						: in std_logic := '1';			
			d								: in std_logic_vector(N-1 downto 0);
		   max_tick, min_tick		: out std_logic;
			q								: out std_logic_vector(N-1 downto 0)		
		);
	end component;

	component clk_enabler is
		GENERIC (CONSTANT cnt_max : integer := 49999999);      --  1.0 Hz 	
		PORT(	
		   clock						: in std_logic;	 
			clk_en					: out std_logic
		);
	end component;

	component Reset_Delay IS	
		 PORT (
			  SIGNAL iCLK 		: IN std_logic;	
			  SIGNAL oRESET 	: OUT std_logic
				);	
	end component;	
	
	component btn_debounce_toggle is
		GENERIC(
			CONSTANT CNTR_MAX : std_logic_vector(15 downto 0) := X"FFFF");  
		Port( 
			BTN_I 	: in  STD_LOGIC;
         CLK 		: in  STD_LOGIC;
         BTN_O 	: out  STD_LOGIC;
         TOGGLE_O : out  STD_LOGIC;
		   PULSE_O  : out STD_LOGIC);
	end component;
	
	component StateMachine is 
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
	end component; 
	
	component SRAM_Controller is
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
	end component;	
	
	component PWM_Controller is 
	generic (
	N: integer :=0 
--	PWM_COUNTER_MAX : integer :=256
 );
	port (
	clk : in std_logic; 
	PWMstate : in std_logic_vector(3 downto 0);
	iData : in std_logic_vector(N-1 downto 0); -- 8-6 bit data from SRAMtrunc
	rst : in std_logic;
	PWMSCL : out std_logic
);
	end component;
	
	component Counter2SRAM is 
	port (
	clk : in std_logic;
	M : integer:=0; -- Tuning Word M. This is decimal 
	state: in std_logic_vector(3 downto 0);
	rst : in std_logic;
	Q : OUT std_logic_vector(7 downto 0)
	);
	end component;
	
	component LCD_Controller2 is
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
	end component;
------Signals------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	signal reset_d							: std_logic;
   signal Counter_Reset        		: std_logic;	
	signal clock_enable_60ns			: std_logic;
	signal clock_enable_1sec			: std_logic;
	signal KEY0_db 						: std_logic;
	signal KEY2_db 						: std_logic;
	signal KEY3_db 						: std_logic;
	signal KEY1_db 						: std_logic;
	signal Qc								: std_logic_vector(7 downto 0); -- counter output
	signal Qr								: std_logic_vector(15 downto 0); -- Rom output
	
	
	signal mux_output_clken				: std_logic;
	signal mux_select_en					: std_logic_vector(1 downto 0);
	signal mux_output_en					: std_logic;
	signal mux_select_clken				: std_logic_vector(1 downto 0);
	signal mux_select_pulse				: std_logic_vector(1 downto 0);
	signal mux_output_pulse				: std_logic;
	signal Qstate							: std_logic_vector(3 downto 0);
	signal mux_select_RW					: std_logic_vector(1 downto 0);
	signal mux_output_RW					: std_logic;
	signal mux_select_datain			: std_logic_vector(1 downto 0);
	signal mux_output_datain			: std_logic_vector(15 downto 0);
	signal mux_select_TW					: std_logic_vector(3 downto 0);
	signal mux_output_TW        		: integer:=0;
	signal Qpc								: std_logic_vector(7 downto 0);
	
	signal mux_output_addrin: std_logic_vector(7 downto 0);
	signal SRAM2PWMtrunc60 : std_logic_vector(7 downto 0);
	signal SRAM2PWMtrunc120 : std_logic_vector(6 downto 0);
	signal SRAM2PWMtrunc1000 : std_logic_vector(5 downto 0);
	signal COUNTER2SRAMtrunc : std_logic_vector(7 downto 0);
	signal Qsc					 : std_logic_vector(7 downto 0);
	signal dataouttrunc		 : std_logic_vector(15 downto 0);
	
	signal M1 : integer:=5135;
	signal M2 : integer:=10307;
	signal M3 : integer:=85899;
	signal PWMSCL60 : STD_LOGIC;
	signal PWMSCL120 : STD_LOGIC;
	signal PWMSCL1000 : STD_LOGIC;
	signal mux_select_PWMSCLOUT : std_logic_vector(3 downto 0);
	signal mux_output_pwmin			: std_logic_vector(1 downto 0);
	signal mux_select_statein : std_logic_vector(3 downto 0);
	signal mux_output_statein : std_logic_vector(1 downto 0); 
	
	
	begin
--	COUNTER2SRAMtrunc <= Qsc(31 downto 24); -- 8 (31 downto 24)
	SRAM2PWMtrunc60 <= dataouttrunc(15 downto 8); -- 8 (15 downto 8)
	SRAM2PWMtrunc120 <= dataouttrunc(15 downto 9); -- 7 (15 downto 9)
	SRAM2PWMtrunc1000 <= dataouttrunc(15 downto 10); -- 6(15 downto 10)
	
----MUX------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	mux_select_RW <= Qstate(3 downto 2);
	process(mux_select_RW) 
	begin 
    case mux_select_RW is
        when "00" =>
            mux_output_RW <= '0'; -- write
		  when others =>
            mux_output_RW <= '1'; --reading
    end case;
	end process;
	
		-- states for LCD
	mux_select_statein <= Qstate(3 downto 0);
	process(mux_select_statein)
	begin
	 case mux_select_statein is
		  when "0011" =>
				mux_output_statein <= "00";
		  when "0111" =>
				mux_output_statein <= "01";
		  when "0110" =>
				mux_output_statein <= "10";
		  when others =>
				mux_output_statein <= "11";
	 end case;
	end process;
	
	-- Tuning Word (M) mux
	mux_select_TW <= Qstate(3 downto 0);
	process(mux_select_TW)
	begin
	 case mux_select_TW is
		  when "1001" =>
				mux_output_TW <= M1;
				mux_output_pwmin <= "00";
		  when "1010" =>
				mux_output_TW <= M2;
				mux_output_pwmin <= "01";
		  when "1011" =>
				mux_output_TW <= M3;
				mux_output_pwmin <= "10";
		  when others =>
				mux_output_TW <= 0;
	 end case;
	end process;
	
	-- not needed for now because they are all 6?
	mux_select_PWMSCLOUT <= Qstate(3 downto 0);
	process(mux_select_PWMSCLOUT)
	begin
	 case mux_select_PWMSCLOUT is 
	   when "1001" =>
			 PWMSCL <= PWMSCL60;
	   when "1010" =>
			 PWMSCL <= PWMSCL120;
		when "1011" =>
			 PWMSCL <= PWMSCL1000;
		when others =>
			 PWMSCL <= '0';
	 end case;
	end process;
	
	-- en mux (PAUSE_MODE LOGIC)
	mux_select_en <= Qstate(3 downto 2);
	process(mux_select_en, Qstate(0))
	begin
    case mux_select_en is
        when "00" | "01" =>
            mux_output_en <= Qstate(0);
        when others =>
            mux_output_en <= '0';
    end case;
	end process;
	
	-- clock_en mux
	mux_select_clken <= Qstate(3 downto 2);
	process(mux_select_clken, clock_enable_1sec, clock_enable_60ns) 
	begin 
    case mux_select_clken is
        when "00" =>
            mux_output_clken <= clock_enable_60ns;
        when "01" =>
            mux_output_clken <= clock_enable_1sec; 
        when others =>
            mux_output_clken <= '0';
    end case;
	end process;
	
	-- pulse mux not used until connected to SRAM
	mux_select_pulse <= Qstate(3 downto 2);
	process(mux_select_pulse, clock_enable_1sec, clock_enable_60ns)
	begin 
    case mux_select_pulse is
        when "00" =>
            mux_output_pulse <= clock_enable_60ns;
        when "01" =>
            mux_output_pulse <= clock_enable_1sec;
		  when "10" =>
				mux_output_pulse <= '1';
        when others =>
            mux_output_pulse <= '0';
    end case;
	end process;
	
	-- reading addr to SRAM from rom or SRAMcounter(M)
	mux_select_datain <= Qstate(3 downto 2);
	process(mux_select_datain, iClk) 
	begin 
    case mux_select_datain is
        when "10" =>
				mux_output_addrin <= Qsc; -- COUNTER2SRAMtrunc
		   when others =>
				mux_output_addrin <= Qc;
    end case;
	end process;
----INST------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
 Counter_Reset <= not KEY0_db or reset_d; 
			
	Inst_clk_Reset_Delay: Reset_Delay	
			port map(
			  iCLK 		=> iClk,	
			  oRESET    => reset_d
			);			

	-- clk value comfortable for user
	Inst_clk_enabler1sec: clk_enabler
			generic map(
			cnt_max 		=> 49999999) -- 49999999, 5 is 120 ns
			port map( 
			clock 		=> iClk, 			--  from system clock
			clk_en 		=> clock_enable_1sec  
			);
			
	Inst_clk_enabler60ns: clk_enabler
			generic map(
			cnt_max 		=> 2) -- 833333 or 3000
			port map( 
			clock 		=> iClk, 			
			clk_en 		=> clock_enable_60ns  
			);	
			
	Inst_univ_bin_counter: univ_bin_counter
		generic map(N => 8, N2 => 255, N1 => 0)
		port map(
			clk 			=> iClk,
			reset 		=> Counter_Reset,
			syn_clr		=> '0', 
			load			=> '0', 
			en				=> mux_output_en, 
			up				=> '1', 
			clk_en 		=> mux_output_clken, 
			d				=> (others => '0'),
		   max_tick		=> open, 
		   min_tick 	=> open,
			q				=> Qc 
		);

	inst_KEY0: btn_debounce_toggle
		GENERIC MAP( CNTR_MAX => X"0009") -- use X"FFFF" for implementation
		Port Map(
			BTN_I => KEY0,
			CLK => iClk,
			BTN_O => KEY0_db,
			TOGGLE_O => open,
			PULSE_O => open);

	inst_KEY1: btn_debounce_toggle
	GENERIC MAP( CNTR_MAX => X"0009") -- use X"FFFF" for implementation
	Port Map(
		BTN_I => KEY1,
		CLK => iClk,
		BTN_O => KEY1_db,
		TOGGLE_O => open,
		PULSE_O => open);

	inst_KEY2: btn_debounce_toggle
	GENERIC MAP( CNTR_MAX => X"0009") -- use X"FFFF" for implementation
	Port Map(
		BTN_I     => KEY2,
		CLK       => iClk,
		BTN_O     => KEY2_db,
		TOGGLE_O  => open,
		PULSE_O   => open);	

	inst_KEY3: btn_debounce_toggle
	GENERIC MAP( CNTR_MAX => X"0009") -- use X"FFFF" for implementation
	Port Map(
		BTN_I => KEY3,
		CLK => iClk,  
		BTN_O => KEY3_db,
		TOGGLE_O => open,
		PULSE_O => open);	
	
	Inst_State_Machine: StateMachine
	port map(
		clk 		 => iClk,
      reset 	 => Counter_Reset,
	   KEY0      => KEY0_db,
		KEY1 		 => KEY1_db,  
		KEY2 		 => KEY2_db,  		
		KEY3 		 => KEY3_db, 			  
      state_out => Qstate,
	   counter 	 => Qc );	

	
	Inst_Rom: Rom
	Port Map(
		address => Qc,
		clock   => iClk,
		q       => Qr );
		
	Inst_counter2sram: Counter2SRAM  
	port map(
		clk     => iClk,
		M       => mux_output_TW, -- Tuning Word M. 
		state   => Qstate,
		rst     => Counter_Reset,
		Q 	     => Qsc );
	
	Inst_I2c: i2c_usrLogic 
	PORT map(
		clk		  => iClk,
		iData  	  => dataouttrunc,
		scl		  => scl,
		sda		  => sda );             
	
	Inst_LCD: LCD_Controller2
    Port map(
        Clk      => iClk,
        Rst      => reset_d,
        iHex 	  => dataouttrunc,
		  iAddr    => Qc,
		  state_in => mux_output_statein,
		  pwm_in   => mux_output_pwmin,
        LCD_DATA => LCD_DATA,
        LCD_EN   => LCD_EN,
        LCD_RS   => LCD_RS );

	Inst_SRAM_Controller: SRAM_Controller
	port map(
		clk => iClk,
		reset      => Counter_Reset,
		pulse      => mux_output_pulse,		
		rw         => mux_output_RW, 			--hardwire to a switch, '0' for reading and '1' for writing
		address_in => mux_output_addrin,		--hardwire using switches in binary 0x00001
		data_in    => Qr,	--hardwire using switches in binary 0x0003 Qr????
		data_out   => dataouttrunc, 
		io         => SRAM_IO, --IN and OUT between SRAM and SRAM controller
		SRAM_addr  => SRAM_addr2SRAM,-- GOES TO SRAM addr but padded with X"000"
		ce_n       => SRAM_ce, 	-- GOES to SRAM BUT SHOULD BE TIED TO 0
		ub_n       => SRAM_ub,		-- GOES to SRAM BUT SHOULD BE TIED TO 0
		lb_n       => SRAM_lb,		-- GOES to SRAM BUT SHOULD BE TIED TO 0
		we_n       => SRAM_we,
		oe_n       => SRAM_oe ); 
		
	Inst_PWM60: PWM_Controller
	generic map(N => 8)
--	PWM_COUNTER_MAX  => 256)
	port map (
		clk      => iClk,
		PWMstate => Qstate,
		iData    => SRAM2PWMtrunc60, -- 8-6 bit data from SRAMtrunc
		rst      => Counter_Reset,
		PWMSCL   => PWMSCL60 );
	
	Inst_PWM120: PWM_Controller
	generic map(N => 7)
--	PWM_COUNTER_MAX  => 128)
	port map (
		clk      => iClk,
		PWMstate => Qstate,
		iData    => SRAM2PWMtrunc120, -- 8-6 bit data from SRAMtrunc
		rst      => Counter_Reset,
		PWMSCL   => PWMSCL120 );
	
	Inst_PWM1000: PWM_Controller 
	generic map(N => 6)
--	PWM_COUNTER_MAX  => 64)
	port map (
		clk      => iClk,
		PWMstate => Qstate,
		iData    => SRAM2PWMtrunc1000, -- 8-6 bit data from SRAMtrunc
		rst      => Counter_Reset,
		PWMSCL   => PWMSCL1000 );
		
end Structural;
