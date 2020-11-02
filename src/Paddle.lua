--[[
    GD50
    Breakout Remake

    -- Paddle Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents a paddle that can move left and right. Used in the main
    program to deflect the ball toward the bricks; if the ball passes
    the paddle, the player loses one heart. The Paddle can have a skin,
    which the player gets to choose upon starting the game.
]]

-- inherits from Rect
Paddle = Class{__includes = Rect}

PADDLE_BASE_WIDTH = 32      -- width of the smallest paddle. all other paddles are multiples of that width
PADDLE_HEIGHT = 16
PADDLE_NUM_SKINS = 4        -- number of different paddle colors in the spritesheet
PADDLE_NUM_SIZES = 4        -- number of different paddle sizes in the spritesheet

--[[
    Our Paddle will initialize at the same spot every time, in the middle
    of the world horizontally, toward the bottom.
]]
function Paddle:init(skin)
    -- 2 is the starting size, as the smallest is too tough to start with. range: 1 - PADDLE_NUM_SIZES
    self.default_size = 2
    self.size = self.default_size

    -- starting dimensions
    self.width = PADDLE_BASE_WIDTH * self.size
    self.height = PADDLE_HEIGHT

    -- x is placed in the middle
    self.x = VIRTUAL_WIDTH / 2 - self.width / 2

    -- y is placed a little above the bottom edge of the screen
    self.y = VIRTUAL_HEIGHT - PADDLE_HEIGHT * 2

    -- start with no velocity
    self.dx = 0

    -- the skin only has the effect of changing our color, used to offset us
    -- into the gPaddleSkins table later. range: 1 - PADDLE_NUM_SKINS
    self.skin = skin
end

-- used when a paddle shrink powerup was picked up
-- decrease the paddle size by PADDLE_BASE_WIDTH
function Paddle:shrink()
    if self.size > 1 then
        self.size = self.size - 1
        self.width = PADDLE_BASE_WIDTH * self.size
    end
end

-- used when a paddle grow powerup was picked up
-- increase the paddle size by PADDLE_BASE_WIDTH
function Paddle:grow()
    if self.size < PADDLE_NUM_SIZES then
        self.size = self.size + 1
        self.width = PADDLE_BASE_WIDTH * self.size
    end
end

-- used to revert the paddle back to normal from a powerup effect
function Paddle:default()
    self.size = self.default_size
    self.width = PADDLE_BASE_WIDTH * self.size
end

function Paddle:update(dt)
    -- keyboard input
    if love.keyboard.isDown('left') then
        self.dx = -PADDLE_SPEED
    elseif love.keyboard.isDown('right') then
        self.dx = PADDLE_SPEED
    else
        self.dx = 0
    end

    -- math.max ensures that we're the greater of 0 or the player's
    -- current calculated Y position when pressing left so that we don't
    -- go into the negatives; the movement calculation is simply our
    -- previously-defined paddle speed scaled by dt
    if self.dx < 0 then
        self.x = math.max(0, self.x + self.dx * dt)
    -- similar to before, this time we use math.min to ensure we don't
    -- go any farther than the right edge of the screen minus the paddle's height
    else
        self.x = math.min(VIRTUAL_WIDTH - self.width, self.x + self.dx * dt)
    end
end

--[[
    Render the paddle by drawing the main texture, passing in the quad
    that corresponds to the proper skin and size.
]]
function Paddle:render()
    love.graphics.draw(gTextures['main'], gFrames['paddles'][self.size + PADDLE_NUM_SIZES * (self.skin - 1)],
        self.x, self.y)
end
