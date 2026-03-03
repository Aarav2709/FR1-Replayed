-- dinodash.lua — Dino Dash cross-promotion overlay scene
-- Shows a promotional overlay for the Dino Dash game (Dirtybit's other game)
-- Displayed as an overlay from the main menu

local storyboard = require("modules.storyboard")
local scene = storyboard.newScene()
local gui = require("modules.gui")

local overlay
local closeButton
local promoImage

--------------------------------------------------------------------------------
-- createScene
--------------------------------------------------------------------------------

function scene:createScene(event)
    local group = self.view
    local font = storyboard.gameDataTable and storyboard.gameDataTable.font or native.systemFont

    -- Semi-transparent background overlay
    overlay = display.newRect(group,
        display.contentCenterX, display.contentCenterY,
        display.actualContentWidth, display.actualContentHeight)
    overlay:setFillColor(0, 0, 0, 0.7)

    -- Promo image (use the dinodash button image as promo)
    promoImage = display.newImageRect(group,
        "images/gui/button/dinodash.png", 200, 60)
    promoImage.x = display.contentCenterX
    promoImage.y = display.contentCenterY - 20

    -- Close button
    closeButton = gui.newButton({
        image = "images/gui/button/blank.png",
        text = {
            "Close",
            nil,
            16,
        },
        width = 100,
        height = 35,
        x = display.contentCenterX,
        y = display.contentCenterY + 60,
        displayGroup = group,
        onRelease = function()
            storyboard.hideOverlay(true, "fade", 200)
        end,
    })
end

--------------------------------------------------------------------------------
-- enterScene
--------------------------------------------------------------------------------

function scene:enterScene(event)
    -- Nothing to do
end

--------------------------------------------------------------------------------
-- exitScene
--------------------------------------------------------------------------------

function scene:exitScene(event)
    -- Nothing to clean up
end

--------------------------------------------------------------------------------
-- destroyScene
--------------------------------------------------------------------------------

function scene:destroyScene(event)
    overlay = nil
    closeButton = nil
    promoImage = nil
end

--------------------------------------------------------------------------------
-- Scene event listeners
--------------------------------------------------------------------------------

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
