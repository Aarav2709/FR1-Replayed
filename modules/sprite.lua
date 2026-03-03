-- sprite.lua — Compatibility shim for old Corona SDK sprite library
-- Modern Solar2D uses graphics.newImageSheet + display.newSprite directly.
-- This module wraps those APIs to support legacy code.

local M = {}

--- Create a sprite sheet from an image file
-- @param imagePath string - path to the sprite sheet image
-- @param frameWidth number - width of each frame
-- @param frameHeight number - height of each frame
-- @return table - sheet data object
function M.newSpriteSheet(imagePath, frameWidth, frameHeight)
    local sheet = {
        imagePath = imagePath,
        frameWidth = frameWidth,
        frameHeight = frameHeight,
    }
    return sheet
end

--- Create a sprite set (frame configuration) from a sheet
-- @param sheet table - the sprite sheet from newSpriteSheet
-- @param startFrame number - first frame index
-- @param numFrames number - total number of frames
-- @return table - sprite set object
function M.newSpriteSet(sheet, startFrame, numFrames)
    local set = {
        sheet = sheet,
        startFrame = startFrame,
        numFrames = numFrames,
        sequences = {},
    }
    -- Default sequence
    set.sequences["default"] = {
        name = "default",
        start = startFrame,
        count = numFrames,
        time = 1000,
        loopCount = 0,
    }
    return set
end

--- Add a named animation sequence to a sprite set
-- @param set table - the sprite set
-- @param name string - sequence name
-- @param startFrame number - first frame of the sequence
-- @param numFrames number - number of frames
-- @param time number - total animation time in ms
-- @param loopCount number - number of loops (0 = infinite)
function M.add(set, name, startFrame, numFrames, time, loopCount)
    set.sequences[name] = {
        name = name,
        start = startFrame,
        count = numFrames,
        time = time or 1000,
        loopCount = loopCount or 0,
    }
end

--- Create a sprite factory (multi-sprite) from a sprite set
-- This creates the Solar2D image sheet and returns a factory
-- that can produce sprite instances.
-- @param set table - the sprite set
-- @return table - factory with newInstance() method
function M.newSpriteMulti(set)
    local sheet = set.sheet

    -- Build the options for graphics.newImageSheet
    local sheetOptions = {
        width = sheet.frameWidth,
        height = sheet.frameHeight,
        numFrames = set.numFrames,
    }

    -- Create the actual Solar2D image sheet
    local imageSheet = graphics.newImageSheet(sheet.imagePath, sheetOptions)

    -- Build sequence data array for display.newSprite
    local sequenceData = {}
    for name, seq in pairs(set.sequences) do
        sequenceData[#sequenceData + 1] = {
            name = seq.name,
            start = seq.start,
            count = seq.count,
            time = seq.time,
            loopCount = seq.loopCount,
        }
    end

    -- Factory object
    local factory = {
        imageSheet = imageSheet,
        sequenceData = sequenceData,
        set = set,
    }

    --- Create a new sprite instance from this factory
    function factory:newInstance()
        local spriteObj = display.newSprite(self.imageSheet, self.sequenceData)
        return spriteObj
    end

    return factory
end

return M
