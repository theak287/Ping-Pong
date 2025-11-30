----------------------------------------------------------------------------------
-- Company: DHBW Ravensburg
-- Engineer: Thea Karwowski, Pauline Barmettler
-- 
-- Create Date: 17.11.2025 18:00:19
-- Design Name: Pong Renderer
-- Module Name: renderer - Behavioral
-- Project Name: Pingpong
-- Target Devices: Arty A7-35
-- Tool Versions: 2025.1
-- Description: 
--   Combines all visual layers and generates the final RGB output:
--     - start screen text
--     - end screen text
--     - countdown overlay
--     - score and lives HUD
--     - game scene (ball, paddles, midline, background)
--   Priority order: endscreen > countdown > HUD > ball > paddles > midline > background.
--
-- Dependencies: 
--   - IEEE.STD_LOGIC_1164
--   - IEEE.NUMERIC_STD
--   - font.vhd
--   - game_pkg.vhd
--   - startscreen.vhd
--   - endscreen.vhd
--   - score.vhd
--   - countdown.vhd
--
-- Revision:
--   Revision 0.01 - File Created
--   Revision 0.02 - Added midline and paddle coloring
--   Revision 0.03 - Integrated HUD, endscreen and countdown overlays
--
-- Additional Comments:
--   The renderer is purely combinational/sequential drawing logic and does not
--   implement any game rules.
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- renderer.vhd 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.font.all;
use work.game_pkg.all;

entity renderer is
    port (
        clk     : in  std_logic;
        active  : in  std_logic;
        pixel_x : in  unsigned(11 downto 0);
        pixel_y : in  unsigned(11 downto 0);

        -- Start / Running / End
        game_running    : in  std_logic;
        show_endscreen  : in  std_logic;
        winner          : in  std_logic;

        -- HUD
        score_p1        : in integer range 0 to 99;
        score_p2        : in integer range 0 to 99;
        lives_p1        : in integer range 0 to 3;
        lives_p2        : in integer range 0 to 3;

        -- Countdown
        countdown_active : in std_logic;
        countdown_value  : in integer range 0 to 3;

        -- Game objects
        ball_x        : in integer;
        ball_y        : in integer;
        paddle_left_y : in integer;
        paddle_right_y: in integer;

        -- VGA out
        vga_r : out std_logic_vector(3 downto 0);
        vga_g : out std_logic_vector(3 downto 0);
        vga_b : out std_logic_vector(3 downto 0)
    );
end renderer;


architecture Behavioral of renderer is

    ----------------------------------------------------------------------------
    -- Pixel masks
    ----------------------------------------------------------------------------
    signal pixel_in_ball         : std_logic := '0';
    signal pixel_in_paddle_left  : std_logic := '0';
    signal pixel_in_paddle_right : std_logic := '0';
    signal pixel_in_midline      : std_logic := '0';

    signal pixel_in_starttext    : std_logic := '0';
    signal pixel_in_endtext      : std_logic := '0';
    signal pixel_in_score        : std_logic := '0';
    signal pixel_in_countdown    : std_logic := '0';

    ----------------------------------------------------------------------------
    -- Sub-Renderers
    ----------------------------------------------------------------------------
    component startscreen is
        port (
            clk               : in  std_logic;
            pixel_x           : in  unsigned(11 downto 0);
            pixel_y           : in  unsigned(11 downto 0);
            pixel_in_starttext: out std_logic
        );
    end component;

    component endscreen is
        port (
            clk             : in  std_logic;
            pixel_x         : in  unsigned(11 downto 0);
            pixel_y         : in  unsigned(11 downto 0);
            show_endscreen  : in  std_logic;
            winner          : in  std_logic;
            pixel_in_endtext: out std_logic
        );
    end component;

    component score is
        port (
            clk         : in  std_logic;
            pixel_x     : in  unsigned(11 downto 0);
            pixel_y     : in  unsigned(11 downto 0);

            score_p1    : in integer range 0 to 99;
            score_p2    : in integer range 0 to 99;

            lives_p1    : in integer range 0 to 3;
            lives_p2    : in integer range 0 to 3;

            pixel_in_score : out std_logic
        );
    end component;

    component countdown is
        port (
            clk               : in  std_logic;
            pixel_x           : in  unsigned(11 downto 0);
            pixel_y           : in  unsigned(11 downto 0);

            countdown_active  : in  std_logic;
            countdown_value   : in  integer range 0 to 3;

            pixel_in_countdown : out std_logic
        );
    end component;


    signal r_reg, g_reg, b_reg : std_logic_vector(3 downto 0);

