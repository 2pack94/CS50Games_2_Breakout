--[[
    GD50
    Breakout Remake

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Originally developed by Atari in 1976. An effective evolution of
    Pong, Breakout ditched the two-player mechanic in favor of a single-
    player game where the player, still controlling a paddle, was tasked
    with eliminating a screen full of differently placed bricks of varying
    values by deflecting a ball back at them.

    This version is built to more closely resemble the NES than
    the original Pong machines or the Atari 2600 in terms of
    resolution, though in widescreen (16:9) so it looks nicer on 
    modern systems.

    Credit for graphics (amazing work!):
    https://opengameart.org/users/buch

    Credit for music (great loop):
    http://freesound.org/people/joshuaempyre/sounds/251461/
    http://www.soundcloud.com/empyreanma
]]

require 'src/Dependencies'

-- a table we'll use to keep track of which keys have been pressed this
-- frame, to get around the fact that LÖVE's default callback won't let us
-- test for input from within other functions
local keys_pressed = {}

--[[
    Called just once at the beginning of the game; used to set up
    game objects, variables, etc. and prepare the game world.
]]
function love.load()
    -- set love's default filter to "nearest-neighbor", which essentially
    -- means there will be no filtering of pixels (blurriness), which is
    -- important for a nice crisp, 2D look
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- seed the RNG so that calls to math.random are always random
    math.randomseed(os.time())

    -- set the application title bar
    love.window.setTitle('Breakout')

    -- initialize our nice-looking retro text fonts
    gFonts = {
        ['small'] = love.graphics.newFont('fonts/font.ttf', 8),
        ['medium'] = love.graphics.newFont('fonts/font.ttf', 16),
        ['large'] = love.graphics.newFont('fonts/font.ttf', 32)
    }
    love.graphics.setFont(gFonts['small'])

    -- load up the graphics we'll be using throughout our states
    gTextures = {
        ['background'] = love.graphics.newImage('graphics/background.png'),
        ['main'] = love.graphics.newImage('graphics/breakout.png'),
        ['arrows'] = love.graphics.newImage('graphics/arrows.png'),
        ['hearts'] = love.graphics.newImage('graphics/hearts.png'),
        ['particle'] = love.graphics.newImage('graphics/particle.png')
    }
    ARROW_WIDTH = gTextures['arrows']:getWidth() / 2
    HEART_WIDTH = gTextures['hearts']:getWidth() / 2

    -- Quads we will generate for all of our textures; Quads allow us
    -- to show only part of a texture and not the entire thing
    gFrames = {
        ['arrows'] = GenerateQuads(gTextures['arrows'], ARROW_WIDTH, gTextures['arrows']:getHeight()),
        ['paddles'] = GenerateQuadsPaddles(gTextures['main']),
        ['balls'] = GenerateQuadsBalls(gTextures['main']),
        ['bricks'] = GenerateQuadsBricks(gTextures['main']),
        ['hearts'] = GenerateQuads(gTextures['hearts'], HEART_WIDTH, gTextures['hearts']:getHeight()),
        ['powerups'] = GenerateQuadsPowerups(gTextures['main'])
    }

    -- initialize our virtual resolution, which will be rendered within our
    -- actual window no matter its dimensions
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        vsync = true,
        fullscreen = false,
        resizable = true
    })

    -- set up our sound effects; later, we can just index this table and
    -- call each entry's `play` method
    gSounds = {
        ['paddle-hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
        ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
        ['wall-hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static'),
        ['confirm'] = love.audio.newSource('sounds/confirm.wav', 'static'),
        ['select'] = love.audio.newSource('sounds/select.wav', 'static'),
        ['no-select'] = love.audio.newSource('sounds/no-select.wav', 'static'),
        ['brick-hit-1'] = love.audio.newSource('sounds/brick-hit-1.wav', 'static'),
        ['brick-hit-2'] = love.audio.newSource('sounds/brick-hit-2.wav', 'static'),
        ['hurt'] = love.audio.newSource('sounds/hurt.wav', 'static'),
        ['victory'] = love.audio.newSource('sounds/victory.wav', 'static'),
        ['recover'] = love.audio.newSource('sounds/recover.wav', 'static'),
        ['high-score'] = love.audio.newSource('sounds/high_score.wav', 'static'),
        ['pause'] = love.audio.newSource('sounds/pause.wav', 'static'),
        ['powerup-good'] = love.audio.newSource('sounds/powerup-good.wav', 'static'),
        ['powerup-bad'] = love.audio.newSource('sounds/powerup-bad.wav', 'static'),
        
        ['music'] = love.audio.newSource('sounds/music.mp3', 'static')
    }

    -- the state machine we'll be using to transition between various states
    -- in our game instead of clumping them together in the main update and draw
    -- methods
    --
    -- the current game state can be any of the following:
    -- 1. 'start' (the beginning of the game, where we're told to press Enter)
    -- 2. 'paddle-select' (where we get to choose the color of our paddle)
    -- 3. 'serve' (waiting on a key press to serve the ball)
    -- 4. 'play' (the ball is in play, bouncing between paddle and bricks)
    -- 5. 'victory' (the current level is over, with a victory jingle)
    -- 6. 'game-over' (the player has lost; display score and allow restart)
    gStateMachine = StateMachine {
        ['start'] = function() return StartState() end,
        ['play'] = function() return PlayState() end,
        ['serve'] = function() return ServeState() end,
        ['game-over'] = function() return GameOverState() end,
        ['victory'] = function() return VictoryState() end,
        ['high-scores'] = function() return HighScoreState() end,
        ['enter-high-score'] = function() return EnterHighScoreState() end,
        ['paddle-select'] = function() return PaddleSelectState() end
    }
    -- change() instantiates a State class (calls: exit() of previous state class -> init() of the new state class -> enter() of the new state class)
    -- objects or variables needed in more than 1 state can be transferred with the second Parameter 'enterParams' of the change() method. They will be available in the enter() method of the next state.
    -- if not referenced by something else (e.g. by passing them as 'enterParams' for the next state),
    -- the previous state object and all of its members get discarded and cleaned up (Lua garbage collection) (because the variable the state object was assigned to gets overwritten by the next state object)
    gStateMachine:change('start', {
        high_scores = loadHighScores()
    })

    -- play our music outside of all states and set it to looping
    gSounds['music']:play()
    gSounds['music']:setVolume(0.7)
    gSounds['music']:setLooping(true)
end

--[[
    Called whenever we change the dimensions of our window, as by dragging
    out its bottom corner, for example. In this case, we only need to worry
    about calling out to `push` to handle the resizing. Takes in a `w` and
    `h` variable representing width and height, respectively.
]]
function love.resize(w, h)
    push:resize(w, h)
end

--[[
    Called every frame, passing in `dt` since the last frame. `dt`
    is short for `deltaTime` and is measured in seconds. Multiplying
    this by any changes we wish to make in our game will allow our
    game to perform consistently across all hardware; otherwise, any
    changes we make will be applied as fast as possible and will vary
    depending on the FPS.
]]
function love.update(dt)
    -- if the games freezes (e.g. when the window gets moved), dt gets accumulated and will be applied in the next update.
    -- prevent the glitches caused by that by limiting dt to 0.07 (about 1/15) seconds.
    dt = math.min(dt, 0.07)

    -- pass in dt to the update method of the state object currently in use
    gStateMachine:update(dt)

    -- reset keys pressed
    keys_pressed = {}
end

--[[
    A callback that processes key strokes as they happen, just once.
    Does not account for keys that are held down, which is handled by a
    separate function (`love.keyboard.isDown`). Useful for when we want
    things to happen right away.
]]
function love.keypressed(key)
    -- toggle fullscreen mode by pressing left alt + enter
    if love.keyboard.isDown('lalt') and (key == 'enter' or key == 'return') then
        push:switchFullscreen()
        return      -- don't use this keypress for the game logic
    end
    -- add to our table of keys pressed this frame
    keys_pressed[key] = true
end

--[[
    A custom function that will let us test for individual keystrokes outside
    of the default `love.keypressed` callback, since we can't call that logic
    elsewhere by default.
]]
function keyboardWasPressed(key)
    if keys_pressed[key] then
        return true
    end
    return false
end

--[[
    Called each frame after update; is responsible simply for
    drawing all of our game objects and more to the screen.
]]
function love.draw()
    -- begin drawing with push, in our virtual resolution
    push:start()

    -- background should be drawn regardless of state, scaled to fit the virtual resolution
    local backgroundWidth = gTextures['background']:getWidth()
    local backgroundHeight = gTextures['background']:getHeight()

    love.graphics.draw(gTextures['background'], 
        0, 0,   -- draw at coordinates 0, 0
        0,      -- no rotation
        VIRTUAL_WIDTH / (backgroundWidth - 1), VIRTUAL_HEIGHT / (backgroundHeight - 1)  -- scale factors on X and Y axis so it fills the screen
    )
    
    -- use the state machine to defer rendering to the current state
    gStateMachine:render()
    
    -- display FPS for debugging
    displayFPS()
    
    push:finish()
end

--[[
    Loads high scores from a .lst file, saved in LÖVE2D's default save directory %appdata%\LOVE\ in a subfolder
    called 'breakout'. (file not tamper proof)
]]
function loadHighScores()
    -- subfolder in the save directory
    love.filesystem.setIdentity('breakout')

    -- if the file doesn't exist, initialize it with some default scores
    if not love.filesystem.getInfo('breakout.lst') then
        local scores_str = ''
        local init_name = ''
        for i = 1, NUM_CHARS_HS do
            init_name = init_name .. 'A'
        end
        for i = NUM_HIGH_SCORES, 1, -1 do       -- write from the highest to lowest score
            scores_str = scores_str .. init_name .. '\n'
            scores_str = scores_str .. tostring(i * 1000) .. '\n'
        end

        love.filesystem.write('breakout.lst', scores_str)
    end

    -- flag for whether we're reading a name or a score
    local is_name = true
    local counter = 1

    -- initialize scores table with at least NUM_HIGH_SCORES blank entries
    local scores = {}

    for i = 1, NUM_HIGH_SCORES do
        -- blank table; each will hold a name and a score
        scores[i] = {
            name = nil,
            score = nil
        }
    end

    -- iterate over each line in the file, reading names and scores
    -- highest score gets lowest index in the table
    for line in love.filesystem.lines('breakout.lst') do
        if is_name then
            scores[counter].name = string.sub(line, 1, NUM_CHARS_HS)
        else
            scores[counter].score = tonumber(line)
            counter = counter + 1
        end
        if counter > NUM_HIGH_SCORES then   -- in case the file has too many entries
            break
        end
        -- toggle the name flag
        is_name = not is_name
    end

    return scores
end

--[[
    Renders hearts based on how much health the player has. First renders
    full hearts, then empty hearts for however much health we're missing.
]]
function renderHealth(health)
    -- start of our health rendering
    local health_x = VIRTUAL_WIDTH / 2 - (MAX_HEALTH / 2) * HEART_WIDTH
    local health_y = 4
    
    -- render health left
    for i = 1, health do
        love.graphics.draw(gTextures['hearts'], gFrames['hearts'][1], health_x, health_y)
        health_x = health_x + HEART_WIDTH + 1
    end

    -- render missing health
    for i = 1, MAX_HEALTH - health do
        love.graphics.draw(gTextures['hearts'], gFrames['hearts'][2], health_x, health_y)
        health_x = health_x + HEART_WIDTH + 1
    end
end

--[[
    Renders the current FPS.
]]
function displayFPS()
    -- simple FPS display across all states
    love.graphics.setFont(gFonts['small'])
    love.graphics.setColor(0/255, 255/255, 0/255, 255/255)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 5, 5)
end

--[[
    Simply renders the player's score at the top right, with left-side padding
    for the score number.
]]
function renderScore(score)
    love.graphics.setFont(gFonts['small'])
    love.graphics.print('Score:', VIRTUAL_WIDTH - 70, 5)
    love.graphics.printf(tostring(score), VIRTUAL_WIDTH - 50, 5, 40, 'right')
end

--[[
    render the points needed to recover a heart
]]
function renderRecover(need_recover_points)
    love.graphics.setFont(gFonts['small'])
    love.graphics.print('Recover:', VIRTUAL_WIDTH - 145, 5)
    love.graphics.printf(tostring(need_recover_points), VIRTUAL_WIDTH - 115, 5, 40, 'right')
end
