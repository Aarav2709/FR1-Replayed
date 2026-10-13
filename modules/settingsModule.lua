-- settings buttons.

local storyboard = require("modules.storyboard")
local gui = require("modules.gui")
local pcMode = require("modules.pcMode")

local M = {}

function M.create()
  local group = display.newGroup()
  local WIDTH, HEIGHT = 112, 50
  local scale = display.contentWidth / 480
  local LEFT, Y, SPACING = 160 * scale, 290, 120 * scale
  if pcMode.isPC then
    LEFT = 150
    SPACING = (display.contentWidth - 60 - LEFT) / 3
    WIDTH = math.min(WIDTH, SPACING - 6)
  end

  local general = gui.newButton({
    image = "images/gui/button/general.png", width = WIDTH, height = HEIGHT,
    onRelease = function() storyboard.showOverlay("scenes.generalSettings", { isModal = true }) end,
    x = LEFT + SPACING, y = Y, displayGroup = group,
  })
  local account = gui.newButton({
    image = "images/gui/button/account.png", width = WIDTH, height = HEIGHT,
    onRelease = function() storyboard.showOverlay("scenes.accountSettings", { isModal = true }) end,
    x = LEFT, y = Y, displayGroup = group,
  })
  local help = gui.newButton({
    image = "images/gui/button/help.png", width = WIDTH, height = HEIGHT,
    onRelease = function() storyboard.showOverlay("scenes.helpSettings", { isModal = true }) end,
    x = LEFT + 2 * SPACING, y = Y, displayGroup = group,
  })

  local buttons = { account, general, help }
  if pcMode.isPC then
    buttons[#buttons + 1] = gui.newButton({
      image = "images/gui/button/blank.png", text = { string = "PC", size = 24 }, width = WIDTH * 0.75, height = HEIGHT,
      onRelease = function() storyboard.showOverlay("scenes.pcSettings", { isModal = true }) end,
      x = LEFT + 3 * SPACING, y = Y, displayGroup = group,
    })
  end

  function group.addButtonListeners()
    for _, button in ipairs(buttons) do
      button.addListener()
    end
  end

  function group.removeButtonListeners()
    for _, button in ipairs(buttons) do
      button.removeListener()
    end
  end

  function group.clean()
    group.removeButtonListeners()
    display.remove(group)
  end

  return group
end

return M
