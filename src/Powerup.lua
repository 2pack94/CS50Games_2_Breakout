--[[
    GD50
    Breakout Remake

    -- Powerup Class --

    Author: Richard Tuppack

    Represents a Powerup that spawns occasionally from bricks when they are destroyed.
    After spawning they float downwards. If the player catches the Powerup with the paddle a Powerup specific effect starts
    The effects always ends when a level was cleared or when all balls were dropped (except for damage).
    There are good and bad powerups:
    Good:
        increase the size of the paddle
        add an additional ball
        strong ball: ball does double the damage to the bricks (on a timer)
    Bad:
        shrink the paddle
        1 health damage
]]

POWERUP_SIZE = 16
NUM_POWERUPS = 5

-- inherits from Rect
Powerup = Class{__includes = Rect}

-- the powerup depends on the location and color of the brick
-- brick: input. Brick object
function Powerup:init(brick)
    -- dimensions and coordinates. spawn in the middle of the brick
    self.width = POWERUP_SIZE
    self.height = POWERUP_SIZE
    self.x = brick.x + brick.width / 2 - self.width / 2
    self.y = brick.y + brick.height / 2 - self.height / 2
    -- downward velocity
    self.dy = 50
    -- there are NUM_POWERUPS powerups in use. These are the first in the sprite sheet. The others are not used
    -- from left to right: [1] damage [2] paddle shrink [3] paddle grow [4] add ball [5] strong ball
    -- type of powerup depends on the ball
    if brick.color == 1 then            -- blue
        self.type = math.random(2, 3)                   -- paddle shrink or paddle grow
    elseif brick.color == 2 then        -- green
        self.type = math.random(2, 3)                   -- paddle shrink or paddle grow
    elseif brick.color == 3 then        -- red
        self.type = math.random(1, 2) == 1 and 1 or 4   -- damage or add ball
    elseif brick.color == 4 then        -- violet
        self.type = math.random(1, 2) == 1 and 1 or 5   -- damage or strong ball
    elseif brick.color == 5 then        -- orange
        self.type = math.random(4, 5)                   -- add ball or strong ball
    else
        self.type = math.random(1, NUM_POWERUPS)        -- choose the powerup randomly (never happens because there are only 5 bricks)
    end
end

function Powerup:update(dt)
    -- the movement calculation is speed scaled by dt. there is no movement in the x direction
    self.y = self.y + self.dy * dt
end

--[[
    Render the powerup by drawing the main texture, passing in the quad
    that corresponds to the proper type.
]]
function Powerup:render()
    love.graphics.draw(gTextures['main'], gFrames['powerups'][self.type],
        self.x, self.y)
end
