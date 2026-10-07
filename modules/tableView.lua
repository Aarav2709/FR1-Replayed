-- vertical list.

local M = {}

local screenHeight = display.contentHeight
local marginX = display.contentWidth - display.viewableContentWidth

local activeList
local velocity = 0
local defaultImage, overImage
local highlightStart = 0
local lastScrollTime, lastTrackTime = 0, 0
local previousY
local startY, lastY
local delta = 0
local currentY = -10
local scrolled = false

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
  if elapsed == 0 then
    elapsed = 10
  end
  lastTrackTime = lastTrackTime + elapsed
  if previousY then
    velocity = (activeList.y - previousY) / elapsed
  end
  previousY = activeList.y
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
  if math.abs(velocity) < 0.01 then
    velocity = 0
    Runtime:removeEventListener("enterFrame", scrollList)
  end
  velocity = velocity * FRICTION
  activeList.y = math.floor(activeList.y + velocity * elapsed)
  local upperLimit = activeList.top
  local lowerLimit = screenHeight - activeList.height - activeList.bottom
  currentY = activeList.y
  if activeList.y > upperLimit then
    velocity = 0
    Runtime:removeEventListener("enterFrame", scrollList)
    activeList.tween = transition.to(activeList, { time = 400, y = upperLimit, transition = easing.outQuad })
    currentY = upperLimit
  elseif activeList.y < lowerLimit and lowerLimit < 0 then
    velocity = 0
    Runtime:removeEventListener("enterFrame", scrollList)
    activeList.tween = transition.to(activeList, { time = 400, y = lowerLimit, transition = easing.outQuad })
    currentY = lowerLimit
  elseif activeList.y < lowerLimit then
    velocity = 0
    Runtime:removeEventListener("enterFrame", scrollList)
    activeList.tween = transition.to(activeList, { time = 400, y = upperLimit, transition = easing.outQuad })
    currentY = upperLimit
  end
  scrolled = true
  return true
end
M.scrollList = scrollList

local function newListItemHandler(self, event)
  local list = activeList
  local phase = event.phase
  local default, over = self.default, self.over
  local upperLimit = self.top
  local lowerLimit = screenHeight - activeList.height - self.bottom
  local result = true

  if phase == "began" then
    if event.y > 50 then
      display.getCurrentStage():setFocus(self)
      self.isFocus = true
      startY = event.y
      lastY = event.y
      velocity = 0
      delta = 0
      if activeList.tween then
        transition.cancel(activeList.tween)
      end
      Runtime:removeEventListener("enterFrame", scrollList)
      Runtime:removeEventListener("enterFrame", trackVelocity)
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
      delta = event.y - lastY
      lastY = event.y
      if list.y > upperLimit or list.y < lowerLimit then
        list.y = list.y + delta / 2
      else
        list.y = list.y + delta
      end
    elseif phase == "ended" or phase == "cancelled" then
      lastScrollTime = event.time
      local moved = event.y - startY
      Runtime:removeEventListener("enterFrame", trackVelocity)
      Runtime:addEventListener("enterFrame", scrollList)
      if event.x >= self.stageBounds.xMin and moved < 10 and moved > -10 then
        velocity = 0
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
  local width, height = params.width, params.height
  local item = display.newGroup()
  if params.default then
    local default = display.newImageRect(params.default, width, height)
    item:insert(default)
    default.x = default.width * 0.5 - marginX
    default.y = 25
    item.default = default
  end
  if params.over then
    local over = display.newImageRect(params.over, width, height)
    over.isVisible = false
    item:insert(over)
    over.x = over.width * 0.5 - marginX
    item.over = over
  end
  item.id = params.id
  item.data = params.data
  item.onRelease = params.onRelease
  item.top = params.top
  item.bottom = params.bottom
  local content = params.callback(params.data)
  item.t = content
  item:insert(content)
  item.touch = newListItemHandler
  item:addEventListener("touch", item)
  return item
end
M.newListItem = newListItem

function M.newList(params)
  local data = params.data
  local top = params.top or 20
  local bottom = params.bottom or 48
  local callback = params.callback or function() return {} end
  local cells = {}
  local list = display.newGroup()
  local lastCellY, lastCellHeight = 0, 0

  local function addCell(index, event)
    if data[index] == nil then
      if event then
        timer.cancel(event.source)
      end
      return
    end
    local cell = newListItem({
      data = data[index], default = params.default, over = params.over, onRelease = params.onRelease,
      top = top, bottom = bottom, callback = callback, id = index,
      height = params.height, width = params.width,
    })
    list:insert(1, cell)
    cell.x = marginX * 0.5
    cell.y = lastCellY + lastCellHeight
    lastCellY = cell.y
    lastCellHeight = cell.height
    cells[index] = cell
  end

  local FIRST_CELLS = 15
  local firstCount = math.min(FIRST_CELLS, #data)
  local remaining = #data - firstCount
  for i = 1, firstCount do
    addCell(i)
  end
  local nextIndex = firstCount + 1
  local addTimer
  if remaining > 0 then
    addTimer = timer.performWithDelay(50, function(event)
      addCell(nextIndex, event)
      nextIndex = nextIndex + 1
    end, remaining)
  end

  list.y = top
  list.top = top
  list.bottom = bottom
  list.c = {}
  activeList = list
  M.deleteingCell = false
  local deleteQueue = {}
  local onDeleted

  function list.getCells()
    return cells
  end

  function list:removeItem(id)
    if M.deleteingCell then
      deleteQueue[#deleteQueue + 1] = id
    elseif cells then
      M.deleteingCell = true
      local index
      for i = 1, #cells do
        if cells[i] and cells[i].id == id then
          index = i
          break
        end
      end
      if index then
        display.remove(table.remove(cells, index))
        for i = index, #cells do
          if cells[i] then
            cells[i].y = cells[i].y - cells[i].height
          end
        end
      end
      timer.performWithDelay(200, onDeleted, 1)
    end
  end

  function onDeleted()
    M.deleteingCell = false
    if #deleteQueue > 0 then
      list:removeItem(table.remove(deleteQueue, 1))
    end
  end

  function list:cleanUp()
    Runtime:removeEventListener("enterFrame", scrollList)
    Runtime:removeEventListener("enterFrame", showHighlight)
    Runtime:removeEventListener("enterFrame", trackVelocity)
    if addTimer then
      timer.cancel(addTimer)
      addTimer = nil
    end
    cells = nil
    for i = list.numChildren, 1, -1 do
      list:remove(i)
    end
    currentY = -10
  end

  function list:scrollTo(y, time)
    velocity = 0
    Runtime:removeEventListener("enterFrame", scrollList)
    self.tween = transition.to(self, { time = time or 400, y = y or 0 })
  end

  function list:getY()
    return currentY
  end

  function list:hasScrolled()
    if scrolled then
      scrolled = false
      return true
    end
    return false
  end

  return list
end

return M
