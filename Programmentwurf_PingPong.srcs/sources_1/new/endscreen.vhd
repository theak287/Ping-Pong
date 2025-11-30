--endscreen.vhd: ----------------------------------------------------------------------------------
-- Company: DHBW Ravensburg
-- Engineer: Pauline Barmettler
-- 
-- Create Date: 20.11.2025
-- Design Name: 
-- Module Name: endscreen - Behavioral
-- Project Name: PingPong
-- Target Devices: Arty A7-35
-- Tool Versions: 2025.1
-- Description: 
--   Creates the text overlay for the end screen.
--   Displays:
--       "GAME OVER!"
--       "PLAYER X WON!"
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
--   Outputs only one signal: pixel_in_endtext
--   (set to '1' when the current pixel belongs to the end screen text).
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- endscreen.vhd
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.font.all;

entity endscreen is
    port (
        clk             : in  std_logic;
        pixel_x         : in  unsigned(11 downto 0);
        pixel_y         : in  unsigned(11 downto 0);
        show_endscreen  : in  std_logic;
        winner          : in  std_logic;   -- '0' = Player 1, '1' = Player 2
        pixel_in_endtext: out std_logic
    );
end endscreen;

architecture Behavioral of endscreen is

    signal pixel_in_endtext_next : std_logic := '0';

begin

    ----------------------------------------------------------------
    -- Kombinatorik: Endscreen-Text (GAME OVER! PLAYER X WINS)
    ----------------------------------------------------------------
    process(pixel_x, pixel_y, show_endscreen, winner)
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
        -- Standardmäßig: kein Endscreen-Pixel
        pixel_in_endtext_next <= '0';

        -- Nur zeichnen, wenn Endscreen aktiv ist
        if show_endscreen = '1' then

            hx := to_integer(pixel_x);
            vy := to_integer(pixel_y);

            if (hx >= END_TEXT_X_START) and
               (hx <  END_TEXT_X_START + TEXT_COLS * CHAR_WIDTH * END_TEXT_SCALE) and
               (vy >= END_TEXT_Y_START) and
               (vy <  END_TEXT_Y_START + TEXT_ROWS * CHAR_HEIGHT * END_TEXT_SCALE) then

                rel_x := hx - END_TEXT_X_START;
                rel_y := vy - END_TEXT_Y_START;

                char_col := rel_x / (CHAR_WIDTH * END_TEXT_SCALE);
                char_row := rel_y / (CHAR_HEIGHT * END_TEXT_SCALE);

                if (char_col >= 0) and (char_col < TEXT_COLS) and
                   (char_row >= 0) and (char_row < TEXT_ROWS) then

                    -- passenden Textscreen je nach Gewinner auswählen
                    if winner = '0' then
                        ch_code := END_TEXT_P1(char_row)(char_col);
                    else
                        ch_code := END_TEXT_P2(char_row)(char_col);
                    end if;

                    px_in_char := (rel_x mod (CHAR_WIDTH * END_TEXT_SCALE)) / END_TEXT_SCALE;
                    py_in_char := (rel_y mod (CHAR_HEIGHT * END_TEXT_SCALE)) / END_TEXT_SCALE;

                    ascii_idx := to_integer(unsigned(ch_code));

                    if (ascii_idx >= 0) and (ascii_idx <= 127) then
                        glyph_row := FONT_ROM(ascii_idx)(py_in_char);
                    else
                        glyph_row := (others => '0');
                    end if;

                    bit_index := CHAR_WIDTH - 1 - px_in_char;

                    if (bit_index >= 0) and (bit_index <= CHAR_WIDTH-1) then
                        if glyph_row(bit_index) = '1' then
                            pixel_in_endtext_next <= '1';
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------
    -- Registerstufe
    ----------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            pixel_in_endtext <= pixel_in_endtext_next;
        end if;
    end process;

end Behavioral;