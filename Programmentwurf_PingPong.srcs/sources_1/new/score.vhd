----------------------------------------------------------------------------------
-- Company: DHBW Ravensburg
-- Engineer: Pauline Barmettler 
-- 
-- Create Date: 20.11.2025
-- Design Name: Score and Lives HUD
-- Module Name: score - Behavioral
-- Project Name: Pingpong
-- Target Devices: Arty A7-35
-- Tool Versions: 2025.1
-- Description: 
--   Renders the HUD (Head-Up Display) consisting of:
--     - two-digit score for player 1 and 2
--     - up to three hearts for player 1 and 2 (lives)
--   Uses FONT_ROM for digits and HEART_FULL / HEART_EMPTY bitmaps from font.vhd.
--   Outputs pixel_in_score = '1' for all pixels belonging to HUD elements.
--
-- Dependencies: 
--   - IEEE.STD_LOGIC_1164
--   - IEEE.NUMERIC_STD
--   - font.vhd
--
-- Revision:
--   Revision 0.01 - File Created
--   Revision 0.02 - Added hearts rendering for lives
--
-- Additional Comments:
--   The renderer draws HUD pixels with a higher priority than background and
--   paddles, but below the endscreen overlay.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.font.all;

entity score is
    port (
        clk         : in  std_logic;
        pixel_x     : in  unsigned(11 downto 0);
        pixel_y     : in  unsigned(11 downto 0);

        score_p1    : in  integer range 0 to 99;
        score_p2    : in  integer range 0 to 99;

        lives_p1    : in  integer range 0 to 3;
        lives_p2    : in  integer range 0 to 3;

        pixel_in_score : out std_logic
    );
end score;


architecture Behavioral of score is

    --------------------------------------------------------------------
    -- Layout constants (must match font.vhd)
    --------------------------------------------------------------------
    constant SCALE : integer := SCORE_TEXT_SCALE;

    constant DIGIT_W : integer := CHAR_WIDTH  * SCALE;
    constant DIGIT_H : integer := CHAR_HEIGHT * SCALE;

    constant HEART_W : integer := HEART_WIDTH  * SCALE;
    constant HEART_H : integer := HEART_HEIGHT * SCALE;

    signal pixel_in_score_next : std_logic := '0';

