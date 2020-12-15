LIBRARY IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity snakepos is
	port (
--	    game_clk : IN std_logic := '0';
		reset : IN STD_LOGIC := '0';
		length_in : in integer range 0 to 50 := 1;
	    v_sync : IN STD_LOGIC;
		pixel_row : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
		pixel_col : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
		green : OUT STD_LOGIC;
		head_x : out integer;
        head_y : out integer;
		
		btn_up : IN STD_LOGIC;  
		btn_down : IN STD_LOGIC;
		btn_left : IN STD_LOGIC;
		btn_right : IN STD_LOGIC;
		btn_len : IN STD_LOGIC
	);
end snakepos;

architecture Behavioral of snakepos is
    constant snake_size : integer := 30;
    constant max_length : integer := 20;
    constant grid_size : integer := 18; --40 to 18
    constant boundary : integer := (grid_size-snake_size)/2;
    signal snake_on : std_logic := '0';
    type snake_pieces_array_type is array (0 to max_length, 0 to 2) of integer range 0 to 20; -- array of pieces where each piece contains 1 number for on or off and then the x,y grid coordinate
    signal snake_pieces : snake_pieces_array_type := ((1, 0, 0), others => (0,20,20));
    type int_array is array (0 to max_length) of integer range -1 to max_length;
    signal snake_order : int_array := (0, others => -1);
    shared variable head_pos : integer range 0 to max_length := 0;
    shared variable next_dir : std_logic_vector(3 downto 0) := "0100";
     
    -----------------------------------------------
    signal length_change : integer := 1;
    -----------------------------------------------
begin
green <= snake_on;
snake_drawing : process(pixel_row, pixel_col)
        function grid_to_pixel (grid_pos : integer range 0 to 20) return integer is
            variable pixel_coord : integer;
        begin
            pixel_coord := grid_pos*grid_size;
            return pixel_coord;
        end function grid_to_pixel;
    begin
    snake_on <= '0';
    draw_loop : for i in 0 to max_length loop
        if (snake_pieces(i, 0) = 1)
            and (CONV_INTEGER(pixel_col) > grid_to_pixel(snake_pieces(i, 1)))
            and (CONV_INTEGER(pixel_col) < grid_to_pixel(snake_pieces(i, 1)) + grid_size)
            and (CONV_INTEGER(pixel_row) > grid_to_pixel(snake_pieces(i, 2)))
            and (CONV_INTEGER(pixel_row) < grid_to_pixel(snake_pieces(i, 2)) + grid_size) then
                snake_on <= '1';
        end if;
    end loop draw_loop;
end Process;
snake_positioning : process -- TODO: add collision code some
    variable old_head : integer range 0 to max_length := 0;
    variable head_pos_in_snake_pieces_array : integer := snake_order(head_pos); -- get position of head from mapping array
    variable old_head_pos_in_snake_pieces_array : integer := snake_order(old_head); -- get position of old head from mapping array
begin
    wait until rising_edge(v_sync);
    old_head := head_pos;
    head_pos := (head_pos - 1) mod length_in;
    head_pos_in_snake_pieces_array := snake_order(head_pos);

    if head_pos_in_snake_pieces_array = -1 then
        head_pos_in_snake_pieces_array := 0;
    end if;
    old_head_pos_in_snake_pieces_array := snake_order(old_head);
    if old_head_pos_in_snake_pieces_array = -1 then
        old_head_pos_in_snake_pieces_array := 0;
    end if;
  
    if btn_left = '1' then         
        next_dir := "1000";        
    elsif btn_right = '1' then     
        next_dir := "0100";        
    elsif btn_up = '1' then        
        next_dir := "0010";        
    elsif btn_down = '1' then      
        next_dir := "0001";        
    end if;
    case next_dir is
        when "1000" => -- left
            snake_pieces(head_pos, 1) <= snake_pieces(old_head_pos_in_snake_pieces_array, 1) - 1;
            snake_pieces(head_pos_in_snake_pieces_array, 2) <= snake_pieces(old_head_pos_in_snake_pieces_array, 2);
        when "0100" => -- right
            snake_pieces(head_pos_in_snake_pieces_array, 1) <= snake_pieces(old_head_pos_in_snake_pieces_array, 1) + 1;
            snake_pieces(head_pos_in_snake_pieces_array, 2) <= snake_pieces(old_head_pos_in_snake_pieces_array, 2);
        when "0010" => -- up
            snake_pieces(head_pos_in_snake_pieces_array, 1) <= snake_pieces(old_head_pos_in_snake_pieces_array, 1);
            snake_pieces(head_pos_in_snake_pieces_array, 2) <= snake_pieces(old_head_pos_in_snake_pieces_array, 2) - 1;
        when "0001" => -- down
            snake_pieces(head_pos_in_snake_pieces_array, 1) <= snake_pieces(old_head_pos_in_snake_pieces_array, 1);
            snake_pieces(head_pos_in_snake_pieces_array, 2) <= snake_pieces(old_head_pos_in_snake_pieces_array, 2) + 1;
        when others => -- right
            snake_pieces(head_pos_in_snake_pieces_array, 1) <= snake_pieces(old_head_pos_in_snake_pieces_array, 1) + 1;
            snake_pieces(head_pos_in_snake_pieces_array, 2) <= snake_pieces(old_head_pos_in_snake_pieces_array, 2);
    end case;
    head_x <= snake_pieces(head_pos_in_snake_pieces_array, 1);
    head_y <= snake_pieces(head_pos_in_snake_pieces_array, 2);
end process;

button_length : process               
begin                                 
wait until rising_edge(btn_len);
length_change <= length_change +1;      
end process;                          

length_chng : process(length_change) --length_in to length_change
    variable snake_pieces_copy : snake_pieces_array_type := snake_pieces;
    variable tmp1 : integer := length_in - 1;
    variable tmp2 : integer := length_in - 1;
begin
    snake_pieces(length_in-1,0) <= 1; -- "turn on" new piece
    add_piece : for i in 0 to max_length loop --change order array to insert this piece
        if(i >= head_pos) then
            tmp2 := snake_order(i);
            snake_order(i) <= tmp1;
            tmp1 := tmp2;
        end if;
    end loop;
end process;
end Behavioral;