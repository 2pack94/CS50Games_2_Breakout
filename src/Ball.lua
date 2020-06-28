--[[
    GD50
    Breakout Remake

    -- Ball Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents a ball which will bounce back and forth between the sides
    of the world space, the player's paddle, and the bricks laid out above
    the paddle. The ball can have a skin, which is chosen at random, just
    for visual variety.
]]

-- inherits from Rect
Ball = Class{__includes = Rect}

BALL_SIZE = 8
NUM_BALL_COLORS = 7

local strong_ball_color = {
    -- gold
    ['r'] = 251/255,
    ['g'] = 242/255,
    ['b'] = 54/255
}

function Ball:init(skin)
    -- positional and dimensional variables (x, y, w, h)
    self.x = 0
    self.y = 0
    self.width = BALL_SIZE
    self.height = BALL_SIZE

    -- x and y  velocity
    self.dy = 0
    self.dx = 0
    -- maximum y velocity (unsigned int)
    self.max_dy = 225
    -- factor by which dy of the ball is increased when it hits a brick
    self.dy_inc = 1.025

    -- this will effectively be the color of our ball, and we will index
    -- our table of Quads relating to the global block texture using this. range: 1 - NUM_BALL_COLORS
    self.skin = skin

    -- set to true when the strong ball powerup was picked up during the game.
    -- this changes the color of the ball (to a reserved color on the sprite sheet). Also the ball hits bricks twice.
    self.is_strong = false

    -- particle system for strong ball powerup effect (see brick Class for description)
    self.psystem = love.graphics.newParticleSystem(gTextures['particle'], 128)
    self.psystem:setParticleLifetime(0.2, 0.5)
    self.psystem:setLinearAcceleration(-10, -10, 10, 80)
    self.psystem:setEmissionArea('normal', 3, 3)
    self.psystem:setEmissionRate(20)        -- emit x particles per second
    self.psystem:setColors(
        strong_ball_color.r,
        strong_ball_color.g,
        strong_ball_color.b,
        200 / 255
    )
end

--[[
    put the ball in the top middle of the paddle
]]
function Ball:centerPaddle(paddle)
    self.x = paddle.x + (paddle.width / 2) - self.width / 2
    self.y = paddle.y - self.height
end

--[[
    give the ball its starting velocity. with a random x velocity
]]
function Ball:launch()
    self.dx = math.random(-50, 50)
    self.dy = -80
end

--[[
    Rebound the ball by its displacement values (update position) and invert its velocity if there was a displacement (reflect from box).
    see: https://github.com/noooway/love2d_arkanoid_tutorial/wiki/Resolving-Collisions
    The displacement is the shift in the position (x, y) of the ball necessary to resolve the possible overlap with another Box (see Rect:getDisplacement())
    Set the bigger shift amount to 0. Rebound the ball only with the smaller shift value (smallest effort to resolve overlap).
    the following assumptions can be made (there can be rare cases where these assumptions are not true, e.g. if one velocity component is much higher than the other):
        abs(shift_x) is smaller (not 0) and shift_x is negative: right side of the ball collided with the left side of the Box
        abs(shift_x) is smaller (not 0) and shift_x is positive: left side of the ball collided with the right side of the Box
        abs(shift_y) is smaller (not 0) and shift_y is negative: bottom side of the ball collided with the top side of the Box
        abs(shift_y) is smaller (not 0) and shift_y is positive: top side of the ball collided with the bottom side of the Box
    shift_x, shift_y: input. x and y shift values.
]]
function Ball:reboundReflect(shift_x, shift_y)
    -- set the bigger shift amount to 0. if they are the same, set the y shift to 0.
    if math.abs(shift_x) > math.abs(shift_y) then
        shift_x = 0
    else
        shift_y = 0
    end
    -- if shift not 0, rebound the ball and invert the corresponding velocity part to reflect the ball from the collision plane (only works properly if the collision plane is not moving)
    if shift_x ~= 0 then
        self.x = self.x + shift_x
        self.dx = -self.dx
    elseif shift_y ~= 0 then
        self.y = self.y + shift_y
        self.dy = -self.dy
    end
end

-- reflect without rebounding.
-- use after obtaining the shift values from Rect:getDisplacement() and after Rect:rebound()
-- same reflection as in Ball:reboundReflect()
function Ball:reflect(shift_x, shift_y)
    -- set the bigger shift amount to 0. if they are the same, set the y shift to 0.
    if math.abs(shift_x) > math.abs(shift_y) then
        shift_x = 0
    else
        shift_y = 0
    end
    -- if shift not 0, invert the corresponding velocity part to reflect the ball from the collision plane (only works properly if the collision plane is not moving)
    if shift_x ~= 0 then
        self.dx = -self.dx
    elseif shift_y ~= 0 then
        self.dy = -self.dy
    end