begin
    ----------------------------------------------------------------------------
    -- Startscreen
    ----------------------------------------------------------------------------
    startscreen_inst : startscreen
        port map (
            clk               => clk,
            pixel_x           => pixel_x,
            pixel_y           => pixel_y,
            pixel_in_starttext=> pixel_in_starttext
        );

    ----------------------------------------------------------------------------
    -- Endscreen
    ----------------------------------------------------------------------------
    endscreen_inst : endscreen
        port map (
            clk             => clk,
            pixel_x         => pixel_x,
            pixel_y         => pixel_y,
            show_endscreen  => show_endscreen,
            winner          => winner,
            pixel_in_endtext=> pixel_in_endtext
        );

    ----------------------------------------------------------------------------
    -- HUD (Score + Lives)
    ----------------------------------------------------------------------------
    score_inst : score
        port map (
            clk            => clk,
            pixel_x        => pixel_x,
            pixel_y        => pixel_y,
            score_p1       => score_p1,
            score_p2       => score_p2,
            lives_p1       => lives_p1,
            lives_p2       => lives_p2,
            pixel_in_score => pixel_in_score
        );

    ----------------------------------------------------------------------------
    -- Countdown
    ----------------------------------------------------------------------------
    countdown_inst : countdown
        port map (
            clk               => clk,
            pixel_x           => pixel_x,
            pixel_y           => pixel_y,
            countdown_active  => countdown_active,
            countdown_value   => countdown_value,
            pixel_in_countdown=> pixel_in_countdown
        );

    ----------------------------------------------------------------------------
    -- BALL
    ----------------------------------------------------------------------------
    pixel_in_ball <= '1' when
        (to_integer(pixel_x) >= ball_x) and
        (to_integer(pixel_x) <  ball_x + BALL_SIZE) and
        (to_integer(pixel_y) >= ball_y) and
        (to_integer(pixel_y) <  ball_y + BALL_SIZE)
    else '0';

    ----------------------------------------------------------------------------
    -- PADDLES
    ----------------------------------------------------------------------------
    pixel_in_paddle_left <= '1' when
        (to_integer(pixel_x) >= PADDLE_LEFT_X) and
        (to_integer(pixel_x) <  PADDLE_LEFT_X + PADDLE_WIDTH) and
        (to_integer(pixel_y) >= paddle_left_y) and
        (to_integer(pixel_y) <  paddle_left_y + PADDLE_HEIGHT)
    else '0';

    pixel_in_paddle_right <= '1' when
        (to_integer(pixel_x) >= PADDLE_RIGHT_X) and
        (to_integer(pixel_x) <  PADDLE_RIGHT_X + PADDLE_WIDTH) and
        (to_integer(pixel_y) >= paddle_right_y) and
        (to_integer(pixel_y) <  paddle_right_y + PADDLE_HEIGHT)
    else '0';

    ----------------------------------------------------------------------------
    -- MIDLINE (dashed)
    ----------------------------------------------------------------------------
    pixel_in_midline <= '1' when
        (to_integer(pixel_x) = FRAME_WIDTH/2) and
        ((to_integer(pixel_y) mod 20) < 10)
    else '0';


    ----------------------------------------------------------------------------
    -- RGB PRIORITY SYSTEM
    ----------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then

            if active = '0' then
                r_reg <= (others=>'0');
                g_reg <= (others=>'0');
                b_reg <= (others=>'0');

            elsif game_running = '0' then
                -- STARTSCREEN
                if pixel_in_starttext = '1' then
                    r_reg <= "0000"; g_reg <= "1111"; b_reg <= "0000";
                else
                    r_reg <= "0000"; g_reg <= "0000"; b_reg <= "0000";
                end if;

            else
                -- GAME MODE ==================================================

                ------------------------------------------------------------
                -- 1) ENDSCREEN (highest priority)
                ------------------------------------------------------------
                if pixel_in_endtext = '1' then
                    r_reg <= "1111"; g_reg <= "0000"; b_reg <= "0000"; -- red

                ------------------------------------------------------------
                -- 2) COUNTDOWN (shown over game but under endscreen)
                ------------------------------------------------------------
                elsif pixel_in_countdown = '1' then
                    r_reg <= "1111"; g_reg <= "1111"; b_reg <= "0000"; -- yellow

                ------------------------------------------------------------
                -- 3) HUD
                ------------------------------------------------------------
                elsif pixel_in_score = '1' then
                    r_reg <= "1111"; g_reg <= "1111"; b_reg <= "0000"; -- yellow

                ------------------------------------------------------------
                -- 4) BALL
                ------------------------------------------------------------
                elsif pixel_in_ball = '1' then
                    r_reg <= "1111"; g_reg <= "1111"; b_reg <= "1111"; -- white

                ------------------------------------------------------------
                -- 5) PADDLES
                ------------------------------------------------------------
                elsif pixel_in_paddle_left = '1' then
                    r_reg <= "0000"; g_reg <= "0000"; b_reg <= "1111"; -- blue

                elsif pixel_in_paddle_right = '1' then
                    r_reg <= "1111"; g_reg <= "0000"; b_reg <= "0000"; -- red

                ------------------------------------------------------------
                -- 6) MIDLINE
                ------------------------------------------------------------
                elsif pixel_in_midline = '1' then
                    r_reg <= "1111"; g_reg <= "1111"; b_reg <= "1111"; -- white

                ------------------------------------------------------------
                -- 7) BACKGROUND
                ------------------------------------------------------------
                else
                    r_reg <= "0000"; g_reg <= "0000"; b_reg <= "0000";
                end if;
            end if;

        end if;
    end process;

    vga_r <= r_reg;
    vga_g <= g_reg;
    vga_b <= b_reg;

end Behavioral;
