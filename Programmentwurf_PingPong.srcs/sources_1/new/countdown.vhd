----------------------------------------------------------------------------------
-- Company: DHBW Ravensburg
-- Engineer: Thea Karwowski
-- 
-- Create Date: 26.11.2025 15:48:34
-- Design Name: Center Screen Countdown
-- Module Name: countdown - Behavioral
-- Project Name: Pingpong
-- Target Devices: Arty A7-35
-- Tool Versions: 2025.1
-- Description: 
--   Renders a large centered countdown digit (3, 2, 1) using FONT_ROM from
--   font.vhd. The countdown is controlled by:
--     - countdown_active : enables / disables the overlay
--     - countdown_value  : 3..1 selects the digit to draw
--   Outputs pixel_in_countdown = '1' for pixels belonging to the countdown.
--
-- Dependencies: 
--   - IEEE.STD_LOGIC_1164
--   - IEEE.NUMERIC_STD
--   - font.vhd
--
-- Revision:
--   Revision 0.01 - File Created
--
-- Additional Comments:
--   Used after each missed ball and on initial start, driven by game_logic via
--   countdown_active and countdown_value.
----------------------------------------------------------------------------------



----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.font.all;

entity countdown is
    port (
        clk                : in  std_logic;
        pixel_x            : in  unsigned(11 downto 0);
        pixel_y            : in  unsigned(11 downto 0);

        countdown_active   : in  std_logic;
        countdown_value    : in  integer range 0 to 3;

        pixel_in_countdown : out std_logic
    );
end countdown;

architecture Behavioral of countdown is

    --------------------------------------------------------------------
    -- Layout 
    --------------------------------------------------------------------
    constant SCALE : integer := 8;
    constant W     : integer := CHAR_WIDTH  * SCALE;
    constant H     : integer := CHAR_HEIGHT * SCALE;

    -- Centering
    constant X0 : integer := (1920 - W) / 2;
    constant Y0 : integer := (1080 - H)/2 - 150;

    signal pixel_in_countdown_next : std_logic := '0';

begin

    --------------------------------------------------------------------
    -- calculate pixel_in_countdown_next
    --------------------------------------------------------------------
    process(pixel_x, pixel_y, countdown_active, countdown_value)
        variable x, y      : integer;
        variable px, py    : integer;
        variable glyph_row : std_logic_vector(CHAR_WIDTH-1 downto 0);
        variable bit_index : integer;
        variable ascii_idx : integer;
    begin
        pixel_in_countdown_next <= '0';

        -- Countdown off or Value 0 → show nothing
        if (countdown_active = '1') and (countdown_value > 0) then

            x := to_integer(pixel_x);
            y := to_integer(pixel_y);

          
            if (x >= X0) and (x < X0 + W) and
               (y >= Y0) and (y < Y0 + H) then

                px := (x - X0) / SCALE;
                py := (y - Y0) / SCALE;

                ascii_idx := 48 + countdown_value;  -- '0' = 48

                -- Safety check for indices
                if (py >= 0) and (py < CHAR_HEIGHT) and
                   (ascii_idx >= 0) and (ascii_idx <= 127) then

                    glyph_row := FONT_ROM(ascii_idx)(py);

                    bit_index := CHAR_WIDTH - 1 - px;

                    if (bit_index >= 0) and (bit_index < CHAR_WIDTH) then
                        if glyph_row(bit_index) = '1' then
                            pixel_in_countdown_next <= '1';
                        end if;
                    end if;

                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Register level: stable, timed Output
    --------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            pixel_in_countdown <= pixel_in_countdown_next;
        end if;
    end process;

end Behavioral;
