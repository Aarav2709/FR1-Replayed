-- createSprite.lua — Sprite creation helper module
-- Provides utility functions for creating animated sprites from the
-- pre-loaded sprite factories in storyboard.gameDataTable.sprites

local storyboard = require("modules.storyboard")

local createSprite = {}

--------------------------------------------------------------------------------
-- createFromFactory(factoryName, x, y, group)
-- Creates a sprite instance from a named factory in gameDataTable.sprites
--------------------------------------------------------------------------------
function createSprite.createFromFactory(factoryName, x, y, group)
    local sprites = storyboard.gameDataTable and storyboard.gameDataTable.sprites
    if not sprites then
        print("createSprite: gameDataTable.sprites not initialized")
        return nil
    end

    local factory = sprites[factoryName]
    if not factory then
        print("createSprite: factory not found — " .. tostring(factoryName))
        return nil
    end

    local instance = factory.newInstance()
    if instance then
        instance.x = x or display.contentCenterX
        instance.y = y or display.contentCenterY
        if group then
            group:insert(instance)
        end
    end
    return instance
end

--------------------------------------------------------------------------------
-- createAvatarSprite(avatarData, x, y, scale, group)
-- Creates a character/avatar display group from animation data
--------------------------------------------------------------------------------
function createSprite.createAvatarSprite(avatarData, x, y, scale, group)
    local avatarGroup = display.newGroup()
    avatarGroup.x = x or display.contentCenterX
    avatarGroup.y = y or display.contentCenterY

    if avatarData then
        -- Body
        if avatarData.body then
            local body = display.newImageRect(avatarGroup, avatarData.body, 64, 64)
            body.x = 0
            body.y = 0
        end

        -- Head
        if avatarData.head then
            local head = display.newImageRect(avatarGroup, avatarData.head, 64, 64)
            head.x = 0
            head.y = -20
        end

        -- Hat
        if avatarData.hat then
            local hat = display.newImageRect(avatarGroup, avatarData.hat, 64, 64)
            hat.x = 0
            hat.y = -36
        end

        -- Feet
        if avatarData.feet then
            local feet = display.newImageRect(avatarGroup, avatarData.feet, 64, 64)
            feet.x = 0
            feet.y = 20
        end
    end

    if scale then
        avatarGroup:scale(scale, scale)
    end

    if group then
        group:insert(avatarGroup)
    end

    return avatarGroup
end

--------------------------------------------------------------------------------
-- createSimpleSprite(imagePath, width, height, x, y, group)
-- Creates a simple static image sprite
--------------------------------------------------------------------------------
function createSprite.createSimpleSprite(imagePath, width, height, x, y, group)
    local img = display.newImageRect(imagePath, width or 64, height or 64)
    if img then
        img.x = x or display.contentCenterX
        img.y = y or display.contentCenterY
        if group then
            group:insert(img)
        end
    end
    return img
end

--------------------------------------------------------------------------------
-- updateAvatar(avatarData)
-- Updates the current avatar display. In offline mode this is a no-op
-- since the avatar rendering system requires full sprite sheet data.
-- avatarData is { avatar, hat, item, boots } indices or nil
--------------------------------------------------------------------------------
function createSprite.updateAvatar(avatarData)
    -- Store current avatar data for later use
    createSprite._currentAvatarData = avatarData
    -- In offline/stub mode, avatar rendering is simplified — no-op here
end

return createSprite
