--[[
    GD50
    Breakout Remake

    -- StartState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Helper functions for writing games.
]]

--[[
    Given an "atlas" (a texture with multiple sprites/ spritesheet), as well as a
    width and a height for the tiles therein, split the texture into
    all of the quads by simply dividing it evenly.
    The returned spritesheet indexes the quads from left to right and top to bottom (starting index: 1)
]]
function GenerateQuads(atlas, tilewidth, tileheight)
    local sheet_width = atlas:getWidth() / tilewidth
    local sheet_height = atlas:getHeight() / tileheight

    local sheet_counter = 1
    local spritesheet = {}

    for y = 0, sheet_height - 1 do
        for x = 0, sheet_width - 1 do
            spritesheet[sheet_counter] =
                love.graphics.newQuad(x * tilewidth, y * tileheight, tilewidth,
                tileheight, atlas:getDimensions())
            sheet_counter = sheet_counter + 1
        end
    end

    return spritesheet
end

--[[
    This function is specifically made to piece out the bricks from the
    sprite sheet. Since the sprite sheet has non-uniform sprites within,
    we have to return a subset of GenerateQuads.
]]
function GenerateQuadsBricks(atlas)
    -- there are 20 bricks in use (first 20 in the sprite sheet. the others are not used)
    return table.slice(GenerateQuads(atlas, BRICK_WIDTH, BRICK_HEIGHT), 1, 20)
end

--[[
    This function is specifically made to piece out the paddles from the
    sprite sheet. For this, we have to piece out the paddles a little more
    manually, since they are all different sizes.
]]
function GenerateQuadsPaddles(atlas)
    local x = 0                     -- set to x in the atlas where the paddles begin
    local y = 4 * BRICK_HEIGHT      -- set to y in the atlas where the paddles begin

    local counter = 1       -- counter for the number of the paddle
    local quads = {}

    for i = 1, PADDLE_NUM_SKINS do
        -- smallest
        quads[counter] = love.graphics.newQuad(x, y, PADDLE_BASE_WIDTH, PADDLE_HEIGHT,
            atlas:getDimensions())
        counter = counter + 1
        -- medium
        quads[counter] = love.graphics.newQuad(x + PADDLE_BASE_WIDTH, y, PADDLE_BASE_WIDTH * 2, PADDLE_HEIGHT,
            atlas:getDimensions())
        counter = counter + 1
        -- large
        quads[counter] = love.graphics.newQuad(x + PADDLE_BASE_WIDTH * 3, y, PADDLE_BASE_WIDTH * 3, PADDLE_HEIGHT,
            atlas:getDimensions())
        counter = counter + 1
        -- huge (1 row below the smaller paddles of this color)
        quads[counter] = love.graphics.newQuad(x, y + PADDLE_HEIGHT, PADDLE_BASE_WIDTH * 4, PADDLE_HEIGHT,
            atlas:getDimensions())
        counter = counter + 1

        -- prepare X and Y for the next set of paddles
        x = 0
        y = y + PADDLE_HEIGHT * 2
    end

    return quads
end

--[[
    This function is specifically made to piece out the balls from the
    sprite sheet (atlas). For this, we have to piece out the balls a little more
    manually, since they are in an awkward part of the sheet and small.
]]
function GenerateQuadsBalls(atlas)
    local x = BRICK_WIDTH * 3             -- set to x in the atlas where the balls begin
    local y = BRICK_HEIGHT * 3            -- set to y in the atlas where the balls begin

    local counter = 1
    local quads = {}

    for i = 0, 3 do         -- the first ball row (4 balls)
        quads[counter] = love.graphics.newQuad(x, y, BALL_SIZE, BALL_SIZE, atlas:getDimensions())
        x = x + BALL_SIZE
        counter = counter + 1
    end

    x = BRICK_WIDTH * 3
    y = y + BALL_SIZE

    for i = 0, 2 do         -- the second ball row (3 balls)
        quads[counter] = love.graphics.newQuad(x, y, BALL_SIZE, BALL_SIZE, atlas:getDimensions())
        x = x + BALL_SIZE
        counter = counter + 1
    end

    return quads
end

--[[
    piece out the powerups from the sprite sheet.
]]
function GenerateQuadsPowerups(atlas)
    local x = 0                                         -- set to x in the atlas where the powerups begin
    local y = 4 * BRICK_HEIGHT + 8 * PADDLE_HEIGHT      -- set to y in the atlas where the powerups begin

    local quads = {}

    for i = 1, NUM_POWERUPS do
        quads[i] = love.graphics.newQuad(x, y, POWERUP_SIZE, POWERUP_SIZE, atlas:getDimensions())
        x = x + POWERUP_SIZE
    end

    return quads
end
