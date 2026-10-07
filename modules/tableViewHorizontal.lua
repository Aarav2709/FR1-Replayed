-- horizontal list.

local M = {}

local LIST_WIDTH = 330
local CENTER_X = 250
local screenHeight = display.contentHeight
local marginX = display.contentWidth - display.viewableContentWidth

local activeList
local velocity = 0
local defaultImage, overImage
local onScrollEnd
local startX, lastX
local delta = 0
local highlightStart = 0
local lastScrollTime, lastTrackTime = 0, 0
local previousX
local lastIndex

local function showHighlight()
  if system.getTimer() - highlightStart > 100 then
    defaultImage.isVisible = false
    overImage.isVisible = true
    Runtime:removeEventListener("enterFrame", showHighlight)
  end
end
M.showHighlight = showHighlight

local function trackVelocity(event)
  local elapsed = event.time - lastTrackTime
  lastTrackTime = lastTrackTime + elapsed
  if previousX then
    velocity = (activeList.x - previousX) / elapsed
  end
  previousX = activeList.x
end
M.trackVelocity = trackVelocity

function M.in_table(value, list)
  for _, entry in pairs(list) do
    if entry == value then
      return true
    end
  end
  return false
end

local function scrollList(event)
  local FRICTION = 0.9
  local elapsed = event.time - lastScrollTime
  lastScrollTime = lastScrollTime + elapsed
  if math.abs(velocity) < 0.05 then
    velocity = 0
    Runtime:removeEventListener("enterFrame", scrollList)
  end
  velocity = velocity * FRICTION
  activeList.x = math.floor(activeList.x + velocity * elapsed)
  local leftLimit = activeList.left
  local rightLimit = LIST_WIDTH - activeList.width - activeList.right
  if activeList.x > leftLimit then
    velocity = 0
    onScrollEnd(1)
    Runtime:removeEventListener("enterFrame", scrollList)
    activeList.tween = transition.to(activeList, { time = 400, x = leftLimit, transition = easing.outQuad })
  elseif activeList.x < rightLimit then
    velocity = 0
    onScrollEnd(lastIndex)
    Runtime:removeEventListener("enterFrame", scrollList)
    activeList.tween = transition.to(activeList, { time = 400, x = rightLimit, transition = easing.outQuad })
  elseif velocity == 0 then
    local position = math.round(math.abs((CENTER_X - activeList.x) / activeList[1].width))
    onScrollEnd(position + 1)
    Runtime:removeEventListener("enterFrame", scrollList)
    activeList.tween = transition.to(activeList, {
      time = 200, x = CENTER_X - activeList[1].width * position, transition = easing.outQuad,
    })
  end
  return true
end
M.scrollList = scrollList

local function newListItemHandler(self, event)
  local list = activeList
  local phase = event.phase
  local default, over = self.default, self.over
  local leftLimit = self.left
  local rightLimit = LIST_WIDTH - activeList.width - self.right
  local result = true

  if phase == "began" then
    if event.x > 100 then
      display.getCurrentStage():setFocus(self)
      self.isFocus = true
      startX = event.x
      lastX = event.x
      velocity = 0
      delta = 0
      if activeList.tween then
        transition.cancel(activeList.tween)
      end
      Runtime:removeEventListener("enterFrame", scrollList)
      Runtime:addEventListener("enterFrame", trackVelocity)
      if over then
        defaultImage = default
        overImage = over
        highlightStart = system.getTimer()
        Runtime:addEventListener("enterFrame", showHighlight)
      end
    end
  elseif self.isFocus then
    if phase == "moved" then
      Runtime:removeEventListener("enterFrame", showHighlight)
      if over then
        default.isVisible = true
        over.isVisible = false
      end
      delta = event.x - lastX
      lastX = event.x
      if list.x > leftLimit or list.x < rightLimit then
        list.x = list.x + delta / 2
      else
        list.x = list.x + delta
      end
    elseif phase == "ended" or phase == "cancelled" then
      lastScrollTime = event.time
      local moved = event.x - startX
      Runtime:removeEventListener("enterFrame", trackVelocity)
      Runtime:addEventListener("enterFrame", scrollList)
      if event.x >= self.stageBounds.xMin and moved < 10 and moved > -10 then

        onScrollEnd(self.data.index)
        velocity = 0
        Runtime:removeEventListener("enterFrame", scrollList)
        activeList.tween = transition.to(activeList, {
          time = 400, x = CENTER_X - self.width * (self.data.tableIndex - 1), transition = easing.outQuad,
        })
        result = self.onRelease(event)
      end
      display.getCurrentStage():setFocus(nil)
      self.isFocus = false
      if over then
        default.isVisible = true
        over.isVisible = false
        Runtime:removeEventListener("enterFrame", showHighlight)
      end
    end
  end
  return result
