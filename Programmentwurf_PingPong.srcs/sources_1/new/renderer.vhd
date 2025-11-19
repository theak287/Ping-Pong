----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.11.2025 18:00:19
-- Design Name: 
-- Module Name: renderer - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity renderer is
    port (
        clk     : in  std_logic;
        active  : in  std_logic;
        pixel_x : in  unsigned(11 downto 0);
        pixel_y : in  unsigned(11 downto 0);
        
        -- Inputs from game_logic
        ball_x        : in integer;
        ball_y        : in integer;
        paddle_left_y : in integer;
        paddle_right_y: in integer;

        -- VGA output
        vga_r : out std_logic_vector(3 downto 0);
        vga_g : out std_logic_vector(3 downto 0);
        vga_b : out std_logic_vector(3 downto 0)
    );
end renderer;


architecture Behavioral of renderer is
    -------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------
    constant BALL_SIZE      : integer := 18;  -- sichtbare Ballgröße in Pixel
    constant PADDLE_WIDTH   : integer := 24;  
    constant PADDLE_HEIGHT  : integer := 200;

    constant PADDLE_LEFT_X  : integer := 60;
    constant PADDLE_RIGHT_X : integer := 1920 - 60 - PADDLE_WIDTH;

    -------------------------------------------------------------------------
    -- PIXELMASK
    -------------------------------------------------------------------------
    signal pixel_in_ball         : std_logic := '0';
    signal pixel_in_paddle_left  : std_logic := '0';
    signal pixel_in_paddle_right : std_logic := '0';
begin

    -------------------------------------------------------------------------
    -- Ballmaske
    -------------------------------------------------------------------------
    pixel_in_ball <= '1' when
        (to_integer(pixel_x) >= ball_x) and
        (to_integer(pixel_x) <  ball_x + BALL_SIZE) and
        (to_integer(pixel_y) >= ball_y) and
        (to_integer(pixel_y) <  ball_y + BALL_SIZE)
    else
        '0';


    -------------------------------------------------------------------------
    -- Linkes Paddle
    -------------------------------------------------------------------------
    pixel_in_paddle_left <= '1' when
        (to_integer(pixel_x) >= PADDLE_LEFT_X) and
        (to_integer(pixel_x) <  PADDLE_LEFT_X + PADDLE_WIDTH) and
        (to_integer(pixel_y) >= paddle_left_y) and
        (to_integer(pixel_y) <  paddle_left_y + PADDLE_HEIGHT)
    else
        '0';


    -------------------------------------------------------------------------
    -- Rechtes Paddle
    -------------------------------------------------------------------------
    pixel_in_paddle_right <= '1' when
        (to_integer(pixel_x) >= PADDLE_RIGHT_X) and
        (to_integer(pixel_x) <  PADDLE_RIGHT_X + PADDLE_WIDTH) and
        (to_integer(pixel_y) >= paddle_right_y) and
        (to_integer(pixel_y) <  paddle_right_y + PADDLE_HEIGHT)
    else
        '0';


    -------------------------------------------------------------------------
    -- RGB-Ausgabe ( PRIORITÄT: Ball > Paddle > Hintergrund )
    -------------------------------------------------------------------------
    process(active, pixel_in_ball, pixel_in_paddle_left, pixel_in_paddle_right)
    begin

        if active = '0' then
            -- Bereich außerhalb der aktiven Displayfläche
            vga_r <= (others => '0');
            vga_g <= (others => '0');
            vga_b <= (others => '0');

        elsif pixel_in_ball = '1' then
            -- BALL = ROT
            vga_r <= "1111";
            vga_g <= "0000";
            vga_b <= "0000";

        elsif (pixel_in_paddle_left = '1') or (pixel_in_paddle_right = '1') then
            -- PADDLE = BLAU
            vga_r <= "0000";
            vga_g <= "0000";
            vga_b <= "1111";

        else
            -- HINTERGRUND = SCHWARZ
            vga_r <= "0000";
            vga_g <= "0000";
            vga_b <= "0000";
        end if;

    end process;

end Behavioral;