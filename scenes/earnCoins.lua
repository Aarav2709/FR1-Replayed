-- daily challenges.

local storyboard = require("modules.storyboard")
local gui = require("modules.gui")
local tableView = require("modules.tableView")

local scene = storyboard.newScene()

local homeButton
local challenges
local minutesLeft
local timeLeftText
local setChallenges, showCoins, cleanUp, stopTimer
local onFrame, onKey

local FRAME_SCALE = display.contentWidth / 480
local LIST_LEFT = 100 * FRAME_SCALE
local CELL_WIDTH = display.contentWidth - LIST_LEFT
local CELL_SHIFT = CELL_WIDTH - 380
local CONTENT_X = (LIST_LEFT + display.contentWidth) * 0.5

function scene:createScene()
  local view = self.view
  local font = storyboard.gameDataTable.font
  local FONT_SIZE = 30
  local WHITE = { 1, 1, 1, 1 }
  local frame, title, newChallengesText, coinIcon, coinsText, loadingText
  local list
  challenges = {}

  local function showList()
    if list then
      list:cleanUp()
      list = nil
    end
    if loadingText then
      display.remove(loadingText)
      loadingText = nil
    end
    if challenges == nil then
      return
    end
    list = tableView.newList({
      data = challenges, default = "images/gui/tableView/cell.png", width = CELL_WIDTH, height = 70,
      onRelease = function() end, top = 70, bottom = 0,
      callback = function(row)
        local cell = display.newGroup()
        if row.h and row.b and row.c then
          local heading = display.newText(storyboard.localized.get(row.h), 0, 0, font, FONT_SIZE * 1.8)
          heading:setFillColor(0, 0, 0, 1)
          heading.xScale, heading.yScale = 0.5, 0.5
          heading.anchorX, heading.anchorY = 0, 1
          heading.x, heading.y = 25, 25
          cell:insert(heading)
          local text = display.newText(storyboard.localized.get(row.b), 0, 0, font, FONT_SIZE * 1.4)
          text:setFillColor(0, 0, 0, 1)
          text.xScale, text.yScale = 0.5, 0.5
          text.anchorX, text.anchorY = 0, 1
          text.x, text.y = 25, 55
          cell:insert(text)
          local reward = display.newText(row.c, 0, 0, font, FONT_SIZE * 1.5)
          reward:setFillColor(0, 0, 0, 1)
          reward.xScale, reward.yScale = 0.5, 0.5
          reward.anchorX, reward.anchorY = 0, 0.5
          reward.x, reward.y = 330 + CELL_SHIFT, 10
          cell:insert(reward)
          local coin = display.newImageRect("images/gui/extra/coin.png", 15, 15)
          coin.anchorX, coin.anchorY = 0, 0.5
          coin.x, coin.y = 310 + CELL_SHIFT, 10
          cell:insert(coin)
          if row.i == 2 then
            local BAR_WIDTH = 58
            if row.p > row.g then
              row.p = row.g
            end
            local filled = row.p / row.g * BAR_WIDTH
            local bar = display.newRect(0, 0, 0, 18)
            bar:setFillColor(0.9137254901960784, 0.7725490196078432, 0.21568627450980393, 1)
            bar.anchorX, bar.anchorY = 0, 0.5
            bar.x, bar.y = 306 + CELL_SHIFT, 40
            cell:insert(bar)
            if row.p == row.g then
              bar:setFillColor(0.5686274509803921, 0.8666666666666667, 0.2901960784313726, 1)
            end
            local border = display.newRect(0, 0, BAR_WIDTH, 20)
            border.strokeWidth = 2
            border:setStrokeColor(0, 0, 0)
            border:setFillColor(1, 1, 1, 0)
            border.x, border.y = 335 + CELL_SHIFT, 40
            cell:insert(border)
            local progress
            if row.p == row.g then
              progress = display.newText("\226\156\147", 0, 0, font, isAndroid and FONT_SIZE or FONT_SIZE * 1.2)
              progress.y = isAndroid and 50 or 54
            else
              progress = display.newText(row.p .. " / " .. row.g, 0, 0, font, FONT_SIZE)
              progress.y = 50
            end
            progress:setFillColor(0, 0, 0, 1)
            progress.xScale, progress.yScale = 0.5, 0.5
            progress.anchorX, progress.anchorY = 0.5, 1
            progress.x = 335 + CELL_SHIFT
            cell:insert(progress)
            transition.to(bar, { time = 1, width = bar.width + filled, x = bar.x })
          end
        end
        function cell.getId()
          return row.i
        end
        return cell
      end,
    })
    list.x = LIST_LEFT
    view:insert(list)
    view:insert(frame)
    view:insert(title)
    view:insert(newChallengesText)
    view:insert(timeLeftText)
    view:insert(coinIcon)
    if coinsText then
      view:insert(coinsText)
    end
    homeButton.updateDisplay(view)
  end

  function setChallenges(packet)
    challenges = {}
    if packet then
      challenges = packet.l
      minutesLeft = packet.t
      showList()
    end
  end

  function cleanUp()
    if list then
      list:cleanUp()
      list = nil
    end
    if coinsText then
      coinsText.text = ""
      display.remove(coinsText)
      coinsText = nil
    end
  end

  local background = display.newRect(0, 0, display.contentWidth, 320)
  background:setFillColor(0.9529411764705882, 0.8980392156862745, 0.803921568627451)
  background.anchorX, background.anchorY = 0, 0
  view:insert(background)
  frame = display.newImageRect("images/gui/background/earnCoins.png", 480, 320)
  frame.anchorX, frame.anchorY = 0, 0
  frame.xScale, frame.yScale = FRAME_SCALE, 1
  view:insert(frame)
  title = display.newText(storyboard.localized.get("Challenges"), 0, 0, font, FONT_SIZE * 2.3)
  title:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
  title.xScale, title.yScale = 0.5, 0.5
  title.x, title.y = CONTENT_X, 25
  view:insert(title)
  loadingText = display.newText(storyboard.localized.get("Loading"), 0, 0, font, FONT_SIZE * 1.5)
  loadingText:setFillColor(0, 0, 0, 1)
  loadingText.xScale, loadingText.yScale = 0.5, 0.5
  loadingText.x, loadingText.y = CONTENT_X, 70
  view:insert(loadingText)
  newChallengesText = display.newText(storyboard.localized.get("NewChallenges"), 0, 0, 180, 200, font, FONT_SIZE * 0.8)
  newChallengesText:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
  newChallengesText.anchorX, newChallengesText.anchorY = 0, 0
  newChallengesText.xScale, newChallengesText.yScale = 0.5, 0.5
  newChallengesText.x, newChallengesText.y = 6 + (LIST_LEFT - 100) * 0.5, 110
  view:insert(newChallengesText)
  timeLeftText = display.newText("", 0, 0, font, FONT_SIZE)
  timeLeftText:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
  timeLeftText.anchorX, timeLeftText.anchorY = 0.5, 0
  timeLeftText.xScale, timeLeftText.yScale = 0.5, 0.5
  timeLeftText.x, timeLeftText.y = LIST_LEFT * 0.5, 145
  view:insert(timeLeftText)
  homeButton = gui.newButton({
    image = "images/gui/button/home.png",
    width = storyboard.gameDataTable.backButton[1], height = storyboard.gameDataTable.backButton[2],
    onRelease = function()
      storyboard.gotoScene("scenes.mainMenu")
      storyboard.purgeScene("scenes.earnCoins")
    end,
    x = storyboard.gameDataTable.backButton[3], y = storyboard.gameDataTable.backButton[4],
    displayGroup = view,
  })

  function showCoins()
    if storyboard.getCurrentSceneName() == "scenes.earnCoins" then
      local money = storyboard.database.getMoney() or 0
      if coinsText then
        display.remove(coinsText)
        coinsText = nil
      end
      coinsText = display.newText(money, 0, 0, font, FONT_SIZE * 1.3)
      coinsText:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
      coinsText.xScale, coinsText.yScale = 0.5, 0.5
      coinsText.anchorX, coinsText.anchorY = 0, 0.5
      coinsText.x, coinsText.y = 30, 25
      view:insert(coinsText)
    end
  end

  coinIcon = display.newImageRect("images/gui/extra/coin.png", 16, 16)
  coinIcon.anchorX, coinIcon.anchorY = 0, 0.5
  coinIcon.x, coinIcon.y = 10, 25
  view:insert(coinIcon)
