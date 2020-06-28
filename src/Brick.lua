--[[
    GD50
    Breakout Remake

    -- Brick Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents a brick in the world space that the ball can collide with;
    differently colored bricks have different point values. On collision,
    the ball will bounce away depending on the angle of collision. When all
    bricks are cleared in the current map, the player should be taken to a new
    layout of bricks.
]]

-- inherits from Rect
Brick = Class{__includes = Rect}

BRICK_WIDTH = 32
BRICK_HEIGHT = 16
BRICK_NUM_COLORS = 5        -- number of different brick colors in the spritesheet
BRICK_NUM_TIERS = 4         -- every color has 4 different tiers that also have distinct visuals

-- some of the colors in our palette (to be used with particle systems)
local palette_colors = {
    -- blue
    [1] = {
        ['r'] = 99/255,
        ['g'] = 155/255,
        ['b'] = 255/255
    },
    -- green
    [2] = {
        ['r'] = 106/255,
        ['g'] = 190/255,
        ['b'] = 47/255
    },
    -- red
    [3] = {
        ['r'] = 217/255,
        ['g'] = 87/255,
        ['b'] = 99/255
    },
    -- purple
    [4] = {
        ['r'] = 215/255,
        ['g'] = 123/255,
        ['b'] = 186/255
    },
    -- gold
    [5] = {
        ['r'] = 251/255,
        ['g'] = 242/255,
        ['b'] = 54/255
    }
}

function Brick:init(x, y)
    -- used for coloring and score calculation
    self.tier = 1       -- range 1 - BRICK_NUM_TIERS. the tier specifies how many times the ball must hit the brick to remove it and how many points are gained when hit.
    self.color = 1      -- range 1 - BRICK_NUM_COLORS. blue, green, red, violet, orange. the color specifies which powerups the brick can spawn
    
    self.x = x
    self.y = y
    self.width = BRICK_WIDTH
    self.height = BRICK_HEIGHT
    
    -- used to determine whether this brick should be rendered/ updated
    self.is_in_play = true

    -- particle system belonging to the brick, emitted on hit. second parameter is the max number of particles at the same time.
    self.psystem = love.graphics.newParticleSystem(gTextures['particle'], 128)

    -- various behavior-determining functions for the particle system
    -- https://love2d.org/wiki/ParticleSystem

    -- lasts between (min, max) seconds
    self.psystem:setParticleLifetime(0.3, 1)

    -- set an acceleration of anywhere between ( xmin, ymin, xmax, ymax )
    -- give generally downward acceleration to simulate gravity
    self.psystem:setLinearAcceleration(-40, -20, 40, 200)

    -- spread of particles; normal: Normal (gaussian) distribution. looks more natural than uniform
    -- maximum spawn distance from the emitter along the x and y axis
    self.psystem:setEmissionArea('normal', 10, 10)
end

--[[
    Triggers a hit on the brick, taking it out of play if at 0 health or
    changing its color otherwise.
]]
function Brick:hit()
    -- Sets a series of colors to apply to the particle sprite. The particle system will interpolate between each color evenly over the particle's lifetime.
    -- in this case, we give it our self.color but with varying alpha; higher for higher tiers, fading to 0 over the particle's lifetime
    self.psystem:setColors(
        palette_colors[self.color].r,
        palette_colors[self.color].g,
        palette_colors[self.color].b,
        55 * self.tier / 255,         -- alpha 1
        palette_colors[self.color].r,
        palette_colors[self.color].g,
        palette_colors[self.color].b,
        0                             -- alpha 2
    )
    -- emit a number of particles
    self.psystem:emit(64)

    -- sound on hit
    gSounds['brick-hit-2']:stop()
    gSounds['brick-hit-2']:play()

    -- if brick is at a higher tier than the base, go down a tier
    if self.tier > 1 then
        self.tier = self.tier - 1
    else
        -- if brick is in the first tier, remove brick from play
        self.is_in_play = false
    end

    -- play a second layer sound if the brick is destroyed
    if not self.is_in_play then
        gSounds['brick-hit-1']:stop()
        gSounds['brick-hit-1']:play()
    end
end

-- Update the particle system; moving, creating and killing particles.
function Brick:update(dt)
    self.psystem:update(dt)
end

function Brick:render()
    if self.is_in_play then
        love.graphics.draw(
            gTextures['main'], 
            -- (self.color - 1) * BRICK_NUM_TIERS to get the color offset, then add tier to that
            -- to draw the correct tier and color brick onto the screen
            gFrames['bricks'][1 + ((self.color - 1) * BRICK_NUM_TIERS) + (self.tier - 1)],
            self.x, self.y
        )
    end
end

--[[
    Need a separate render function for our particles so it can be called after all bricks are drawn;
    otherwise, some bricks would render over other bricks' particle systems.
]]
function Brick:renderParticles()
    love.graphics.draw(self.psystem, self.x + self.width / 2, self.y + self.height / 2)
end
