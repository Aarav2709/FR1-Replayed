-- keyboard and mouse menus for pc. arrows move, enter presses, the mouse hovers and the wheel scrolls lists.

local storyboard = require("modules.storyboard")
local gui = require("modules.gui")
local pcMode = require("modules.pcMode")
local pcSettings = require("modules.pcSettings")

local M = {}

local CATCHER_SHARE = 0.55
local PANEL_SHARE = 0.12
local FOCUS_GROW = 1.08
local WHEEL_SPEED = 0.6
local STRIP_UNITS = 50
local SKIPPED_SCENES = { ["scenes.gamePlay"] = true, ["scenes.loadingScene"] = true }
local NO_POP = { ["scenes.ranking"] = true, ["scenes.earnCoins"] = true }
local DIRECTIONS = { up = { 0, -1 }, down = { 0, 1 }, left = { -1, 0 }, right = { 1, 0 } }

local buttons = setmetatable({}, { __mode = "k" })
local focused, shown, shownRestore
local stripAccumulator, stripTarget, stripTime = 0, nil, 0
local hovered, mouseX, mouseY
local lastHoverCheck = 0
local cursor = "arrow"
local started = false

local function isAlive(object)
  return object ~= nil and object.parent ~= nil and object.removeSelf ~= nil
end

