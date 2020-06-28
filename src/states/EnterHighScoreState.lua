--[[
    GD50
    Breakout Remake

    -- EnterHighScoreState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Screen that allows us to input a new high score name in the form of single characters, arcade-style.
]]

EnterHighScoreState = Class{__includes = BaseState}

-- enter from GameOverState (if High Score was reached)
function EnterHighScoreState:enter(params)
    self.high_scores = params.high_scores
    self.score = params.score
    self.high_score_index = params.high_score_index
    -- individual chars of our string. initialize with starting chars
    self.chars = {}
    for i = 1, NUM_CHARS_HS do
        self.chars[i] = string.byte('A')
    end

    -- char we're currently changing
    self.highlighted_char = 1
end

function EnterHighScoreState:update(dt)
    -- update scores table, if enter was pressed
    if keyboardWasPressed('enter') or keyboardWasPressed('return') then
        -- name for this high score
        local name = ''
        -- convert char to string and concatenate
        for i = 1, NUM_CHARS_HS do
            name = name .. string.char(self.chars[i])
        end
        -- go backwards (lowest score to highest score) through high scores table till this score, shifting scores (1 index higher each)
        for i = NUM_HIGH_SCORES, self.high_score_index, -1 do
            self.high_scores[i + 1] = {
                name = self.high_scores[i].name,
                score = self.high_scores[i].score
            }
        end
        -- remove the last element (that was added in the previous for loop)
        table.remove(self.high_scores, NUM_HIGH_SCORES + 1)

        self.high_scores[self.high_score_index].name = name
        self.high_scores[self.high_score_index].score = self.score

        -- write scores to file
        local scores_str = ''
        for i = 1, NUM_HIGH_SCORES do
            scores_str = scores_str .. self.high_scores[i].name .. '\n'
            scores_str = scores_str .. tostring(self.high_scores[i].score) .. '\n'
        end

        love.filesystem.write('breakout.lst', scores_str)

        gStateMachine:change('high-scores', {
            high_scores = self.high_scores
        })
    end

    -- scroll through character slots
    if keyboardWasPressed('left') and self.highlighted_char > 1 then
        self.highlighted_char = self.highlighted_char - 1
        gSounds['select']:play()
    elseif keyboardWasPressed('right') and self.highlighted_char < NUM_CHARS_HS then
        self.highlighted_char = self.highlighted_char + 1
        gSounds['select']:play()
    end

    -- scroll through characters
    if keyboardWasPressed('up') then
        self.chars[self.highlighted_char] = self.chars[self.highlighted_char] + 1
        if self.chars[self.highlighted_char] > string.byte('Z') then
            self.chars[self.highlighted_char] = string.byte('A')
        end
    elseif keyboardWasPressed('down') then
        self.chars[self.highlighted_char] = self.chars[self.highlighted_char] - 1
        if self.chars[self.highlighted_char] < string.byte('A') then
            self.chars[self.highlighted_char] = string.byte('Z')
        end
    end
end

function EnterHighScoreState:render()
    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf('Your score: ' .. tostring(self.score), 0, 30,
        VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(gFonts['large'])
    
    -- render all characters of the name, highlight the selected one
    local char_spacing = 25
    local horizontal_offset = VIRTUAL_WIDTH / 2 - (char_spacing / 2) * NUM_CHARS_HS
    for i = 1, NUM_CHARS_HS do
        if i == self.highlighted_char then
            love.graphics.setColor(103/255, 255/255, 255/255, 255/255)
        end
        love.graphics.print(string.char(self.chars[i]), horizontal_offset + char_spacing * (i - 1), VIRTUAL_HEIGHT / 2)
        love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
    end
    
    love.graphics.setFont(gFonts['small'])
    love.graphics.printf('Press Enter to confirm!', 0,
        VIRTUAL_HEIGHT - 18, VIRTUAL_WIDTH, 'center')
end
