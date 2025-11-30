----------------------------------------------------------------------------------
-- Company: DHBW Ravensburg
-- Engineer: Pauline Barmettler
-- 
-- Create Date: 20.11.2025
-- Design Name: Pong Game Constants Package
-- Module Name: game_pkg - Package
-- Project Name: Pingpong
-- Target Devices: Arty A7-35
-- Tool Versions: 2025.1
-- Description: 
--   Common package for all game-related constants and types, such as frame
--   size, ball and paddle dimensions, initial positions, base speeds and
--   countdown timing. Shared between game_logic and renderer.
--
-- Dependencies: 
--   - IEEE.STD_LOGIC_1164
--
-- Revision:
--   Revision 0.01 - File Created
--   Revision 0.02 - Added countdown-related constants and ball start position
--
-- Additional Comments:
--   Centralizes "magic numbers" so resolution or gameplay tweaks can be done
--   in one place.
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- game_pkg.vhd
-- Gemeinsame Spielkonstanten für Game-Logic und Renderer
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package game_pkg is

    constant FRAME_WIDTH  : integer := 1920;
    constant FRAME_HEIGHT : integer := 1080;

    -- Ball
    constant BALL_SIZE    : integer := 18;
    constant BALL_SPEED_X : integer := 8;
    constant BALL_SPEED_Y : integer := 8;

    constant BALL_START_X : integer := FRAME_WIDTH/2 - BALL_SIZE/2;
    constant BALL_START_Y : integer := FRAME_HEIGHT/2 - BALL_SIZE/2;

    -- Paddles
    constant PADDLE_WIDTH  : integer := 24;
    constant PADDLE_HEIGHT : integer := 200;

    constant PADDLE_LEFT_X  : integer := 60;
    constant PADDLE_RIGHT_X : integer := FRAME_WIDTH - 60 - PADDLE_WIDTH;

    constant PADDLE_SPEED   : integer := 20;

    -- Countdown Dauer
    constant COUNTDOWN_TICKS : integer := 90;  

end package game_pkg;