local function hasListener(object, name)
  local functions = rawget(object, "_functionListeners")
  local tables = rawget(object, "_tableListeners")
  return (functions and functions[name] and #functions[name] > 0) or (tables and tables[name] and #tables[name] > 0)
end

local function isTouchable(object)
  return hasListener(object, "touch") or hasListener(object, "tap")
end

local function boundsOf(object)
  local bounds = object.contentBounds
  if not bounds then
    return nil
  end
  local width, height = bounds.xMax - bounds.xMin, bounds.yMax - bounds.yMin
  if width < 4 or height < 4 then
    return nil
  end
  return bounds, width, height
end

local function screenArea()
  return display.actualContentWidth * display.actualContentHeight
end

local function onScreen(bounds)
  return bounds.xMax > display.screenOriginX and bounds.xMin < display.screenOriginX + display.actualContentWidth
    and bounds.yMax > display.screenOriginY and bounds.yMin < display.screenOriginY + display.actualContentHeight
end

local function isListCell(object)
  local parent = object.parent
  return parent ~= nil and (parent.getCells ~= nil or parent.startAt ~= nil)
end

local function skipped()
  return SKIPPED_SCENES[storyboard.getCurrentSceneName() or ""] and not storyboard.getOverlay()
    and not storyboard.raceMenuOpen
end

local function popAllowed()
  return storyboard.getOverlay() ~= nil or not NO_POP[storyboard.getCurrentSceneName() or ""]
end

local function rootView()
  local overlay = storyboard.getOverlay()
  if overlay and overlay.view then
    return overlay.view
  end
  local scene = storyboard.getScene(storyboard.getCurrentSceneName() or "")
  return scene and scene.view or display.getCurrentStage()
end

-- every pressable object on screen, in drawing order. a full screen touch catcher hides what is under it.
local function collect()
  local area = screenArea()
  local found, catcher = {}, nil
  local function walk(object)
    if not object.isVisible or ((object.alpha or 1) <= 0 and not object.isHitTestable) then
      return
    end
    if isTouchable(object) and not object.navIgnore then
      local bounds, width, height = boundsOf(object)
      if bounds and onScreen(bounds) then
        if width * height >= area * CATCHER_SHARE then
          found, catcher = {}, object
        elseif buttons[object] or isListCell(object) or object.numChildren
            or width * height < area * PANEL_SHARE then
          found[#found + 1] = object
        end
      end
    end
    if object.numChildren and not buttons[object] then
      for i = 1, object.numChildren do
        if object[i] then
          walk(object[i])
        end
      end
    end
  end
  walk(rootView())
  return found, catcher
end

local function centerOf(object)
  local bounds = object.contentBounds
  return (bounds.xMin + bounds.xMax) * 0.5, (bounds.yMin + bounds.yMax) * 0.5
end

local function partsOf(object)
  local parts = { object }
  if buttons[object] then
    local over = object.getOver and object.getOver()
    if over then
      parts[#parts + 1] = over
    end
    if object.text then
      parts[#parts + 1] = object.text
      if object.text.text2 then
        parts[#parts + 1] = object.text.text2
      end
    end
  end
  return parts
end

local function setCursor(name)
  if name ~= cursor then
    cursor = name
    pcall(native.setProperty, "mouseCursor", name)
  end
end

local function unpop()
  local object, restore = shown, shownRestore
  shown, shownRestore = nil, nil
  if not isAlive(object) then
    return
  end
  if object.navCustomFocus then
    object.navCustomFocus(false)
    return
  end
  for _, entry in ipairs(restore or {}) do
    local part = entry.part
    if isAlive(part) and math.abs(part.xScale - entry.poppedX) < 1e-6 then
      part.xScale, part.yScale, part.x, part.y = entry.xScale, entry.yScale, entry.x, entry.y
    end
  end
end

-- grow the focused object a little around its own center, whatever its anchor.
local function pop(object)
  shown = object
  if object.navCustomFocus then
    object.navCustomFocus(true)
    return
  end
  local bounds = object.contentBounds
  local centerX, centerY = (bounds.xMin + bounds.xMax) * 0.5, (bounds.yMin + bounds.yMax) * 0.5
  local restore = {}
  for _, part in ipairs(partsOf(object)) do
    if part.parent and part.xScale ~= 0 and part.yScale ~= 0 then
      local entry = { part = part, xScale = part.xScale, yScale = part.yScale, x = part.x, y = part.y }
      local localX, localY = part.parent:contentToLocal(centerX, centerY)
      part.xScale, part.yScale = part.xScale * FOCUS_GROW, part.yScale * FOCUS_GROW
      part.x = localX + (part.x - localX) * FOCUS_GROW
      part.y = localY + (part.y - localY) * FOCUS_GROW
      entry.poppedX = part.xScale
      restore[#restore + 1] = entry
    end
  end
  shownRestore = restore
end

local function isFocusable(object)
  return isAlive(object) and object.isVisible and not object.navIgnore
end

local function updateHighlight()
  local current = isFocusable(focused) and not skipped() and popAllowed() and focused or nil
  if current ~= shown then
    unpop()
    if current then
      pop(current)
    end
  end
end

-- scroll a vertical list so the focused cell is fully on screen.
local function reveal(object)
  local list = object.parent
  if not (list and list.getCells and list.top) then
    return
  end
  local bounds = object.contentBounds
  local top, bottom = list.top, display.contentHeight - (list.bottom or 0)
  local shift = 0
  if bounds.yMin < top then
    shift = top - bounds.yMin
  elseif bounds.yMax > bottom then
    shift = bottom - bounds.yMax
  end
  if shift ~= 0 then
    if list.tween then
      transition.cancel(list.tween)
    end
    list.y = list.y + shift
  end
end

local function move(dx, dy)
  local candidates = collect()
  if #candidates == 0 then
    focused = nil
    return
  end
  local stillThere = false
  for _, object in ipairs(candidates) do
    if object == focused then
      stillThere = true
    end
  end
  if not stillThere then
    local midX, midY = display.contentCenterX, display.contentCenterY
    local best, bestDistance
    for _, object in ipairs(candidates) do
      local x, y = centerOf(object)
      local distance = (x - midX) ^ 2 + (y - midY) ^ 2
      if not bestDistance or distance < bestDistance then
        best, bestDistance = object, distance
      end
    end
    focused = best
    return
  end
  local fromX, fromY = centerOf(focused)
  local best, bestScore
  for _, object in ipairs(candidates) do
    if object ~= focused then
      local x, y = centerOf(object)
      local along = (x - fromX) * dx + (y - fromY) * dy
      if along > 2 then
        local across = math.abs((x - fromX) * dy) + math.abs((y - fromY) * dx)
        local score = along + across * 2
        if not bestScore or score < bestScore then
          best, bestScore = object, score
        end
      end
    end
  end
  if best then
    focused = best
    reveal(best)
  end
end

local function press(object)
  local x, y = centerOf(object)
  if hasListener(object, "tap") and not hasListener(object, "touch") then
    object:dispatchEvent({ name = "tap", numTaps = 1, target = object, x = x, y = y })
    return
  end
  local time = system.getTimer()
  local event = { name = "touch", phase = "began", target = object, x = x, y = y, xStart = x, yStart = y,
    id = "keyboard", time = time }
  object:dispatchEvent(event)
  if isAlive(object) then
    object:dispatchEvent({ name = "touch", phase = "ended", target = object, x = x, y = y, xStart = x, yStart = y,
      id = "keyboard", time = time })
  end
  display.getCurrentStage():setFocus(nil)
end

local function confirm()
  local candidates, catcher = collect()
  for _, object in ipairs(candidates) do
    if object == focused then
      press(object)
      return
    end
  end
  if #candidates == 0 and catcher then
    press(catcher)
  else
    move(0, 0)
  end
end

local function inside(bounds, x, y)
  return x >= bounds.xMin and x <= bounds.xMax and y >= bounds.yMin and y <= bounds.yMax
end

local function refreshHover()
  if not mouseX then
    return
  end
  local found
  if not skipped() and popAllowed() then
    local candidates = collect()
    for i = #candidates, 1, -1 do
      if inside(candidates[i].contentBounds, mouseX, mouseY) then
        found = candidates[i]
        break
      end
    end
  end
  if found then
    hovered, focused = found, found
    setCursor("pointingHand")
  elseif hovered then
    if focused == hovered then
      focused = nil
    end
    hovered = nil
    setCursor("arrow")
  end
end

-- the list under the mouse. lists keep their visible top and bottom margins.
local function listAt(x, y)
  local target
  local function walk(object)
    if not object.isVisible then
      return
    end
    if object.getCells and object.top and object.numChildren and object.numChildren > 0 then
      local bounds = object.contentBounds
      if bounds and x >= bounds.xMin and x <= bounds.xMax then
        target = object
      end
    end
    if object.numChildren then
      for i = 1, object.numChildren do
        if object[i] then
          walk(object[i])
        end
      end
    end
  end
  walk(rootView())
  return target
end

local function stripIn(object)
  if object.step and object.startAt then
    return object
  end
  if object.numChildren and object.isVisible then
    for i = 1, object.numChildren do
      local found = object[i] and stripIn(object[i])
      if found then
        return found
      end
    end
  end
end

local function stripScroll(strip, delta)
  local now = system.getTimer()
  if stripTarget ~= strip or now - stripTime > 600 then
    stripAccumulator = 0
  end
  stripTarget, stripTime = strip, now
  stripAccumulator = stripAccumulator + delta
  while math.abs(stripAccumulator) >= STRIP_UNITS do
    local direction = stripAccumulator > 0 and 1 or -1
    stripAccumulator = stripAccumulator - direction * STRIP_UNITS
    strip:step(direction)
  end
end

local function onWheel(event)
  local list = listAt(event.x, event.y)
  if not list then
    local strip = stripIn(rootView())
    if strip then
      local amount = (event.scrollX and event.scrollX ~= 0) and event.scrollX or (event.scrollY or 0)
      stripScroll(strip, amount)
    end
    return
  end
  if list.tween then
    transition.cancel(list.tween)
  end
  local upper = list.top
  local lower = math.min(upper, display.contentHeight - list.height - (list.bottom or 0))
  list.y = math.max(lower, math.min(upper, list.y - (event.scrollY or 0) * WHEEL_SPEED))
  refreshHover()
end

local function onMouse(event)
  if (event.scrollY and event.scrollY ~= 0) or (event.scrollX and event.scrollX ~= 0) then
    if not skipped() then
      onWheel(event)
    end
    return true
  end
  mouseX, mouseY = event.x, event.y
  local now = system.getTimer()
  if now - lastHoverCheck >= 50 then
    lastHoverCheck = now
    refreshHover()
  end
  return false
end

local function onKey(event)
  if event.phase ~= "down" then
    return false
  end
  local key = event.keyName
  if storyboard.capturingKey then
    local handler = storyboard.capturingKey
    storyboard.capturingKey = nil
    handler(key)
    return true
  end
  if key == "f11" and pcMode.isPC then
    pcSettings.toggleFullscreen()
    return true
  end
  if skipped() then
    return false
  end
  if storyboard.navHandler and not storyboard.getOverlay() and storyboard.navHandler(key, event) then
    return true
  end
  local direction = DIRECTIONS[key]
  if direction then
    if hovered then
      hovered = nil
      setCursor("arrow")
    end
    move(direction[1], direction[2])
    return true
  end
  if (key == "enter" or key == "numPadEnter") and not event.isRepeat then
    confirm()
    return true
  end
  return false
end

function M.getFocus()
  return isFocusable(focused) and focused or nil
end

function M.setFocus(object)
  focused = object
end

function M.start()
  if started then
    return
  end
  started = true
  local newButton = gui.newButton
  gui.newButton = function(params)
    local button = newButton(params)
    buttons[button] = true
    return button
  end
  Runtime:addEventListener("key", onKey)
  Runtime:addEventListener("enterFrame", updateHighlight)
  if pcMode.isPC then
    Runtime:addEventListener("mouse", onMouse)
  end
end

return M
