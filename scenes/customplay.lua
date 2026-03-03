---------------------------------------------------------------------------------
-- customplay.lua — Custom play room setup (create / join room)
---------------------------------------------------------------------------------
local storyboard = require("modules.storyboard")
local scene = storyboard.newScene()

-- Module-level variables
local homeButton
local createRoomButton
local joinRoomButton
local enterFrameListener
local keyListener
local background
local serverCallback
local loadingAnimation
local isProcessing = false
local roomCodeField
local errorText

---------------------------------------------------------------------------------
-- CREATE SCENE
---------------------------------------------------------------------------------
function scene:createScene(event)
    local view = self.view
    local gui = require("modules.gui")
    local font = storyboard.gameDataTable.font
    local fontSize = storyboard.localized.getFontSize()
    local textColor = {1, 1, 1, 1}

    isProcessing = false

    ---------------------------------------------------------------------------
    -- Background
    ---------------------------------------------------------------------------
    background = display.newImageRect("images/gui/background/lobbyCustomPlay.png",
        display.contentWidth, display.contentHeight)
    background.x = display.contentCenterX
    background.y = display.contentCenterY
    view:insert(background)

    background:addEventListener("tap", function()
        native.setKeyboardFocus(nil)
        return true
    end)

    ---------------------------------------------------------------------------
    -- Title
    ---------------------------------------------------------------------------
    local titleText = display.newText({
        text = storyboard.localized.get("CustomPlay") or "Custom Play",
        x = display.contentCenterX,
        y = display.contentHeight * 0.12,
        font = font,
        fontSize = fontSize * 2,
    })
    titleText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(titleText)

    ---------------------------------------------------------------------------
    -- Error text
    ---------------------------------------------------------------------------
    errorText = display.newText("", display.contentCenterX, display.contentHeight * 0.22,
        font, fontSize)
    errorText:setFillColor(1, 0, 0)
    view:insert(errorText)

    ---------------------------------------------------------------------------
    -- Create Room button
    ---------------------------------------------------------------------------
    local function onCreateRoomTap(event)
        if isProcessing then return end
        isProcessing = true
        storyboard.comm.send("createCustomRoom", {
            username = storyboard.playerInfo.username,
            avatar = storyboard.database.getAvatarData(),
        }, serverCallback)
        return true
    end

    createRoomButton = gui.newButton({
        image = "images/gui/button/blank.png",
        text = storyboard.localized.get("CreateRoom") or "Create Room",
        width = 150, height = 40,
        x = display.contentCenterX,
        y = display.contentHeight * 0.38,
        onRelease = onCreateRoomTap,
    })
    view:insert(createRoomButton.displayGroup or createRoomButton)

    ---------------------------------------------------------------------------
    -- Room code text field
    ---------------------------------------------------------------------------
    roomCodeField = native.newTextField(display.contentCenterX,
        display.contentHeight * 0.55, display.contentWidth * 0.5, 30)
    roomCodeField.placeholder = storyboard.localized.get("RoomCode") or "Room Code"

    ---------------------------------------------------------------------------
    -- Join Room button
    ---------------------------------------------------------------------------
    local function onJoinRoomTap(event)
        if isProcessing then return end
        native.setKeyboardFocus(nil)
        local code = roomCodeField.text
        if not code or code == "" then
            errorText.text = storyboard.localized.get("EnterRoomCode") or "Enter a room code"
            return true
        end
        isProcessing = true
        storyboard.comm.send("joinCustomRoom", {
            code = code,
            username = storyboard.playerInfo.username,
            avatar = storyboard.database.getAvatarData(),
        }, serverCallback)
        return true
    end

    joinRoomButton = gui.newButton({
        image = "images/gui/button/blank.png",
        text = storyboard.localized.get("JoinRoom") or "Join Room",
        width = 150, height = 40,
        x = display.contentCenterX,
        y = display.contentHeight * 0.65,
        onRelease = onJoinRoomTap,
    })
    view:insert(joinRoomButton.displayGroup or joinRoomButton)

    ---------------------------------------------------------------------------
    -- Server callback
    ---------------------------------------------------------------------------
    serverCallback = function(response)
        isProcessing = false
        if response and response.status == "OK" then
            storyboard.gotoScene("scenes.lobbyCustomPlay")
            storyboard.purgeScene("scenes.customplay")
        else
            errorText.text = storyboard.localized.get("ErrorOccurred") or "Could not connect"
        end
    end

    ---------------------------------------------------------------------------
    -- Home button
    ---------------------------------------------------------------------------
    local function onHomeTap(event)
        native.setKeyboardFocus(nil)
        storyboard.gotoScene("scenes.playMenu")
        storyboard.purgeScene("scenes.customplay")
        return true
    end

    homeButton = gui.newButton({
        image = "images/gui/button/smallHome.png",
        width = 35, height = 35,
        x = 26, y = 26,
        onRelease = onHomeTap,
    })
    view:insert(homeButton.displayGroup or homeButton)

    ---------------------------------------------------------------------------
    -- Key listener (Android back)
    ---------------------------------------------------------------------------
    keyListener = function(event)
        if event.keyName == "back" and event.phase == "up" then
            onHomeTap(event)
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
    if roomCodeField and roomCodeField.removeSelf then
        roomCodeField:removeSelf()
        roomCodeField = nil
    end
    Runtime:removeEventListener("key", keyListener)
end

---------------------------------------------------------------------------------
-- DESTROY SCENE
---------------------------------------------------------------------------------
function scene:destroyScene(event)
    background = nil
    homeButton = nil
    createRoomButton = nil
    joinRoomButton = nil
    roomCodeField = nil
    loadingAnimation = nil
    errorText = nil
    serverCallback = nil
    enterFrameListener = nil
    keyListener = nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
