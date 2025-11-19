----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.11.2025 18:00:19
-- Design Name: 
-- Module Name: game_logic - Behavioral
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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity game_logic is
    port (
        clk_game  : in  std_logic;                      -- z.B. euer game-tick-Clock
        reset     : in  std_logic;                      -- aktiver Reset (z.B. SW0)

        BTN       : in  std_logic_vector(3 downto 0);   -- BTN0..BTN3

        ball_x        : out integer;
        ball_y        : out integer;
        paddle_left_y : out integer;
        paddle_right_y: out integer;

        score      : out integer;
        lives      : out integer;
        game_state : out std_logic_vector(1 downto 0)   -- 00=Welcome, 01=Playing, 10=Pause, 11=GameOver
    );
end game_logic;

architecture Behavioral of game_logic is

    constant FRAME_WIDTH  : integer := 1920;
    constant FRAME_HEIGHT : integer := 1080;

    constant BALL_SIZE      : integer := 18;
    constant PADDLE_HEIGHT  : integer := 200;
    
    constant PADDLE_SPEED : integer := 10;  -- Geschwindigkeit in Pixel pro Tick


    -- interne Register
    signal ball_x_reg        : integer := FRAME_WIDTH/2 - BALL_SIZE/2;
    signal ball_y_reg        : integer := FRAME_HEIGHT/2 - BALL_SIZE/2;
    signal paddle_left_y_reg : integer := FRAME_HEIGHT/2 - PADDLE_HEIGHT/2;
    signal paddle_right_y_reg: integer := FRAME_HEIGHT/2 - PADDLE_HEIGHT/2;

    signal score_reg : integer := 0;
    signal lives_reg : integer := 3;
    signal state_reg : std_logic_vector(1 downto 0) := "01";  -- direkt PLAYING
    
    signal tick_counter : unsigned(19 downto 0) := (others => '0');
    signal game_tick    : std_logic := '0';
    


begin

    ----------------------------------------------------------------
    -- Einfache synchrone Logik: aktuell nur Reset, keine Bewegung
    ----------------------------------------------------------------
    process(clk_game)
    begin
    if rising_edge(clk_game) then

        --------------------------------------------------------------------
        -- GLOBAL RESET
        --------------------------------------------------------------------
        if reset = '1' then

            -- Paddle & Ball in die Mitte setzen
            ball_x_reg        <= FRAME_WIDTH/2 - BALL_SIZE/2;
            ball_y_reg        <= FRAME_HEIGHT/2 - BALL_SIZE/2;
            paddle_left_y_reg <= FRAME_HEIGHT/2 - PADDLE_HEIGHT/2;
            paddle_right_y_reg<= FRAME_HEIGHT/2 - PADDLE_HEIGHT/2;

            -- Spielwerte zurücksetzen
            score_reg <= 0;
            lives_reg <= 3;
            state_reg <= "00";  -- WELCOME oder IDLE

            -- Tick zurücksetzen
            tick_counter <= (others => '0');
            game_tick    <= '0';


        --------------------------------------------------------------------
        -- GAME TICK GENERIEREN (~150 Hz)
        --------------------------------------------------------------------
        else

            if tick_counter = 500000 then    -- 148.5 MHz / 500000 ≈ 297 Hz (angepasst danach)
                tick_counter <= (others => '0');
                game_tick <= '1';
            else
                tick_counter <= tick_counter + 1;
                game_tick <= '0';
            end if;


            ----------------------------------------------------------------
            -- SPIELAKTIONEN NUR BEI game_tick
            ----------------------------------------------------------------
            if game_tick = '1' then

                ----------------------------------------------------------------
                -- RECHTES PADDLE (BTN0 hoch, BTN1 runter)
                ----------------------------------------------------------------
                if BTN(0) = '1' then
                    paddle_right_y_reg <= paddle_right_y_reg - PADDLE_SPEED;
                elsif BTN(1) = '1' then
                    paddle_right_y_reg <= paddle_right_y_reg + PADDLE_SPEED;
                end if;


                ----------------------------------------------------------------
                -- LINKES PADDLE (BTN2 hoch, BTN3 runter)
                ----------------------------------------------------------------
                if BTN(2) = '1' then
                    paddle_left_y_reg <= paddle_left_y_reg - PADDLE_SPEED;
                elsif BTN(3) = '1' then
                    paddle_left_y_reg <= paddle_left_y_reg + PADDLE_SPEED;
                end if;


                ----------------------------------------------------------------
                -- CLAMPING (oben/unten stoppen)
                ----------------------------------------------------------------
                if paddle_left_y_reg < 0 then
                    paddle_left_y_reg <= 0;
                elsif paddle_left_y_reg > FRAME_HEIGHT - PADDLE_HEIGHT then
                    paddle_left_y_reg <= FRAME_HEIGHT - PADDLE_HEIGHT;
                end if;

                if paddle_right_y_reg < 0 then
                    paddle_right_y_reg <= 0;
                elsif paddle_right_y_reg > FRAME_HEIGHT - PADDLE_HEIGHT then
                    paddle_right_y_reg <= FRAME_HEIGHT - PADDLE_HEIGHT;
                end if;

            end if;  -- game_tick

        end if;  -- reset

    end if;  -- rising_edge
end process;


    ----------------------------------------------------------------
    -- Outputs verdrahten
    ----------------------------------------------------------------
    ball_x        <= ball_x_reg;
    ball_y        <= ball_y_reg;
    paddle_left_y <= paddle_left_y_reg;
    paddle_right_y<= paddle_right_y_reg;

    score      <= score_reg;
    lives      <= lives_reg;
    game_state <= state_reg;

end Behavioral;

