----------------------------------------------------------------------------------
-- Company: DHBW Ravensburg
-- Engineer: Thea Karwowski, Pauline Barmettler, Sanley Aytacer
-- 
-- Create Date: 17.11.2025 18:01:44
-- Design Name: FPGA Pong Game - Top Level
-- Module Name: top - Behavioral
-- Project Name: Pingpong
-- Target Devices: Arty A7-35
-- Tool Versions: 2025.1
-- Description: 
--   Top-level module of the Pong project. Instantiates clock wizard, VGA timing
--   (vga_sync), game logic (game_logic) and the renderer. Connects board
--   buttons, switches and VGA signals and wires all submodules together.
--
-- Dependencies: 
--   - clk_wiz_0 (Xilinx IP)
--   - vga_sync.vhd
--   - game_pkg.vhd
--   - game_logic.vhd
--   - font.vhd
--   - startscreen.vhd
--   - endscreen.vhd
--   - score.vhd
--   - countdown.vhd
--   - renderer.vhd
--
-- Revision:
--   Revision 0.01 - File Created
--   Revision 0.02 - Integrated game_logic, renderer and HUD
--   Revision 0.03 - Added countdown interface and endscreen wiring
--
-- Additional Comments:
--   This file defines the external interface to the FPGA board (clock, buttons,
--   switches and VGA output) and is the entry point for synthesis.
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- top.vhd 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
    port (
        CLK_I     : in  std_logic;                       -- 100 MHz system clock
        BTN       : in  std_logic_vector(3 downto 0);    -- BTN0..BTN3
        SW        : in  std_logic_vector(0 downto 0);    -- SW0 = RESET
        VGA_HS_O  : out std_logic;
        VGA_VS_O  : out std_logic;
        VGA_R     : out std_logic_vector(3 downto 0);
        VGA_G     : out std_logic_vector(3 downto 0);
        VGA_B     : out std_logic_vector(3 downto 0)
    );
end top;

architecture Behavioral of top is

    component clk_wiz_0
        port (
            CLK_IN1  : in  std_logic;
            RESET    : in  std_logic;
            CLK_OUT1 : out std_logic;
            LOCKED   : out std_logic
        );
    end component;

    signal pxl_clk      : std_logic;
    signal clk_locked   : std_logic;
    signal reset_global : std_logic;

    component vga_sync
        port (
            clk      : in  std_logic;
            reset    : in  std_logic;
            hsync    : out std_logic;
            vsync    : out std_logic;
            active   : out std_logic;
            pixel_x  : out unsigned(11 downto 0);
            pixel_y  : out unsigned(11 downto 0)
        );
    end component;

    signal pixel_x  : unsigned(11 downto 0);
    signal pixel_y  : unsigned(11 downto 0);
    signal active_s : std_logic;

    --------------------------------------------------------------------
    -- GAME LOGIC
    --------------------------------------------------------------------
    component game_logic is
        port (
            clk_game        : in  std_logic;
            reset           : in  std_logic;
            game_enable     : in  std_logic;   
            countdown_start : in  std_logic;               -- Startscreen → Countdown
            BTN             : in  std_logic_vector(3 downto 0);

            ball_x          : out integer;
            ball_y          : out integer;
            paddle_left_y   : out integer;
            paddle_right_y  : out integer;

            score_left      : out integer;
            score_right     : out integer;
            lives_left      : out integer;
            lives_right     : out integer;
            game_state      : out std_logic_vector(1 downto 0);
            
            countdown_value  : out integer range 0 to 3;
            countdown_active : out std_logic
        );
    end component;

    signal ball_x_s, ball_y_s                : integer;
    signal paddle_left_y_s, paddle_right_y_s : integer;
    signal score_left_s, score_right_s       : integer;
    signal lives_left_s, lives_right_s       : integer;
    signal game_state_s                      : std_logic_vector(1 downto 0);

    --------------------------------------------------------------------
    -- RENDERER
    --------------------------------------------------------------------
    component renderer is
        port (
            clk         : in  std_logic;
            active      : in  std_logic;
            pixel_x     : in  unsigned(11 downto 0);
            pixel_y     : in  unsigned(11 downto 0);

            game_running    : in  std_logic;
            show_endscreen  : in  std_logic;
            winner          : in  std_logic;
                       
            score_p1        : in  integer range 0 to 99;
            score_p2        : in  integer range 0 to 99;
            lives_p1        : in  integer range 0 to 3;
            lives_p2        : in  integer range 0 to 3;
            
            countdown_active : in std_logic;
            countdown_value  : in integer range 0 to 3;

            ball_x          : in integer;
            ball_y          : in integer;
            paddle_left_y   : in integer;
            paddle_right_y  : in integer;

            vga_r : out std_logic_vector(3 downto 0);
            vga_g : out std_logic_vector(3 downto 0);
            vga_b : out std_logic_vector(3 downto 0)
        );
    end component;

    signal game_running      : std_logic := '0';
    signal show_endscreen_s  : std_logic;
    signal winner_s          : std_logic;
    
    signal countdown_value_s  : integer range 0 to 3;
    signal countdown_active_s : std_logic;
    signal countdown_start_s  : std_logic;

    signal score_p1_hud      : integer range 0 to 99;
    signal score_p2_hud      : integer range 0 to 99;

