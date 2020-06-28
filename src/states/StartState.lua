--[[
    GD50
    Breakout Remake

    -- StartState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state the game is in when we've just started; should
    simply display "Breakout" in large text, as well as a message to press
    Enter to begin.
]]

-- the "__includes" bit here means we're going to inherit all of the methods
-- that BaseState has, so it will have empty versions of all StateMachine methods
-- even if we don't override them ourselves; handy to avoid superfluous code!
StartState = Class{__includes = BaseState}

-- initial state. can be entered from GameOverState. can be entered from HighScoreState, PlayState, ServeState, PaddleSelectState if pressed escape
function StartState:enter(params)
    self.high_scores = params.high_scores
    -- whether we're highlighting "Start" or "High Scores"
    self.highlighted = 0
end

function StartState:update(dt)
    -- toggle self.highlighted option if we press an arrow key up or down (only 2 options)
    if keyboardWasPressed('up') or keyboardWasPressed('down') then
        self.highlighted = (self.highlighted + 1) % 2
        gSounds['paddle-hit']:play()
    end

    -- confirm whichever option we have selected to change screens
    if keyboardWasPressed('enter') or keyboardWasPressed('return') then
        gSounds['confirm']:play()

        if self.highlighted == 0 then
            gStateMachine:change('paddle-select', {
                high_scores = self.high_scores
            })
        elseif self.highlighted == 1 then
            gStateMachine:change('high-scores', {
                high_scores = self.high_scores
            })
        end
    end

    -- exit the program if escape was pressed
    if keyboardWasPressed('escape') then
        love.event.quit()
    end
end

function StartState:render()
    -- title
    love.graphics.setFont(gFonts['large'])
    love.graphics.printf("BREAKOUT", 0, VIRTUAL_HEIGHT / 3,
        VIRTUAL_WIDTH, 'center')
    
    -- instructions
    love.graphics.setFont(gFonts['medium'])

    -- render option 1 blue if we're highlighting that one
    if self.highlighted == 0 then
        love.graphics.setColor(103/255, 255/255, 255/255, 255/255)
    end
    love.graphics.printf("START", 0, VIRTUAL_HEIGHT / 2 + 70,
        VIRTUAL_WIDTH, 'center')

    -- reset the color
    love.graphics.setColor(255/255, 255/255, 255/255, 255/255)

    -- render option 2 blue if we're highlighting that one
    if self.highlighted == 1 then
        love.graphics.setColor(103/255, 255/255, 255/255, 255/255)
    end
    love.graphics.printf("HIGH SCORES", 0, VIRTUAL_HEIGHT / 2 + 90,
        VIRTUAL_WIDTH, 'center')

    -- reset the color
    love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
end
