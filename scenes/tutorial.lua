---------------------------------------------------------------------------------
-- tutorial.lua — Tutorial scene
---------------------------------------------------------------------------------
local storyboard = require("modules.storyboard")
local scene = storyboard.newScene()

-- Module-level variables
local backButton
local nextButton
local keyListener
local background
local tutorialStep = 1
local tutorialImages = {}
local instructionText
local enterFrameListener

local MAX_STEPS = 5 -- placeholder number of tutorial pages

---------------------------------------------------------------------------------
-- CREATE SCENE
---------------------------------------------------------------------------------
function scene:createScene(event)
    local view = self.view
    local gui = require("modules.gui")
    local font = storyboard.gameDataTable.font
    local fontSize = storyboard.localized.getFontSize()
    local textColor = {1, 1, 1, 1}

    tutorialStep = 1

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
        text = storyboard.localized.get("Tutorial") or "Tutorial",
        x = display.contentCenterX,
        y = display.contentHeight * 0.08,
        font = font,
        fontSize = fontSize * 2,
    })
    titleText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(titleText)

    ---------------------------------------------------------------------------
    -- Tutorial content area
    ---------------------------------------------------------------------------
    local contentBg = display.newRect(display.contentCenterX, display.contentCenterY - 10,
        display.contentWidth * 0.85, display.contentHeight * 0.55)
    contentBg:setFillColor(0, 0, 0, 0.25)
    view:insert(contentBg)

    ---------------------------------------------------------------------------
    -- Instruction text (changes per step)
    ---------------------------------------------------------------------------
    local tutorialTexts = {
        storyboard.localized.get("TutorialStep1") or "Tap the screen to jump!",
        storyboard.localized.get("TutorialStep2") or "Pick up power-ups to use against opponents.",
        storyboard.localized.get("TutorialStep3") or "Reach the finish line first to win!",
        storyboard.localized.get("TutorialStep4") or "Earn coins to buy hats and accessories.",
        storyboard.localized.get("TutorialStep5") or "Play with friends in Custom Play!",
    }

    instructionText = display.newText({
        text = tutorialTexts[1],
        x = display.contentCenterX,
        y = display.contentCenterY - 10,
        font = font,
        fontSize = fontSize,
        width = display.contentWidth * 0.7,
        align = "center",
    })
    instructionText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(instructionText)

    ---------------------------------------------------------------------------
    -- Step indicator
    ---------------------------------------------------------------------------
    local stepText = display.newText({
        text = "1 / " .. MAX_STEPS,
        x = display.contentCenterX,
        y = display.contentHeight * 0.82,
        font = font,
        fontSize = fontSize * 0.85,
    })
    stepText:setFillColor(textColor[1], textColor[2], textColor[3], 0.7)
    view:insert(stepText)

    ---------------------------------------------------------------------------
    -- Next / Done button
    ---------------------------------------------------------------------------
    local function updateTutorial()
        instructionText.text = tutorialTexts[tutorialStep] or ""
        stepText.text = tostring(tutorialStep) .. " / " .. MAX_STEPS
    end

    local function onNextTap(event)
        if tutorialStep < MAX_STEPS then
            tutorialStep = tutorialStep + 1
            updateTutorial()
        else
            -- Tutorial complete
            storyboard.gotoScene("scenes.mainMenu")
            storyboard.purgeScene("scenes.tutorial")
        end
        return true
    end

    nextButton = gui.newButton({
        image = "images/gui/button/blank.png",
        text = storyboard.localized.get("Next") or "Next",
        width = 120, height = 40,
        x = display.contentCenterX,
        y = display.contentHeight * 0.9,
        onRelease = onNextTap,
    })
    view:insert(nextButton.displayGroup or nextButton)

    ---------------------------------------------------------------------------
    -- Back / Skip button
    ---------------------------------------------------------------------------
    local function onBackTap(event)
        storyboard.gotoScene("scenes.mainMenu")
        storyboard.purgeScene("scenes.tutorial")
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
    nextButton = nil
    instructionText = nil
    tutorialImages = {}
    enterFrameListener = nil
    keyListener = nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
