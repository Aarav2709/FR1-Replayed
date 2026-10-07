-- help pages.

local storyboard = require("modules.storyboard")
local gui = require("modules.gui")

local scene = storyboard.newScene()

local nextButton
local pages
local onFrame, onKey

function scene:createScene()
  local view = self.view
  local font = storyboard.gameDataTable.font
  local fontSize = storyboard.localized.getFontSize() + 1
  local W, H = display.contentWidth, display.contentHeight
  local WHITE = { 1, 1, 1, 1 }

  local background = display.newImageRect("images/gui/background/login.png", 480, 320)
  background.x, background.y = W * 0.5, H * 0.5
  view:insert(background)
  pages = display.newGroup()

  local function addText(text, size, x, y)
    local label = display.newText(text, 0, 0, font, size)
    label:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
    label.xScale, label.yScale = 0.5, 0.5
    label.x, label.y = x, y
    pages:insert(label)
    return label
  end
  local function addImage(path, width, height, x, y)
    local image = display.newImageRect(path, width, height)
    image.x, image.y = x, y
    pages:insert(image)
  end

  addText(storyboard.localized.get("InGame"), 50, 0, H * 0.15)
  addImage("images/gui/button/btnJump.png", 64, 64, W * 0.3, H * 0.4)
  addImage("images/gui/button/btnPowerUp.png", 64, 64, -W * 0.3, H * 0.4)
  addText(storyboard.localized.get("PowerUpButton"), fontSize * 2, -W * 0.3, H * 0.55)
  addText(storyboard.localized.get("JumpButton"), fontSize * 2, W * 0.3, H * 0.55)

  addText(storyboard.localized.get("MainMenu"), 50, W, H * 0.15)
  addImage("images/gui/button/blank.png", 60, 50, W * 0.8, H * 0.4)
  addText("LAN", 44, W * 0.8, H * 0.4)
  addImage("images/gui/button/market.png", 80, 50, W * 1.2, H * 0.4)
  addText("Play on your network", fontSize * 2, W * 0.8, H * 0.55)
  addText(storyboard.localized.get("Customize"), fontSize * 2, W * 1.2, H * 0.55)

  addText(storyboard.localized.get("PlayMenu"), 50, W * 2, H * 0.15)
  addImage("images/gui/button/quickPlay.png", 75, 75, W * 1.8, H * 0.4)
  addImage("images/gui/button/host.png", 75, 75, W * 2.2, H * 0.4)
  addText(storyboard.localized.get("PlayWithRandomPeople"), fontSize * 2, W * 1.8, H * 0.55)
  addText("Play with LAN", fontSize * 2, W * 2.2, H * 0.55)

  addText(storyboard.localized.get("PowerUps"), 50, W * 3, H * 0.15)
  addImage("images/gui/tutorial/powerUps.png", 280, 200, W * 3 - 82, H * 0.55)
  local descriptions = {
    "TrapDesc", "LightningDesc", "SawbladeDesc", "BoxDesc", "NinjaSwordDesc",
    "MagnetDesc", "BoostDesc", "ShieldDesc", "HeartDesc", "JumpBoostDesc",
  }
  for i, key in ipairs(descriptions) do
    local label = addText(storyboard.localized.get(key), fontSize * 2, 0, 0)
    label.anchorX, label.anchorY = 0, 0.5
    if i < 6 then
      label.x = W * 3 - 168
      label.y = H * 0.16 + H * 0.13 * i
    else
      label.x = W * 3 + 72
      label.y = H * 0.16 + H * 0.13 * (i - 5)
    end
  end
  view:insert(pages)
  pages.y = -H * 0.1

  local ready = true
  local page = 1
  nextButton = gui.newButton({
    image = "images/gui/button/next.png",
    width = storyboard.gameDataTable.backButton[1], height = storyboard.gameDataTable.backButton[2],
    x = display.contentWidth - 50, y = storyboard.gameDataTable.backButton[4], displayGroup = view,
    onRelease = function()
      if ready then
        if page < 4 then
          ready = false
          transition.to(pages, { time = 300, x = pages.x - W, onComplete = function() ready = true end })
          page = page + 1
        else
          storyboard.gotoScene("scenes.settings")
          storyboard.purgeScene("scenes.tutorial")
        end
      end
    end,
  })
end

function scene:enterScene()
  local backKeyEnabled, backPressed = false, false

  function onFrame()
    if backPressed then
      backPressed = false
      backKeyEnabled = false
      storyboard.gotoScene("scenes.settings")
      storyboard.purgeScene("scenes.tutorial")
    end
  end

  function onKey(event)
    if event.phase == "up" and event.keyName == "back" then
      if backKeyEnabled then
        backPressed = true
      end
      return true
    end
    return false
  end

  timer.performWithDelay(200, function()
    if storyboard.getCurrentSceneName() == "scenes.tutorial" then
      nextButton.addListener()
      backKeyEnabled = true
    end
  end, 1)
  Runtime:addEventListener("key", onKey)
  Runtime:addEventListener("enterFrame", onFrame)
  pages.x = display.contentWidth * 0.5
end

function scene:exitScene()
  nextButton.removeListener()
  Runtime:removeEventListener("key", onKey)
  Runtime:removeEventListener("enterFrame", onFrame)
end

function scene:destroyScene()
  nextButton, pages = nil, nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
