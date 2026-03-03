---------------------------------------------------------------------------------
-- loginScene.lua — User login scene
---------------------------------------------------------------------------------
local storyboard = require("modules.storyboard")
local scene = storyboard.newScene()

-- Module-level variables
local usernameField
local passwordField
local loginPlayButton
local createUserButton
local forgotPasswordButton
local facebookButton
local enterFrameListener
local keyListener
local forgotPasswordText
local passwordFieldHandlerFactory
local usernameFieldHandlerFactory
local serverCallback
local loadingAnimation
local background
local isProcessing = false
local timeoutTimer
local errorText

---------------------------------------------------------------------------------
-- CREATE SCENE
---------------------------------------------------------------------------------
function scene:createScene(event)
    local view = self.view
    local font = storyboard.gameDataTable.font
    local fontSize = storyboard.localized.getFontSize()
    local textColor = {1, 1, 1, 1}
    local titleText
    local usernameLabel
    local passwordLabel

    isProcessing = false

    local gui = require("modules.gui")
    local loadingAnimModule = require("modules.loadingAnimation")
    loadingAnimation = loadingAnimModule.newLoadingAnimation()
    loadingAnimation.displayGroup.x = display.contentWidth * 0.8
    loadingAnimation.displayGroup.y = display.contentHeight * 0.3

    ---------------------------------------------------------------------------
    -- Reset processing flag (timeout guard)
    ---------------------------------------------------------------------------
    local function resetProcessing()
        isProcessing = false
    end

    ---------------------------------------------------------------------------
    -- Login / submit button handler
    ---------------------------------------------------------------------------
    local function onLoginTap(event)
        if isProcessing then return end

        errorText.text = ""
        native.setKeyboardFocus(nil)

        -- Remove login button tap to prevent double-taps
        loginPlayButton:removeEventListener("tap", loginPlayButton)
        loadingAnimation.startLoader()

        -- Get and sanitize username
        local username = usernameField.text
        if username then
            username = string.gsub(username, "%s", "")
        else
            username = nil
        end

        isProcessing = true

        if timeoutTimer then
            timer.cancel(timeoutTimer)
            timeoutTimer = nil
        end
        timeoutTimer = timer.performWithDelay(5000, resetProcessing, 1)

        if username then
            local password = passwordField.text
            if password then
                if string.len(username) < 3 then
                    serverCallback({m = "a", e = storyboard.localized.get("UsernameTooShort")})
                    storyboard.analytics.newEvent("design", {
                        event_id = "login:username too short",
                        area = storyboard.getCurrentSceneName()
                    })
                elseif string.len(password) == 0 then
                    serverCallback({m = "a", e = storyboard.localized.get("EnterPassword")})
                    storyboard.analytics.newEvent("design", {
                        event_id = "login:no password",
                        area = storyboard.getCurrentSceneName()
                    })
                else
                    local cleaned = string.gsub(username, "[^%a%d]", "")
                    if cleaned ~= username then
                        serverCallback({m = "a", e = storyboard.localized.get("ValidCharacterMessage")})
                        storyboard.analytics.newEvent("design", {
                            event_id = "login:username !a-z0-9",
                            area = storyboard.getCurrentSceneName()
                        })
                    else
                        storyboard.comm.loginUser(username, password)
                    end
                end
            end
        else
            serverCallback({m = "a", e = storyboard.localized.get("EnterPassword")})
        end
    end

    ---------------------------------------------------------------------------
    -- Navigate to register scene
    ---------------------------------------------------------------------------
    local function onRegisterTap(event)
        native.setKeyboardFocus(nil)
        storyboard.gotoScene("scenes.registerScene")
        storyboard.purgeScene("scenes.loginScene")
    end

    ---------------------------------------------------------------------------
    -- Navigate to forgot password scene
    ---------------------------------------------------------------------------
    local function onForgotPasswordTap(event)
        native.setKeyboardFocus(nil)
        storyboard.gotoScene("scenes.forgotPasswordScene")
        storyboard.purgeScene("scenes.loginScene")
    end

    ---------------------------------------------------------------------------
    -- Navigate to Facebook login scene
    ---------------------------------------------------------------------------
    local function onFacebookTap(event)
        storyboard.gotoScene("scenes.facebookScene")
        storyboard.purgeScene("scenes.loginScene")
        return true
    end

    ---------------------------------------------------------------------------
    -- Text field handler factories
    ---------------------------------------------------------------------------
    passwordFieldHandlerFactory = function(getDefaultField)
        local function handler(event)
            if event.phase == "ended" then
                -- no action
            elseif event.phase == "submitted" then
                native.setKeyboardFocus(nil)
            end
        end
        return handler
    end

    usernameFieldHandlerFactory = function(getDefaultField)
        local function handler(event)
            if string.len(usernameField.text) > 15 then
                usernameField.text = usernameField.text:sub(1, 15)
            end
            if event.phase == "ended" then
                -- no action
            elseif event.phase == "submitted" then
                native.setKeyboardFocus(nil)
            end
        end
        return handler
    end

    ---------------------------------------------------------------------------
    -- Dismiss keyboard on background tap
    ---------------------------------------------------------------------------
    local function dismissKeyboard()
        native.setKeyboardFocus(nil)
    end

    ---------------------------------------------------------------------------
    -- UI: Background
    ---------------------------------------------------------------------------
    background = display.newImageRect("images/gui/background/login.png", 480, 320)
    background.tap = dismissKeyboard
    background.x = display.contentWidth * 0.5
    background.y = display.contentHeight * 0.5
    view:insert(background)

    ---------------------------------------------------------------------------
    -- Text field height (platform-dependent)
    ---------------------------------------------------------------------------
    local fieldHeight = 30
    if isAndroid then
        fieldHeight = 40
    end

    ---------------------------------------------------------------------------
    -- UI: Title "Login"
    ---------------------------------------------------------------------------
    titleText = display.newText(storyboard.localized.get("Login"), 0, 0, font, fontSize * 3)
    titleText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    titleText.xScale = 0.5
    titleText.yScale = 0.5
    titleText.x = display.contentWidth * 0.5
    titleText.y = display.contentHeight * 0.05
    view:insert(titleText)

    ---------------------------------------------------------------------------
    -- UI: Username label + field
    ---------------------------------------------------------------------------
    usernameLabel = display.newText(storyboard.localized.get("Username"), 0, 0, font, fontSize * 2)
    usernameLabel:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    usernameLabel.xScale = 0.5
    usernameLabel.yScale = 0.5
    usernameLabel.anchorX = 1
    usernameLabel.anchorY = 0.5
    usernameLabel.x = display.contentWidth * 0.28
    usernameLabel.y = display.contentHeight * 0.2
    view:insert(usernameLabel)

    usernameField = native.newTextField(display.contentWidth * 3, display.contentHeight * 0.2, 200, fieldHeight)
    usernameField.anchorX = 0
    usernameField.anchorY = 0.5
    usernameField.x = display.contentWidth * 0.29
    usernameField.y = display.contentHeight * 0.2
    usernameField.userInput = usernameFieldHandlerFactory
    view:insert(usernameField)

    ---------------------------------------------------------------------------
    -- UI: Password label + field
    ---------------------------------------------------------------------------
    passwordLabel = display.newText(storyboard.localized.get("Password"), 0, 0, font, fontSize * 2)
    passwordLabel:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    passwordLabel.xScale = 0.5
    passwordLabel.yScale = 0.5
    passwordLabel.anchorX = 1
    passwordLabel.anchorY = 0.5
    passwordLabel.x = display.contentWidth * 0.28
    passwordLabel.y = display.contentHeight * 0.35
    view:insert(passwordLabel)

    passwordField = native.newTextField(display.contentWidth * 3, display.contentHeight * 0.35, 200, fieldHeight)
    passwordField.anchorX = 0
    passwordField.anchorY = 0.5
    passwordField.x = display.contentWidth * 0.29
    passwordField.y = display.contentHeight * 0.35
    passwordField.userInput = passwordFieldHandlerFactory
    passwordField.isSecure = true
    view:insert(passwordField)

    ---------------------------------------------------------------------------
    -- UI: Error / message text
    ---------------------------------------------------------------------------
    errorText = display.newText(storyboard.localized.get(""), 0, 0, font, fontSize * 2)
    errorText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    errorText.xScale = 0.5
    errorText.yScale = 0.5
    errorText.x = display.contentWidth * 0.5
    errorText.y = display.contentHeight * 0.7
    view:insert(errorText)
    errorText.isVisible = true

    ---------------------------------------------------------------------------
    -- UI: Buttons
    ---------------------------------------------------------------------------
    createUserButton = gui.newButton({
        image = "images/gui/button/createUser.png",
        width = storyboard.gameDataTable.backButton[1],
        height = storyboard.gameDataTable.backButton[2],
        onRelease = onRegisterTap,
        x = storyboard.gameDataTable.backButton[3],
        y = storyboard.gameDataTable.backButton[4],
        displayGroup = view
    })

    loginPlayButton = gui.newButton({
        image = "images/gui/button/play.png",
        width = storyboard.gameDataTable.backButton[1],
        height = storyboard.gameDataTable.backButton[2],
        onRelease = onLoginTap,
        x = 430,
        y = storyboard.gameDataTable.backButton[4],
        displayGroup = view
    })

    forgotPasswordButton = gui.newButton({
        image = "images/gui/button/blank.png",
        width = storyboard.gameDataTable.backButton[1],
        height = storyboard.gameDataTable.backButton[2],
        onRelease = onForgotPasswordTap,
        x = display.contentWidth * 0.5 + 50,
        y = storyboard.gameDataTable.backButton[4],
        displayGroup = view
    })

    facebookButton = gui.newButton({
        image = "images/gui/button/facebookBlank.png",
        text = {
            string = storyboard.localized.get("Use"),
            size = 14,
            color = {1, 1, 1},
            x = 8,
            y = -8
        },
        onRelease = onFacebookTap,
        width = 80,
        height = 50,
        x = display.contentWidth * 0.5 - 50,
        y = storyboard.gameDataTable.backButton[4],
        displayGroup = view
    })

    ---------------------------------------------------------------------------
    -- UI: "Forgot Password?" text label
    ---------------------------------------------------------------------------
    local forgotPwFontSize = 25
    if storyboard.localized.language == "ja" then
        forgotPwFontSize = 17
    end

    forgotPasswordText = display.newText(
        storyboard.localized.get("ForgotPassword"),
        0, 0, 160, 100, font, forgotPwFontSize
    )
    forgotPasswordText:setFillColor(0.0784313725490196, 0.0784313725490196, 0.0784313725490196)
    forgotPasswordText.xScale = 0.5
    forgotPasswordText.yScale = 0.5
    forgotPasswordText.x = display.contentWidth * 0.525 + 55
    forgotPasswordText.y = storyboard.gameDataTable.backButton[4] + 8
    view:insert(forgotPasswordText)

    ---------------------------------------------------------------------------
    -- Insert loading animation
    ---------------------------------------------------------------------------
    view:insert(loadingAnimation.displayGroup)
