-- gui.lua — GUI button factory module
-- Reconstructed from decompiled gui.lu.lua
-- Creates interactive buttons with optional text, images, and touch handling

local storyboard = require("modules.storyboard")

local gui = {}

--------------------------------------------------------------------------------
-- newButton(params) — Creates a new interactive button
--
-- params:
--   image       — (string) path to button image
--   over        — (string, optional) path to button "pressed" image overlay
--   text        — (string or table) button label
--                  If table: { string, string2, size, languageSizes, x, y, color, embossColor }
--   width       — (number) button width
--   height      — (number) button height
--   x           — (number) x position
--   y           — (number) y position
--   displayGroup — (DisplayGroup, optional) parent group
--   onPress     — (function, optional) called on touch began
--   onRelease   — (function, optional) called on touch ended (inside button)
--   onEvent     — (function, optional) called on all touch events
--   reference   — (string, optional) content reference point
--------------------------------------------------------------------------------

function gui.newButton(params)
    local button = {}
    local buttonGroup = display.newGroup()

    -- Image
    local buttonImage = display.newImageRect(params.image, params.width, params.height)
    buttonImage.x = params.x or 0
    buttonImage.y = params.y or 0
    buttonGroup:insert(buttonImage)

    -- Over image (optional)
    local overImage = nil
    if params.over then
        overImage = display.newImageRect(params.over, params.width, params.height)
        overImage.x = buttonImage.x
        overImage.y = buttonImage.y
        overImage.isVisible = false
        buttonGroup:insert(overImage)
    end

    -- Text label (optional)
    local buttonText = nil
    local buttonText2 = nil

    if params.text then
        local font = storyboard.gameDataTable and storyboard.gameDataTable.font or native.systemFont
        local defaultColor = { 0.0784313725490196, 0.0784313725490196, 0.0784313725490196 }

        if type(params.text) == "string" then
            -- Simple string text
            buttonText = display.newText(params.text, buttonImage.x, buttonImage.y, font, 14)
            buttonText:setFillColor(defaultColor[1], defaultColor[2], defaultColor[3])
            buttonGroup:insert(buttonText)

        elseif type(params.text) == "table" then
            local textData = params.text
            local label = textData[1] or ""
            local label2 = textData[2]
            local fontSize = textData[3] or 14
            local languageSizes = textData[4]
            local textOffsetX = textData[5] or 0
            local textOffsetY = textData[6] or 0
            local textColor = textData[7] or defaultColor
            local embossColor = textData[8]

            -- Apply language-specific font size
            if languageSizes then
                local localization = storyboard.localized
                if localization and localization.language and languageSizes[localization.language] then
                    fontSize = languageSizes[localization.language]
                end
            end

            if embossColor then
                -- Embossed text
                buttonText = display.newEmbossedText(
                    label,
                    buttonImage.x + textOffsetX,
                    buttonImage.y + textOffsetY,
                    font,
                    fontSize
                )
                buttonText:setFillColor(textColor[1], textColor[2], textColor[3])
                buttonText:setEmbossColor(embossColor)
            else
                buttonText = display.newText(
                    label,
                    buttonImage.x + textOffsetX,
                    buttonImage.y + textOffsetY,
                    font,
                    fontSize
                )
                buttonText:setFillColor(textColor[1], textColor[2], textColor[3])
            end
            buttonGroup:insert(buttonText)

            -- Second text line (optional)
            if label2 then
                buttonText2 = display.newText(
                    label2,
                    buttonImage.x + textOffsetX,
                    buttonImage.y + textOffsetY + fontSize + 2,
                    font,
                    fontSize
                )
                buttonText2:setFillColor(textColor[1], textColor[2], textColor[3])
                buttonGroup:insert(buttonText2)
            end
        end
    end

    -- Reference point
    if params.reference then
        buttonGroup.anchorChildren = true
        if params.reference == "TopLeft" then
            buttonGroup.anchorX = 0
            buttonGroup.anchorY = 0
        elseif params.reference == "TopRight" then
            buttonGroup.anchorX = 1
            buttonGroup.anchorY = 0
        elseif params.reference == "BottomLeft" then
            buttonGroup.anchorX = 0
            buttonGroup.anchorY = 1
        elseif params.reference == "BottomRight" then
            buttonGroup.anchorX = 1
            buttonGroup.anchorY = 1
        end
    end

    -- Add to display group
    if params.displayGroup then
        params.displayGroup:insert(buttonGroup)
    end

    ---------------------------------------------------------------------------
    -- Touch handler
    ---------------------------------------------------------------------------
    local function onTouch(event)
        local phase = event.phase
        local target = event.target
        local database = storyboard.database

        if phase == "began" then
            -- Play button sound
            if database and database.getSound() == 1 then
                local sounds = storyboard.gameDataTable and storyboard.gameDataTable.sounds
                if sounds and sounds.buttonSound then
                    audio.play(sounds.buttonSound)
                end
            end

            -- Visual feedback
            if overImage then
                overImage.isVisible = true
                buttonImage.isVisible = false
            else
                buttonImage:setFillColor(0.5)
            end

            display.getCurrentStage():setFocus(target)
            target.isFocused = true

            if params.onPress then
                params.onPress(event)
            end
            if params.onEvent then
                params.onEvent(event)
            end

        elseif target.isFocused then
            if phase == "moved" then
                -- Check if finger moved outside button bounds
                local bounds = target.contentBounds
                if event.x < bounds.xMin or event.x > bounds.xMax or
                   event.y < bounds.yMin or event.y > bounds.yMax then
                    -- Finger moved outside
                    if overImage then
                        overImage.isVisible = false
                        buttonImage.isVisible = true
                    else
                        buttonImage:setFillColor(1)
                    end
                else
                    -- Finger still inside
                    if overImage then
                        overImage.isVisible = true
                        buttonImage.isVisible = false
                    else
                        buttonImage:setFillColor(0.5)
                    end
                end

                if params.onEvent then
                    params.onEvent(event)
                end

            elseif phase == "ended" or phase == "cancelled" then
                -- Restore visual
                if overImage then
                    overImage.isVisible = false
                    buttonImage.isVisible = true
                else
                    buttonImage:setFillColor(1)
                end

                display.getCurrentStage():setFocus(nil)
                target.isFocused = false

                -- Check if ended inside button
                local bounds = target.contentBounds
                if event.x >= bounds.xMin and event.x <= bounds.xMax and
                   event.y >= bounds.yMin and event.y <= bounds.yMax then
                    if params.onRelease then
                        params.onRelease(event)
                    end
                end

                if params.onEvent then
                    params.onEvent(event)
                end
            end
        end

        return true
    end

    ---------------------------------------------------------------------------
    -- Button methods
    ---------------------------------------------------------------------------

    function button.getText()
        return buttonText
    end

    function button.getButton()
        return buttonImage
    end

    function button.getOver()
        return overImage
    end

    function button.getGroup()
        return buttonGroup
    end

    function button.setPosition(x, y)
        buttonGroup.x = x
        buttonGroup.y = y
    end

    function button.updateDisplay(group)
        if group then
            group:insert(buttonGroup)
        end
    end

    function button.showButton(visible)
        buttonGroup.isVisible = visible
    end

    function button.addListener()
        buttonGroup:addEventListener("touch", onTouch)
    end

    function button.removeListener()
        buttonGroup:removeEventListener("touch", onTouch)
    end

    -- Add listener by default
    buttonGroup:addEventListener("touch", onTouch)

    -- Expose the display group so `button.displayGroup` works everywhere
    button.displayGroup = buttonGroup

    -- Forward common display-object properties to the underlying group
    button.x = buttonImage.x
    button.y = buttonImage.y
    setmetatable(button, {
        __index = function(t, k)
            if k == "x" then return buttonGroup.x
            elseif k == "y" then return buttonGroup.y
            elseif k == "isVisible" then return buttonGroup.isVisible
            elseif k == "contentBounds" then return buttonGroup.contentBounds
            end
        end,
        __newindex = function(t, k, v)
            if k == "x" then buttonGroup.x = v
            elseif k == "y" then buttonGroup.y = v
            elseif k == "isVisible" then buttonGroup.isVisible = v
            else rawset(t, k, v)
            end
        end
    })

    return button
end

return gui
