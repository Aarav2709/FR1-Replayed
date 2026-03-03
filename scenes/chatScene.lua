---------------------------------------------------------------------------------
-- chatScene.lua — In-game chat scene
---------------------------------------------------------------------------------
local storyboard = require("modules.storyboard")
local scene = storyboard.newScene()

-- Module-level variables
local backButton
local sendButton
local keyListener
local background
local chatField
local chatScrollView
local chatData
local enterFrameListener
local serverCallback

---------------------------------------------------------------------------------
-- CREATE SCENE
---------------------------------------------------------------------------------
function scene:createScene(event)
    local view = self.view
    local gui = require("modules.gui")
    local font = storyboard.gameDataTable.font
    local fontSize = storyboard.localized.getFontSize()
    local textColor = {1, 1, 1, 1}

    chatData = require("modules.chatData")

    ---------------------------------------------------------------------------
    -- Background
    ---------------------------------------------------------------------------
    background = display.newImageRect("images/gui/background/login.png",
        display.contentWidth, display.contentHeight)
    background.x = display.contentCenterX
    background.y = display.contentCenterY
    view:insert(background)

    ---------------------------------------------------------------------------
    -- Title
    ---------------------------------------------------------------------------
    local titleText = display.newText({
        text = storyboard.localized.get("Chat") or "Chat",
        x = display.contentCenterX,
        y = display.contentHeight * 0.06,
        font = font,
        fontSize = fontSize * 2,
    })
    titleText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(titleText)

    ---------------------------------------------------------------------------
    -- Chat scroll area (placeholder)
    ---------------------------------------------------------------------------
    local chatBg = display.newRect(display.contentCenterX, display.contentCenterY - 20,
        display.contentWidth * 0.9, display.contentHeight * 0.6)
    chatBg:setFillColor(0, 0, 0, 0.3)
    view:insert(chatBg)

    -- TODO: Populate with chat messages from chatData

    ---------------------------------------------------------------------------
    -- Chat native text field
    ---------------------------------------------------------------------------
    chatField = native.newTextField(display.contentCenterX - 30,
        display.contentHeight * 0.9, display.contentWidth * 0.65, 30)
    chatField.placeholder = storyboard.localized.get("TypeMessage") or "Type a message..."

    ---------------------------------------------------------------------------
    -- Send button
    ---------------------------------------------------------------------------
    local function onSendTap(event)
        local msg = chatField.text
        if not msg or msg == "" then return true end

        storyboard.comm.send("chatMessage", {
            username = storyboard.playerInfo.username,
            message = msg,
        })
        chatField.text = ""
        return true
    end

    sendButton = gui.newButton({
        image = "images/gui/button/blank.png",
        text = storyboard.localized.get("Send") or "Send",
        width = 60, height = 30,
        x = display.contentWidth * 0.88,
        y = display.contentHeight * 0.9,
        onRelease = onSendTap,
    })
    view:insert(sendButton.displayGroup or sendButton)

    ---------------------------------------------------------------------------
    -- Back button
    ---------------------------------------------------------------------------
    local function onBackTap(event)
        native.setKeyboardFocus(nil)
        storyboard.gotoScene("scenes.friends")
        storyboard.purgeScene("scenes.chatScene")
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
    if chatField and chatField.removeSelf then
        chatField:removeSelf()
        chatField = nil
    end
    Runtime:removeEventListener("key", keyListener)
end

---------------------------------------------------------------------------------
-- DESTROY SCENE
---------------------------------------------------------------------------------
function scene:destroyScene(event)
    background = nil
    backButton = nil
    sendButton = nil
    chatField = nil
    chatScrollView = nil
    chatData = nil
    serverCallback = nil
    enterFrameListener = nil
    keyListener = nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
