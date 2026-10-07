-- full width backgrounds and strips for screens wider than 3:2.

local adaptiveUI = {}

local DESIGN_WIDTH, DESIGN_HEIGHT = 480, 320

local newImageRect = display.newImageRect

function adaptiveUI.coverScale()
  return math.max(display.actualContentWidth / DESIGN_WIDTH, display.actualContentHeight / DESIGN_HEIGHT)
end

function adaptiveUI.coverPoint(x, y)
  local scale = adaptiveUI.coverScale()
  return display.contentCenterX + (x - DESIGN_WIDTH * 0.5) * scale, display.contentCenterY + (y - DESIGN_HEIGHT * 0.5) * scale
end

function adaptiveUI.newSidebarBackground(path)
  local group = display.newGroup()
  local sheet = graphics.newImageSheet(path, {
    frames = { { x = 0, y = 0, width = 216, height = 640 }, { x = 216, y = 0, width = 744, height = 640 } },
    sheetContentWidth = 960, sheetContentHeight = 640,
  })
  local wall = display.newImageRect(group, sheet, 1, 108, DESIGN_HEIGHT)
  wall.anchorX, wall.anchorY = 0, 0
  local sky = display.newImageRect(group, sheet, 2, display.contentWidth - 108, DESIGN_HEIGHT)
  sky.anchorX, sky.anchorY = 0, 0
  sky.x = 108
  group.y = (display.contentHeight - DESIGN_HEIGHT) * 0.5
  return group
end

function display.newImageRect(...)
  local args = { ... }
  local image = newImageRect(...)

  local first = type(args[1]) == "string" and 1 or 2
  local path, width, height = args[first], args[first + 1], args[first + 2]
  if image and type(path) == "string" and path:find("^images/gui/background/") and width == DESIGN_WIDTH then
    if height == DESIGN_HEIGHT then
      local scale = adaptiveUI.coverScale()
      image.xScale, image.yScale = scale, scale
    else
      image.xScale = display.actualContentWidth / DESIGN_WIDTH
    end
  end
  return image
end

return adaptiveUI
