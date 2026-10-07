-- settings buttons.

local storyboard = require("modules.storyboard")
local gui = require("modules.gui")

local M = {}

function M.create()
  local group = display.newGroup()
  local WIDTH, HEIGHT = 112, 50
  local scale = display.contentWidth / 480
  local LEFT, Y, SPACING = 160 * scale, 290, 120 * scale

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

  function group.addButtonListeners()
    account.addListener()
    general.addListener()
    help.addListener()
  end

  function group.removeButtonListeners()
    account.removeListener()
    general.removeListener()
    help.removeListener()
  end

  function group.clean()
    group.removeButtonListeners()
    display.remove(group)
  end

  return group
end

return M