begin

    --------------------------------------------------------------------
    -- calculates pixel_in_score_next
    --------------------------------------------------------------------
    process(pixel_x, pixel_y,
            score_p1, score_p2,
            lives_p1, lives_p2)

        variable x, y : integer;
        variable px, py : integer;
        variable glyph_row : std_logic_vector(CHAR_WIDTH-1 downto 0);
        variable heart_row : std_logic_vector(HEART_WIDTH-1 downto 0);
        variable bit_index : integer;

        -- two-digit temp values
        variable d1, d0 : integer;

    begin
        x := to_integer(pixel_x);
        y := to_integer(pixel_y);
        pixel_in_score_next <= '0';

        ------------------------------------------------------------
        -- PLAYER 1 SCORE (left)
        ------------------------------------------------------------
        d1 := score_p1 / 10;
        d0 := score_p1 mod 10;

        -- tens digit
        if (x >= P1_SCORE_X_START) and
           (x <  P1_SCORE_X_START + DIGIT_W) and
           (y >= SCORE_Y_START) and
           (y <  SCORE_Y_START + DIGIT_H) then

            px := (x - P1_SCORE_X_START) / SCALE;
            py := (y - SCORE_Y_START)    / SCALE;

            glyph_row := FONT_ROM(48 + d1)(py);
            bit_index := CHAR_WIDTH - 1 - px;

            if glyph_row(bit_index) = '1' then
                pixel_in_score_next <= '1';
            end if;
        end if;

        -- ones digit
        if (x >= P1_SCORE_X_START + DIGIT_W) and
           (x <  P1_SCORE_X_START + 2*DIGIT_W) and
           (y >= SCORE_Y_START) and
           (y <  SCORE_Y_START + DIGIT_H) then

            px := (x - (P1_SCORE_X_START + DIGIT_W)) / SCALE;
            py := (y - SCORE_Y_START)                / SCALE;

            glyph_row := FONT_ROM(48 + d0)(py);
            bit_index := CHAR_WIDTH - 1 - px;

            if glyph_row(bit_index) = '1' then
                pixel_in_score_next <= '1';
            end if;
        end if;

        ------------------------------------------------------------
        -- PLAYER 2 SCORE (right)
        ------------------------------------------------------------
        d1 := score_p2 / 10;
        d0 := score_p2 mod 10;

        -- tens digit
        if (x >= P2_SCORE_X_START) and
           (x <  P2_SCORE_X_START + DIGIT_W) and
           (y >= SCORE_Y_START) and
           (y <  SCORE_Y_START + DIGIT_H) then

            px := (x - P2_SCORE_X_START) / SCALE;
            py := (y - SCORE_Y_START)    / SCALE;

            glyph_row := FONT_ROM(48 + d1)(py);
            bit_index := CHAR_WIDTH - 1 - px;

            if glyph_row(bit_index) = '1' then
                pixel_in_score_next <= '1';
            end if;
        end if;

        -- ones digit
        if (x >= P2_SCORE_X_START + DIGIT_W) and
           (x <  P2_SCORE_X_START + 2*DIGIT_W) and
           (y >= SCORE_Y_START) and
           (y <  SCORE_Y_START + DIGIT_H) then

            px := (x - (P2_SCORE_X_START + DIGIT_W)) / SCALE;
            py := (y - SCORE_Y_START)                / SCALE;

            glyph_row := FONT_ROM(48 + d0)(py);
            bit_index := CHAR_WIDTH - 1 - px;

            if glyph_row(bit_index) = '1' then
                pixel_in_score_next <= '1';
            end if;
        end if;


        ------------------------------------------------------------
        -- PLAYER 1 HEARTS (3 hearts)
        ------------------------------------------------------------
        for i in 0 to 2 loop
            if (x >= P1_LIVES_X_START + i*HEART_W) and
               (x <  P1_LIVES_X_START + (i+1)*HEART_W) and
               (y >= LIVES_Y_START) and
               (y <  LIVES_Y_START + HEART_H) then

                px := (x - (P1_LIVES_X_START + i*HEART_W)) / SCALE;
                py := (y - LIVES_Y_START) / SCALE;

                if i < lives_p1 then
                    heart_row := HEART_FULL(py);
                else
                    heart_row := HEART_EMPTY(py);
                end if;

                bit_index := HEART_WIDTH - 1 - px;

                if heart_row(bit_index) = '1' then
                    pixel_in_score_next <= '1';
                end if;
            end if;
        end loop;

        ------------------------------------------------------------
        -- PLAYER 2 HEARTS (3 hearts)
        ------------------------------------------------------------
        for i in 0 to 2 loop
            if (x >= P2_LIVES_X_START + i*HEART_W) and
               (x <  P2_LIVES_X_START + (i+1)*HEART_W) and
               (y >= LIVES_Y_START) and
               (y <  LIVES_Y_START + HEART_H) then

                px := (x - (P2_LIVES_X_START + i*HEART_W)) / SCALE;
                py := (y - LIVES_Y_START) / SCALE;

                if i < lives_p2 then
                    heart_row := HEART_FULL(py);
                else
                    heart_row := HEART_EMPTY(py);
                end if;

                bit_index := HEART_WIDTH - 1 - px;

                if heart_row(bit_index) = '1' then
                    pixel_in_score_next <= '1';
                end if;
            end if;
        end loop;

    end process;

    --------------------------------------------------------------------
    -- Register levels
    --------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            pixel_in_score <= pixel_in_score_next;
        end if;
    end process;

end Behavioral;