end

function scene:enterScene()
  local backKeyEnabled, backPressed = false, false
  local lastMinute = 0
  storyboard.tcpSocial.setReceiveInterval(50)

  local function updateTimeLeft()
    if minutesLeft and timeLeftText and lastMinute <= os.time() - 60 then
      lastMinute = os.time()
      minutesLeft = minutesLeft - 1
      if minutesLeft < 0 then
        timeLeftText.text = "0h 0m"
        storyboard.comm.getDaliyChallanges()
      else
        timeLeftText.text = math.floor(minutesLeft / 60) .. "h " .. minutesLeft % 60 .. "m"
      end
    end
  end

  storyboard.comm.setCallback(function(packet)
    if packet.m == "r" then
      showCoins()
      setChallenges(packet)
      lastMinute = 0
      updateTimeLeft()
    end
  end)
  storyboard.comm.getDaliyChallanges()
  local countdown = timer.performWithDelay(1000, function(event)
    if storyboard.getCurrentSceneName() ~= "scenes.earnCoins" then
      timer.cancel(event.source)
      return
    end
    updateTimeLeft()
  end, 0)

  function onFrame()
    if backPressed then
      backPressed = false
      backKeyEnabled = false
      storyboard.gotoScene("scenes.mainMenu")
      storyboard.purgeScene("scenes.earnCoins")
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
    if storyboard.getCurrentSceneName() == "scenes.earnCoins" then
      homeButton.addListener()
      backKeyEnabled = true
    end
  end, 1)
  Runtime:addEventListener("key", onKey)
  Runtime:addEventListener("enterFrame", onFrame)

  function stopTimer()
    timer.cancel(countdown)
  end
end

function scene:exitScene()
  storyboard.tcpSocial.setReceiveInterval(nil)
  cleanUp()
  stopTimer()
  homeButton.removeListener()
  Runtime:removeEventListener("key", onKey)
  Runtime:removeEventListener("enterFrame", onFrame)
  storyboard.comm.setCallback(function() end)
end

function scene:destroyScene()
  homeButton = nil
  challenges, minutesLeft = nil, nil
  setChallenges, showCoins, cleanUp, stopTimer = nil, nil, nil, nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