end

--[[
    collision logic with the paddle
]]
function Ball:collidePaddle(paddle)
    local is_ball_intersect, ball_shift_x, ball_shift_y = false, 0, 0
    -- check if ball collided with the paddle
    is_ball_intersect, ball_shift_x, ball_shift_y = self:getDisplacement(paddle)
    if is_ball_intersect then
        -- rebound the ball, but don't reflect (invert 1 velocity component) yet.
        -- only do not reflect if paddle and ball move in the same direction and the paddles far side was hit
        self:rebound(ball_shift_x, ball_shift_y)
        -- if the top of the paddle was hit (can only be checked properly after rebound())
        if self.x + self.width > paddle.x and self.x < paddle.x + paddle.width then
            -- reflect ball off of paddle
            self:reflect(ball_shift_x, ball_shift_y)

            -- if the paddle is moving, alter the balls x velocity
            -- movement in the direction of the balls dx amplifies the balls dx
            -- movement in the opposite direction lowers the balls dx (can also change the sign of the balls dx)
            self.dx = self.dx + (paddle.dx / 4)

            -- alter the balls x velocity based on the point of the paddle that was hit
            -- the more to the left the paddle is hit, the more the ball will go the left
            -- the more to the right the paddle is hit, the more the ball will go the right
            -- this factor is the x distance between the paddles and balls center x
            local ball_dx_add_fac = (self.x + self.width / 2) - (paddle.x + paddle.width / 2)
            -- this is the base value that gets scaled and then added to the balls dx
            local ball_dx_add_base = 1.6
            self.dx = self.dx + (ball_dx_add_fac * ball_dx_add_base)
        else    -- if a side of the paddle was hit
            -- flag that indicates if the ball should be reflected (by inverting its velocity)
            -- depending on the situation bouncing the ball off the paddle is achieved by reflecting or not reflecting
            local is_reflect = false
            if paddle.dx ~= 0 then     -- if the paddle is moving
                -- ball and paddle move in opposite directions
                if (self.dx > 0 and paddle.dx < 0) or (self.dx < 0 and paddle.dx > 0) then
                    is_reflect = true       -- after reflect, ball and paddle move in the same x direction
                -- ball and paddle move in the same direction
                -- paddle is moving right and was hit on the left side or paddle is moving left and was hit on the right side
                elseif (paddle.dx > 0 and self.x <= paddle.x) or (paddle.dx < 0 and self.x > paddle.x) then
                    is_reflect = true       -- after reflect, ball and paddle move in the opposite x direction
                end

                -- The ball does not get reflected if they are moving in the same direction and
                -- the paddle is moving right and was hit on the right side or the paddle is moving left and was hit on the left side
                -- In that case only the paddles x velocity should get added to the ball, so it bounces off the paddle
            else                            -- if the paddle is not moving
                is_reflect = true
            end
            if is_reflect then
                -- reflect ball off of paddle
                self:reflect(ball_shift_x, ball_shift_y)
            end
            -- add the paddles x velocity to the ball
            self.dx = self.dx + paddle.dx
        end

        gSounds['paddle-hit']:play()
    end
end

function Ball:update(dt)
    -- restrict maximum ball y velocity
    if math.abs(self.dy) > self.max_dy then
        if self.dy >= 0 then
            self.dy = self.max_dy
        else
            self.dy = -self.max_dy
        end
    end
    -- update position according to velocity
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt

    -- allow ball to bounce off walls (collisions with paddle, bricks and bottom are calculated in PlayState)
    -- left wall
    if self.x < 0 then
        self.x = 0
        self.dx = -self.dx
        gSounds['wall-hit']:play()
    end
    -- right wall
    if self.x + self.width > VIRTUAL_WIDTH then
        self.x = VIRTUAL_WIDTH - self.width
        self.dx = -self.dx
        gSounds['wall-hit']:play()
    end
    -- top wall
    if self.y < 0 then
        self.y = 0
        self.dy = -self.dy
        gSounds['wall-hit']:play()
    end

    if self.is_strong then      -- if strong ball effect applies
        -- update the particle system
        self.psystem:setPosition(self.x + self.width / 2, self.y + self.height / 2)     -- set position of the emitter
        self.psystem:update(dt)
    end
end

function Ball:render()
    local draw_color = self.skin
    if self.is_strong then              -- if strong ball effect applies
        draw_color = NUM_BALL_COLORS    -- last ball in the sprite sheet: yellow (reserved for this powerup effect)
        -- render particle system at the position that was set last
        love.graphics.draw(self.psystem)
    end

    -- render ball
    -- gTextures is our global texture for all blocks
    -- gFrames['balls'] is a table of quads mapping to each individual ball skin in the texture
    love.graphics.draw(gTextures['main'], gFrames['balls'][draw_color],
    self.x, self.y)
end
