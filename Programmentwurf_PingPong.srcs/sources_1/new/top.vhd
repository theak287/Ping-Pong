----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.11.2025 18:01:44
-- Design Name: 
-- Module Name: top - Behavioral
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

    ------------------------------------------------------
    -- CLOCK WIZARD: 148.5 MHz Pixelclock
    ------------------------------------------------------
    component clk_wiz_0
        port (
            CLK_IN1  : in  std_logic;
            RESET    : in  std_logic;
            CLK_OUT1 : out std_logic;
            LOCKED   : out std_logic
        );
    end component;

    signal pxl_clk    : std_logic;
    signal clk_locked : std_logic;

    --------------------------------------------------------------------
    -- VGA_SYNC
    --------------------------------------------------------------------
    component vga_sync
        port (
            clk      : in  std_logic;                -- Pixelclock (148.5 MHz)
            reset    : in  std_logic;

            hsync    : out std_logic;
            vsync    : out std_logic;

            active   : out std_logic;

            pixel_x  : out unsigned(11 downto 0);    -- 0..1919
            pixel_y  : out unsigned(11 downto 0)     -- 0..1079
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
            btn             : in  std_logic_vector(3 downto 0);

            ball_x          : out integer;
            ball_y          : out integer;
            paddle_left_y   : out integer;
            paddle_right_y  : out integer;

            score           : out integer;
            lives           : out integer;
            game_state      : out std_logic_vector(1 downto 0)
        );
    end component;

    signal ball_x_s, ball_y_s               : integer;
    signal paddle_left_y_s, paddle_right_y_s: integer;
    signal score_s, lives_s                 : integer;
    signal game_state_s                     : std_logic_vector(1 downto 0);

    --------------------------------------------------------------------
    -- RENDERER
    --------------------------------------------------------------------
    component renderer is
        port (
            clk         : in  std_logic;
            active      : in  std_logic;
            pixel_x     : in  unsigned(11 downto 0);
            pixel_y     : in  unsigned(11 downto 0);

            -- Startscreen / Game Umschaltung
            game_running    : in  std_logic;

            -- Inputs from game_logic
            ball_x          : in integer;
            ball_y          : in integer;
            paddle_left_y   : in integer;
            paddle_right_y  : in integer;

            -- VGA output
            vga_r : out std_logic_vector(3 downto 0);
            vga_g : out std_logic_vector(3 downto 0);
            vga_b : out std_logic_vector(3 downto 0)
        );
    end component;

    -- Steuersignal für Startscreen / Spiel
    signal game_running : std_logic := '0';

begin

    --------------------------------------------------------------------
    -- CLOCK WIZARD
    --------------------------------------------------------------------
    clk_inst : clk_wiz_0
        port map (
            CLK_IN1  => CLK_I,
            RESET    => '0',
            CLK_OUT1 => pxl_clk,
            LOCKED   => clk_locked
        );

    --------------------------------------------------------------------
    -- VGA_SYNC
    --------------------------------------------------------------------
    vga_inst : vga_sync
        port map (
            clk      => pxl_clk,
            reset    => '0',        -- falls gewünscht: SW(0) hier benutzen
            hsync    => VGA_HS_O,
            vsync    => VGA_VS_O,
            active   => active_s,
            pixel_x  => pixel_x,
            pixel_y  => pixel_y
        );

    --------------------------------------------------------------------
    -- GAME LOGIC
    --------------------------------------------------------------------
    game_inst : game_logic
        port map (
            clk_game        => pxl_clk,
            reset           => SW(0),   -- Reset über Schalter
            btn             => BTN,

            ball_x          => ball_x_s,
            ball_y          => ball_y_s,
            paddle_left_y   => paddle_left_y_s,
            paddle_right_y  => paddle_right_y_s,

            score           => score_s,
            lives           => lives_s,
            game_state      => game_state_s
        );

    --------------------------------------------------------------------
    -- SPIEL STARTEN: BTN(0) startet, SW(0) resettet
    --------------------------------------------------------------------
    process(pxl_clk)
    begin
        if rising_edge(pxl_clk) then
            if SW(0) = '1' then
                game_running <= '0';       -- Reset => zurück zum Startscreen
            elsif BTN(0) = '1' then
                game_running <= '1';       -- BTN0 => Spiel starten
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- RENDERER
    --------------------------------------------------------------------
    renderer_inst : renderer
        port map (
            clk         => pxl_clk,
            active      => active_s,
            pixel_x     => pixel_x,
            pixel_y     => pixel_y,

            game_running    => game_running,

            ball_x          => ball_x_s,
            ball_y          => ball_y_s,
            paddle_left_y   => paddle_left_y_s,
            paddle_right_y  => paddle_right_y_s,

            vga_r => VGA_R,
            vga_g => VGA_G,
            vga_b => VGA_B
        );

end Behavioral;
