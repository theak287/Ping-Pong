--game_pkg.vhd:----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 25.11.2025 22:52:00
-- Design Name: 
-- Module Name: game_pkg - Behavioral
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
    constant BALL_SPEED_X : integer := 6;
    constant BALL_SPEED_Y : integer := 6;

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