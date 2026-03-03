---------------------------------------------------------------------------------
-- friends.lua — Friends list
---------------------------------------------------------------------------------
local storyboard = require("modules.storyboard")
local scene = storyboard.newScene()

-- Module-level variables
local homeButton
local addFriendButton
local enterFrameListener
local keyListener
local background
local friendsList
local noFriendsText
local serverCallback
local loadingAnimation

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
    -- Title
    ---------------------------------------------------------------------------
    local titleText = display.newText({
        text = storyboard.localized.get("Friends") or "Friends",
        x = display.contentCenterX,
        y = display.contentHeight * 0.08,
        font = font,
        fontSize = fontSize * 2,
    })
    titleText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(titleText)

    ---------------------------------------------------------------------------
    -- No friends placeholder
    ---------------------------------------------------------------------------
    noFriendsText = display.newText({
        text = storyboard.localized.get("NoFriends") or "No friends yet. Add some!",
        x = display.contentCenterX,
        y = display.contentCenterY,
        font = font,
        fontSize = fontSize,
        width = display.contentWidth * 0.7,
        align = "center",
    })
    noFriendsText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(noFriendsText)

    ---------------------------------------------------------------------------
    -- Add Friend button
    ---------------------------------------------------------------------------
    local function onAddFriendTap(event)
        storyboard.gotoScene("scenes.addFriend")
        return true
    end

    addFriendButton = gui.newButton({
        image = "images/gui/button/blank.png",
        text = storyboard.localized.get("AddFriend") or "Add Friend",
        width = 120, height = 40,
        x = display.contentCenterX,
        y = display.contentHeight * 0.85,
        onRelease = onAddFriendTap,
    })
    view:insert(addFriendButton.displayGroup or addFriendButton)

    ---------------------------------------------------------------------------
    -- Home button
    ---------------------------------------------------------------------------
    local function onHomeTap(event)
        storyboard.gotoScene("scenes.mainMenu")
        storyboard.purgeScene("scenes.friends")
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

    ---------------------------------------------------------------------------
    -- Server callback — load friends list
    ---------------------------------------------------------------------------
    serverCallback = function(response)
        if response and response.friends then
            noFriendsText.isVisible = (#response.friends == 0)
            -- TODO: populate scrollable friends list
        end
    end
end

---------------------------------------------------------------------------------
-- ENTER SCENE
---------------------------------------------------------------------------------
function scene:enterScene(event)
    -- Request friends list
    storyboard.comm.send("getFriends", {
        username = storyboard.playerInfo.username,
    }, serverCallback)
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
    homeButton = nil
    addFriendButton = nil
    noFriendsText = nil
    friendsList = nil
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
