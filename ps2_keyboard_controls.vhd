LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_ARITH.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

ENTITY keyBoard IS
  GENERIC(
    clk_frequency              : INTEGER := 50_000_000; --system clock frequency in Hz
    debounce_counter_size : INTEGER := 8);         --set so that (2^size)/clk_freq = 5us (size = 8 for 50MHz)
  PORT(
    clk          : IN  STD_LOGIC;                          --system clock
    keyboard_clk      : IN  STD_LOGIC;                     --clock signal from PS/2 keyboard
    keyboard_data     : IN  STD_LOGIC;                     --data signal from PS/2 keyboard
    keyboard_code_new : OUT STD_LOGIC;                     --flag that new PS/2 code is available on keyboard_code bus
    keyboard_code     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)); --code received from PS/2
END keyBoard;

ARCHITECTURE logic OF keyBoard IS
  SIGNAL sync_ffs     : STD_LOGIC_VECTOR(1 DOWNTO 0);       --synchronizer flip-flops for PS/2 signals
  SIGNAL keyboard_clk_int  : STD_LOGIC;                          --debounced clock signal from PS/2 keyboard
  SIGNAL keyboard_data_int : STD_LOGIC;                          --debounced data signal from PS/2 keyboard
  SIGNAL keyboard_word     : STD_LOGIC_VECTOR(10 DOWNTO 0);      --stores the ps2 data word
  SIGNAL error        : STD_LOGIC;                          --validate parity, start, and stop bits
  SIGNAL count_idle   : INTEGER RANGE 0 TO clk_freq/18_000; --counter to determine PS/2 is idle
  
  --declare debounce component for debouncing PS2 input signals
  COMPONENT debounce IS
    GENERIC(
      counter_size : INTEGER); --debounce period (in seconds) = 2^counter_size/(clk freq in Hz)
    PORT(
      clk    : IN  STD_LOGIC;  --input clock
      button : IN  STD_LOGIC;  --input signal to be debounced
      result : OUT STD_LOGIC); --debounced signal
  END COMPONENT;
BEGIN

  --synchronizer inverts
  PROCESS(clk)
  BEGIN
    IF(clk'EVENT AND clk = '1') THEN  --rising edge of system clock
      sync_ffs(0) <= keyboard_clk;           --synchronize PS/2 clock signal
      sync_ffs(1) <= keyboard_data;          --synchronize PS/2 data signal
    END IF;
  END PROCESS;

  --debounce PS2 input signals
  debounce_keyboard_clk: debounce
    GENERIC MAP(counter_size => debounce_counter_size)
    PORT MAP(clk => clk, button => sync_ffs(0), result => keyboard_clk_int);
  debounce_keyboard_data: debounce
    GENERIC MAP(counter_size => debounce_counter_size)
    PORT MAP(clk => clk, button => sync_ffs(1), result => keyboard_data_int);

  --input keyboard data
  PROCESS(keyboard_clk_int)
  BEGIN
    IF(keyboard_clk_int'EVENT AND keyboard_clk_int = '0') THEN    --falling edge of PS2 clock
      keyboard_word <= keyboard_data_int & keyboard_word(10 DOWNTO 1);   --shift in PS2 data bit
    END IF;
  END PROCESS;
    
  --verify that parity, start, and stop bits are all correct
  error <= NOT (NOT keyboard_word(0) AND keyboard_word(10) AND (keyboard_word(9) XOR keyboard_word(8) XOR
        keyboard_word(7) XOR keyboard_word(6) XOR keyboard_word(5) XOR keyboard_word(4) XOR keyboard_word(3) XOR 
        keyboard_word(2) XOR keyboard_word(1)));  

  --determine if PS2 port is idle (i.e. last transaction is finished) and output result
  PROCESS(clk)
  BEGIN
    IF(clk'EVENT AND clk = '1') THEN           --rising edge of system clock
    
      IF(keyboard_clk_int = '0') THEN                 --low PS2 clock, PS/2 is active
        count_idle <= 0;                           --reset idle counter
      ELSIF(count_idle /= clk_freq/18_000) THEN  --PS2 clock has been high less than a half clock period (<55us)
          count_idle <= count_idle + 1;            --continue counting
      END IF;
      
      IF(count_idle = clk_freq/18_000 AND error = '0') THEN  --idle threshold reached and no errors detected
        keyboard_code_new <= '1';                                   --set flag that new PS/2 code is available
        keyboard_code <= keyboard_word(8 DOWNTO 1);                      --output new PS/2 code
      ELSE                                                   --PS/2 port active or error detected
        keyboard_code_new <= '0';                                   --set flag that PS/2 transaction is in progress
      END IF;
      
    END IF;
  END PROCESS;
  
END logic;
