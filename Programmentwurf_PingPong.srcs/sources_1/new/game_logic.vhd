--game_logic.vhd: ---------------------------------------------------------------------------------
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
----------------------------------------------------------------------------------
-- GAME LOGIC (mit Start-/Restart-Countdown und Game-Over-Freeze)
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.game_pkg.all;

entity game_logic is
    port (
        clk_game        : in  std_logic;
        reset           : in  std_logic;
        game_enable     : in  std_logic;               -- aus top: game_running
        countdown_start : in  std_logic;               -- ebenfalls game_running
        BTN             : in  std_logic_vector(3 downto 0);

        ball_x          : out integer;
        ball_y          : out integer;
        paddle_left_y   : out integer;
        paddle_right_y  : out integer;

        score_left      : out integer;
        score_right     : out integer;

        lives_left      : out integer;
        lives_right     : out integer;

        game_state      : out std_logic_vector(1 downto 0);  -- 00=Welcome,10=Countdown,01=Play,11=GameOver

        countdown_value  : out integer range 0 to 3;          -- 3,2,1,0
        countdown_active : out std_logic                      -- '1' = Countdown sichtbar
    );
end entity;

architecture Behavioral of game_logic is

    --------------------------------------------------------------------
    -- interne Register
    --------------------------------------------------------------------
    -- Ball
    signal ball_x_reg : integer := BALL_START_X;
    signal ball_y_reg : integer := BALL_START_Y;
    signal ball_vx    : integer := 0;
    signal ball_vy    : integer := 0;

    -- Paddles
    signal paddle_left_y_reg  : integer := FRAME_HEIGHT/2 - PADDLE_HEIGHT/2;
    signal paddle_right_y_reg : integer := FRAME_HEIGHT/2 - PADDLE_HEIGHT/2;

    -- Score & Lives
    signal score_l  : integer := 0;
    signal score_r  : integer := 0;
    signal lives_l  : integer := 3;
    signal lives_r  : integer := 3;

    -- Game State
    -- 00 = Welcome / Idle
    -- 10 = Countdown
    -- 01 = Playing
    -- 11 = Game Over
    signal game_state_reg : std_logic_vector(1 downto 0) := "00";

    -- Tick ~ 60 FPS 
    signal tick_counter : unsigned(21 downto 0) := (others => '0');
    signal game_tick    : std_logic := '0';

    -- Countdown-Logik
    signal restart_counter      : integer := 0;                    -- Zähler in Ticks
    signal countdown_active_reg : std_logic := '0';
    signal countdown_val_reg    : integer range 0 to 3 := 0;

    -- um zu erkennen, dass das Spiel zum ersten Mal gestartet wurde
    signal started_once : std_logic := '0';