begin

    clk_inst : clk_wiz_0
        port map (
            CLK_IN1  => CLK_I,
            RESET    => '0',
            CLK_OUT1 => pxl_clk,
            LOCKED   => clk_locked
        );

    reset_global <= SW(0) or (not clk_locked);

    vga_inst : vga_sync
        port map (
            clk      => pxl_clk,
            reset    => reset_global,
            hsync    => VGA_HS_O,
            vsync    => VGA_VS_O,
            active   => active_s,
            pixel_x  => pixel_x,
            pixel_y  => pixel_y
        );

game_inst : game_logic
    port map (
        clk_game        => pxl_clk,
        reset           => reset_global,
        game_enable     => game_running,
        countdown_start => game_running, 
        BTN             => BTN,

        ball_x          => ball_x_s,
        ball_y          => ball_y_s,
        paddle_left_y   => paddle_left_y_s,
        paddle_right_y  => paddle_right_y_s,

        score_left      => score_left_s,
        score_right     => score_right_s,
        lives_left      => lives_left_s,
        lives_right     => lives_right_s,
        game_state      => game_state_s,

        countdown_value  => countdown_value_s,
        countdown_active => countdown_active_s
    );


    -- BTN0 starts the Game
    process(pxl_clk)
    begin
        if rising_edge(pxl_clk) then
            if reset_global = '1' then
                game_running <= '0';
            elsif BTN(0) = '1' then
                game_running <= '1';
            end if;
        end if;
    end process;

    -- Endscreen & Winner
    show_endscreen_s <= '1' when (lives_left_s = 0) or (lives_right_s = 0) else '0';

    winner_s <= '0' when (lives_left_s > 0 and lives_right_s = 0) else
                '1' when (lives_right_s > 0 and lives_left_s = 0) else
                '0';

    -- Score clamping
    score_p1_hud <= 99 when score_left_s  > 99 else score_left_s;
    score_p2_hud <= 99 when score_right_s > 99 else score_right_s;

renderer_inst : renderer
    port map (
        clk         => pxl_clk,
        active      => active_s,
        pixel_x     => pixel_x,
        pixel_y     => pixel_y,

        game_running => game_running,
        show_endscreen => show_endscreen_s,
        winner         => winner_s,

        score_p1 => score_p1_hud,
        score_p2 => score_p2_hud,
        lives_p1 => lives_left_s,
        lives_p2 => lives_right_s,

        countdown_value  => countdown_value_s,
        countdown_active => countdown_active_s,

        ball_x        => ball_x_s,
        ball_y        => ball_y_s,
        paddle_left_y => paddle_left_y_s,
        paddle_right_y=> paddle_right_y_s,

        vga_r => VGA_R,
        vga_g => VGA_G,
        vga_b => VGA_B
    );



end Behavioral;