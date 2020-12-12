--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the screen where we can view all high scores previously recorded.
]]

HighScoreState = Class{__includes = BaseState}

-- enter from EnterHighScoreState or StartState
function HighScoreState:enter(params)
    self.high_scores = params.high_scores
end

function HighScoreState:update(dt)
    -- return to the start screen
    if keyboardWasPressed('escape') or keyboardWasPressed('return') then
        gSounds['wall-hit']:play()
        
        gStateMachine:change('start', {
            high_scores = self.high_scores
        })
    end
end

function HighScoreState:render()
    love.graphics.setFont(gFonts['large'])
    love.graphics.printf('High Scores', 0, 20, VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(gFonts['medium'])

    -- iterate over all high score indices in our high scores table
    local vertical_spacing = 13
    local vertical_offset = 60
    for i = 1, NUM_HIGH_SCORES do
        local name = self.high_scores[i].name or '---'
        local score = self.high_scores[i].score or '---'

        -- score number
        love.graphics.printf(tostring(i) .. '.', VIRTUAL_WIDTH / 4, 
            vertical_offset + i * vertical_spacing, 50, 'left')

        -- score name
        love.graphics.printf(name, VIRTUAL_WIDTH / 4 + 38, 
            vertical_offset + i * vertical_spacing, 70, 'left')
        
        -- score itself
        love.graphics.printf(tostring(score), VIRTUAL_WIDTH / 2,
            vertical_offset + i * vertical_spacing, 100, 'right')
    end

    love.graphics.setFont(gFonts['small'])
    love.graphics.printf("Press Escape to return to the main menu!",
        0, VIRTUAL_HEIGHT - 18, VIRTUAL_WIDTH, 'center')
end
