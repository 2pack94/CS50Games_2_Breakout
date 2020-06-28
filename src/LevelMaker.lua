--[[
    GD50
    Breakout Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Creates randomized levels for our Breakout game. Returns a table of
    bricks that the game can render, based on the current level we're at
    in the game.
]]

LevelMaker = Class{}

--[[
    Creates a table of Bricks to be returned to the main game, with different
    possible ways of randomizing rows and columns of bricks. Calculates the
    brick colors and tiers to choose based on the level passed in.
]]
function LevelMaker.createMap(level)
    -- table that holds all generated bricks for this level
    local bricks = {}

    local max_num_rows = 6
    local min_num_rows = 1
    -- increase the maximum number of rows depending on the level
    max_num_rows = math.min(max_num_rows, min_num_rows + math.floor(level / 2))
    -- randomly choose the number of rows
    local num_rows = math.random(min_num_rows, max_num_rows)

    local max_num_cols_on_screen = math.floor(VIRTUAL_WIDTH / BRICK_WIDTH)    -- number of bricks that fit in the screen horizontally
    local max_num_cols = max_num_cols_on_screen
    local min_num_cols = 7
    -- increase the maximum number of cols depending on the level
    max_num_cols = math.min(max_num_cols, min_num_cols + math.floor(level / 2))
    local extra_screen_space = VIRTUAL_WIDTH % BRICK_WIDTH          -- number of pixels that are left over when max_num_cols of bricks are on the screen
    -- randomly choose the number of columns, ensuring odd
    local num_cols = math.random(min_num_cols, max_num_cols)
    num_cols = num_cols % 2 == 0 and (num_cols + 1) or num_cols     -- if not odd, make odd
    num_cols = math.min(num_cols, max_num_cols)                     -- if num_cols > max_num_cols

    -- highest possible spawned brick Tier in this level
    -- add a new tier to the map generation for every 5th level until BRICK_NUM_TIERS is reached
    local highest_tier = math.min(BRICK_NUM_TIERS, math.floor(level / 5) + 1)

    -- lay out bricks such that they touch each other and fill the space
    for y = 1, num_rows do
        -- whether we want to enable skipping for this row
        local is_skip_pattern = math.random(2) == 1 and true or false

        -- whether we want to enable alternating colors for this row
        local is_alternate_pattern = math.random(2) == 1 and true or false
        
        -- choose two colors and tiers to alternate between
        -- if not alternating, use only color_choise1 and tier_choise1
        local color_choise1 = math.random(1, BRICK_NUM_COLORS)
        local color_choise2 = math.random(1, BRICK_NUM_COLORS)
        local tier_choise1 = math.random(1, highest_tier)
        local tier_choise2 = math.random(1, highest_tier)
        
        -- used only for skip pattern. if true, skip the current brick. initialize randomly
        local is_skip = math.random(2) == 1 and true or false

        -- used only for alternate pattern, chooses which color/ tier to pick for the current brick. initialize randomly
        -- if true choose color_choise1 and tier_choise1 for this v
        local alternate_flag = math.random(2) == 1 and true or false

        for x = 1, num_cols do
            if is_skip_pattern then     -- skipping is turned on for this row
                if is_skip then
                    -- turn skipping off for the next brick
                    is_skip = false

                    -- Lua doesn't have a continue statement, so this is the workaround
                    goto continue
                else
                    -- turn skipping on for the next brick
                    is_skip = true
                end
            end

            local brick = Brick(
                -- x-coordinate
                (x-1)                                           -- decrement x by 1 because tables are 1-indexed, coords are 0
                * BRICK_WIDTH                                   -- multiply by BRICK_WIDTH
                + extra_screen_space / 2                        -- extra padding when VIRTUAL_WIDTH is not a multiple of BRICK_WIDTH
                + (max_num_cols_on_screen - num_cols) * (BRICK_WIDTH / 2), -- left-side padding for when there are fewer than max_num_cols columns
                
                -- y-coordinate
                y * BRICK_HEIGHT        -- this also adds a top padding
            )

            -- if we're alternating, figure out which color/ tier we're on
            if is_alternate_pattern then
                if alternate_flag then
                    brick.color = color_choise1
                    brick.tier = tier_choise1
                else
                    brick.color = color_choise2
                    brick.tier = tier_choise2
                end
                alternate_flag = not alternate_flag     -- toggle the alternate flag
            else    -- if not alternating and the brick is not skipped, use the solid color/ tier
                brick.color = color_choise1
                brick.tier = tier_choise1
            end

            table.insert(bricks, brick)

            -- Flag for goto statement (Lua doesn't have a continue statement)
            ::continue::
        end
    end

    return bricks
end
