---------------------------------------------------------------------------------
-- forgotPasswordScene.lua — Forgot password: email reset form
---------------------------------------------------------------------------------
local storyboard = require("modules.storyboard")
local scene = storyboard.newScene()

-- Module-level variables
local emailField
local submitButton
local backButton
local enterFrameListener
local keyListener
local loadingAnimation
local background
local isProcessing = false
local timeoutTimer
local errorText
local serverCallback

---------------------------------------------------------------------------------
-- CREATE SCENE
---------------------------------------------------------------------------------
function scene:createScene(event)
    local view = self.view
    local gui = require("modules.gui")
    local loadingAnimModule = require("modules.loadingAnimation")
    local font = storyboard.gameDataTable.font
    local fontSize = storyboard.localized.getFontSize()
    local textColor = {1, 1, 1, 1}

    isProcessing = false

    loadingAnimation = loadingAnimModule.newLoadingAnimation()
    loadingAnimation.displayGroup.x = display.contentWidth * 0.8
    loadingAnimation.displayGroup.y = display.contentHeight * 0.3

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
        text = storyboard.localized.get("ForgotPassword") or "Forgot Password",
        x = display.contentCenterX,
        y = display.contentHeight * 0.15,
        font = font,
        fontSize = fontSize * 2,
    })
    titleText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(titleText)

    ---------------------------------------------------------------------------
    -- Instruction text
    ---------------------------------------------------------------------------
    local instructionText = display.newText({
        text = storyboard.localized.get("EnterEmail") or "Enter your email to reset password",
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
    -- Email native text field
    ---------------------------------------------------------------------------
    emailField = native.newTextField(display.contentCenterX, display.contentHeight * 0.4,
        display.contentWidth * 0.6, 30)
    emailField.placeholder = "email@example.com"
    emailField.inputType = "email"

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
    -- Submit handler
    ---------------------------------------------------------------------------
    local function onSubmitTap(event)
        if isProcessing then return end
        errorText.text = ""
        native.setKeyboardFocus(nil)

        local email = emailField.text
        if not email or email == "" then
            errorText.text = storyboard.localized.get("EnterEmail") or "Please enter your email"
            return true
        end

        isProcessing = true
        loadingAnimation.startLoader()

        if timeoutTimer then timer.cancel(timeoutTimer); timeoutTimer = nil end
        timeoutTimer = timer.performWithDelay(8000, resetProcessing, 1)

        -- Send forgot-password request via communication module
        storyboard.comm.send("forgotPassword", {email = email}, serverCallback)
        return true
    end

    ---------------------------------------------------------------------------
    -- Server callback
    ---------------------------------------------------------------------------
    serverCallback = function(response)
        if loadingAnimation then loadingAnimation.stopLoader() end
        isProcessing = false
        if timeoutTimer then timer.cancel(timeoutTimer); timeoutTimer = nil end

        if response and response.status == "OK" then
            native.showAlert("Fun Run",
                storyboard.localized.get("PasswordResetSent") or "Password reset email sent!",
                {storyboard.localized.get("Ok") or "OK"})
        else
            errorText.text = storyboard.localized.get("ErrorOccurred") or "An error occurred"
        end
    end

    ---------------------------------------------------------------------------
    -- Submit button
    ---------------------------------------------------------------------------
    submitButton = gui.newButton({
        image = "images/gui/button/blank.png",
        text = storyboard.localized.get("Submit") or "Submit",
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
        storyboard.gotoScene("scenes.loginScene")
        storyboard.purgeScene("scenes.forgotPasswordScene")
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
    if loadingAnimation then loadingAnimation.stopLoader() end
    if timeoutTimer then timer.cancel(timeoutTimer); timeoutTimer = nil end

    if emailField and emailField.removeSelf then
        emailField:removeSelf()
        emailField = nil
    end

    Runtime:removeEventListener("key", keyListener)
end

---------------------------------------------------------------------------------
-- DESTROY SCENE
---------------------------------------------------------------------------------
function scene:destroyScene(event)
    background = nil
    emailField = nil
    submitButton = nil
    backButton = nil
    loadingAnimation = nil
    errorText = nil
    enterFrameListener = nil
    keyListener = nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
