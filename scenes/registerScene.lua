---------------------------------------------------------------------------------
-- registerScene.lua — New user registration scene
---------------------------------------------------------------------------------
local storyboard = require("modules.storyboard")
local scene = storyboard.newScene()

-- Module-level variables
local usernameField
local playButton
local loginButton
local suggestionButton
local enterFrameListener
local keyListener
local goToTutorial
local genericFieldHandlerFactory
local usernameFieldHandlerFactory
local serverCallback
local showSuggestionFn
local errorText
local statusText
local suggestionLabel
local suggestionValueText
local background
local isProcessing = false
local timeoutTimer
local isTutorial
local loadingAnimation
local baseY = 60

---------------------------------------------------------------------------------
-- CREATE SCENE
---------------------------------------------------------------------------------
function scene:createScene(event)
    local view = self.view
    local font = storyboard.gameDataTable.font
    local fontSize = storyboard.localized.getFontSize()
    local textColor = {1, 1, 1, 1}
    local titleText
    local messageText
    local usernameLabel

    isProcessing = false

    local gui = require("modules.gui")
    local loadingAnimModule = require("modules.loadingAnimation")
    loadingAnimation = loadingAnimModule.newLoadingAnimation()
    loadingAnimation.displayGroup.x = display.contentWidth * 0.85
    loadingAnimation.displayGroup.y = display.contentHeight * 0.2

    ---------------------------------------------------------------------------
    -- Show register form (resets UI to registration state)
    ---------------------------------------------------------------------------
    local function showRegisterFn()
        statusText.isVisible = false
        messageText.text = ""
        usernameLabel.isVisible = true
        errorText.isVisible = true
        errorText.text = ""
        usernameField.isVisible = true
        playButton.isVisible = true
        loginButton.isVisible = true
        isTutorial = false
    end
    showRegister = showRegisterFn -- global, called from communication layer

    ---------------------------------------------------------------------------
    -- Navigate to tutorial after successful registration
    ---------------------------------------------------------------------------
    goToTutorial = function()
        storyboard.config.tutorial = true
        storyboard.gotoScene("scenes.loadingScene")
        storyboard.purgeScene("scenes.registerScene")
    end

    ---------------------------------------------------------------------------
    -- Reset processing flag (timeout guard)
    ---------------------------------------------------------------------------
    local function resetProcessing()
        isProcessing = false
    end

    ---------------------------------------------------------------------------
    -- Register / submit button handler
    ---------------------------------------------------------------------------
    local function onRegisterTap(event)
        if isProcessing then return end

        native.setKeyboardFocus(nil)
        loadingAnimation.startLoader()

        -- Get and sanitize username
        local username = usernameField.text
        if username then
            username = string.gsub(username, "%s", "")
        else
            username = ""
        end

        -- Clear error text
        if errorText then
            if errorText.text then
                errorText.text = ""
            end
        end

        -- Validate username
        if string.len(username) < 1 then
            serverCallback({m = "a", e = storyboard.localized.get("EnterUsername")})
            storyboard.analytics.newEvent("design", {
                event_id = "register:no username",
                area = "lua.scenes.intro.loginOverlay"
            })
            return
        elseif string.len(username) < 3 then
            serverCallback({m = "a", e = storyboard.localized.get("UsernameTooShort")})
            storyboard.analytics.newEvent("design", {
                event_id = "register:username too short",
                area = "lua.scenes.intro.loginOverlay"
            })
            return
        else
            local cleaned = string.gsub(username, "[^%a%d]", "")
            if cleaned ~= username then
                serverCallback({m = "a", e = storyboard.localized.get("ValidCharacterMessage")})
                storyboard.analytics.newEvent("design", {
                    event_id = "register:username !a-z0-9",
                    area = "lua.scenes.intro.loginOverlay"
                })
                return
            end
        end

        -- Start registration
        isProcessing = true
        if timeoutTimer then
            timer.cancel(timeoutTimer)
            timeoutTimer = nil
        end
        timeoutTimer = timer.performWithDelay(5000, resetProcessing, 1)

        storyboard.comm.createUser("", username, "")
        storyboard.analytics.newEvent("design", {
            event_id = "register:createHalfUser",
            area = "lua.scenes.intro.loginOverlay"
        })
    end

    ---------------------------------------------------------------------------
    -- Navigate to login scene
    ---------------------------------------------------------------------------
    local function onLoginTap(event)
        native.setKeyboardFocus(nil)
        storyboard.gotoScene("scenes.loginScene")
        storyboard.purgeScene("scenes.registerScene")
    end

    ---------------------------------------------------------------------------
    -- Text field handler factories
    ---------------------------------------------------------------------------
    genericFieldHandlerFactory = function(getDefaultField)
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
    -- UI: Message text (top, initially empty)
    ---------------------------------------------------------------------------
    messageText = display.newText(storyboard.localized.get(""), 0, 0, font, fontSize * 2)
    messageText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    messageText.xScale = 0.5
    messageText.yScale = 0.5
    messageText.x = display.contentWidth * 0.5
    messageText.y = display.contentHeight * 0.05
    view:insert(messageText)
    messageText.isVisible = true

    ---------------------------------------------------------------------------
    -- UI: Status text (server response, initially hidden)
    ---------------------------------------------------------------------------
    statusText = display.newText(storyboard.localized.get(""), 0, 0, font, fontSize * 2)
    statusText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    statusText.xScale = 0.5
    statusText.yScale = 0.5
    statusText.x = display.contentWidth * 0.5
    statusText.y = display.contentHeight * 0.2
    view:insert(statusText)
    statusText.isVisible = false

    ---------------------------------------------------------------------------
    -- UI: Title "Register"
    ---------------------------------------------------------------------------
    titleText = display.newText(storyboard.localized.get("Register"), 0, 0, font, fontSize * 3)
    titleText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    titleText.xScale = 0.5
    titleText.yScale = 0.5
    titleText.x = display.contentWidth * 0.5
    titleText.y = baseY
    view:insert(titleText)

    ---------------------------------------------------------------------------
    -- Text field height (platform-dependent)
    ---------------------------------------------------------------------------
    local fieldHeight = 30
    if isAndroid then
        fieldHeight = 40
    end

    ---------------------------------------------------------------------------
    -- UI: Username label
    ---------------------------------------------------------------------------
    usernameLabel = display.newText(storyboard.localized.get("Username"), 0, 0, font, fontSize * 2)
    usernameLabel:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    usernameLabel.xScale = 0.5
    usernameLabel.yScale = 0.5
    usernameLabel.anchorX = 1
    usernameLabel.anchorY = 0.5
    usernameLabel.x = display.contentWidth * 0.28
    usernameLabel.y = baseY + 40
    view:insert(usernameLabel)

    ---------------------------------------------------------------------------
    -- UI: Username text field
    ---------------------------------------------------------------------------
    usernameField = native.newTextField(display.contentWidth * 3, display.contentHeight * 0.35, 200, fieldHeight)
    usernameField.anchorX = 0
    usernameField.anchorY = 0.5
    usernameField.x = display.contentWidth * 0.29
    usernameField.y = baseY + 40
    usernameField.userInput = usernameFieldHandlerFactory
    view:insert(usernameField)

    ---------------------------------------------------------------------------
    -- UI: Suggestion label (hidden by default)
    ---------------------------------------------------------------------------
    suggestionLabel = display.newText("Suggestion", 0, 0, font, fontSize * 2)
    suggestionLabel:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    suggestionLabel.xScale = 0.5
    suggestionLabel.yScale = 0.5
    suggestionLabel.anchorX = 1
    suggestionLabel.anchorY = 0.5
    suggestionLabel.x = display.contentWidth * 0.28
    suggestionLabel.y = baseY + 100
    view:insert(suggestionLabel)
    suggestionLabel.isVisible = false

    ---------------------------------------------------------------------------
    -- UI: Suggestion value text (hidden, black)
    ---------------------------------------------------------------------------
    suggestionValueText = display.newText("", 0, 0, font, fontSize * 2)
    suggestionValueText:setFillColor(0, 0, 0)
    suggestionValueText.xScale = 0.5
    suggestionValueText.yScale = 0.5
    suggestionValueText.anchorX = 0
    suggestionValueText.anchorY = 0.5
    suggestionValueText.x = display.contentWidth * 0.4
    suggestionValueText.y = baseY + 100
    suggestionValueText.isVisible = false

    ---------------------------------------------------------------------------
    -- UI: Error text (hidden by default)
    ---------------------------------------------------------------------------
    errorText = display.newText(storyboard.localized.get(""), 0, 0, font, fontSize * 2)
    errorText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    errorText.xScale = 0.5
    errorText.yScale = 0.5
    errorText.x = display.contentWidth * 0.5
    errorText.y = baseY + 65
    view:insert(errorText)
    errorText.isVisible = false

    ---------------------------------------------------------------------------
    -- Show username suggestion when taken
    ---------------------------------------------------------------------------
    showSuggestionFn = function(suggestion)
        if suggestion then
            if suggestion ~= usernameField.text then
                if suggestionValueText then
                    suggestionValueText:removeSelf()
                    suggestionValueText = nil
                end
                suggestionLabel.isVisible = true
                suggestionButton.isVisible = true
                suggestionValueText = display.newText(suggestion, 0, 0, font, fontSize * 2)
                suggestionValueText:setFillColor(0, 0, 0)
                suggestionValueText.xScale = 0.5
                suggestionValueText.yScale = 0.5
                suggestionValueText.x = display.contentWidth * 0.5
                suggestionValueText.y = baseY + 100
                view:insert(suggestionValueText)
            end
        end
    end

    ---------------------------------------------------------------------------
    -- Accept the suggested username
    ---------------------------------------------------------------------------
    local function acceptSuggestion()
        usernameField.text = suggestionValueText.text
        errorText.text = ""
        suggestionLabel.isVisible = false
        suggestionButton.isVisible = false
        suggestionValueText.isVisible = false
    end

    ---------------------------------------------------------------------------
    -- UI: Buttons
    ---------------------------------------------------------------------------
    playButton = gui.newButton({
        image = "images/gui/button/play.png",
        width = storyboard.gameDataTable.backButton[1],
        height = storyboard.gameDataTable.backButton[2],
        onRelease = onRegisterTap,
        x = 430,
        y = storyboard.gameDataTable.backButton[4],
        displayGroup = view
    })
    playButton.isVisible = false

    suggestionButton = gui.newButton({
        image = "images/gui/button/blankLong.png",
        width = 200,
        height = 40,
        onRelease = acceptSuggestion,
        x = display.contentWidth * 0.5,
        y = baseY + 100,
        displayGroup = view
    })
    suggestionButton.isVisible = false

    loginButton = gui.newButton({
        image = "images/gui/button/loginKey.png",
        width = storyboard.gameDataTable.backButton[1],
        height = storyboard.gameDataTable.backButton[2],
        onRelease = onLoginTap,
        x = storyboard.gameDataTable.backButton[3],
        y = storyboard.gameDataTable.backButton[4],
        displayGroup = view
    })

    view:insert(loadingAnimation.displayGroup)

    -- Show the registration form
    showRegister()
