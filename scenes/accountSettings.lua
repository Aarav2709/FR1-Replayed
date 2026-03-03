---------------------------------------------------------------------------------
-- accountSettings.lua — Account settings overlay
---------------------------------------------------------------------------------
local storyboard = require("modules.storyboard")
local scene = storyboard.newScene()

-- Module-level variables
local backButton
local keyListener
local background
local usernameText
local emailText
local changePasswordButton
local syncButton
local enterFrameListener

---------------------------------------------------------------------------------
-- CREATE SCENE
---------------------------------------------------------------------------------
function scene:createScene(event)
    local view = self.view
    local gui = require("modules.gui")
    local font = storyboard.gameDataTable.font
    local fontSize = storyboard.localized.getFontSize()
    local textColor = {1, 1, 1, 1}

    ---------------------------------------------------------------------------
    -- Background
    ---------------------------------------------------------------------------
    background = display.newImageRect("images/gui/background/login.png",
        display.contentWidth, display.contentHeight)
    background.x = display.contentCenterX
    background.y = display.contentCenterY
    view:insert(background)

    ---------------------------------------------------------------------------
    -- Settings tab bar
    ---------------------------------------------------------------------------
    local settingsModule = require("modules.settingsModule")
    local settingsBar = settingsModule.create()
    if settingsBar and settingsBar.displayGroup then
        view:insert(settingsBar.displayGroup)
    end

    ---------------------------------------------------------------------------
    -- Title
    ---------------------------------------------------------------------------
    local titleText = display.newText({
        text = storyboard.localized.get("Account") or "Account",
        x = display.contentCenterX,
        y = display.contentHeight * 0.12,
        font = font,
        fontSize = fontSize * 2,
    })
    titleText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(titleText)

    ---------------------------------------------------------------------------
    -- Username display
    ---------------------------------------------------------------------------
    local username = ""
    if storyboard.playerInfo then
        username = storyboard.playerInfo.username or ""
    end

    local usernameLabel = display.newText({
        text = (storyboard.localized.get("Username") or "Username") .. ":",
        x = display.contentWidth * 0.25,
        y = display.contentHeight * 0.28,
        font = font,
        fontSize = fontSize,
    })
    usernameLabel:setFillColor(textColor[1], textColor[2], textColor[3], 0.7)
    view:insert(usernameLabel)

    usernameText = display.newText({
        text = username,
        x = display.contentWidth * 0.65,
        y = display.contentHeight * 0.28,
        font = font,
        fontSize = fontSize,
    })
    usernameText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(usernameText)

    ---------------------------------------------------------------------------
    -- Email display
    ---------------------------------------------------------------------------
    local email = ""
    if storyboard.playerInfo then
        email = storyboard.playerInfo.email or ""
    end

    local emailLabel = display.newText({
        text = (storyboard.localized.get("Email") or "Email") .. ":",
        x = display.contentWidth * 0.25,
        y = display.contentHeight * 0.38,
        font = font,
        fontSize = fontSize,
    })
    emailLabel:setFillColor(textColor[1], textColor[2], textColor[3], 0.7)
    view:insert(emailLabel)

    emailText = display.newText({
        text = email,
        x = display.contentWidth * 0.65,
        y = display.contentHeight * 0.38,
        font = font,
        fontSize = fontSize,
    })
    emailText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(emailText)

    ---------------------------------------------------------------------------
    -- Change Password button
    ---------------------------------------------------------------------------
    local function onChangePasswordTap(event)
        storyboard.gotoScene("scenes.forgotPasswordScene")
        return true
    end

    changePasswordButton = gui.newButton({
        image = "images/gui/button/blank.png",
        text = storyboard.localized.get("ChangePassword") or "Change Password",
        width = 150, height = 40,
        x = display.contentCenterX,
        y = display.contentHeight * 0.55,
        onRelease = onChangePasswordTap,
    })
    view:insert(changePasswordButton.displayGroup or changePasswordButton)

    ---------------------------------------------------------------------------
    -- Sync Devices button
    ---------------------------------------------------------------------------
    local function onSyncTap(event)
        storyboard.gotoScene("scenes.syncDevicesScene")
        return true
    end

    syncButton = gui.newButton({
        image = "images/gui/button/blank.png",
        text = storyboard.localized.get("SyncDevices") or "Sync Devices",
        width = 150, height = 40,
        x = display.contentCenterX,
        y = display.contentHeight * 0.68,
        onRelease = onSyncTap,
    })
    view:insert(syncButton.displayGroup or syncButton)

    ---------------------------------------------------------------------------
    -- Back button
    ---------------------------------------------------------------------------
    local function onBackTap(event)
        storyboard.gotoScene("scenes.settings")
        storyboard.purgeScene("scenes.accountSettings")
        return true
    end

    backButton = gui.newButton({
        image = "images/gui/button/smallHome.png",
        width = 35, height = 35,
        x = 26, y = 26,
        onRelease = onBackTap,
    })
    view:insert(backButton.displayGroup or backButton)

    ---------------------------------------------------------------------------
    -- Key listener (Android back)
    ---------------------------------------------------------------------------
    keyListener = function(event)
        if event.keyName == "back" and event.phase == "up" then
            onBackTap(event)
            return true
        end
    end
    Runtime:addEventListener("key", keyListener)
end

---------------------------------------------------------------------------------
-- ENTER SCENE
---------------------------------------------------------------------------------
function scene:enterScene(event)
end

---------------------------------------------------------------------------------
-- EXIT SCENE
---------------------------------------------------------------------------------
function scene:exitScene(event)
    Runtime:removeEventListener("key", keyListener)
end

---------------------------------------------------------------------------------
-- DESTROY SCENE
---------------------------------------------------------------------------------
function scene:destroyScene(event)
    background = nil
    backButton = nil
    usernameText = nil
    emailText = nil
    changePasswordButton = nil
    syncButton = nil
    enterFrameListener = nil
    keyListener = nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
