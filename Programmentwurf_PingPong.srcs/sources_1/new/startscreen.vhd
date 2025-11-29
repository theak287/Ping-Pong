--startscreen.vhd: ----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.11.2025
-- Design Name: 
-- Module Name: startscreen - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
--   Creates the text overlay for the start screen.
--   Displays:
--       "WELCOME"
--       "PRESS BTN0 TO START"
--
-- Dependencies:
--   - font.vhd 
--       provides FONT_ROM, TEXT_ROM,
--       CHAR_WIDTH/HEIGHT, TEXT_COLS/ROWS,
--       and global constants for text position and scale
--
-- Revision:
--   Revision 0.01 - File Created
--
-- Additional Comments:
--   Instantiated inside renderer.vhd.
--   Outputs only one signal: pixel_in_starttext
--   (set to '1' when the current pixel belongs to the start screen text).
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- startscreen.vhd
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.font.all;

entity startscreen is
    port (
        clk               : in  std_logic;
        pixel_x           : in  unsigned(11 downto 0);  -- current pixel X
        pixel_y           : in  unsigned(11 downto 0);  -- current pixel Y
        pixel_in_starttext: out std_logic               -- '1' if this pixel is part of start text
    );
end startscreen;

architecture Behavioral of startscreen is

    signal pixel_in_starttext_next : std_logic := '0';

begin

    ----------------------------------------------------------------
    -- Kombinatorik: berechnet pixel_in_starttext_next
    ----------------------------------------------------------------
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
        pixel_in_starttext_next <= '0';

        hx := to_integer(pixel_x);
        vy := to_integer(pixel_y);

        if (hx >= START_TEXT_X_START) and
           (hx <  START_TEXT_X_START + TEXT_COLS * CHAR_WIDTH * START_TEXT_SCALE) and
           (vy >= START_TEXT_Y_START) and
           (vy <  START_TEXT_Y_START + TEXT_ROWS * CHAR_HEIGHT * START_TEXT_SCALE) then

            rel_x := hx - START_TEXT_X_START;
            rel_y := vy - START_TEXT_Y_START;

            char_col := rel_x / (CHAR_WIDTH * START_TEXT_SCALE);
            char_row := rel_y / (CHAR_HEIGHT * START_TEXT_SCALE);

            if (char_col >= 0) and (char_col < TEXT_COLS) and
               (char_row >= 0) and (char_row < TEXT_ROWS) then

                px_in_char := (rel_x mod (CHAR_WIDTH * START_TEXT_SCALE)) / START_TEXT_SCALE;
                py_in_char := (rel_y mod (CHAR_HEIGHT * START_TEXT_SCALE)) / START_TEXT_SCALE;

                -- get character code from TEXT_ROM
                ch_code := TEXT_ROM(char_row)(char_col);
                ascii_idx := to_integer(unsigned(ch_code));

                if (ascii_idx >= 0) and (ascii_idx <= 127) then
                    glyph_row := FONT_ROM(ascii_idx)(py_in_char);
                else
                    glyph_row := (others => '0');
                end if;

                bit_index := CHAR_WIDTH - 1 - px_in_char;

                if (bit_index >= 0) and (bit_index <= CHAR_WIDTH-1) then
                    if glyph_row(bit_index) = '1' then
                        pixel_in_starttext_next <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------
    -- Registerstufe: stabiler, getakteter Output
    ----------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            pixel_in_starttext <= pixel_in_starttext_next;
        end if;
    end process;

end Behavioral;