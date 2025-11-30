----------------------------------------------------------------------------------
-- Company: DHBW Ravensburg
-- Engineer: Sanley Aytacer
-- 
-- Create Date: 17.11.2025 18:00:19
-- Design Name: VGA Timing Generator 1920x1080@60Hz
-- Module Name: vga_sync - Behavioral
-- Project Name: Pingpong
-- Target Devices: Arty A7-35
-- Tool Versions: 2025.1
-- Description: 
--   Generates horizontal and vertical sync signals, active-video region and
--   current pixel coordinates for 1920x1080@60Hz based on a 148.5 MHz pixel
--   clock. Used as the timing base for all rendering.
--
-- Dependencies: 
--   - IEEE.STD_LOGIC_1164
--   - IEEE.NUMERIC_STD
--
-- Revision:
--   Revision 0.01 - File Created
--   Revision 0.02 - Adapted timing parameters for 1080p
--
-- Additional Comments:
--   The module outputs pixel_x and pixel_y counters that are used by the
--   renderer, startscreen, endscreen, score and countdown modules.
----------------------------------------------------------------------------------



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity vga_sync is
    port (
        clk      : in  std_logic;                -- Pixelclock (148.5 MHz)
        reset    : in  std_logic;

        hsync    : out std_logic;
        vsync    : out std_logic;

        active   : out std_logic;

        pixel_x  : out unsigned(11 downto 0);    -- 0..1919
        pixel_y  : out unsigned(11 downto 0)     -- 0..1079
    );
end vga_sync;

architecture Behavioral of vga_sync is

    --------------------------------------------------------------------
    -- 1920x1080@60Hz Timing
    --------------------------------------------------------------------
    constant H_VISIBLE  : integer := 1920;
    constant H_FP       : integer := 88;
    constant H_SYNC     : integer := 44;
    constant H_BP       : integer := 148;
    constant H_TOTAL    : integer := H_VISIBLE + H_FP + H_SYNC + H_BP;  -- 2200

    constant V_VISIBLE  : integer := 1080;
    constant V_FP       : integer := 4;
    constant V_SYNC     : integer := 5;
    constant V_BP       : integer := 36;
    constant V_TOTAL    : integer := V_VISIBLE + V_FP + V_SYNC + V_BP;  -- 1125

    constant H_POL : std_logic := '0';   -- active low
    constant V_POL : std_logic := '0';   -- active low

    --------------------------------------------------------------------
    -- Counter
    --------------------------------------------------------------------
    signal h_count : unsigned(11 downto 0) := (others => '0');
    signal v_count : unsigned(11 downto 0) := (others => '0');

begin

    --------------------------------------------------------------------
    -- Timing Generator
    --------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then

            if reset = '1' then
                h_count <= (others => '0');
                v_count <= (others => '0');

            else
                if to_integer(h_count) = H_TOTAL - 1 then
                    h_count <= (others => '0');

                    if to_integer(v_count) = V_TOTAL - 1 then
                        v_count <= (others => '0');
                    else
                        v_count <= v_count + 1;
                    end if;

                else
                    h_count <= h_count + 1;
                end if;

            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- HSYNC / VSYNC
    --------------------------------------------------------------------
    hsync <= H_POL when 
        (to_integer(h_count) >= H_VISIBLE + H_FP and
         to_integer(h_count) <  H_VISIBLE + H_FP + H_SYNC)
    else not H_POL;

    vsync <= V_POL when 
        (to_integer(v_count) >= V_VISIBLE + V_FP and
         to_integer(v_count) <  V_VISIBLE + V_FP + V_SYNC)
    else not V_POL;

    --------------------------------------------------------------------
    -- Display active area
    --------------------------------------------------------------------
    active <= '1' when
        (to_integer(h_count) < H_VISIBLE and
         to_integer(v_count) < V_VISIBLE)
    else '0';

    --------------------------------------------------------------------
    -- Output pixel coordinates
    --------------------------------------------------------------------
    pixel_x <= h_count;
    pixel_y <= v_count;

end Behavioral;