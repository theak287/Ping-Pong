--font.vhd: ----------------------------------------------------------------------------------
-- Company: DHBW Ravensburg
-- Engineer: Pauline Barmettler
--
-- Create Date: 20.11.2025
-- Design Name: 
-- Module Name: font - Package
-- Project Name: Programmentwurf_PingPong
-- Target Devices: Arty A7-35
-- Tool Versions: 2025.1
--
-- Description:
--   Central font and text library used by start screen, end screen and score.
--
--   Provides:
--     - FONT_ROM: bitmap definitions for all required ASCII characters
--     - TEXT_ROM: text lines for the start screen ("WELCOME", "PRESS BTN0 TO START")
--     - END_TEXT_P1 / END_TEXT_P2: text lines for the end screen
--         ("GAME OVER! PLAYER 1 WINS" / "PLAYER 2 WINS")
--     - Layout constants for start/end text and score / lives display.
--
--   Also defines:
--     - Character size (CHAR_WIDTH / CHAR_HEIGHT)
--     - Text layout (TEXT_COLS / TEXT_ROWS)
--     - Shared text position and scale constants
--         START_TEXT_SCALE, START_TEXT_X_START, START_TEXT_Y_START
--         END_TEXT_SCALE,   END_TEXT_X_START,   END_TEXT_Y_START
--         SCORE_TEXT_SCALE, SCORE/LIVES positions for P1 and P2
--
-- Dependencies:
--   None (self-contained package)
--
-- Revision:
--   Revision 0.03 - Extended with score/lives layout and digit/heart glyphs
--
-- Additional Comments:
--   Imported using:
--       use work.font.all;
--
--   This package contains only data and constants.
--   All pixel rendering logic is handled inside:
--       - startscreen.vhd
--       - endscreen.vhd
--       - (later) score.vhd
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package font is

  ----------------------------------------------------------------
  -- Character and text area constants
  ----------------------------------------------------------------
  constant CHAR_WIDTH   : integer := 8;   -- Font width  in font pixels
  constant CHAR_HEIGHT  : integer := 8;   -- Font height in font pixels

  constant TEXT_COLS    : integer := 20;  -- characters per line
  constant TEXT_ROWS    : integer := 4;   -- number of text lines

  ----------------------------------------------------------------
  -- Screen size and shared text layout (position and scale)
  ----------------------------------------------------------------
  constant SCREEN_WIDTH  : integer := 1920;
  constant SCREEN_HEIGHT : integer := 1080;

  -- Startscreen
  constant START_TEXT_SCALE   : integer := 4;
  constant START_TEXT_WIDTH   : integer := TEXT_COLS * CHAR_WIDTH  * START_TEXT_SCALE;
  constant START_TEXT_HEIGHT  : integer := TEXT_ROWS * CHAR_HEIGHT * START_TEXT_SCALE;
  constant START_TEXT_X_START : integer := (SCREEN_WIDTH  - START_TEXT_WIDTH)  / 2;
  constant START_TEXT_Y_START : integer := (SCREEN_HEIGHT - START_TEXT_HEIGHT) / 2;

  -- Endscreen
  constant END_TEXT_SCALE   : integer := 4;
  constant END_TEXT_WIDTH   : integer := TEXT_COLS * CHAR_WIDTH  * END_TEXT_SCALE;
  constant END_TEXT_HEIGHT  : integer := TEXT_ROWS * CHAR_HEIGHT * END_TEXT_SCALE;
  constant END_TEXT_X_START : integer := (SCREEN_WIDTH  - END_TEXT_WIDTH)  / 2;
  constant END_TEXT_Y_START : integer := (SCREEN_HEIGHT - END_TEXT_HEIGHT);

  ----------------------------------------------------------------
  -- Score and lives layout (top left / top right)
  ----------------------------------------------------------------
  -- Scale for score digits and hearts
  constant SCORE_TEXT_SCALE : integer := 2;

  -- Vertical position for score (both players)
  constant SCORE_Y_START : integer := 40;

  -- Player 1 score: near top-left
  constant P1_SCORE_X_START : integer := 40;

  -- Player 2 score: near top-right (reserve 2 digits)
  constant P2_SCORE_X_START : integer :=
      SCREEN_WIDTH - (2 * CHAR_WIDTH * SCORE_TEXT_SCALE) - 40;

  -- Vertical position for lives row (slightly below score)
  constant LIVES_Y_START : integer :=
      SCORE_Y_START + CHAR_HEIGHT * SCORE_TEXT_SCALE + 10;

  -- Player 1 lives (3 hearts) to the right of P1 score
  constant P1_LIVES_X_START : integer :=
      P1_SCORE_X_START + (2 * CHAR_WIDTH * SCORE_TEXT_SCALE) + 40;

  -- Player 2 lives (3 hearts) to the left of P2 score
  constant P2_LIVES_X_START : integer :=
      P2_SCORE_X_START - (3 * CHAR_WIDTH * SCORE_TEXT_SCALE) - 40;

  ----------------------------------------------------------------
  -- Types for font ROM and text ROMs
  ----------------------------------------------------------------
  type glyph_t is array (0 to CHAR_HEIGHT-1) of std_logic_vector(CHAR_WIDTH-1 downto 0);
  type font_t  is array (0 to 127) of glyph_t;  -- ASCII 0..127

  type text_line_t   is array (0 to TEXT_COLS-1) of std_logic_vector(7 downto 0);
  type text_screen_t is array (0 to TEXT_ROWS-1) of text_line_t;

  ----------------------------------------------------------------
  -- Heart glyph support (for score/lives)
  ----------------------------------------------------------------
  -- We reuse the same 8x8 resolution as the normal font.
  constant HEART_WIDTH  : integer := CHAR_WIDTH;
  constant HEART_HEIGHT : integer := CHAR_HEIGHT;

  type heart_t is array (0 to HEART_HEIGHT-1) of std_logic_vector(HEART_WIDTH-1 downto 0);

  ----------------------------------------------------------------
  -- Special character codes for hearts (used by score/lives logic)
  ----------------------------------------------------------------
  -- These refer to indices 3 and 4 in FONT_ROM below
  constant HEART_FULL_CODE  : std_logic_vector(7 downto 0) := x"03";  -- full heart
  constant HEART_EMPTY_CODE : std_logic_vector(7 downto 0) := x"04";  -- empty heart

  ----------------------------------------------------------------
  -- FONT_ROM: Bitmap for all used characters
  ----------------------------------------------------------------
  constant FONT_ROM : font_t := (
    ----------------------------------------------------------------
    -- Special symbols for lives (hearts) at indices 3 and 4
    ----------------------------------------------------------------
    -- HEART_FULL (3)
    3 => (
      "00000000",
      "01100110",
      "11111111",
      "11111111",
      "01111110",
      "00111100",
      "00011000",
      "00000000"
    ),

    -- HEART_EMPTY (4)
    4 => (
      "00000000",
      "01100110",
      "10011001",
      "10000001",
      "01000010",
      "00100100",
      "00011000",
      "00000000"
    ),

    ----------------------------------------------------------------
    -- Basic punctuation and digits
    ----------------------------------------------------------------
    -- space (32)
    32 => ( -- ' '
      "00000000",
      "00000000",
      "00000000",
      "00000000",
      "00000000",
      "00000000",
      "00000000",
      "00000000"
    ),

    -- '!' (33)
    33 => (
      "00001000",
      "00001000",
      "00001000",
      "00001000",
      "00001000",
      "00000000",
      "00001000",
      "00000000"
    ),

    -- '0' (48)
    48 => (
      "00111110",
      "01000011",
      "01000101",
      "01001001",
      "01010001",
      "01100001",
      "00111110",
      "00000000"
    ),

    -- '1' (49)
    49 => (
      "00001000",
      "00011000",
      "00001000",
      "00001000",
      "00001000",
      "00001000",
      "00011100",
      "00000000"
    ),

    -- '2' (50)
    50 => (
      "00111110",
      "01000001",
      "00000001",
      "00001110",
      "00110000",
      "01000000",
      "01111111",
      "00000000"
    ),

    -- '3' (51)
    51 => (
      "00111110",
      "01000001",
      "00000001",
      "00011110",
      "00000001",
      "01000001",
      "00111110",
      "00000000"
    ),

    -- '4' (52)
    52 => (
      "00000110",
      "00001010",
      "00010010",
      "00100010",
      "01111111",
      "00000010",
      "00000010",
      "00000000"
    ),

    -- '5' (53)
    53 => (
      "01111111",
      "01000000",
      "01111110",
      "00000001",
      "00000001",
      "01000001",
      "00111110",
      "00000000"
    ),

    -- '6' (54)
    54 => (
      "00111110",
      "01000000",
      "01111110",
      "01000001",
      "01000001",
      "01000001",
      "00111110",
      "00000000"
    ),

    -- '7' (55)
    55 => (
      "01111111",
      "00000001",
      "00000010",
      "00000100",
      "00001000",
      "00010000",
      "00010000",
      "00000000"
    ),

    -- '8' (56)
    56 => (
      "00111110",
      "01000001",
      "01000001",
      "00111110",
      "01000001",
      "01000001",
      "00111110",
      "00000000"
    ),

    -- '9' (57)
    57 => (
      "00111110",
      "01000001",
      "01000001",
      "00111111",
      "00000001",
      "00000001",
      "00111110",
      "00000000"
    ),

    ----------------------------------------------------------------
    -- Letters
    ----------------------------------------------------------------
    -- 'A' (65)
    65 => (
      "00011100",
      "00100010",
      "01000001",
      "01000001",
      "01111111",
      "01000001",
      "01000001",
      "00000000"
    ),

    -- 'B' (66)
    66 => (
      "01111110",
      "01000001",
      "01000001",
      "01111110",
      "01000001",
      "01000001",
      "01111110",
      "00000000"
    ),

    -- 'C' (67)
    67 => (
      "00111110",
      "01000001",
      "01000000",
      "01000000",
      "01000000",
      "01000001",
      "00111110",
      "00000000"
    ),

    -- 'E' (69)
    69 => (
      "01111111",
      "01000000",
      "01000000",
      "01111110",
      "01000000",
      "01000000",
      "01111111",
      "00000000"
    ),

    -- 'G' (71)
    71 => (
      "00111110",
      "01000001",
      "01000000",
      "01001111",
      "01000001",
      "01000001",
      "00111110",
      "00000000"
    ),

    -- 'I' (73)
    73 => (
      "00111110",
      "00001000",
      "00001000",
      "00001000",
      "00001000",
      "00001000",
      "00111110",
      "00000000"
    ),

    -- 'L' (76)
    76 => (
      "01000000",
      "01000000",
      "01000000",
      "01000000",
      "01000000",
      "01000000",
      "01111111",
      "00000000"
    ),

    -- 'M' (77)
    77 => (
      "01000001",
      "01100011",
      "01010101",
      "01001001",
      "01000001",
      "01000001",
      "01000001",
      "00000000"
    ),

    -- 'N' (78)
    78 => (
      "01000001",
      "01100001",
      "01010001",
      "01001001",
      "01000101",
      "01000011",
      "01000001",
      "00000000"
    ),

    -- 'O' (79)
    79 => (
      "00111110",
      "01000001",
      "01000001",
      "01000001",
      "01000001",
      "01000001",
      "00111110",
      "00000000"
    ),

    -- 'P' (80)
    80 => (
      "01111110",
      "01000001",
      "01000001",
      "01111110",
      "01000000",
      "01000000",
      "01000000",
      "00000000"
    ),

    -- 'R' (82)
    82 => (
      "01111110",
      "01000001",
      "01000001",
      "01111110",
      "01001000",
      "01000100",
      "01000010",
      "00000000"
    ),

    -- 'S' (83)
    83 => (
      "00111111",
      "01000000",
      "01000000",
      "00111110",
      "00000001",
      "00000001",
      "01111110",
      "00000000"
    ),

    -- 'T' (84)
    84 => (
      "01111111",
      "00001000",
      "00001000",
      "00001000",
      "00001000",
      "00001000",
      "00001000",
      "00000000"
    ),

    -- 'V' (86)
    86 => (
      "01000001",
      "01000001",
      "00100010",
      "00100010",
      "00010100",
      "00010100",
      "00001000",
      "00000000"
    ),

    -- 'W' (87)
    87 => (
      "01000001",
      "01000001",
      "01000001",
      "01001001",
      "01010101",
      "01100011",
      "01000001",
      "00000000"
    ),

    -- 'Y' (89)
    89 => (
      "01000001",
      "00100010",
      "00010100",
      "00001000",
      "00001000",
      "00001000",
      "00001000",
      "00000000"
    ),

    ----------------------------------------------------------------
    -- default: all other characters blank
    ----------------------------------------------------------------
    others => (
      "00000000","00000000","00000000","00000000",
      "00000000","00000000","00000000","00000000"
    )
  );

  ----------------------------------------------------------------
  -- Separate heart glyphs as heart_t arrays
  -- (used by score.vhd for lives display)
  ----------------------------------------------------------------
  constant HEART_FULL : heart_t := (
    "00000000",
    "01100110",
    "11111111",
    "11111111",
    "01111110",
    "00111100",
    "00011000",
    "00000000"
  );

  constant HEART_EMPTY : heart_t := (
    "00000000",
    "01100110",
    "10011001",
    "10000001",
    "01000010",
    "00100100",
    "00011000",
    "00000000"
  );

  ----------------------------------------------------------------
  -- TEXT_ROM for start screen:
  -- "WELCOME" and "PRESS BTN0 TO START"
  ----------------------------------------------------------------
  constant TEXT_ROM : text_screen_t := (
    0 => (
      x"20", x"20", x"20", x"20", x"20", x"20", x"20", x"57", -- "       W"
      x"45", x"4C", x"43", x"4F", x"4D", x"45", x"20", x"20", -- "ELCOME  "
      x"20", x"20", x"20", x"20"                              -- "    "
    ),
    1 => ( others => x"20" ), -- empty line
    2 => (
      x"20", x"50", x"52", x"45", x"53", x"53", x"20", x"42", -- " PRESS B"
      x"54", x"4E", x"30", x"20", x"54", x"4F", x"20", x"53", -- "TN0 TO S"
      x"54", x"41", x"52", x"54"                              -- "TART"
    ),
    3 => ( others => x"20" )
  );

  ----------------------------------------------------------------
  -- END_TEXT for end screen:
  -- "GAME OVER! PLAYER 1/2 WINS"
  ----------------------------------------------------------------
  constant END_TEXT_P1 : text_screen_t := (
    -- Line 0: "   GAME OVER!       "
    0 => (
      x"20", x"20", x"20",                -- "   "
      x"47", x"41", x"4D", x"45",         -- "GAME"
      x"20",                              -- " "
      x"4F", x"56", x"45", x"52",         -- "OVER"
      x"21",                              -- "!"
      x"20", x"20", x"20", x"20", x"20", x"20", x"20"  -- 7 spaces
    ),
    -- Line 1: "  PLAYER 1 WINS     "
    1 => (
      x"20", x"20",                       -- "  "
      x"50", x"4C", x"41", x"59", x"45", x"52", -- "PLAYER"
      x"20",                              -- " "
      x"31",                              -- "1"
      x"20",                              -- " "
      x"57", x"49", x"4E", x"53",         -- "WINS"
      x"20", x"20", x"20", x"20", x"20"   -- 5 spaces
    ),
    2 => (others => x"20"),
    3 => (others => x"20")
  );

  constant END_TEXT_P2 : text_screen_t := (
    -- Line 0: "   GAME OVER!       "
    0 => (
      x"20", x"20", x"20",
      x"47", x"41", x"4D", x"45",
      x"20",
      x"4F", x"56", x"45", x"52",
      x"21",
      x"20", x"20", x"20", x"20", x"20", x"20", x"20"
    ),
    -- Line 1: "  PLAYER 2 WINS     "
    1 => (
      x"20", x"20",
      x"50", x"4C", x"41", x"59", x"45", x"52", -- "PLAYER"
      x"20",
      x"32",                                    -- "2"
      x"20",
      x"57", x"49", x"4E", x"53",               -- "WINS"
      x"20", x"20", x"20", x"20", x"20"
    ),
    2 => (others => x"20"),
    3 => (others => x"20")
  );

end package font;