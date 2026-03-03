-- startScreen.lua — Start/Welcome screen scene
-- Reconstructed from decompiled startScreen.lu.lua
-- Displays Register, Login, and Facebook buttons

local storyboard = require("modules.storyboard")
local scene = storyboard.newScene()

local gui = require("modules.gui")
local localization = storyboard.localized
local database = storyboard.database

local facebook = require("modules.lib_facebook")

-- Scene-level references
local registerButton
local loginButton
local facebookButton
local background

--------------------------------------------------------------------------------
-- createScene
--------------------------------------------------------------------------------

function scene:createScene(event)
    local group = self.view

    -- Background image (480x320)
    background = display.newImageRect("images/gui/background/startScreen.png", 480, 320)
    background.x = display.contentCenterX
    background.y = display.contentCenterY
    group:insert(background)

    -- Register button
    registerButton = gui.newButton({
        image = "images/gui/button/blank.png",

        text = {
            localization.get("Register"),
            nil,
            18,
            nil,
            0,
            0,
        },
        width = 200,
        height = 40,
        x = display.contentCenterX,
        y = display.contentCenterY - 40,
        displayGroup = group,
        onRelease = function(event)
            storyboard.gotoScene("scenes.registerScene", "slideLeft", 200)
        end,
    })

    -- Login button
    loginButton = gui.newButton({
        image = "images/gui/button/blank.png",

        text = {
            localization.get("Login"),
            nil,
            18,
            { ar = 13 },
            0,
            0,
        },
        width = 200,
        height = 40,
        x = 430,
        y = display.contentCenterY + 10,
        displayGroup = group,
        onRelease = function(event)
            storyboard.gotoScene("scenes.loginScene", "slideLeft", 200)
        end,
    })

    -- Facebook button
    facebookButton = gui.newButton({
        image = "images/gui/button/facebookBlank.png",
        text = {
            localization.get("Use"),
            nil,
            14,
            nil,
            8,
            -8,
            { 1, 1, 1 },
        },
        width = 200,
        height = 40,
        x = display.contentCenterX,
        y = display.contentCenterY + 60,
        displayGroup = group,
        onRelease = function(event)
            storyboard.gotoScene("scenes.facebookScene", "slideLeft", 200)
        end,
    })
end

--------------------------------------------------------------------------------
-- enterScene
--------------------------------------------------------------------------------

function scene:enterScene(event)
    local group = self.view

    -- Log out of Facebook
    pcall(function()
        facebook.logout()
    end)

    -- Reset global state
    storyboard.onlineFriends = nil
    storyboard.gameInvites = nil
    storyboard.playerInfo = nil
    storyboard.tutorial = false
    storyboard.cheater = false

    -- Reset database (keep receipts)
    if database then
        database.resetWithoutReceipts()
    end

    -- Set default avatar
    storyboard.avatar = { 1, 1, 1, 1 }

    -- Small delay before adding listeners
    timer.performWithDelay(200, function()
        if registerButton then
            registerButton.addListener()
        end
        if loginButton then
            loginButton.addListener()
        end
        if facebookButton then
            facebookButton.addListener()
        end
    end)
end

--------------------------------------------------------------------------------
-- exitScene
--------------------------------------------------------------------------------

function scene:exitScene(event)
    if registerButton then
        registerButton.removeListener()
    end
    if loginButton then
        loginButton.removeListener()
    end
    if facebookButton then
        facebookButton.removeListener()
    end
end

--------------------------------------------------------------------------------
-- destroyScene
--------------------------------------------------------------------------------

function scene:destroyScene(event)
    registerButton = nil
    loginButton = nil
    facebookButton = nil
    background = nil
end

--------------------------------------------------------------------------------
-- Scene event listeners
--------------------------------------------------------------------------------

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
