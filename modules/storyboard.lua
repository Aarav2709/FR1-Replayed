-- scene manager.

local storyboard = {}

local stage = display.newGroup()

local currentSceneName
local currentView
local previousSceneName
local overlayScene
local touchBlocker
local modalRect

storyboard.loadedSceneMods = {}
storyboard.scenes = {}
storyboard.stage = stage
storyboard.disableAutoPurge = false
storyboard.purgeOnSceneChange = false

local isGraphicsV1 = false
if system.getInfo("graphicsPipelineVersion") ~= "1.0" then
  isGraphicsV1 = display.getDefault("graphicsCompatibility") == 1
end

local W, H = display.contentWidth, display.contentHeight
local screenLeft, screenTop = display.screenOriginX, display.screenOriginY
local screenWidth = W - screenLeft * 2
local screenHeight = H - screenTop * 2

local slide = { transition = easing.outQuad }
local function slideEffect(fromX, fromY, toX, toY)
  return {
    from = { xStart = 0, yStart = 0, xEnd = fromX, yEnd = fromY, transition = slide.transition },
    to = { xStart = toX, yStart = toY, xEnd = 0, yEnd = 0, transition = slide.transition },
    concurrent = true,
    sceneAbove = true,
  }
end

local effectList = {
  fade = {
    from = { alphaStart = 1, alphaEnd = 0 },
    to = { alphaStart = 0, alphaEnd = 1 },
  },
  crossFade = {
    from = { alphaStart = 1, alphaEnd = 0 },
    to = { alphaStart = 0, alphaEnd = 1 },
    concurrent = true,
  },
  zoomOutIn = {
    from = { xEnd = W * 0.5, yEnd = H * 0.5, xScaleEnd = 0.001, yScaleEnd = 0.001 },
    to = { xScaleStart = 0.001, yScaleStart = 0.001, xScaleEnd = 1, yScaleEnd = 1,
           xStart = W * 0.5, yStart = H * 0.5, xEnd = 0, yEnd = 0 },
    hideOnOut = true,
  },
  zoomOutInFade = {
    from = { xEnd = W * 0.5, yEnd = H * 0.5, xScaleEnd = 0.001, yScaleEnd = 0.001, alphaStart = 1, alphaEnd = 0 },
    to = { xScaleStart = 0.001, yScaleStart = 0.001, xScaleEnd = 1, yScaleEnd = 1,
           xStart = W * 0.5, yStart = H * 0.5, xEnd = 0, yEnd = 0, alphaStart = 0, alphaEnd = 1 },
    hideOnOut = true,
  },
  zoomInOut = {
    from = { xEnd = -W * 0.5, yEnd = -H * 0.5, xScaleEnd = 2, yScaleEnd = 2 },
    to = { xScaleStart = 2, yScaleStart = 2, xScaleEnd = 1, yScaleEnd = 1,
           xStart = -W * 0.5, yStart = -H * 0.5, xEnd = 0, yEnd = 0 },
    hideOnOut = true,
  },
  zoomInOutFade = {
    from = { xEnd = -W * 0.5, yEnd = -H * 0.5, xScaleEnd = 2, yScaleEnd = 2, alphaStart = 1, alphaEnd = 0 },
    to = { xScaleStart = 2, yScaleStart = 2, xScaleEnd = 1, yScaleEnd = 1,
           xStart = -W * 0.5, yStart = -H * 0.5, xEnd = 0, yEnd = 0, alphaStart = 0, alphaEnd = 1 },
    hideOnOut = true,
  },
  flip = {
    from = { xEnd = W * 0.5, xScaleEnd = 0.001 },
    to = { xScaleStart = 0.001, xScaleEnd = 1, xStart = W * 0.5, xEnd = 0 },
  },
  flipFadeOutIn = {
    from = { xEnd = W * 0.5, xScaleEnd = 0.001, alphaStart = 1, alphaEnd = 0 },
    to = { xScaleStart = 0.001, xScaleEnd = 1, xStart = W * 0.5, xEnd = 0, alphaStart = 0, alphaEnd = 1 },
  },
  zoomOutInRotate = {
    from = { xEnd = W * 0.5, yEnd = H * 0.5, xScaleEnd = 0.001, yScaleEnd = 0.001, rotationStart = 0, rotationEnd = -360 },
    to = { xScaleStart = 0.001, yScaleStart = 0.001, xScaleEnd = 1, yScaleEnd = 1,
           xStart = W * 0.5, yStart = H * 0.5, xEnd = 0, yEnd = 0, rotationStart = -360, rotationEnd = 0 },
    hideOnOut = true,
  },
  zoomOutInFadeRotate = {
    from = { xEnd = W * 0.5, yEnd = H * 0.5, xScaleEnd = 0.001, yScaleEnd = 0.001,
             rotationStart = 0, rotationEnd = -360, alphaStart = 1, alphaEnd = 0 },
    to = { xScaleStart = 0.001, yScaleStart = 0.001, xScaleEnd = 1, yScaleEnd = 1,
           xStart = W * 0.5, yStart = H * 0.5, xEnd = 0, yEnd = 0,
           rotationStart = -360, rotationEnd = 0, alphaStart = 0, alphaEnd = 1 },
    hideOnOut = true,
  },
  zoomInOutRotate = {
    from = { xEnd = W * 0.5, yEnd = H * 0.5, xScaleEnd = 2, yScaleEnd = 2, rotationStart = 0, rotationEnd = -360 },
    to = { xScaleStart = 2, yScaleStart = 2, xScaleEnd = 1, yScaleEnd = 1,
           xStart = W * 0.5, yStart = H * 0.5, xEnd = 0, yEnd = 0, rotationStart = -360, rotationEnd = 0 },
    hideOnOut = true,
  },
  zoomInOutFadeRotate = {
    from = { xEnd = W * 0.5, yEnd = H * 0.5, xScaleEnd = 2, yScaleEnd = 2,
             rotationStart = 0, rotationEnd = -360, alphaStart = 1, alphaEnd = 0 },
    to = { xScaleStart = 2, yScaleStart = 2, xScaleEnd = 1, yScaleEnd = 1,
           xStart = W * 0.5, yStart = H * 0.5, xEnd = 0, yEnd = 0,
           rotationStart = -360, rotationEnd = 0, alphaStart = 0, alphaEnd = 1 },
    hideOnOut = true,
  },
  fromRight = slideEffect(0, 0, W, 0),
  fromLeft = slideEffect(0, 0, -W, 0),
  fromTop = slideEffect(0, 0, 0, -H),
  fromBottom = slideEffect(0, 0, 0, H),
  slideLeft = slideEffect(-W, 0, W, 0),
  slideRight = slideEffect(W, 0, -W, 0),
  slideDown = slideEffect(0, H, 0, -H),
  slideUp = slideEffect(0, -H, 0, H),
}
storyboard.effectList = effectList

