---------------------------------------------------------------------------------
-- generalSettings.lua — General settings overlay (sound, chat, notifications)
---------------------------------------------------------------------------------
local storyboard = require("modules.storyboard")
local scene = storyboard.newScene()

-- Module-level variables
local backButton
local keyListener
local background
local soundToggle
local chatToggle
local notificationToggle
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
        text = storyboard.localized.get("General") or "General",
        x = display.contentCenterX,
        y = display.contentHeight * 0.12,
        font = font,
        fontSize = fontSize * 2,
    })
    titleText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(titleText)

    ---------------------------------------------------------------------------
    -- Sound toggle
    ---------------------------------------------------------------------------
    local soundState = storyboard.database.getSound()

    local soundLabel = display.newText({
        text = storyboard.localized.get("Sound") or "Sound",
        x = display.contentWidth * 0.3,
        y = display.contentHeight * 0.3,
        font = font,
        fontSize = fontSize,
    })
    soundLabel:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(soundLabel)

    local soundStatusText = display.newText({
        text = (soundState == 1) and (storyboard.localized.get("On") or "On") or (storyboard.localized.get("Off") or "Off"),
        x = display.contentWidth * 0.7,
        y = display.contentHeight * 0.3,
        font = font,
        fontSize = fontSize,
    })
    soundStatusText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(soundStatusText)

    local function onSoundToggle(event)
        local s = storyboard.database.getSound()
        if s == 1 then
            storyboard.database.setSound(0)
            soundStatusText.text = storyboard.localized.get("Off") or "Off"
        else
            storyboard.database.setSound(1)
            soundStatusText.text = storyboard.localized.get("On") or "On"
        end
        return true
    end
    soundStatusText:addEventListener("tap", onSoundToggle)

    ---------------------------------------------------------------------------
    -- Chat toggle
    ---------------------------------------------------------------------------
    local chatState = storyboard.database.getChat and storyboard.database.getChat() or 1

    local chatLabel = display.newText({
        text = storyboard.localized.get("Chat") or "Chat",
        x = display.contentWidth * 0.3,
        y = display.contentHeight * 0.42,
        font = font,
        fontSize = fontSize,
    })
    chatLabel:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(chatLabel)

    local chatStatusText = display.newText({
        text = (chatState == 1) and (storyboard.localized.get("On") or "On") or (storyboard.localized.get("Off") or "Off"),
        x = display.contentWidth * 0.7,
        y = display.contentHeight * 0.42,
        font = font,
        fontSize = fontSize,
    })
    chatStatusText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(chatStatusText)

    local function onChatToggle(event)
        local c = storyboard.database.getChat and storyboard.database.getChat() or 1
        if c == 1 then
            if storyboard.database.setChat then storyboard.database.setChat(0) end
            chatStatusText.text = storyboard.localized.get("Off") or "Off"
        else
            if storyboard.database.setChat then storyboard.database.setChat(1) end
            chatStatusText.text = storyboard.localized.get("On") or "On"
        end
        return true
    end
    chatStatusText:addEventListener("tap", onChatToggle)

    ---------------------------------------------------------------------------
    -- Notification toggle
    ---------------------------------------------------------------------------
    local notifState = storyboard.database.getNotification and storyboard.database.getNotification() or 1

    local notifLabel = display.newText({
        text = storyboard.localized.get("Notifications") or "Notifications",
        x = display.contentWidth * 0.3,
        y = display.contentHeight * 0.54,
        font = font,
        fontSize = fontSize,
    })
    notifLabel:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(notifLabel)

    local notifStatusText = display.newText({
        text = (notifState == 1) and (storyboard.localized.get("On") or "On") or (storyboard.localized.get("Off") or "Off"),
        x = display.contentWidth * 0.7,
        y = display.contentHeight * 0.54,
        font = font,
        fontSize = fontSize,
    })
    notifStatusText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(notifStatusText)

    local function onNotifToggle(event)
        local n = storyboard.database.getNotification and storyboard.database.getNotification() or 1
        if n == 1 then
            if storyboard.database.setNotification then storyboard.database.setNotification(0) end
            notifStatusText.text = storyboard.localized.get("Off") or "Off"
        else
            if storyboard.database.setNotification then storyboard.database.setNotification(1) end
            notifStatusText.text = storyboard.localized.get("On") or "On"
        end
        return true
    end
    notifStatusText:addEventListener("tap", onNotifToggle)

    ---------------------------------------------------------------------------
    -- Back button
    ---------------------------------------------------------------------------
    local function onBackTap(event)
        storyboard.gotoScene("scenes.settings")
        storyboard.purgeScene("scenes.generalSettings")
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
    soundToggle = nil
    chatToggle = nil
    notificationToggle = nil
    enterFrameListener = nil
    keyListener = nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
