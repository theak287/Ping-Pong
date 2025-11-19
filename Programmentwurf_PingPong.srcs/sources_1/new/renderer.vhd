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
use IEEE.NUMERIC_STD.ALL;

-- Startscreen-Package mit Font & Text
use work.startscreen.all;

entity renderer is
    port (
        clk     : in  std_logic;
        active  : in  std_logic;
        pixel_x : in  unsigned(11 downto 0);
        pixel_y : in  unsigned(11 downto 0);
        
        -- Startscreen / Game Umschaltung
        game_running    : in  std_logic;

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
    -- CONSTANTS SPIEL
    -------------------------------------------------------------------------
    constant BALL_SIZE      : integer := 18;  -- sichtbare Ballgröße in Pixel
    constant PADDLE_WIDTH   : integer := 24;  
    constant PADDLE_HEIGHT  : integer := 200;

    constant PADDLE_LEFT_X  : integer := 60;
    constant PADDLE_RIGHT_X : integer := 1920 - 60 - PADDLE_WIDTH;

    -------------------------------------------------------------------------
    -- CONSTANTS STARTSCREEN TEXT
    -------------------------------------------------------------------------
    constant TEXT_SCALE   : integer := 4;      -- Skalierung
    constant TEXT_X_START : integer := 640;    -- Startpixel X
    constant TEXT_Y_START : integer := 400;    -- Startpixel Y

    -------------------------------------------------------------------------
    -- PIXELMASKEN SPIEL
    -------------------------------------------------------------------------
    signal pixel_in_ball         : std_logic := '0';
    signal pixel_in_paddle_left  : std_logic := '0';
    signal pixel_in_paddle_right : std_logic := '0';
    
    signal pixel_in_midline : std_logic := '0';
    -------------------------------------------------------------------------
    -- PIXELMASKEN STARTSCREEN
    -------------------------------------------------------------------------
    signal pixel_in_text : std_logic := '0';

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
    -- Middle line
    -------------------------------------------------------------------------  
    pixel_in_midline <= '1' when
        (to_integer(pixel_x) = 1920/2) and    -- mittlere Spalte
        ((to_integer(pixel_y) mod 20) < 10)   -- Länge 10px, Pause 10px
    else
        '0';


    -------------------------------------------------------------------------
    -- STARTSCREEN TEXT-OVERLAY (FONT & TEXT aus startscreen-Package)
    -------------------------------------------------------------------------
    process(pixel_x, pixel_y)
        variable hx, vy          : integer;
        variable rel_x, rel_y    : integer;
        variable char_col        : integer;
        variable char_row        : integer;
        variable px_in_char      : integer;
        variable py_in_char      : integer;
        variable glyph_row       : std_logic_vector(CHAR_WIDTH-1 downto 0);
        variable bit_index       : integer;
        variable ch_code         : std_logic_vector(7 downto 0);
        variable ascii_idx       : integer;
    begin
        pixel_in_text <= '0';

        hx := to_integer(pixel_x);
        vy := to_integer(pixel_y);

        if (hx >= TEXT_X_START) and (hx < TEXT_X_START + TEXT_COLS*CHAR_WIDTH*TEXT_SCALE) and
           (vy >= TEXT_Y_START) and (vy < TEXT_Y_START + TEXT_ROWS*CHAR_HEIGHT*TEXT_SCALE) then

            rel_x := hx - TEXT_X_START;
            rel_y := vy - TEXT_Y_START;

            char_col := rel_x / (CHAR_WIDTH * TEXT_SCALE);
            char_row := rel_y / (CHAR_HEIGHT * TEXT_SCALE);

            if (char_col >= 0) and (char_col < TEXT_COLS) and
               (char_row >= 0) and (char_row < TEXT_ROWS) then

                px_in_char := (rel_x mod (CHAR_WIDTH * TEXT_SCALE)) / TEXT_SCALE;
                py_in_char := (rel_y mod (CHAR_HEIGHT * TEXT_SCALE)) / TEXT_SCALE;

                -- Zeichen aus Text-ROM holen
                ch_code := TEXT_ROM(char_row)(char_col);

                ascii_idx := to_integer(unsigned(ch_code));

                if ascii_idx >= 0 and ascii_idx <= 127 then
                    glyph_row := FONT_ROM(ascii_idx)(py_in_char);
                else
                    glyph_row := (others => '0');
                end if;

                bit_index := CHAR_WIDTH - 1 - px_in_char;

                if (bit_index >= 0) and (bit_index <= CHAR_WIDTH-1) then
                    if glyph_row(bit_index) = '1' then
                        pixel_in_text <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;


    -------------------------------------------------------------------------
    -- RGB-Ausgabe
    -- PRIORITÄT:
    --   1) Außerhalb active => schwarz
    --   2) Startscreen (game_running='0'): grüner Text
    --   3) Spiel (game_running='1'): Ball > Paddle > Hintergrund
    -------------------------------------------------------------------------
    process(active, game_running,
            pixel_in_text,
            pixel_in_ball, pixel_in_paddle_left, pixel_in_paddle_right)
    begin

        if active = '0' then
            -- Bereich außerhalb der aktiven Displayfläche
            vga_r <= (others => '0');
            vga_g <= (others => '0');
            vga_b <= (others => '0');

        elsif game_running = '0' then
            -- STARTSCREEN: grüner Text auf schwarzem Hintergrund
            if pixel_in_text = '1' then
                vga_r <= "0000";
                vga_g <= "1111";
                vga_b <= "0000";
            else
                vga_r <= "0000";
                vga_g <= "0000";
                vga_b <= "0000";
            end if;

        else
            -- SPIEL: Pong-Grafik
            if pixel_in_ball = '1' then
                -- BALL = ROT
                vga_r <= "1111";
                vga_g <= "1111";
                vga_b <= "1111";

            elsif pixel_in_paddle_left = '1' then
                -- LINKES PADDLE = ROT
                vga_r <= "1111";
                vga_g <= "0000";
                vga_b <= "0000";

            elsif pixel_in_paddle_right = '1' then
                -- RECHTES PADDLE = BLAU
                vga_r <= "0000";
                vga_g <= "0000";
                vga_b <= "1111";
            elsif pixel_in_midline = '1' then
                -- MITTELLINIE = WEISS
                vga_r <= "1111";
                vga_g <= "1111";
                vga_b <= "1111";



            else
                -- HINTERGRUND = SCHWARZ
                vga_r <= "0000";
                vga_g <= "0000";
                vga_b <= "0000";
            end if;
        end if;

    end process;

end Behavioral;
