--[[
    GD50
    Breakout Remake

    -- ServeState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The state in which we are waiting to serve the ball; here, we are
    basically just moving the paddle left and right with the ball until we
    press Enter, though everything in the actual game now should render in
    preparation for the serve, including our current health and score, as
    well as the level we're on.
]]

ServeState = Class{__includes = BaseState}

-- enter from PaddleSelectState, VictoryState or PlayState
function ServeState:enter(params)
    -- grab game state from params
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.high_scores = params.high_scores
    self.level = params.level
    self.recovery_sys = params.recovery_sys

    self.paddle:default()           -- change paddle back to normal (if it was shrunk or enlarged)

    -- init new ball (random color for fun, but reserve last color for a powerup effect)
    self.ball = Ball(math.random(NUM_BALL_COLORS - 1))
end

function ServeState:update(dt)
    -- have the ball track the player
    self.paddle:update(dt)
    self.ball:centerPaddle(self.paddle)

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if keyboardWasPressed('enter') or keyboardWasPressed('return') or keyboardWasPressed('space') then
        -- pass in all important state info to the PlayState
        gStateMachine:change('play', {
            paddle = self.paddle,
            bricks = self.bricks,
            health = self.health,
            score = self.score,
            high_scores = self.high_scores,
            ball = self.ball,
            level = self.level,
            recovery_sys = self.recovery_sys,
        })
    end

    -- return to the start screen if escape was pressed
    if keyboardWasPressed('escape') then
        gSounds['wall-hit']:play()
        
        gStateMachine:change('start', {
            high_scores = self.high_scores
        })
    end
end

function ServeState:render()
    self.paddle:render()
    self.ball:render()

    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end
    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    renderScore(self.score)
    renderRecover(self.recovery_sys.points_thres - self.recovery_sys.points)
    renderHealth(self.health)

    love.graphics.setFont(gFonts['large'])
    love.graphics.printf('Level ' .. tostring(self.level), 0, VIRTUAL_HEIGHT / 3,
        VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf('Press Enter to serve!', 0, VIRTUAL_HEIGHT / 2,
        VIRTUAL_WIDTH, 'center')
end
