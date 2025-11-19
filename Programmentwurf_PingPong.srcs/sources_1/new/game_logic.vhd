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
    constant PADDLE_WIDTH   : integer := 24;  
    constant PADDLE_HEIGHT  : integer := 200;

    constant PADDLE_LEFT_X  : integer := 60;
    constant PADDLE_RIGHT_X : integer := 1920 - 60 - PADDLE_WIDTH;
    
    constant PADDLE_SPEED : integer := 10;  -- Geschwindigkeit in Pixel pro Tick

    -- Starting values
    constant BALL_START_X : integer := FRAME_WIDTH/2 - BALL_SIZE/2;
    constant BALL_START_Y : integer := FRAME_HEIGHT/2 - BALL_SIZE/2;

    constant BALL_SPEED_X : integer := 6;
    constant BALL_SPEED_Y : integer := 4;

    -- Ballspeed
    signal ball_vx : integer := 0;
    signal ball_vy : integer := 0;


    -- internal Register
    signal ball_x_reg        : integer := FRAME_WIDTH/2 - BALL_SIZE/2;
    signal ball_y_reg        : integer := FRAME_HEIGHT/2 - BALL_SIZE/2;
    signal paddle_left_y_reg : integer := FRAME_HEIGHT/2 - PADDLE_HEIGHT/2;
    signal paddle_right_y_reg: integer := FRAME_HEIGHT/2 - PADDLE_HEIGHT/2;

    signal score_reg : integer := 0;
    signal lives_reg : integer := 3;
    signal state_reg : std_logic_vector(1 downto 0) := "01";  -- direct PLAYING
    
    signal tick_counter : unsigned(21 downto 0) := (others => '0');
    signal game_tick    : std_logic := '0';
    
    


begin

    ----------------------------------------------------------------
    -- Einfache synchrone Logik: aktuell nur Reset, keine Bewegung
    ----------------------------------------------------------------
    process(clk_game)
                 -- Mittelpunkt des Balls
                variable ball_center    : integer;
                variable paddle_center  : integer;
                variable delta          : integer;

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

            -- Reset game parameters
            score_reg <= 0;
            lives_reg <= 3;
            state_reg <= "00";  -- WELCOME oder IDLE

            -- reset Tick
            tick_counter <= (others => '0');
            game_tick    <= '0';
            
            -- reset ball position and speed
            ball_x_reg <= BALL_START_X;
            ball_y_reg <= BALL_START_Y;

            ball_vx <= 0;
            ball_vy <= 0;



        --------------------------------------------------------------------
        -- GAME TICK GENERIEREN (~150 Hz)
        --------------------------------------------------------------------
        else

            if tick_counter = 2500000 then    -- 148.5 MHz / 2500000 ≈ 60 Hz (angepasst danach)
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
                
                --------------------------------------------------------------------
                -- BALL START
                --------------------------------------------------------------------
                if ball_vx = 0 and ball_vy = 0 then
                    ball_vx <= BALL_SPEED_X;    -- Start nach rechts
                    ball_vy <= BALL_SPEED_Y;    -- leicht schräge Bewegung
                end if;

                --------------------------------------------------------------------
                -- BALL BEWEGUNG
                --------------------------------------------------------------------
                ball_x_reg <= ball_x_reg + ball_vx;
                ball_y_reg <= ball_y_reg + ball_vy;

                --------------------------------------------------------------------
                -- WANLLCOLLISION TOP / BOTTOM
                --------------------------------------------------------------------
                -- top
                if ball_y_reg <= 0 then
                    ball_y_reg <= 0 - (ball_y_reg);
                    ball_vy <= -ball_vy;
                end if;

                -- bottom
                if (ball_y_reg + BALL_SIZE) >= FRAME_HEIGHT then
                    ball_y_reg <= 2*(FRAME_HEIGHT - BALL_SIZE) - ball_y_reg; 
                    ball_vy <= -ball_vy;                                     
                end if;
                
                -- BALL AUS DEM FELD LINKS ODER RECHTS?
                if ball_x_reg < 0 or ball_x_reg > FRAME_WIDTH then

                -- Ball zurück in die Mitte
                ball_x_reg <= BALL_START_X;
                ball_y_reg <= BALL_START_Y;

                -- Geschwindigkeit neu setzen
                ball_vx <= BALL_SPEED_X;  -- später zufällig
                ball_vy <= BALL_SPEED_Y;

                end if;
                
                --------------------------------------------------------------------
                -- 5. PADDLE COLLISION (left + right)
                 --------------------------------------------------------------------


                ball_center := ball_y_reg + BALL_SIZE/2;

                -------------------------
                -- LEFT PADDLE COLLISION
                -------------------------
                if (ball_x_reg <= PADDLE_LEFT_X + PADDLE_WIDTH) and
                    (ball_x_reg + BALL_SIZE >= PADDLE_LEFT_X) and
                    (ball_y_reg + BALL_SIZE > paddle_left_y_reg) and
                    (ball_y_reg < paddle_left_y_reg + PADDLE_HEIGHT) then

                -- Ball rechts neben das Paddle setzen, damit er nicht klebt
                ball_x_reg <= PADDLE_LEFT_X + PADDLE_WIDTH + 1;

                -- X-Richtung umdrehen (nach rechts)
                ball_vx <= abs(ball_vx);

                -- Trefferposition bestimmen
                paddle_center := paddle_left_y_reg + PADDLE_HEIGHT/2;
                delta := ball_center - paddle_center;

                -- vertikaler Winkel
                if delta < -40 then
                    ball_vy <= -3;   -- steil nach oben
                elsif delta < -15 then
                    ball_vy <= -2;
                elsif delta < 15 then
                    ball_vy <= 0;    -- flach
                elsif delta < 40 then
                    ball_vy <= +2;
                else
                    ball_vy <= +3;   -- steil nach unten
                end if;
            end if;


        -------------------------
        -- RIGHT PADDLE COLLISION
        -------------------------
        if (ball_x_reg + BALL_SIZE >= PADDLE_RIGHT_X) and
            (ball_x_reg <= PADDLE_RIGHT_X + PADDLE_WIDTH) and
            (ball_y_reg + BALL_SIZE > paddle_right_y_reg) and
            (ball_y_reg < paddle_right_y_reg + PADDLE_HEIGHT) then

        -- Ball links neben das Paddle setzen
        ball_x_reg <= PADDLE_RIGHT_X - BALL_SIZE - 1;

        -- X-Richtung umdrehen (nach links)
        ball_vx <= -abs(ball_vx);

        -- Trefferposition bestimmen
        paddle_center := paddle_right_y_reg + PADDLE_HEIGHT/2;
        delta := ball_center - paddle_center;

        -- vertikaler Winkel
        if delta < -40 then
            ball_vy <= -3;
        elsif delta < -15 then
            ball_vy <= -2;
        elsif delta < 15 then
            ball_vy <= 0;
        elsif delta < 40 then
            ball_vy <= +2;
        else
            ball_vy <= +3;
        end if;
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

