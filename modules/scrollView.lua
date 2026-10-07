-- scroll view.

local M = {}

local screenHeight = display.contentHeight
local viewableWidth = display.viewableContentWidth

function M.new(params)
  local view = display.newGroup()
  view.top = params.top or 0
  view.bottom = params.bottom or 0

  function view.changeBottom(_, bottom)
    view.bottom = bottom
  end

  local function trackVelocity(event)
    local elapsed = event.time - view.prevTime
    view.prevTime = view.prevTime + elapsed
    if view.prevY then
      view.velocity = (view.y - view.prevY) / elapsed
    end
    view.prevY = view.y
  end

  local function fadeScrollBar(alpha, time)
    if view.scrollBar then
      transition.to(view.scrollBar, { time = time, alpha = alpha })
    end
  end

  function view:touch(event)
    local phase = event.phase
    if phase == "began" then
      self.startPos = event.y
      self.prevPos = event.y
      self.velocity = 0
      self.delta = 0
      if self.tween then
        transition.cancel(self.tween)
      end
      Runtime:removeEventListener("enterFrame", view)
      self.prevTime = 0
      self.prevY = 0
      fadeScrollBar(1, 200)
      Runtime:addEventListener("enterFrame", trackVelocity)
      display.getCurrentStage():setFocus(self)
      self.isFocus = true
    elseif self.isFocus then
      if phase == "moved" then
        local lowerLimit = screenHeight - self.height - self.bottom
        self.delta = event.y - self.prevPos
        self.prevPos = event.y
        if self.y > self.top or self.y < lowerLimit then
          self.y = self.y + self.delta / 2
        else
          self.y = self.y + self.delta
        end
        view:moveScrollBar()
      elseif phase == "ended" or phase == "cancelled" then
        self.lastTime = event.time
        Runtime:addEventListener("enterFrame", view)
        Runtime:removeEventListener("enterFrame", trackVelocity)
        display.getCurrentStage():setFocus(nil)
        self.isFocus = false
      end
    end
    return true
  end

  function view:enterFrame(event)
    local FRICTION = 0.9
    local elapsed = event.time - self.lastTime
    self.lastTime = self.lastTime + elapsed
    if math.abs(self.velocity) < 0.01 then
      self.velocity = 0
      Runtime:removeEventListener("enterFrame", view)
      fadeScrollBar(0, 400)
    end
    self.velocity = self.velocity * FRICTION
    self.y = math.floor(self.y + self.velocity * elapsed)
    local upperLimit = self.top
    local last = self[self.numChildren]
    local lowerLimit = screenHeight - (last.y + last.height * 2) - self.bottom
    if self.y > upperLimit then
      self.velocity = 0
      Runtime:removeEventListener("enterFrame", view)
      self.tween = transition.to(self, { time = 400, y = upperLimit, transition = easing.outQuad })
      fadeScrollBar(0, 400)
    elseif self.y < lowerLimit and lowerLimit < 0 then
      self.velocity = 0
      Runtime:removeEventListener("enterFrame", view)
      self.tween = transition.to(self, { time = 400, y = lowerLimit, transition = easing.outQuad })
      fadeScrollBar(0, 400)
    elseif self.y < lowerLimit then
      self.velocity = 0
      Runtime:removeEventListener("enterFrame", view)
      self.tween = transition.to(self, { time = 400, y = upperLimit, transition = easing.outQuad })
      fadeScrollBar(0, 400)
    end
    view:moveScrollBar()
    return true
  end

  function view:moveScrollBar()
    local bar = self.scrollBar
    if bar then
      bar.y = -self.y * self.yRatio + bar.height * 0.5 + self.top
      if bar.y < 5 + self.top + bar.height * 0.5 then
        bar.y = 5 + self.top + bar.height * 0.5
      end
      if bar.y > screenHeight - self.bottom - 5 - bar.height * 0.5 then
        bar.y = screenHeight - self.bottom - 5 - bar.height * 0.5
      end
    end
  end

  view.y = view.top
  view.isHitTestable = true
  view:addEventListener("touch", view)

  function view:addScrollBar(r, g, b, a)
    if self.scrollBar then
      display.remove(self.scrollBar)
    end
    local visibleHeight = screenHeight - self.top - self.bottom
    local barHeight = visibleHeight * self.height / (self.height * 2 - visibleHeight)
    local bar = display.newRoundedRect(viewableWidth - 8, 0, 5, barHeight, 2)
    bar:setFillColor(r or 0, g or 0, b or 0, a or 0.47058823529411764)
    self.yRatio = barHeight / self.height
    bar.y = bar.height * 0.5 + self.top
    self.scrollBar = bar
    transition.to(bar, { time = 400, alpha = 0 })
  end

  function view:removeScrollBar()
    if self.scrollBar then
      display.remove(self.scrollBar)
      self.scrollBar = nil
    end
  end

  function view:cleanUp()
    Runtime:removeEventListener("enterFrame", trackVelocity)
    Runtime:removeEventListener("enterFrame", view)
    view:removeScrollBar()
  end

  return view
end

return M
