--score.vhd: ----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 20.11.2025
-- Design Name:
-- Module Name: score - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
--
-- Description:
--   Draws the HUD overlay (Score + Hearts) for both players.
--   Uses FONT_ROM and HEART glyphs from font.vhd.
--
-- Inputs:
--   - pixel_x, pixel_y     : current VGA pixel position
--   - score_p1, score_p2   : integer scores 0..99
--   - lives_p1, lives_p2   : 0..3 hearts
--
-- Output:
--   - pixel_in_score       : '1' when this pixel belongs to HUD
--
-- Dependencies:
--   - font.vhd (FONT_ROM, HEART_FULL, HEART_EMPTY)
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
    -- Kombinatorik: berechnet pixel_in_score_next
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
        -- PLAYER 1 SCORE (links)
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
        -- PLAYER 2 SCORE (rechts)
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
    -- Registerstufe
    --------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            pixel_in_score <= pixel_in_score_next;
        end if;
    end process;

end Behavioral;