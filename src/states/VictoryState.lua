--[[
    GD50
    Breakout Remake

    -- StartState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state that the game is in when we've just completed a level.
    Very similar to the ServeState, except here we increment the level
]]

VictoryState = Class{__includes = BaseState}

-- enter from PlayState
function VictoryState:enter(params)
    self.level = params.level
    self.score = params.score
    self.high_scores = params.high_scores
    self.paddle = params.paddle
    self.health = params.health
    self.balls = params.balls
    self.bricks = params.bricks
    self.recovery_sys = params.recovery_sys
end

function VictoryState:update(dt)
    -- freeze the ball(s) in place by not updating, but still rendering

    self.paddle:update(dt)
    -- for rendering particle systems (otherwise the last brick would disappear without effects when the level was cleared)
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    -- go to play screen if the player presses Enter
    if keyboardWasPressed('return') then
        gStateMachine:change('serve', {
            level = self.level + 1,
            bricks = LevelMaker.createMap(self.level + 1),
            paddle = self.paddle,
            health = self.health,
            score = self.score,
            high_scores = self.high_scores,
            recovery_sys = self.recovery_sys,
        })
    end
end

function VictoryState:render()
    self.paddle:render()
    for k, ball in pairs(self.balls) do
        ball:render()
    end

    -- render all particle systems (otherwise the last brick would disappear without effects when the level was cleared)
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    renderHealth(self.health)
    renderRecover(self.recovery_sys.points_thres - self.recovery_sys.points)
    renderScore(self.score)

    -- level complete text
    love.graphics.setFont(gFonts['large'])
    love.graphics.printf("Level " .. tostring(self.level) .. " complete!",
        0, VIRTUAL_HEIGHT / 4, VIRTUAL_WIDTH, 'center')

    -- instructions text
    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf('Press Enter to continue!', 0,
        VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
end
