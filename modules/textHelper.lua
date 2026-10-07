-- text fitting.

local storyboard = require("modules.storyboard")

local function font()
  return storyboard.gameDataTable.font
end

local function measure(options)
  local text = display.newText(options)
  local width = text.contentWidth
  display.remove(text)
  return width
end

function storyboard.fitText(text, size, maxWidth)
  if not text then
    return nil
  end
  local options = { text = text, fontSize = size, font = font() }
  local shortened = false
  while measure(options) > maxWidth do
    shortened = true
    text = text:sub(1, text:len() - 1)
    options.text = text .. ".."
  end
  if shortened then
    text = text .. ".."
  end
  return text
end

function storyboard.fitTextFontSize(text, minSize, maxSize, maxWidth)
  if not text then
    return maxSize
  end
  local options = { text = text, fontSize = maxSize, font = font() }
  while measure(options) > maxWidth and options.fontSize >= minSize do
    options.fontSize = options.fontSize - 0.5
  end
  return options.fontSize
end

function storyboard.formatPlacementNumber(n)
  local lastTwo = n % 100
  if lastTwo > 10 and lastTwo < 21 then
    return n .. "th"
  end
  local last = n % 10
  if last == 1 then
    return n .. "st"
  elseif last == 2 then
    return n .. "nd"
  elseif last == 3 then
    return n .. "rd"
  end
  return n .. "th"
end

function storyboard.formatTextKilo(value, limit)
  local function format(text, number)
    if number then
      limit = limit or 100000
      if number >= limit then
        return math.floor(number / 1000) .. "K"
      end
    end
    return text
  end
  if type(value) == "table" then
    value.text = format(value.text, tonumber(value.text))
  else
    return format(value, tonumber(value))
  end
end

local DARK = { 0.0784313725490196, 0.0784313725490196, 0.0784313725490196, 1 }

local function newGameText(options)
  local text = options.string
  if text == nil then
    text = ""
  end
  local color = options.color
  if color == nil then
    color = { 0, 0, 0, 1 }
    options.noFade = true
  end
  if #color == 3 then
    color[4] = 1
  end
  local white = true
  for i = 1, #color do
    if color[i] ~= 1 then
      white = false
    end
  end
  local textOptions = {
    text = string.upper(text),
    width = options.width or 0,
    height = options.height or 0,
    fontSize = options.size or storyboard.localized.getFontSize(),
    font = font(),
    align = options.align,
  }
  local object = white and display.newEmbossedText(textOptions) or display.newText(textOptions)
  object:setFillColor(color[1], color[2], color[3], color[4])
  object.x = options.x or 0
  object.y = options.y or 0
  if options.ax then
    object.anchorX = options.ax
  end
  if options.ay then
    object.anchorY = options.ay
  end

  function object.fadeColor()
    if not options.noFade then
      object:setFillColor(0.5)
    end
  end

  function object.returnToNormalColor()
    object:setFillColor(color[1], color[2], color[3], color[4])
  end

  return object
end

local function newDarkText(text, x, y)
  return newGameText({
    string = text,
    size = storyboard.localized.getFontSize(),
    color = { DARK[1], DARK[2], DARK[3], DARK[4] },
    x = x or 0,
    y = y or 0,
    noFade = true,
  })
end

function storyboard.newText(options)
  if type(options) == "table" then
    return newGameText(options)
  end
  return newDarkText(options)
end

function storyboard.newButtonText(options, x, y)
  if type(options) == "table" then
    if options.x and options.y then
      options.x = options.x + x
      options.y = options.y + y
    elseif not options.x then
      options.x = x
      options.y = y
    end
    return newGameText(options)
  end
  return newDarkText(options, x, y)
end

return storyboard