begin

    ----------------------------------------------------------------------------
    -- TICK-GENERATION
    ----------------------------------------------------------------------------
    process(clk_game)
    begin
        if rising_edge(clk_game) then
            if tick_counter = 2_500_000 then
                tick_counter <= (others => '0');
                game_tick    <= '1';
            else
                tick_counter <= tick_counter + 1;
                game_tick    <= '0';
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- MAIN GAME LOGIC
    ----------------------------------------------------------------------------
    process(clk_game)
    begin
        if rising_edge(clk_game) then

            --------------------------------------------------------------------
            -- GLOBAL RESET
            --------------------------------------------------------------------
            if reset = '1' then
                -- Ball & Velocity
                ball_x_reg <= BALL_START_X;
                ball_y_reg <= BALL_START_Y;
                ball_vx    <= 0;
                ball_vy    <= 0;

                -- Paddles
                paddle_left_y_reg  <= FRAME_HEIGHT/2 - PADDLE_HEIGHT/2;
                paddle_right_y_reg <= FRAME_HEIGHT/2 - PADDLE_HEIGHT/2;

                -- Score & Lives
                score_l <= 0;
                score_r <= 0;
                lives_l <= 3;
                lives_r <= 3;

                -- Countdown
                restart_counter      <= 0;
                countdown_active_reg <= '0';
                countdown_val_reg    <= 0;

                -- Game-Start-Flag
                started_once   <= '0';

                -- State: Welcome
                game_state_reg <= "00";

            --------------------------------------------------------------------
            -- KEIN RESET → Logik pro Tick
            --------------------------------------------------------------------
            elsif game_tick = '1' then

                ----------------------------------------------------------------
                -- FALL 1: SPIEL NOCH NICHT GESTARTET (Startscreen)
                ----------------------------------------------------------------
                if game_enable = '0' then
                    -- Wir sind im WELCOME-STATE
                    game_state_reg <= "00";

                    -- Alles in Ausgangsposition halten
                    ball_x_reg <= BALL_START_X;
                    ball_y_reg <= BALL_START_Y;
                    ball_vx    <= 0;
                    ball_vy    <= 0;

                    paddle_left_y_reg  <= FRAME_HEIGHT/2 - PADDLE_HEIGHT/2;
                    paddle_right_y_reg <= FRAME_HEIGHT/2 - PADDLE_HEIGHT/2;

                    -- Countdown aus
                    restart_counter      <= 0;
                    countdown_active_reg <= '0';
                    countdown_val_reg    <= 0;

                    -- „Start" darf später wieder erkannt werden
                    started_once <= '0';

                ----------------------------------------------------------------
                -- FALL 2: SPIEL GESTARTET (game_enable = '1')
                ----------------------------------------------------------------
                else

                    ----------------------------------------------------------------
                    -- 2a) GAME OVER?
                    ----------------------------------------------------------------
                    if (lives_l = 0) or (lives_r = 0) then
                        -- GAME OVER STATE
                        game_state_reg <= "11";

                        -- alles einfrieren und in Startposition legen
                        ball_x_reg <= BALL_START_X;
                        ball_y_reg <= BALL_START_Y;
                        ball_vx    <= 0;
                        ball_vy    <= 0;

                        paddle_left_y_reg  <= FRAME_HEIGHT/2 - PADDLE_HEIGHT/2;
                        paddle_right_y_reg <= FRAME_HEIGHT/2 - PADDLE_HEIGHT/2;

                        -- Countdown komplett aus
                        restart_counter      <= 0;
                        countdown_active_reg <= '0';
                        countdown_val_reg    <= 0;

                    ----------------------------------------------------------------
                    -- 2b) SPIEL LAUFEND, LEBEN > 0
                    ----------------------------------------------------------------
                    else
                        ----------------------------------------------------------------
                        -- ERSTER START NACH WELCOME → COUNTDOWN INITIALISIEREN
                        ----------------------------------------------------------------
                        if (started_once = '0') and (countdown_start = '1') then
                            restart_counter   <= COUNTDOWN_TICKS;  -- z.B. 90
                            started_once      <= '1';
                            -- Ball in Mitte, Startschnelligkeit setzen
                            ball_x_reg <= BALL_START_X;
                            ball_y_reg <= BALL_START_Y;
                            ball_vx    <= BALL_SPEED_X;
                            ball_vy    <= BALL_SPEED_Y;
                        end if;

                        ----------------------------------------------------------------
                        -- COUNTDOWN-PHASE (nach Start oder Miss)
                        ----------------------------------------------------------------
                        if restart_counter > 0 then
                            game_state_reg      <= "10";           -- Countdown
                            countdown_active_reg <= '1';

                            -- 3,2,1 aus Ticks ableiten (einfach in 3 Drittel teilen)
                            if restart_counter > (2*COUNTDOWN_TICKS)/3 then
                                countdown_val_reg <= 3;
                            elsif restart_counter > (COUNTDOWN_TICKS)/3 then
                                countdown_val_reg <= 2;
                            else
                                countdown_val_reg <= 1;
                            end if;

                            -- Counter runterzählen
                            restart_counter <= restart_counter - 1;

                            -- Ball in Mitte halten, Richtung vorbereiten
                            ball_x_reg <= BALL_START_X;
                            ball_y_reg <= BALL_START_Y;
                            -- ball_vx, ball_vy bleiben, aber keine echte Bewegung

                            ----------------------------------------------------------------
                            -- Du KANNST während des Countdowns die Paddles bewegen:
                            ----------------------------------------------------------------
                            if BTN(0) = '1' then
                                paddle_right_y_reg <= paddle_right_y_reg - PADDLE_SPEED;
                            elsif BTN(1) = '1' then
                                paddle_right_y_reg <= paddle_right_y_reg + PADDLE_SPEED;
                            end if;

                            if BTN(2) = '1' then
                                paddle_left_y_reg <= paddle_left_y_reg - PADDLE_SPEED;
                            elsif BTN(3) = '1' then
                                paddle_left_y_reg <= paddle_left_y_reg + PADDLE_SPEED;
                            end if;

                            -- Paddles clampen
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

                        ----------------------------------------------------------------
                        -- NORMALE SPIEL-PHASE (PLAY STATE)
                        ----------------------------------------------------------------
                        else
                            game_state_reg      <= "01";   -- PLAY
                            countdown_active_reg <= '0';
                            countdown_val_reg    <= 0;

                            ------------------------------------------------------------
                            -- FALLS BALL NOCH „tot" ist (z.B. nach Reset) → Startvektor
                            ------------------------------------------------------------
                            if (ball_vx = 0) and (ball_vy = 0) then
                                ball_vx <= BALL_SPEED_X;
                                ball_vy <= BALL_SPEED_Y;
                            end if;

                            ------------------------------------------------------------
                            -- PADDLE STEUERUNG
                            ------------------------------------------------------------
                            -- Rechtes Paddle
                            if BTN(0) = '1' then
                                paddle_right_y_reg <= paddle_right_y_reg - PADDLE_SPEED;
                            elsif BTN(1) = '1' then
                                paddle_right_y_reg <= paddle_right_y_reg + PADDLE_SPEED;
                            end if;

                            -- Linkes Paddle
                            if BTN(2) = '1' then
                                paddle_left_y_reg <= paddle_left_y_reg - PADDLE_SPEED;
                            elsif BTN(3) = '1' then
                                paddle_left_y_reg <= paddle_left_y_reg + PADDLE_SPEED;
                            end if;

                            -- Clamp Paddles
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

                            ------------------------------------------------------------
                            -- BALL-BEWEGUNG
                            ------------------------------------------------------------
                            ball_x_reg <= ball_x_reg + ball_vx;
                            ball_y_reg <= ball_y_reg + ball_vy;

                            ------------------------------------------------------------
                            -- WAND-KOLLISIONEN (oben / unten)
                            ------------------------------------------------------------
                            -- oben
                            if ball_y_reg <= 0 then
                                ball_y_reg <= -ball_y_reg;
                                ball_vy    <= -ball_vy;
                            end if;

                            -- unten
                            if (ball_y_reg + BALL_SIZE) >= FRAME_HEIGHT then
                                ball_y_reg <= 2*(FRAME_HEIGHT - BALL_SIZE) - ball_y_reg;
                                ball_vy    <= -ball_vy;
                            end if;

                            ------------------------------------------------------------
                            -- PADDLE-KOLLISIONEN (simple Spiegelung, Score++)
                            ------------------------------------------------------------
                            -- Linkes Paddle
                            if (ball_x_reg <= PADDLE_LEFT_X + PADDLE_WIDTH) and
                               (ball_x_reg + BALL_SIZE >= PADDLE_LEFT_X) and
                               (ball_y_reg + BALL_SIZE >= paddle_left_y_reg) and
                               (ball_y_reg <= paddle_left_y_reg + PADDLE_HEIGHT) then

                                ball_x_reg <= PADDLE_LEFT_X + PADDLE_WIDTH + 1;
                                ball_vx    <= abs(ball_vx);   -- Richtung nach rechts
                                score_l    <= score_l + 1;
                            end if;

                            -- Rechtes Paddle
                            if (ball_x_reg + BALL_SIZE >= PADDLE_RIGHT_X) and
                               (ball_x_reg <= PADDLE_RIGHT_X + PADDLE_WIDTH) and
                               (ball_y_reg + BALL_SIZE >= paddle_right_y_reg) and
                               (ball_y_reg <= paddle_right_y_reg + PADDLE_HEIGHT) then

                                ball_x_reg <= PADDLE_RIGHT_X - BALL_SIZE - 1;
                                ball_vx    <= -abs(ball_vx);  -- Richtung nach links
                                score_r    <= score_r + 1;
                            end if;

                            ------------------------------------------------------------
                            -- BALL AUS DEM FELD → GENAU 1 LEBEN WEG + COUNTDOWN
                            ------------------------------------------------------------
                            if ball_x_reg < -BALL_SIZE then
                                -- links verfehlt
                                if lives_l > 0 then
                                    lives_l <= lives_l - 1;
                                end if;

                                restart_counter   <= COUNTDOWN_TICKS;
                                -- Ball in Mitte vorbereiten
                                ball_x_reg <= BALL_START_X;
                                ball_y_reg <= BALL_START_Y;
                                ball_vx    <= BALL_SPEED_X;
                                ball_vy    <= BALL_SPEED_Y;

                            elsif ball_x_reg > FRAME_WIDTH + BALL_SIZE then
                                -- rechts verfehlt
                                if lives_r > 0 then
                                    lives_r <= lives_r - 1;
                                end if;

                                restart_counter   <= COUNTDOWN_TICKS;
                                -- Ball in Mitte vorbereiten
                                ball_x_reg <= BALL_START_X;
                                ball_y_reg <= BALL_START_Y;
                                ball_vx    <= BALL_SPEED_X;
                                ball_vy    <= BALL_SPEED_Y;
                            end if;

                        end if;  -- restart_counter > 0 ?
                    end if;      -- lives_l/r > 0 ?
                end if;          -- game_enable
            end if;              -- game_tick
        end if;                  -- rising_edge
    end process;

    ----------------------------------------------------------------------------
    -- OUTPUTS
    ----------------------------------------------------------------------------
    ball_x        <= ball_x_reg;
    ball_y        <= ball_y_reg;

    paddle_left_y  <= paddle_left_y_reg;
    paddle_right_y <= paddle_right_y_reg;

    score_left  <= score_l;
    score_right <= score_r;

    lives_left  <= lives_l;
    lives_right <= lives_r;

    game_state      <= game_state_reg;
    countdown_value  <= countdown_val_reg;
    countdown_active <= countdown_active_reg;

end architecture;
