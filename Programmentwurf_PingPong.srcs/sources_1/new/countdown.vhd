----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.11.2025 15:48:34
-- Design Name: 
-- Module Name: countdown - Behavioral
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


----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.font.all;

entity countdown is
    port (
        clk               : in std_logic;
        pixel_x           : in unsigned(11 downto 0);
        pixel_y           : in unsigned(11 downto 0);

        countdown_active  : in std_logic;
        countdown_value   : in integer range 0 to 3;

        pixel_in_countdown : out std_logic
    );
end countdown;

architecture Behavioral of countdown is

    constant SCALE : integer := 12;
    constant W : integer := CHAR_WIDTH * SCALE;
    constant H : integer := CHAR_HEIGHT * SCALE;

    constant X0 : integer := (1920 - W)/2;
    constant Y0 : integer := (1080 - H)/2;

    signal pix : std_logic := '0';

begin

    pixel_in_countdown <= pix;

    process(pixel_x, pixel_y, countdown_active, countdown_value)
        variable x,y : integer;
        variable px,py : integer;
        variable glyph : std_logic_vector(CHAR_WIDTH-1 downto 0);
        variable bit : integer;
    begin
        pix <= '0';

        -- Countdown aus? → nichts anzeigen
        if (countdown_active = '1') and (countdown_value > 0) then

            x := to_integer(pixel_x);
            y := to_integer(pixel_y);

            if (x >= X0) and (x < X0+W) and
                (y >= Y0) and (y < Y0+H) then

                px := (x - X0) / SCALE;
                py := (y - Y0) / SCALE;

                glyph := FONT_ROM(48+countdown_value)(py);
                bit   := CHAR_WIDTH - 1 - px;

                if glyph(bit) = '1' then
                    pix <= '1';
                end if;
            end if;

        end if;

    end process;

end Behavioral;


