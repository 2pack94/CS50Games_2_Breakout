--[[
    GD50
    Breakout Remake

    -- GameOverState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The state in which we've lost all of our health and get our score displayed to us. Should
    transition to the EnterHighScore state if we exceeded one of our stored high scores, else back
    to the StartState.
]]

GameOverState = Class{__includes = BaseState}

-- enter from PlayState
function GameOverState:enter(params)
    self.score = params.score
    self.high_scores = params.high_scores
    -- keep track of what high score ours overwrites, if any
    -- the previous high score at that position and the ones below it get shifted down by 1
    self.high_score_index = NUM_HIGH_SCORES + 1
end

function GameOverState:update(dt)
    if not keyboardWasPressed('return') then
        return
    end
    -- see if score is higher than any in the high scores table
    local is_high_score = false

    -- count from lowest (higest index) to highest (lowest index) high score
    for i = NUM_HIGH_SCORES, 1, -1 do
        local cur_high_score = self.high_scores[i].score or 0
        if self.score > cur_high_score then
            self.high_score_index = i
            is_high_score = true
        end
    end

    if is_high_score then
        gSounds['high-score']:play()
        gStateMachine:change('enter-high-score', {
            high_scores = self.high_scores,
            score = self.score,
            high_score_index = self.high_score_index
        })
    else
        gStateMachine:change('start', {
            high_scores = self.high_scores
        })
    end
end

function GameOverState:render()
    love.graphics.setFont(gFonts['large'])
    love.graphics.printf('GAME OVER', 0, VIRTUAL_HEIGHT / 3, VIRTUAL_WIDTH, 'center')
    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf('Final Score: ' .. tostring(self.score), 0, VIRTUAL_HEIGHT / 2,
        VIRTUAL_WIDTH, 'center')
    love.graphics.printf('Press Enter!', 0, VIRTUAL_HEIGHT - VIRTUAL_HEIGHT / 4,
        VIRTUAL_WIDTH, 'center')
end
