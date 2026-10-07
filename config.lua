-- screen setup. 320 units high, as wide as the screen (at least 3:2), 60 fps.

local DESIGN_HEIGHT = 320
local MIN_ASPECT = 3 / 2

local longSide = math.max(display.pixelWidth, display.pixelHeight)
local shortSide = math.min(display.pixelWidth, display.pixelHeight)
local aspect = math.max(longSide / shortSide, MIN_ASPECT)

application = {
  content = {
    width = DESIGN_HEIGHT,
    height = math.floor(DESIGN_HEIGHT * aspect + 0.5),
    scale = "letterbox",
    xAlign = "center",
    yAlign = "center",
    fps = 60,
    audioPlayFrequency = 22050,
  },
}