end

---------------------------------------------------------------------------------
-- ENTER SCENE
---------------------------------------------------------------------------------
function scene:enterScene(event)
    local view = self.view
    local canGoBack = false
    local backPressed = false

    -- Enable back navigation
    local function enableBack()
        canGoBack = true
    end

    -- Enter frame: process back navigation (back to register)
    enterFrameListener = function(event)
        if backPressed == true then
            backPressed = false
            canGoBack = false
            native.setKeyboardFocus(nil)
            storyboard.gotoScene("scenes.registerScene")
            storyboard.purgeScene("scenes.loginScene")
        end
    end

    -- Key handler: Android back button
    keyListener = function(event)
        if event.phase == "up" and event.keyName == "back" then
            if canGoBack then
                backPressed = true
            end
            return true
        end
        return false
    end

    -- Delayed listener setup
    local function addListeners()
        if storyboard.getCurrentSceneName() == "scenes.loginScene" then
            createUserButton.addListener()
            background:addEventListener("tap", background)
            loginPlayButton.addListener()
            forgotPasswordButton.addListener()
            facebookButton.addListener()
            local usernameHandler = usernameFieldHandlerFactory(function() return defaultField end)
            usernameField:addEventListener("userInput", usernameHandler)
            local passwordHandler = passwordFieldHandlerFactory(function() return defaultField end)
            passwordField:addEventListener("userInput", passwordHandler)
            enableBack()
        end
    end

    timer.performWithDelay(200, addListeners, 1)
    Runtime:addEventListener("key", keyListener)
    Runtime:addEventListener("enterFrame", enterFrameListener)

    ---------------------------------------------------------------------------
    -- Server callback for login response
    ---------------------------------------------------------------------------
    serverCallback = function(response)
        if timeoutTimer then
            timer.cancel(timeoutTimer)
            timeoutTimer = nil
        end
        loadingAnimation.stopLoader()

        local loginSuccess = false

        if response == nil then
            errorText.text = storyboard.localized.get("ErrorServerBusy")
        else
            if response.m == "x" then
                errorText.text = storyboard.localized.get("ErrorServerIsDown")
            else
                if response.e then
                    errorText.text = storyboard.localized.get(response.e)
                end
                if response.a == 1 then
                    loginSuccess = true
                    storyboard.gameDataTable.tryIt = 0
                    storyboard.gotoScene("scenes.loadingScene")
                    storyboard.purgeScene("scenes.loginScene")
                end
            end
        end

        -- Re-enable login button if login failed
        local function readdLoginTap()
            if storyboard.getCurrentSceneName() == "scenes.loginScene" then
                loginPlayButton:addEventListener("tap", loginPlayButton)
            end
        end

        if not loginSuccess then
            timer.performWithDelay(100, readdLoginTap)
        end

        isProcessing = false
    end

    storyboard.comm.setCallback(serverCallback)
end

---------------------------------------------------------------------------------
-- EXIT SCENE
---------------------------------------------------------------------------------
function scene:exitScene(event)
    if loadingAnimation then
        loadingAnimation.stopLoader()
    end
    if timeoutTimer then
        timer.cancel(timeoutTimer)
        timeoutTimer = nil
    end

    storyboard.comm.setCallback(function(response) end)

    background:removeEventListener("tap", background)
    createUserButton.removeListener()
    forgotPasswordButton.removeListener()
    facebookButton.removeListener()
    loginPlayButton.removeListener()
    usernameField:removeEventListener("userInput", usernameField)
    passwordField:removeEventListener("userInput", passwordField)
    Runtime:removeEventListener("key", keyListener)
    Runtime:removeEventListener("enterFrame", enterFrameListener)
end

---------------------------------------------------------------------------------
-- DESTROY SCENE
---------------------------------------------------------------------------------
function scene:destroyScene(event)
    background = nil
    usernameField = nil
    passwordField = nil
    loginPlayButton = nil
    createUserButton = nil
    forgotPasswordText = nil
    passwordFieldHandlerFactory = nil
    usernameFieldHandlerFactory = nil
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