end
M.newListItemHandler = newListItemHandler

local function newListItem(params)
  local data = params.data
  local width, height = params.width, params.height
  local item = display.newGroup()

  local hitArea = display.newRect(0, -height, width, height * 2)
  hitArea.anchorX, hitArea.anchorY = 0, 0
  hitArea:setFillColor(1, 1, 1, 0)
  hitArea.isHitTestable = true
  item:insert(hitArea)
  local default
  if params.default then
    default = display.newImageRect(params.default, width * 0.8, height * 0.8)
    item:insert(default)
    default.x = width * 0.5
    default.y = 34
    if not data.bought then
      default:setFillColor(0, 0, 0)
    end
    item.default = default
  end
  if params.over then
    local over = display.newImageRect(params.over, width, height)
    over.isVisible = false
    item:insert(over)
    over.x = over.width * 0.5 - marginX
    item.over = over
  end
  if data.newItem and not data.bought then
    local newIcon = display.newImageRect("images/gui/market/newIcon.png", 18, 18)
    item:insert(newIcon)
    newIcon.x = default.x + 10
    newIcon.y = default.y - 10
  end
  item.id = params.id
  item.data = data
  item.onRelease = params.onRelease
  item.left = params.left
  item.right = params.right
  if data.price then
    item:insert(params.callback(data))
  end
  item.touch = newListItemHandler
  item:addEventListener("touch", item)
  return item
end
M.newListItem = newListItem

function M.newList(params)
  local FONT_SIZE = 16
  local data = params.data
  local left = params.left or 20
  local right = params.right or 48
  local categoryKey = params.cat
  local order = params.order or {}
  local callback = params.callback or function(text)
    local label = display.newText(text, 0, 0, native.systemFontBold, FONT_SIZE)
    label:setFillColor(1, 1, 1)
    label.x = math.floor(label.width / 2) + 20
    label.y = 24
    return label
  end
  local list = display.newGroup()
  local lastX, lastWidth = 0, 0
  local headers = {}
  local HEADER_MARGIN = 12

  local categoryIndex = 1
  repeat
    local category = order[categoryIndex]
    if category then

      local header = display.newGroup()
      local background
      if params.categoryBackground then
        background = display.newImage(params.categoryBackground, true)
      else
        background = display.newRect(0, 0, LIST_WIDTH, FONT_SIZE * 1.5)
        background:setFillColor(0, 0, 0, 0.39215686274509803)
      end
      header:insert(background)
      local shadow = display.newText(category, 0, 0, native.systemFontBold, FONT_SIZE)
      shadow:setFillColor(0, 0, 0, 0.5019607843137255)
      header:insert(shadow, true)
      shadow.x = shadow.width * 0.5 + 1 + HEADER_MARGIN + marginX * 0.5
      shadow.y = FONT_SIZE * 0.8 + 1
      local title = display.newText(category, 0, 0, native.systemFontBold, FONT_SIZE)
      title:setFillColor(1, 1, 1)
      header:insert(title)
      title.x = title.width * 0.5 + HEADER_MARGIN + marginX * 0.5
      title.y = FONT_SIZE * 0.8
      list:insert(header)
      header.x = 0
      header.y = lastX + lastWidth
      lastX = header.y
      lastWidth = header.height
      headers[#headers + 1] = header
      header.yInit = header.y
    end
    for i = 1, #data do
      if data[i] and data[i][categoryKey] == category then
        local item = newListItem({
          data = data[i], default = data[i].image, over = params.over, onRelease = params.onRelease,
          left = left, right = right, callback = callback, id = i,
          height = params.height, width = params.width,
        })
        list:insert(1, item)
        item.x = lastX + lastWidth
        item.y = marginX * 0.5
        lastX = item.x
        lastWidth = item.width
      end
    end
    categoryIndex = categoryIndex + 1
  until not order[categoryIndex]

  list.y = 0
  list.left = left
  list.right = right
  list.c = headers
  activeList = list
  lastIndex = data[#data].index
  onScrollEnd = params.onScrollEnd or function(index)
  end

  function list:cleanUp()
    Runtime:removeEventListener("enterFrame", scrollList)
    Runtime:removeEventListener("enterFrame", showHighlight)
    Runtime:removeEventListener("enterFrame", trackVelocity)
    for i = list.numChildren, 1, -1 do
      list:remove(i)
    end
  end

  function list:scrollTo(index)
    velocity = 0
    Runtime:removeEventListener("enterFrame", scrollList)
    self.tween = transition.to(self, {
      time = 400, x = CENTER_X - self[1].width * (index - 1), transition = easing.outQuad,
    })
  end

  function list:startAt(index)
    self.x = CENTER_X - self[1].width * (index - 1)
  end

  return list
end

return M