end

---------------------------------------------------------------------------------
-- ENTER SCENE
---------------------------------------------------------------------------------
function scene:enterScene(event)
    local view = self.view
    local canGoBack = false
    local backPressed = false

    -- Reset player state for fresh registration
    storyboard.onlineFriends = {}
    storyboard.gameInvites = {}
    storyboard.playerInfo = nil
    storyboard.database.resetWithoutReceipts()
    storyboard.database.setAvatarData({1, 1, 1, 1})

    -- Enable back navigation
    local function enableBack()
        canGoBack = true
    end

    -- Enter frame: process back navigation
    enterFrameListener = function(event)
        if backPressed == true then
            backPressed = false
            canGoBack = false
            if isTutorial then
                storyboard.gameDataTable.tryIt = 0
                storyboard.gotoScene("scenes.tutorial")
            else
                storyboard.gotoScene(storyboard.getPrevious())
            end
            native.setKeyboardFocus(nil)
            storyboard.purgeScene("scenes.registerScene")
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

    -- Delayed listener setup (avoids race conditions)
    local function addListeners()
        if storyboard.getCurrentSceneName() == "scenes.registerScene" then
            background:addEventListener("tap", background)
            loginButton.addListener()
            suggestionButton.addListener()
            playButton.addListener()
            local handler = usernameFieldHandlerFactory(function() return defaultField end)
            usernameField:addEventListener("userInput", handler)
            enableBack()
        end
    end

    timer.performWithDelay(200, addListeners, 1)
    Runtime:addEventListener("key", keyListener)
    Runtime:addEventListener("enterFrame", enterFrameListener)

    ---------------------------------------------------------------------------
    -- Server callback for registration response
    ---------------------------------------------------------------------------
    serverCallback = function(response)
        if timeoutTimer then
            timer.cancel(timeoutTimer)
            timeoutTimer = nil
        end
        loadingAnimation.stopLoader()

        if response == nil then
            errorText.text = storyboard.localized.get("ErrorServerBusy")
        else
            if response.m == "x" then
                errorText.text = storyboard.localized.get("ErrorServerIsDown")
            else
                if response.e then
                    if response.e == "This username is already taken." then
                        showSuggestionFn(response.s)
                    end
                    errorText.text = storyboard.localized.get(response.e)
                end
                if response.a == 1 then
                    errorText.text = storyboard.localized.get("StartToBegin")
                    goToTutorial()
                end
            end
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
    loginButton.removeListener()
    suggestionButton.removeListener()
    playButton.removeListener()
    usernameField:removeEventListener("userInput", usernameField)
    Runtime:removeEventListener("key", keyListener)
    Runtime:removeEventListener("enterFrame", enterFrameListener)
end

---------------------------------------------------------------------------------
-- DESTROY SCENE
---------------------------------------------------------------------------------
function scene:destroyScene(event)
    background = nil
    usernameField = nil
    playButton = nil
    loginButton = nil
    goToTutorial = nil
    genericFieldHandlerFactory = nil
    usernameFieldHandlerFactory = nil
    errorText = nil
    statusText = nil
    showSuggestionFn = nil
    isTutorial = nil
    loadingAnimation = nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
