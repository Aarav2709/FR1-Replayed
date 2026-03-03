---------------------------------------------------------------------------------
-- settings.lua — Settings scene: credits, social links, account management
---------------------------------------------------------------------------------
local storyboard = require("modules.storyboard")
local scene = storyboard.newScene()

-- Module-level variables
local homeButton
local soundOnImage        -- (unused: referenced by legacy toggle functions)
local soundOffImage       -- (unused: referenced by legacy toggle functions)
local chatOnImage         -- (unused: referenced by legacy toggle functions)
local chatOffImage        -- (unused: referenced by legacy toggle functions)
local notificationOnImage -- (unused: referenced by legacy toggle functions)
local notificationOffImage-- (unused: referenced by legacy toggle functions)
local enterFrameListener
local keyListener
local settingsBar
local onPasswordOrLogout
local cleanUp
local scrollTimer

---------------------------------------------------------------------------------
-- createScene
---------------------------------------------------------------------------------
function scene:createScene(event)
    local view = self.view
    local gui = require("modules.gui")
    local background
    local settingsFooter
    local tableViewModule = require("modules.tableView")
    local creditsList
    local creditsData = {}
    local buttonImage
    local facebookUrlText, funRunGameText, hashtagText
    local font = storyboard.gameDataTable.font
    local fontSize = 20
    local fontSizeLarge = 22
    local textColor = {1, 1, 1, 1}
    local buttonLabelText

    -- Create settings tab bar (General / Account / Help)
    local settingsModule = require("modules.settingsModule")
    settingsBar = settingsModule.create()

    -- Determine Password vs LogOut based on device sync state
    local syncState = storyboard.database.getDeviceSyncState()
    if syncState == 1 then
        buttonImage = "images/gui/button/blank.png"
        buttonLabelText = storyboard.localized.get("Password")
    else
        buttonImage = "images/gui/button/blank.png"
        buttonLabelText = storyboard.localized.get("LogOut")
    end

    ---------------------------------------------------------------------------
    -- Password / Log-out handler
    ---------------------------------------------------------------------------
    local function handlePasswordOrLogout()
        local state = storyboard.database.getDeviceSyncState()
        if state == 1 then
            storyboard.gotoScene("scenes.syncDevicesScene")
            storyboard.purgeScene("scenes.settings")
        else
            local resetOk = storyboard.database.reset()
            if resetOk then
                storyboard.gameDataTable.tryIt = 0
                storyboard.comm.stopTCPSocial()

                local function navigateToRegister()
                    storyboard.purgeScene("scenes.mainMenu")
                    storyboard.gotoScene("scenes.registerScene")
                    storyboard.purgeScene("scenes.settings")
                end

                if storyboard.facebook.isLoggedIn() then
                    storyboard.facebook.logout(function()
                        print("got logout success")
                    end)
                    navigateToRegister()
                else
                    navigateToRegister()
                end
            else
                native.showAlert(
                    storyboard.localized.get("MissingMoney"),
                    storyboard.localized.get("GoToMarketToSync"),
                    {storyboard.localized.get("Ok")}
                )
            end
        end
    end
    onPasswordOrLogout = handlePasswordOrLogout

    ---------------------------------------------------------------------------
    -- Legacy toggle functions (dead code — actual toggles in generalSettings)
    ---------------------------------------------------------------------------
    local function toggleSound()
        local sound = storyboard.database.getSound()
        if sound == 1 then
            storyboard.database.setSound(0)
            soundOffImage.alpha = 1
            soundOnImage.alpha = 0
        else
            storyboard.database.setSound(1)
            soundOnImage.alpha = 1
            soundOffImage.alpha = 0
        end
    end

    local function toggleChat()
        local chat = storyboard.database.getChat()
        if chat == 1 then
            storyboard.database.setChat(0)
            chatOffImage.alpha = 1
            chatOnImage.alpha = 0
        else
            storyboard.database.setChat(1)
            chatOnImage.alpha = 1
            chatOffImage.alpha = 0
        end
    end

    local function toggleNotification()
        local notif = storyboard.database.getNotification()
        if notif == 1 then
            storyboard.database.setNotification(0)
            notificationOnImage.alpha = 1
            notificationOffImage.alpha = 0
        else
            storyboard.database.setNotification(1)
            notificationOffImage.alpha = 1
            notificationOnImage.alpha = 0
        end
    end

    ---------------------------------------------------------------------------
    -- Navigation helpers
    ---------------------------------------------------------------------------
    local function goToTutorial()
        storyboard.gotoScene("scenes.tutorial")
        storyboard.purgeScene("scenes.settings")
    end

    local function goToFacebook()
        storyboard.gotoScene("scenes.facebookScene")
        storyboard.purgeScene("scenes.settings")
    end

    local function goToMainMenu()
        storyboard.gotoScene("scenes.mainMenu")
        storyboard.purgeScene("scenes.settings")
    end

    ---------------------------------------------------------------------------
    -- Background
    ---------------------------------------------------------------------------
    background = display.newImageRect("images/gui/background/login.png", 480, 320)
    background.x = display.contentWidth * 0.5
    background.y = display.contentHeight * 0.5
    view:insert(background)

    ---------------------------------------------------------------------------
    -- Credits data
    ---------------------------------------------------------------------------
    local function addCreditInfo(text, size)
        creditsData[#creditsData + 1] = {creditInfo = text}
        if size then
            creditsData[#creditsData].size = size
        end
    end

    -- Credits title size (adjusted for Spanish)
    local creditsTitleSize = 28
    if storyboard.localized.language == "es" then
        creditsTitleSize = 24
    end

    addCreditInfo(storyboard.localized.get("Credits"), creditsTitleSize)
    addCreditInfo("Erlend B. Haugsdal")
    addCreditInfo("Nicolaj B. Petersen")
    addCreditInfo("Martin N. Vagstad")
    addCreditInfo("Peder A. Aune")
    addCreditInfo("Martin S. Sangolt")
    addCreditInfo("Marius Giske")
    addCreditInfo("Jonas Eikli")
    addCreditInfo("Matthew Guise")
    addCreditInfo("Lars T\195\184nder")
    addCreditInfo("Vellko Pajko")
    addCreditInfo("Fredrik F. Hansen")
    addCreditInfo("Aleksander Elvemo")
    addCreditInfo("Aurora K. Berg")
    addCreditInfo("Ida V. Oltedal")
    addCreditInfo("Anne Marte Markussen")
    addCreditInfo("Zahra Alobaidi")
    addCreditInfo("")
    addCreditInfo(storyboard.localized.get("SpecialThanks"), creditsTitleSize)
    addCreditInfo("Ungdomsfondet i S\195\184r-Tr\195\184ndelag")
    addCreditInfo("Helene E. Wiik")
    addCreditInfo("Mirna Besirovic")
    addCreditInfo("Benedicte H. St\195\184rksen")
    addCreditInfo("")
    addCreditInfo("")
    addCreditInfo("")
    addCreditInfo("")
    addCreditInfo("Dirtybit.com", 28)

    ---------------------------------------------------------------------------
    -- Auto-scroll credits after 5 seconds
    ---------------------------------------------------------------------------
    local function autoScrollCredits()
        if storyboard.getCurrentSceneName() == "scenes.settings" then
            if creditsList then
                local currentY = creditsList:getY()
                if currentY > -15 then
                    local targetY = -creditsList.height + 123
                    creditsList:scrollTo(targetY, 20000)
                end
            end
        end
    end
    scrollTimer = timer.performWithDelay(5000, autoScrollCredits, 1)

    ---------------------------------------------------------------------------
    -- Cancel scroll timer (and cleanup helpers)
    ---------------------------------------------------------------------------
    local function cancelScrollTimer()
        if scrollTimer then
            timer.cancel(scrollTimer)
            scrollTimer = nil
        end
    end

    ---------------------------------------------------------------------------
    -- Create / recreate credits list via tableView
    ---------------------------------------------------------------------------
    local function createCreditsList()
        if creditsList then
            creditsList:cleanUp()
            creditsList = nil
        end

        creditsList = tableViewModule.newList({
            data = creditsData,
            default = "images/transparent.png",
            width = 200,
            height = 28,
            onRelease = cancelScrollTimer,
            top = -10,
            bottom = 197,
            callback = function(item)
                local group = display.newGroup()
                local size = fontSize
                if item.size then
                    size = item.size
                end
                local text = display.newText(item.creditInfo, 0, 0, font, size * 1.5)
                text:setFillColor(1, 1, 1, 1)
                text.xScale = 0.5
                text.yScale = 0.5
                text.anchorX = 0.5
                text.anchorY = 1
                text.x = 35
                text.y = 40
                group:insert(text)
                return group
            end
        })
        creditsList.x = 320
        view:insert(creditsList)
    end

    createCreditsList()

    ---------------------------------------------------------------------------
    -- Username label + value
    ---------------------------------------------------------------------------
    local usernameLabel = display.newText(
        storyboard.localized.get("Username"), 0, 0, font, fontSize * 2
    )
    usernameLabel:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    usernameLabel.xScale = 0.5
    usernameLabel.yScale = 0.5
    usernameLabel.x = display.contentWidth * 0.28
    usernameLabel.y = 16
    view:insert(usernameLabel)

    local usernameText = display.newText(
        storyboard.playerInfo.username, 0, 0, font, fontSizeLarge * 2.6
    )
    usernameText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    usernameText.xScale = 0.5
    usernameText.yScale = 0.5
    usernameText.x = display.contentWidth * 0.28
    usernameText.y = usernameLabel.y + 36
    view:insert(usernameText)

    ---------------------------------------------------------------------------
    -- Game title
    ---------------------------------------------------------------------------
    local gameTitleText = display.newText(
        "Fun Run - Multiplayer Race", 0, 0, font, fontSize * 2
    )
    gameTitleText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    gameTitleText.xScale = 0.5
    gameTitleText.yScale = 0.5
    gameTitleText.x = display.contentWidth * 0.28
    gameTitleText.y = usernameText.y + 70
    view:insert(gameTitleText)

    ---------------------------------------------------------------------------
    -- Version text
    ---------------------------------------------------------------------------
    local versionText = display.newText(
        "Version " .. storyboard.config.fullVersion, 0, 0, font, fontSize * 2
    )
    versionText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    versionText.xScale = 0.5
    versionText.yScale = 0.5
    versionText.x = display.contentWidth * 0.28
    versionText.y = gameTitleText.y + 30
    view:insert(versionText)

    ---------------------------------------------------------------------------
    -- Settings footer image
    ---------------------------------------------------------------------------
    settingsFooter = display.newImageRect("images/gui/background/settings.png", 480, 120)
    settingsFooter.anchorX = 0.5
    settingsFooter.anchorY = 1
    settingsFooter.x = display.contentWidth * 0.5
    settingsFooter.y = display.contentHeight
    view:insert(settingsFooter)

    ---------------------------------------------------------------------------
    -- Social media text (rotated)
    ---------------------------------------------------------------------------
    facebookUrlText = display.newText("facebook.com/", 0, 0, font, fontSizeLarge * 2)
    facebookUrlText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    facebookUrlText.xScale = 0.5
    facebookUrlText.yScale = 0.5
    facebookUrlText.anchorX = 0
    facebookUrlText.anchorY = 1
    facebookUrlText.x = display.contentWidth * 0.05
    facebookUrlText.y = display.contentHeight * 0.78
    facebookUrlText:rotate(-5.5)
    view:insert(facebookUrlText)

    funRunGameText = display.newText("funrungame", 0, 0, font, fontSizeLarge * 2)
    funRunGameText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    funRunGameText.xScale = 0.5
    funRunGameText.yScale = 0.5
    funRunGameText.anchorX = 0
    funRunGameText.anchorY = 1
    funRunGameText.x = display.contentWidth * 0.295
    funRunGameText.y = display.contentHeight * 0.745
    funRunGameText:rotate(-2)
    view:insert(funRunGameText)

    hashtagText = display.newText("# funrun", 0, 0, font, fontSizeLarge * 2)
    hashtagText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    hashtagText.xScale = 0.5
    hashtagText.yScale = 0.5
    hashtagText.anchorX = 0
    hashtagText.anchorY = 1
    hashtagText.x = display.contentWidth * 0.65
    hashtagText.y = display.contentHeight * 0.745
    hashtagText:rotate(2.5)
    view:insert(hashtagText)

    ---------------------------------------------------------------------------
    -- Home button
    ---------------------------------------------------------------------------
    homeButton = gui.newButton({
        image = "images/gui/button/home.png",
        width = storyboard.gameDataTable.backButton[1],
        height = storyboard.gameDataTable.backButton[2],
        onRelease = goToMainMenu,
        x = storyboard.gameDataTable.backButton[3],
        y = storyboard.gameDataTable.backButton[4],
        displayGroup = view
    })

    ---------------------------------------------------------------------------
    -- Color / Facebook state
    ---------------------------------------------------------------------------
    local blueColor = {0.245, 0.36, 0.51}
    local hasFacebook = true
    local facebookId = storyboard.database.getFacebookId()
    if facebookId then
        blueColor = {0.245, 0.36, 0.51}
        hasFacebook = false
    end

    -- Insert settings bar into view
    view:insert(settingsBar)

    ---------------------------------------------------------------------------
    -- cleanUp — cancel scroll timer and release credits list
    ---------------------------------------------------------------------------
    cleanUp = function()
        if scrollTimer then
            timer.cancel(scrollTimer)
            scrollTimer = nil
        end
        if creditsList then
            creditsList:cleanUp()
            creditsList = nil
        end
    end
end

---------------------------------------------------------------------------------
-- enterScene
---------------------------------------------------------------------------------
function scene:enterScene(event)
    local canGoBack = false
    local backPressed = false
    local view = self.view

    local function enableBack()
        canGoBack = true
    end

    enterFrameListener = function()
        if backPressed == true then
            backPressed = false
            canGoBack = false
            storyboard.gotoScene("scenes.mainMenu")
            storyboard.purgeScene("scenes.settings")
        end
    end

    keyListener = function(event)
        if event.phase == "up" and event.keyName == "back" then
            if canGoBack then
                backPressed = true
            end
            return true
        end
        return false
    end

    local function addListeners()
        if storyboard.getCurrentSceneName() == "scenes.settings" then
            settingsBar.addButtonListeners()
            homeButton.addListener()
            enableBack()
        end
    end

    timer.performWithDelay(200, addListeners, 1)
    Runtime:addEventListener("key", keyListener)
    Runtime:addEventListener("enterFrame", enterFrameListener)
end

---------------------------------------------------------------------------------
-- exitScene
---------------------------------------------------------------------------------
function scene:exitScene(event)
    cleanUp()
    settingsBar.removeButtonListeners()
    homeButton.removeListener()
    Runtime:removeEventListener("key", keyListener)
    Runtime:removeEventListener("enterFrame", enterFrameListener)
end

---------------------------------------------------------------------------------
-- destroyScene
---------------------------------------------------------------------------------
function scene:destroyScene(event)
    homeButton = nil
    soundOnImage = nil
    keyListener = nil
    enterFrameListener = nil
    settingsBar.clean()
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
