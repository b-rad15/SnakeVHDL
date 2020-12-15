----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/12/2020 01:10:11 PM
-- Design Name: 
-- Module Name: snakedraw - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity snakedraw is
  Port (
        clk_in : IN STD_LOGIC; -- system clock
        VGA_red : OUT STD_LOGIC_VECTOR (3 DOWNTO 0); -- VGA outputs
        VGA_green : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
        VGA_blue : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
        VGA_hsync : OUT STD_LOGIC;
        VGA_vsync : OUT STD_LOGIC;
        
        btn_up : IN STD_LOGIC;  
		btn_down : IN STD_LOGIC;
		btn_left : IN STD_LOGIC;
		btn_right : IN STD_LOGIC;
		btn_len : IN STD_LOGIC

   );
end snakedraw;

architecture Behavioral of snakedraw is
    SIGNAL pxl_clk : STD_LOGIC := '0'; -- 25 MHz clock to VGA sync module
    -- internal signals to connect modules
    SIGNAL S_red, S_green, S_blue : STD_LOGIC; --_VECTOR (3 DOWNTO 0);
    SIGNAL S_vsync : STD_LOGIC;
    SIGNAL S_pixel_row, S_pixel_col : STD_LOGIC_VECTOR (10 DOWNTO 0);
    --signal S_next_dir : std_logic_vector (3 downto 0) := "0100"; -- start our going right
    -- snake out signals
    signal head_x, head_y : integer := 0;
    -- control signal
    signal S_rst : std_logic := '0';
    -----------------------------------------------
    signal S_length : integer := 1;
    -----------------------------------------------

    COMPONENT vga_sync IS
        PORT (
            pixel_clk : IN STD_LOGIC;
            red_in    : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
            green_in  : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
            blue_in   : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
            red_out   : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
            green_out : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
            blue_out  : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
            hsync : OUT STD_LOGIC;
            vsync : OUT STD_LOGIC;
            pixel_row : OUT STD_LOGIC_VECTOR (10 DOWNTO 0);
            pixel_col : OUT STD_LOGIC_VECTOR (10 DOWNTO 0)
        );
    END COMPONENT;

    component clk_wiz_0 is
    port (
      clk_in1  : in std_logic;
      clk_out1 : out std_logic
    );
    end component;
    
    component snakepos is
        port (
            reset : IN STD_LOGIC := '0';
            length_in : in integer range 0 to 50 := 1;
            v_sync : IN STD_LOGIC := '0';
            pixel_row : IN STD_LOGIC_VECTOR(10 DOWNTO 0) := (others => '0');
            pixel_col : IN STD_LOGIC_VECTOR(10 DOWNTO 0) := (others => '0');
            green : OUT STD_LOGIC;
            head_x : out integer;
            head_y : out integer;
            
            btn_up : IN STD_LOGIC;  
		    btn_down : IN STD_LOGIC;
		    btn_left : IN STD_LOGIC;
		    btn_right : IN STD_LOGIC;
		    btn_len : IN STD_LOGIC
        );
    end component;
begin

    vga_driver : vga_sync
    PORT MAP(--instantiate vga_sync component
        pixel_clk => pxl_clk, 
        red_in => S_red & "000", 
        green_in => S_green & "000", 
        blue_in => S_blue & "000", 
        red_out => VGA_red, 
        green_out => VGA_green, 
        blue_out => VGA_blue, 
        pixel_row => S_pixel_row, 
        pixel_col => S_pixel_col, 
        hsync => VGA_hsync, 
        vsync => S_vsync
    );
    VGA_vsync <= S_vsync; --connect output vsync
    
    snake_pos_and_draw : snakepos
    port map(
        reset => S_rst,
        length_in => 1, ---1 to S_length----------------
        v_sync => S_vsync,
        pixel_row => S_pixel_row,
        pixel_col => S_pixel_col,
        green => S_green,
        head_x => head_x,
        head_y => head_y,
        
        btn_up => btn_up,
        btn_down => btn_down,
        btn_left => btn_left,
        btn_right => btn_right,
        btn_len => btn_len
        
    );
    
     clk_wiz_0_inst : clk_wiz_0
    port map (
      clk_in1 => clk_in,
      clk_out1 => pxl_clk
    );

end Behavioral;