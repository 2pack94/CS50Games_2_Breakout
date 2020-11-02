--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
    enter from ServeState
]]
function PlayState:enter(params)
    self.paddle = params.paddle                 -- instantiated in PaddleSelectState
    self.bricks = params.bricks                 -- instantiated in PaddleSelectState (for first level) and in VictoryState (for next levels)
    self.health = params.health                 -- initialized in PaddleSelectState
    self.score = params.score                   -- initialized in PaddleSelectState
    self.high_scores = params.high_scores       -- initialized in main
    self.balls = {params.ball}                  -- instantiated in ServeState. There is more than 1 ball if the add ball Powerup is collected
    self.level = params.level                   -- initialized in PaddleSelectState, incremented in VictoryState
    self.recovery_sys = params.recovery_sys     -- initialized in PaddleSelectState
    
    self.powerup_spawn_rate = 0.2       -- probability of a powerup spawn when a brick is destroyed
    self.powerups = {}                  -- this table contains all powerup objects visible on the screen
    self.powerup_effect_time = 25       -- number of seconds the timed powerup effects apply
    -- timed effects gained from the powerups ([effect type] = time to expire)
    -- initialize effects as expired
    self.effects = {
        ['strong-ball'] = 0
    }

    -- launch the ball from the paddle (is already centered on the paddle)
    for k, ball in pairs(self.balls) do
        ball:launch()
    end

    self.paused = false
end

