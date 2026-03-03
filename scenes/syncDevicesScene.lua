---------------------------------------------------------------------------------
-- syncDevicesScene.lua — Device sync scene (link account across devices)
---------------------------------------------------------------------------------
local storyboard = require("modules.storyboard")
local scene = storyboard.newScene()

-- Module-level variables
local backButton
local syncButton
local keyListener
local background
local syncCodeField
local errorText
local loadingAnimation
local isProcessing = false
local timeoutTimer
local serverCallback
local enterFrameListener
local syncCodeDisplay

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
        text = storyboard.localized.get("SyncDevices") or "Sync Devices",
        x = display.contentCenterX,
        y = display.contentHeight * 0.1,
        font = font,
        fontSize = fontSize * 2,
    })
    titleText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(titleText)

    ---------------------------------------------------------------------------
    -- Instructions
    ---------------------------------------------------------------------------
    local instructionText = display.newText({
        text = storyboard.localized.get("SyncInstructions") or
            "Enter the sync code from your other device, or use the code below on another device.",
        x = display.contentCenterX,
        y = display.contentHeight * 0.22,
        font = font,
        fontSize = fontSize * 0.85,
        width = display.contentWidth * 0.8,
        align = "center",
    })
    instructionText:setFillColor(textColor[1], textColor[2], textColor[3], 0.8)
    view:insert(instructionText)

    ---------------------------------------------------------------------------
    -- Your sync code display
    ---------------------------------------------------------------------------
    local yourCodeLabel = display.newText({
        text = storyboard.localized.get("YourCode") or "Your Sync Code:",
        x = display.contentCenterX,
        y = display.contentHeight * 0.36,
        font = font,
        fontSize = fontSize,
    })
    yourCodeLabel:setFillColor(textColor[1], textColor[2], textColor[3], 0.7)
    view:insert(yourCodeLabel)

    local syncCode = "------" -- placeholder until server provides it
    syncCodeDisplay = display.newText({
        text = syncCode,
        x = display.contentCenterX,
        y = display.contentHeight * 0.42,
        font = font,
        fontSize = fontSize * 1.5,
    })
    syncCodeDisplay:setFillColor(1, 0.84, 0)
    view:insert(syncCodeDisplay)

    ---------------------------------------------------------------------------
    -- Enter other device's code
    ---------------------------------------------------------------------------
    local enterCodeLabel = display.newText({
        text = storyboard.localized.get("EnterSyncCode") or "Enter code from other device:",
        x = display.contentCenterX,
        y = display.contentHeight * 0.54,
        font = font,
        fontSize = fontSize,
    })
    enterCodeLabel:setFillColor(textColor[1], textColor[2], textColor[3], 0.7)
    view:insert(enterCodeLabel)

    syncCodeField = native.newTextField(display.contentCenterX, display.contentHeight * 0.62,
        display.contentWidth * 0.5, 30)
    syncCodeField.placeholder = storyboard.localized.get("SyncCode") or "Sync Code"

    ---------------------------------------------------------------------------
    -- Error text
    ---------------------------------------------------------------------------
    errorText = display.newText("", display.contentCenterX, display.contentHeight * 0.70,
        font, fontSize)
    errorText:setFillColor(1, 0, 0)
    view:insert(errorText)

    ---------------------------------------------------------------------------
    -- Reset processing
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

        if response then
            if response.syncCode then
                syncCodeDisplay.text = response.syncCode
            end
            if response.status == "OK" then
                native.showAlert("Fun Run",
                    storyboard.localized.get("SyncSuccess") or "Device synced successfully!",
                    {storyboard.localized.get("Ok") or "OK"})
            elseif response.status == "ERROR" then
                errorText.text = storyboard.localized.get("InvalidSyncCode") or "Invalid sync code"
            end
        end
    end

    ---------------------------------------------------------------------------
    -- Sync button
    ---------------------------------------------------------------------------
    local function onSyncTap(event)
        if isProcessing then return end
        errorText.text = ""
        native.setKeyboardFocus(nil)

        local code = syncCodeField.text
        if not code or code == "" then
            errorText.text = storyboard.localized.get("EnterSyncCode") or "Please enter a sync code"
            return true
        end

        isProcessing = true
        if timeoutTimer then timer.cancel(timeoutTimer); timeoutTimer = nil end
        timeoutTimer = timer.performWithDelay(10000, resetProcessing, 1)

        storyboard.comm.send("syncDevice", {
            username = storyboard.playerInfo.username,
            syncCode = code,
        }, serverCallback)
        return true
    end

    syncButton = gui.newButton({
        image = "images/gui/button/blank.png",
        text = storyboard.localized.get("Sync") or "Sync",
        width = 120, height = 40,
        x = display.contentCenterX,
        y = display.contentHeight * 0.78,
        onRelease = onSyncTap,
    })
    view:insert(syncButton.displayGroup or syncButton)

    ---------------------------------------------------------------------------
    -- Back button
    ---------------------------------------------------------------------------
    local function onBackTap(event)
        native.setKeyboardFocus(nil)
        storyboard.gotoScene("scenes.settings")
        storyboard.purgeScene("scenes.syncDevicesScene")
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
    -- Request sync code from server
    storyboard.comm.send("getSyncCode", {
        username = storyboard.playerInfo.username,
    }, serverCallback)
end

---------------------------------------------------------------------------------
-- EXIT SCENE
---------------------------------------------------------------------------------
function scene:exitScene(event)
    if syncCodeField and syncCodeField.removeSelf then
        syncCodeField:removeSelf()
        syncCodeField = nil
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
    syncButton = nil
    syncCodeField = nil
    syncCodeDisplay = nil
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
