---------------------------------------------------------------------------------
-- addFriend.lua — Add friend form
---------------------------------------------------------------------------------
local storyboard = require("modules.storyboard")
local scene = storyboard.newScene()

-- Module-level variables
local backButton
local submitButton
local enterFrameListener
local keyListener
local background
local usernameField
local errorText
local loadingAnimation
local isProcessing = false
local timeoutTimer
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

    isProcessing = false

    ---------------------------------------------------------------------------
    -- Background
    ---------------------------------------------------------------------------
    background = display.newImageRect("images/gui/background/login.png",
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
        text = storyboard.localized.get("AddFriend") or "Add Friend",
        x = display.contentCenterX,
        y = display.contentHeight * 0.15,
        font = font,
        fontSize = fontSize * 2,
    })
    titleText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(titleText)

    ---------------------------------------------------------------------------
    -- Instruction
    ---------------------------------------------------------------------------
    local instructionText = display.newText({
        text = storyboard.localized.get("EnterUsername") or "Enter the username of your friend",
        x = display.contentCenterX,
        y = display.contentHeight * 0.28,
        font = font,
        fontSize = fontSize,
        width = display.contentWidth * 0.8,
        align = "center",
    })
    instructionText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(instructionText)

    ---------------------------------------------------------------------------
    -- Username native text field
    ---------------------------------------------------------------------------
    usernameField = native.newTextField(display.contentCenterX, display.contentHeight * 0.4,
        display.contentWidth * 0.6, 30)
    usernameField.placeholder = storyboard.localized.get("Username") or "Username"

    ---------------------------------------------------------------------------
    -- Error text
    ---------------------------------------------------------------------------
    errorText = display.newText("", display.contentCenterX, display.contentHeight * 0.5,
        font, fontSize)
    errorText:setFillColor(1, 0, 0)
    view:insert(errorText)

    ---------------------------------------------------------------------------
    -- Reset processing flag
    ---------------------------------------------------------------------------
    local function resetProcessing()
        isProcessing = false
    end

    ---------------------------------------------------------------------------
    -- Server callback
    ---------------------------------------------------------------------------
    serverCallback = function(response)
        isProcessing = false
        if timeoutTimer then timer.cancel(timeoutTimer); timeoutTimer = nil end
        if response and response.status == "OK" then
            native.showAlert("Fun Run",
                storyboard.localized.get("FriendRequestSent") or "Friend request sent!",
                {storyboard.localized.get("Ok") or "OK"})
            if usernameField then usernameField.text = "" end
        else
            errorText.text = storyboard.localized.get("UserNotFound") or "User not found"
        end
    end

    ---------------------------------------------------------------------------
    -- Submit handler
    ---------------------------------------------------------------------------
    local function onSubmitTap(event)
        if isProcessing then return end
        errorText.text = ""
        native.setKeyboardFocus(nil)

        local username = usernameField.text
        if not username or username == "" then
            errorText.text = storyboard.localized.get("EnterUsername") or "Please enter a username"
            return true
        end

        isProcessing = true
        if timeoutTimer then timer.cancel(timeoutTimer); timeoutTimer = nil end
        timeoutTimer = timer.performWithDelay(8000, resetProcessing, 1)

        storyboard.comm.send("addFriend", {
            username = storyboard.playerInfo.username,
            friend = username,
        }, serverCallback)
        return true
    end

    ---------------------------------------------------------------------------
    -- Submit button
    ---------------------------------------------------------------------------
    submitButton = gui.newButton({
        image = "images/gui/button/blank.png",
        text = storyboard.localized.get("Send") or "Send",
        width = 120, height = 40,
        x = display.contentCenterX,
        y = display.contentHeight * 0.58,
        onRelease = onSubmitTap,
    })
    view:insert(submitButton.displayGroup or submitButton)

    ---------------------------------------------------------------------------
    -- Back button
    ---------------------------------------------------------------------------
    local function onBackTap(event)
        native.setKeyboardFocus(nil)
        storyboard.gotoScene("scenes.friends")
        storyboard.purgeScene("scenes.addFriend")
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
    if usernameField and usernameField.removeSelf then
        usernameField:removeSelf()
        usernameField = nil
    end
    if timeoutTimer then timer.cancel(timeoutTimer); timeoutTimer = nil end
    Runtime:removeEventListener("key", keyListener)
end

---------------------------------------------------------------------------------
-- DESTROY SCENE
---------------------------------------------------------------------------------
function scene:destroyScene(event)
    background = nil
    backButton = nil
    submitButton = nil
    usernameField = nil
    errorText = nil
    loadingAnimation = nil
    serverCallback = nil
    enterFrameListener = nil
    keyListener = nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
