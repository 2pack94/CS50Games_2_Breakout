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

PaddleSelectState = Class{__includes = BaseState}

-- enter from StartState
function PaddleSelectState:enter(params)
    self.high_scores = params.high_scores
end

function PaddleSelectState:init()
    -- the paddle we're highlighting; will be passed to the ServeState
    -- when we press Enter
    self.paddle_skin = 1
    -- start with level 1
    self.level = 1

    -- recovery_sys.points_thres: points needed to get 1 heart. increases by recovery_sys.points_thres_init for every recovered heart until recovery_sys.points_thres_max
    self.recovery_sys = {}
    self.recovery_sys.points_thres_init = 1000
    self.recovery_sys.points_thres = self.recovery_sys.points_thres_init
    self.recovery_sys.points_thres_max = self.recovery_sys.points_thres_init * 10
    -- current recover points. increase by score points (when a brick was hit). recover a heart when the point threshold was reached. get reset every time a heart was recovered
    self.recovery_sys.points = 0
end

function PaddleSelectState:update(dt)
    if keyboardWasPressed('left') then
        if self.paddle_skin == 1 then
            gSounds['no-select']:play()
        else
            gSounds['select']:play()
            self.paddle_skin = self.paddle_skin - 1
        end
    elseif keyboardWasPressed('right') then
        if self.paddle_skin == PADDLE_NUM_SKINS then
            gSounds['no-select']:play()
        else
            gSounds['select']:play()
            self.paddle_skin = self.paddle_skin + 1
        end
    end

    -- select paddle and move on to the serve state, passing in the selection
    if keyboardWasPressed('return') or keyboardWasPressed('enter') then
        gSounds['confirm']:play()

        gStateMachine:change('serve', {
            paddle = Paddle(self.paddle_skin),
            bricks = LevelMaker.createMap(self.level),
            health = MAX_HEALTH,
            score = 0,
            high_scores = self.high_scores,
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

function PaddleSelectState:render()
    -- instructions
    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf("Select your paddle with left and right!", 0, VIRTUAL_HEIGHT / 4,
        VIRTUAL_WIDTH, 'center')
    love.graphics.setFont(gFonts['small'])
    love.graphics.printf("(Press Enter to continue!)", 0, VIRTUAL_HEIGHT / 3,
        VIRTUAL_WIDTH, 'center')
        
    -- left arrow; should render normally if we're higher than 1, else
    -- in a shadowy form to let us know we're as far left as we can go
    if self.paddle_skin == 1 then
        -- tint; give it a dark gray with half opacity
        love.graphics.setColor(40/255, 40/255, 40/255, 128/255)
    end
    
    love.graphics.draw(gTextures['arrows'], gFrames['arrows'][1], VIRTUAL_WIDTH / 4 - ARROW_WIDTH,
        VIRTUAL_HEIGHT - VIRTUAL_HEIGHT / 3)
   
    -- reset drawing color to full white for proper rendering
    love.graphics.setColor(255/255, 255/255, 255/255, 255/255)

    -- right arrow; should render normally if we're less than 4, else
    -- in a shadowy form to let us know we're as far right as we can go
    if self.paddle_skin == PADDLE_NUM_SKINS then
        -- tint; give it a dark gray with half opacity
        love.graphics.setColor(40/255, 40/255, 40/255, 128/255)
    end
    
    love.graphics.draw(gTextures['arrows'], gFrames['arrows'][2], VIRTUAL_WIDTH - VIRTUAL_WIDTH / 4,
        VIRTUAL_HEIGHT - VIRTUAL_HEIGHT / 3)
    
    -- reset drawing color to full white for proper rendering
    love.graphics.setColor(255/255, 255/255, 255/255, 255/255)

    -- draw the paddle itself (size 2), based on which we have selected
    love.graphics.draw(gTextures['main'], gFrames['paddles'][2 + PADDLE_NUM_SIZES * (self.paddle_skin - 1)],
        VIRTUAL_WIDTH / 2 - PADDLE_BASE_WIDTH, VIRTUAL_HEIGHT - VIRTUAL_HEIGHT / 3)
end
