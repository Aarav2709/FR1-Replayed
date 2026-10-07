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