function PlayState:update(dt)
    if keyboardWasPressed('space') then
        self.paused = not self.paused   -- toggle pause
        gSounds['pause']:play()
    end
    if self.paused then
        return
    end

    self.paddle:update(dt)
    for k, ball in pairs(self.balls) do
        -- update position based on velocity
        ball:update(dt)
        -- calculate the collision with the paddle and reflect ball
        ball:collidePaddle(self.paddle)
        -- update ball based on current strong ball effect
        if self.effects['strong-ball'] > 0 and not ball.is_strong then
            ball.is_strong = true           -- add effect
        elseif self.effects['strong-ball'] <= 0 and ball.is_strong then
            ball.is_strong = false          -- remove effect
        end
    end

    local is_damage = false
    -- if ball goes below bounds, remove it. decrease health if all balls are gone (extra loop for removing)
    for k, ball in pairs(self.balls) do
        if ball.y > VIRTUAL_HEIGHT then
            table.remove(self.balls, k)
            if not next(self.balls) then     -- if no more balls
                is_damage = true
            end
            gSounds['hurt']:play()
        end
    end

    -- detect collision across all bricks with the ball
    for k, brick in pairs(self.bricks) do
        -- only check collision if brick is in play
        if brick.is_in_play then
            for k, ball in pairs(self.balls) do
                local is_ball_intersect, ball_shift_x, ball_shift_y = ball:getDisplacement(brick)
                if is_ball_intersect then
                    local reflect_ball = true       -- without any effects, reflect the ball from the brick
                    local num_hits = 1              -- without any effects, hit the brick 1 time
                    if ball.is_strong then
                        num_hits = 2                -- hit the brick 2 times
                        if brick.tier < 2 then      -- destroy the lowest tier brick without reflecting the ball
                            reflect_ball = false
                        end
                    end
                    for i = 1, num_hits do
                        -- add to score (points per brick and additional points per brick tier)
                        local score_add = 100 + (brick.tier - 1) * 50
                        self.score = self.score + score_add
                        self.recovery_sys.points = self.recovery_sys.points + score_add

                        -- trigger the brick's hit function, which decreases its tier (or removes it)
                        -- removing just sets the is_in_play flag to false. The object itself stays inside the bricks table.
                        brick:hit()
                    end

                    -- spawn a powerup for this brick with a certain probability
                    if not brick.is_in_play and math.random() <= self.powerup_spawn_rate then
                        table.insert(self.powerups, Powerup(brick))
                    end

                    -- if we have enough points, recover one health
                    if self.recovery_sys.points >= self.recovery_sys.points_thres  then
                        -- can't go above MAX_HEALTH
                        self.health = math.min(MAX_HEALTH, self.health + 1)

                        -- reset recover points
                        self.recovery_sys.points = self.recovery_sys.points - self.recovery_sys.points_thres
                        -- increase recover points threshold
                        self.recovery_sys.points_thres = math.min(self.recovery_sys.points_thres_max, self.recovery_sys.points_thres + self.recovery_sys.points_thres_init)

                        -- play recover sound effect
                        gSounds['recover']:play()
                    end

                    -- go to the victory screen if there are no more bricks left
                    if self:isVictory() then
                        gSounds['victory']:play()

                        gStateMachine:change('victory', {
                            level = self.level,
                            paddle = self.paddle,
                            health = self.health,
                            score = self.score,
                            high_scores = self.high_scores,
                            balls = self.balls,
                            bricks = self.bricks,
                            recovery_sys = self.recovery_sys,
                        })
                    end
                    
                    if reflect_ball then
                        -- reflect ball off of brick and rebound it
                        ball:reboundReflect(ball_shift_x, ball_shift_y)
                    end

                    -- slightly scale the y velocity to speed up the game
                    ball.dy = ball.dy * ball.dy_inc

                    -- disable possibility of colliding with multiple bricks in one frame
                    break
                end
            end
        end
    end

    -- collision between the wall and the ball is calculated in Ball.lua

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    -- decrease the time of all effects that have an expiration time above 0
    if self.effects['strong-ball'] > 0 then
        self.effects['strong-ball'] = math.max(self.effects['strong-ball'] - dt, 0)
    end

    -- update powerups
    for k, powerup in pairs(self.powerups) do
        powerup:update(dt)
    end
    -- check if powerup collided with the paddle or went below the screen
    -- when removing an element from a table with numerical keys, all elements after the deleted one decrement their index and the length of the table reduces by 1.
    -- when iterating forward while removing, the element after the removed one is skipped.
    -- iterate backwards from last to first element to solve this issue
    for i = #self.powerups, 1, -1 do
        local powerup = self.powerups[i]
        -- if powerup went below the screen
        if powerup.y > VIRTUAL_HEIGHT then
            table.remove(self.powerups, i)

        -- if powerup collided with paddle
        elseif powerup:intersects(self.paddle) then
            table.remove(self.powerups, i)

            if powerup.type == 1 then       -- 1 damage
                gSounds['powerup-bad']:play()
                gSounds['hurt']:play()
                is_damage = true
            elseif powerup.type == 2 then   -- paddle shrink
                gSounds['powerup-bad']:play()
                self.paddle:shrink()
            elseif powerup.type == 3 then   -- paddle grow
                gSounds['powerup-good']:play()
                self.paddle:grow()
            elseif powerup.type == 4 then   -- add ball
                gSounds['powerup-good']:play()
                local new_ball = Ball(math.random(NUM_BALL_COLORS - 1))
                new_ball:centerPaddle(self.paddle)
                new_ball:launch()
                table.insert(self.balls, new_ball)
            elseif powerup.type == 5 then   -- strong ball
                gSounds['powerup-good']:play()
                -- activate strong ball effect for an amount of time (or replenish the time if already activated)
                self.effects['strong-ball'] = self.powerup_effect_time
            end
        end
    end

    -- if taken damage from ball loss or bad powerup, change the state
    if is_damage then
        self.health = self.health - 1
        if self.health <= 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                high_scores = self.high_scores
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                high_scores = self.high_scores,
                level = self.level,
                recovery_sys = self.recovery_sys,
            })
        end
    end

    -- return to the start screen if escape was pressed
    if keyboardWasPressed('escape') then
        gSounds['wall-hit']:play()
        
        gStateMachine:change('start', {
            high_scores = self.high_scores
        })
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end
    -- render particle system for every brick
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()
    for k, ball in pairs(self.balls) do
        ball:render()
    end
    -- render powerups
    for k, powerup in pairs(self.powerups) do
        powerup:render()
    end

    renderScore(self.score)
    renderRecover(self.recovery_sys.points_thres - self.recovery_sys.points)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

-- if all brick were destroyed, the level is completed
function PlayState:isVictory()
    for k, brick in pairs(self.bricks) do
        if brick.is_in_play then
            return false
        end
    end

    return true
end