local function indexOfLoaded(sceneName)
  for i = 1, #storyboard.loadedSceneMods do
    if storyboard.loadedSceneMods[i] == sceneName then
      return i
    end
  end
end

local function removeFromLoaded(sceneName)
  local i = indexOfLoaded(sceneName)
  if i then
    table.remove(storyboard.loadedSceneMods, i)
  end
end

local function markLoaded(sceneName)
  removeFromLoaded(sceneName)
  storyboard.loadedSceneMods[#storyboard.loadedSceneMods + 1] = sceneName
end

local function exitCurrentScene(view, newSceneName, noEffect)
  if not view then
    return
  end
  local outgoing
  if view.numChildren and view.numChildren > 0 and not noEffect then
    outgoing = view
  end
  for i = view.numChildren, 1, -1 do
    if view[i].enterFrame then
      Runtime:removeEventListener("enterFrame", view[i])
    end
  end
  if currentSceneName and storyboard.scenes[currentSceneName] then
    storyboard.scenes[currentSceneName]:dispatchEvent({ name = "exitScene" })
  end
  currentSceneName = newSceneName
  if outgoing then
    stage:insert(outgoing)
    return outgoing
  end
end

local function newTouchBlocker()
  local function swallow()
    return true
  end
  local rect = display.newRect(screenLeft, screenTop, screenWidth, screenHeight)
  rect:setFillColor(0)
  rect.isVisible = false
  rect.isHitTestable = true
  rect:addEventListener("touch", swallow)
  rect:addEventListener("tap", swallow)
  if not isGraphicsV1 then
    rect.anchorX = 0
    rect.anchorY = 0
  end
  return rect
end

local function applyStart(view, fx)
  view.x = fx.xStart or 0
  view.y = fx.yStart or 0
  view.alpha = fx.alphaStart or 1
  view.xScale = fx.xScaleStart or 1
  view.yScale = fx.yScaleStart or 1
  view.rotation = fx.rotationStart or 0
end

local function loadSceneModule(sceneName)
  local scene = require(sceneName)
  if type(scene) == "boolean" then
    error("Attempting to load scene from invalid scene module (" .. sceneName ..
      ".lua). Did you forget to return the scene object at the end of the scene module? (e.g. 'return scene')")
  end
  storyboard.scenes[sceneName] = scene
  return scene
end

function storyboard.newScene(sceneName)
  local scene = Runtime._super:new()
  if sceneName and not storyboard.scenes[sceneName] then
    storyboard.scenes[sceneName] = scene
  end
  return scene
end

function storyboard.purgeScene(sceneName)
  local scene = storyboard.scenes[sceneName]
  if scene and scene.view then
    scene:dispatchEvent({ name = "destroyScene" })
    removeFromLoaded(sceneName)
    if scene.view then
      display.remove(scene.view)
      scene.view = nil
      collectgarbage("collect")
    end
  end
end

function storyboard.removeScene(sceneName)
  storyboard.purgeScene(sceneName)
  storyboard.scenes[sceneName] = nil
  package.loaded[sceneName] = nil
end

function storyboard.purgeAll()
  local purged = 0
  for i = #storyboard.loadedSceneMods, 1, -1 do
    local name = storyboard.loadedSceneMods[i]
    if name ~= currentSceneName then
      purged = purged + 1
      storyboard.purgeScene(name)
    end
  end
end

function storyboard.removeAll()
  storyboard.hideOverlay()
  for i = #storyboard.loadedSceneMods, 1, -1 do
    local name = storyboard.loadedSceneMods[i]
    if name ~= currentSceneName then
      storyboard.removeScene(name)
    end
  end
end

function storyboard.getPrevious()
  return previousSceneName
end

function storyboard.getScene(sceneName)
  local scene = storyboard.scenes[sceneName]
  return scene
end

function storyboard.getCurrentSceneName()
  return currentSceneName
end

local function transitionIn(view, effect, time, blocker, outgoing, params)
  local function onComplete()
    blocker.isHitTestable = false
    if outgoing then
      outgoing.isVisible = false
    end
    if currentSceneName and storyboard.scenes[currentSceneName] then
      markLoaded(currentSceneName)
      storyboard.scenes[currentSceneName]:dispatchEvent({ name = "enterScene", params = params })
      if storyboard.purgeOnSceneChange then
        storyboard.purgeAll()
      end
    end
  end

  local previous = storyboard.getPrevious()
  if previous and storyboard.scenes[previous] then
    storyboard.scenes[previous]:dispatchEvent({ name = "didExitScene" })
  end
  if storyboard.scenes[currentSceneName] then
    storyboard.scenes[currentSceneName]:dispatchEvent({ name = "willEnterScene", params = params })
  end
  if outgoing and effect.hideOnOut then
    outgoing.isVisible = false
  end
  view.isVisible = true
  transition.to(view, {
    x = effect.to.xEnd, y = effect.to.yEnd, alpha = effect.to.alphaEnd,
    xScale = effect.to.xScaleEnd, yScale = effect.to.yScaleEnd, rotation = effect.to.rotationEnd,
    time = time or 500,
    transition = effect.to.transition,
    onComplete = onComplete,
  })
end

function storyboard.hideOverlay(purgeOnly, effect, time, extra)
  display.remove(modalRect)
  modalRect = nil
  local overlay = overlayScene
  overlayScene = nil
  if not overlay then
    return
  end
  if purgeOnly == storyboard then
    purgeOnly, effect, time = effect, time, extra
  end
  if type(purgeOnly) == "string" then
    time = effect or time
    effect = purgeOnly
    purgeOnly = nil
  end

  local function finish()
    overlay:dispatchEvent({ name = "didExitScene" })
    if indexOfLoaded(overlay.name) then
      purgeOnly = true
    end
    if purgeOnly then
      storyboard.purgeScene(overlay.name)
    else
      storyboard.removeScene(overlay.name)
    end
    if currentSceneName then
      storyboard.scenes[currentSceneName]:dispatchEvent({ name = "overlayEnded", sceneName = overlay.name })
    end
    touchBlocker.isHitTestable = false
  end

  overlay:dispatchEvent({ name = "exitScene" })
  if effect and effectList[effect] then
    local from = effectList[effect].from
    applyStart(overlay.view, from)
    transition.to(overlay.view, {
      x = from.xEnd, y = from.yEnd, alpha = from.alphaEnd,
      xScale = from.xScaleEnd, yScale = from.yScaleEnd, rotation = from.rotationEnd,
      time = time, transition = from.transition, onComplete = finish,
    })
  else
    finish()
  end
end

function storyboard.showOverlay(sceneName, options)
  storyboard.hideOverlay()
  if sceneName == storyboard and type(options) == "string" then
    sceneName, options = options, nil
  end
  options = options or {}
  local effect = options.effect
  local time = options.time or 500
  local params = options.params

  local scene = storyboard.scenes[sceneName]
  if scene then
    if not scene.view then
      scene.view = display.newGroup()
      scene:dispatchEvent({ name = "createScene", params = params })
    end
  else
    scene = loadSceneModule(sceneName)
    scene.view = scene.view or display.newGroup()
    scene:dispatchEvent({ name = "createScene", params = params })
  end
  scene:dispatchEvent({ name = "willEnterScene", params = params })

  local function entered()
    scene:dispatchEvent({ name = "enterScene", params = params })
    if currentSceneName then
      storyboard.scenes[currentSceneName]:dispatchEvent({ name = "overlayBegan", sceneName = sceneName, params = params })
    end
    touchBlocker.isHitTestable = false
  end

  if effect and effectList[effect] then
    local to = effectList[effect].to
    touchBlocker.isHitTestable = true
    applyStart(scene.view, to)
    scene.view.isVisible = true
    transition.to(scene.view, {
      x = to.xEnd, y = to.yEnd, alpha = to.alphaEnd,
      xScale = to.xScaleEnd, yScale = to.yScaleEnd, rotation = to.rotationEnd,
      time = time, transition = to.transition, onComplete = entered,
    })
  else
    touchBlocker.isHitTestable = false
    scene.isVisible = true
    scene.view.x, scene.view.y = 0, 0
    entered()
  end

  overlayScene = scene
  overlayScene.name = sceneName

  if options.isModal then
    modalRect = display.newRect(screenLeft, screenTop, screenWidth, screenHeight)
    modalRect.x = display.contentCenterX
    modalRect.y = display.contentCenterY
    if not isGraphicsV1 then
      modalRect.anchorX = 0.5
      modalRect.anchorY = 0.5
    end
    modalRect.isVisible = false
    modalRect.isHitTestable = true
    local function swallow()
      return true
    end
    modalRect.touch = swallow
    modalRect.tap = swallow
    modalRect:addEventListener("touch")
    modalRect:addEventListener("tap")
    stage:insert(modalRect)
  end
  stage:insert(scene.view)
end

function storyboard.reloadScene()
  if not currentSceneName then
    return
  end
  storyboard.hideOverlay()
  local scene = storyboard.getScene(currentSceneName)
  if not scene then
    return
  end
  local function nextFrame(fn)
    return timer.performWithDelay(1, fn, 1)
  end
  scene:dispatchEvent({ name = "exitScene" })
  nextFrame(function()
    scene:dispatchEvent({ name = "didExitScene" })
    nextFrame(function()
      if not scene.view then
        scene.view = display.newGroup()
        scene:dispatchEvent({ name = "createScene" })
        currentView = scene.view
        stage:insert(currentView)
      end
      nextFrame(function()
        scene:dispatchEvent({ name = "willEnterScene" })
        nextFrame(function()
          scene:dispatchEvent({ name = "enterScene" })
        end)
      end)
    end)
  end)
end

function storyboard.loadScene(sceneName, doNotLoadView, params)
  if sceneName == storyboard then
    error("You must use a dot (instead of a colon) when calling storyboard.loadScene()")
  end
  if doNotLoadView ~= nil and type(doNotLoadView) ~= "boolean" then
    params = doNotLoadView
  end
  local scene = storyboard.scenes[sceneName]
  if scene then
    if not scene.view and not doNotLoadView then
      scene.view = display.newGroup()
      scene:dispatchEvent({ name = "createScene", params = params })
      markLoaded(sceneName)
    end
  else
    scene = loadSceneModule(sceneName)
    if not doNotLoadView then
      scene.view = scene.view or display.newGroup()
      scene:dispatchEvent({ name = "createScene", params = params })
      markLoaded(sceneName)
    end
  end
  if not doNotLoadView then
    scene.view.isVisible = false
    stage:insert(1, scene.view)
  end
  return scene
end

function storyboard.gotoScene(...)
  storyboard.hideOverlay()
  local args = { ... }
  local offset = 0
  if args[1] == storyboard then
    offset = 1
  end
  if type(args[1 + offset]) == "boolean" then
    offset = offset + 1
  end
  local sceneName = args[1 + offset]
  local params, effect, time
  if type(args[2 + offset]) == "table" then
    local options = args[2 + offset]
    effect = options.effect
    time = tonumber(options.time)
    params = options.params
  elseif args[2 + offset] then
    effect = args[2 + offset]
    time = tonumber(args[3 + offset])
  end
  if not effect then
    effect = "crossFade"
    time = 0
  end

  if not currentSceneName then
    currentSceneName = sceneName
  elseif currentSceneName == sceneName then
    storyboard.reloadScene()
    return
  else
    previousSceneName = currentSceneName
  end

  local fx = effectList[effect] or {}
  local outgoing = exitCurrentScene(currentView, sceneName, not effect)

  if not touchBlocker then
    touchBlocker = newTouchBlocker()
  else
    touchBlocker.isHitTestable = true
  end

  local scene = storyboard.scenes[sceneName]
  if scene then
    if not scene.view then
      scene.view = display.newGroup()
      scene:dispatchEvent({ name = "createScene", params = params })
    end
  else
    local ok, err = pcall(function()
      storyboard.scenes[sceneName] = require(sceneName)
    end)
    if not ok and err then
      error(err)
    end
    scene = storyboard.scenes[sceneName]
    if type(scene) == "boolean" then
      error("Attempting to load scene from invalid scene module (" .. sceneName ..
        ".lua). Did you forget to return the scene object at the end of the scene module? (e.g. 'return scene')")
    end
    scene.view = scene.view or display.newGroup()
    scene:dispatchEvent({ name = "createScene", params = params })
  end
  currentView = scene.view

  if fx.sceneAbove then
    stage:insert(currentView)
  else
    stage:insert(1, currentView)
  end
  touchBlocker:toFront()
  currentView.isVisible = false
  if fx.to then
    applyStart(currentView, fx.to)
  end

  local function startIn()
    transitionIn(currentView, fx, time, touchBlocker, outgoing, params)
  end

  local fromParams = {
    x = fx.from.xEnd, y = fx.from.yEnd, alpha = fx.from.alphaEnd,
    xScale = fx.from.xScaleEnd, yScale = fx.from.yScaleEnd, rotation = fx.from.rotationEnd,
    time = time or 500,
    transition = fx.from.transition,
    onComplete = startIn,
    delay = 1,
  }
  if fx.concurrent then
    fromParams.onComplete = nil
  end
  if outgoing then
    if fx.concurrent then
      transition.to(outgoing, fromParams)
      startIn()
    elseif fromParams.onComplete then
      transition.to(outgoing, fromParams)
    end
  else
    startIn()
  end
end

Runtime:addEventListener("memoryWarning", function()
  if not storyboard.disableAutoPurge then
    local oldest = storyboard.loadedSceneMods[1]
    if oldest and oldest ~= currentSceneName and #storyboard.loadedSceneMods > 2 then
      storyboard.purgeScene(oldest)
    end
  end
end)

return storyboard
