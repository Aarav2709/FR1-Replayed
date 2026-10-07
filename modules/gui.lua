-- image buttons.

local storyboard = require("modules.storyboard")

local gui = {}

local function playButtonSound()
  if storyboard.database.getSound() == 1 then
    audio.play(storyboard.gameDataTable.sounds.buttonSound)
  end
end

local function onButtonTouch(button, event)
  local result = true
  local image = button.getButton()
  local over = button.getOver()
  local buttonEvent = { id = button._id }
  local phase = event.phase

  if phase == "began" then
    if over then
      image.isVisible = false
      over.isVisible = true
    else
      image:setFillColor(0.5)
    end
    playButtonSound()
    if button._onEvent then
      buttonEvent.phase = "press"
      result = button._onEvent(buttonEvent)
    elseif button._onPress then
      result = button._onPress(event)
    end
    display.getCurrentStage():setFocus(button, event.id)
    button.isFocus = true

  elseif button.isFocus then
    local bounds = button.contentBounds
    local x, y = event.x, event.y
    local isWithinBounds = bounds.xMin <= x and bounds.xMax >= x and bounds.yMin <= y and bounds.yMax >= y

    if phase == "moved" then
      if over then
        image.isVisible = not isWithinBounds
        over.isVisible = isWithinBounds
      elseif not isWithinBounds then
        image:setFillColor(1)
      end
    elseif phase == "ended" or phase == "cancelled" then
      if over then
        image.isVisible = true
        over.isVisible = false
      else
        image:setFillColor(1)
      end
      if phase == "ended" and isWithinBounds then
        if button._onEvent then
          buttonEvent.phase = "release"
          result = button._onEvent(buttonEvent)
        elseif button._onRelease then
          result = button._onRelease(event)
        end
      end
      display.getCurrentStage():setFocus(button, nil)
      button.isFocus = false
    end
  end
  return result
end

local function newLabel(text, font, size, embossColor)
  if embossColor then
    local label = display.newEmbossedText(text, 0, 0, font, size)
    label:setEmbossColor(embossColor)
    return label
  end
  return display.newText(text, 0, 0, font, size)
end

function gui.newButton(params)
  local font = storyboard.gameDataTable.font
  local button = display.newImageRect(params.image, params.width, params.height)
  button.x = params.x
  button.y = params.y
  params.displayGroup:insert(button)

  local over
  if params.over then
    over = display.newImageRect(params.over, params.width, params.height)
    over.isVisible = false
    over.x = params.x
    over.y = params.y
    params.displayGroup:insert(over)
  end

  local label
  if params.text then
    local text, text2 = "", nil
    local size = storyboard.localized.getFontSize()
    local offsetX, offsetY = 0, 0
    local color = { 0.0784313725490196, 0.0784313725490196, 0.0784313725490196 }
    local embossColor
    if type(params.text) == "string" then
      text = params.text
    elseif type(params.text) == "table" then
      local t = params.text
      text = t.string or text
      text2 = t.string2
      size = t.size or size
      if t.languageSizes and t.languageSizes[storyboard.localized.language] then
        size = t.languageSizes[storyboard.localized.language]
      end
      offsetX = t.x or offsetX
      offsetY = t.y or offsetY
      color = t.color or color
      embossColor = t.embossColor
    end

    label = newLabel(text, font, size, embossColor)
    label.x = params.x + offsetX
    label.y = params.y + offsetY
    label:setFillColor(color[1], color[2], color[3])
    button.text = label
    params.displayGroup:insert(label)

    if text2 then
      label.y = label.y - 7
      local label2 = newLabel(text2, font, size, embossColor)
      label2.x = label.x
      label2.y = label.y + 15
      label2:setFillColor(color[1], color[2], color[3])
      label.text2 = label2
      params.displayGroup:insert(label2)
    end
  end

  function button.getText()
    return label
  end

  function button.getButton()
    return button
  end

  function button.getOver()
    return over
  end

  function button.setPosition(x, y)
    button.x, button.y = x, y
    if over then
      over.x, over.y = x, y
    end
    if button.text then
      button.text.x, button.text.y = x, y
    end
  end

  function button.updateDisplay(group)
    group:insert(button)
    if over then
      group:insert(over)
    end
    if button.text then
      group:insert(button.text)
    end
  end

  function button.showButton(visible)
    button.isVisible = visible
    if button.text then
      button.text.isVisible = visible
      if button.text.text2 then
        button.text.text2.isVisible = visible
      end
    end
  end

  if type(params.onPress) == "function" then
    button._onPress = params.onPress
  end
  if type(params.onRelease) == "function" then
    button._onRelease = params.onRelease
  end
  if type(params.onEvent) == "function" then
    button._onEvent = params.onEvent
  end

  function button.addListener()
    if button then
      button.touch = onButtonTouch
      button:addEventListener("touch", button)
    end
  end

  function button.removeListener()
    button:removeEventListener("touch", button)
  end

  return button
end

return gui
