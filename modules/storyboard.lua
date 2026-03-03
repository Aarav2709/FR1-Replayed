-- storyboard.lua — Scene management module
-- Reconstructed from decompiled Corona SDK storyboard

local storyboard = {}

-- Display stage
local stage = display.newGroup()

-- State tracking
local currentSceneName = nil
local currentSceneView = nil
local previousSceneName = nil
local overlayScene = nil
local touchBlocker = nil
local modalRect = nil

-- Loaded scene modules (LRU order: oldest at index 1)
storyboard.loadedSceneMods = {}
storyboard.scenes = {}
storyboard.stage = stage
storyboard.disableAutoPurge = false
storyboard.purgeOnSceneChange = false
storyboard.isDebug = false

-- Cache screen dimensions
local contentWidth = display.contentWidth
local contentHeight = display.contentHeight
local screenOriginX = display.screenOriginX
local screenOriginY = display.screenOriginY
local fullWidth = contentWidth - screenOriginX * 2
local fullHeight = contentHeight - screenOriginY * 2
local rightEdge = contentWidth - screenOriginX
local bottomEdge = contentHeight - screenOriginY
local centerX = contentWidth / 2
local centerY = contentHeight / 2

-- Check graphics v1 compatibility
local isV1Compatible = false
local gpv = system.getInfo("graphicsPipelineVersion")
if gpv ~= "1.0" then
    local gc = display.getDefault("graphicsCompatibility")
    isV1Compatible = (1 == gc)
end

--------------------------------------------------------------------------------
-- Transition effect definitions
--------------------------------------------------------------------------------

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
        from = {
            xScaleStart = 1, yScaleStart = 1,
            xScaleEnd = 0.001, yScaleEnd = 0.001,
            xStart = 0, yStart = 0,
            xEnd = centerX, yEnd = centerY,
        },
        to = {
            xScaleStart = 0.001, yScaleStart = 0.001,
            xScaleEnd = 1, yScaleEnd = 1,
            xStart = centerX, yStart = centerY,
            xEnd = 0, yEnd = 0,
        },
        hideOnOut = true,
    },
    zoomOutInFade = {
        from = {
            xScaleStart = 1, yScaleStart = 1,
            xScaleEnd = 0.001, yScaleEnd = 0.001,
            xStart = 0, yStart = 0,
            xEnd = centerX, yEnd = centerY,
            alphaStart = 1, alphaEnd = 0,
        },
        to = {
            xScaleStart = 0.001, yScaleStart = 0.001,
            xScaleEnd = 1, yScaleEnd = 1,
            xStart = centerX, yStart = centerY,
            xEnd = 0, yEnd = 0,
            alphaStart = 0, alphaEnd = 1,
        },
        hideOnOut = true,
    },
    zoomInOut = {
        from = {
            xScaleStart = 1, yScaleStart = 1,
            xScaleEnd = 2, yScaleEnd = 2,
            xStart = 0, yStart = 0,
            xEnd = -centerX, yEnd = -centerY,
        },
        to = {
            xScaleStart = 2, yScaleStart = 2,
            xScaleEnd = 1, yScaleEnd = 1,
            xStart = -centerX, yStart = -centerY,
            xEnd = 0, yEnd = 0,
        },
        hideOnOut = true,
    },
    zoomInOutFade = {
        from = {
            xScaleStart = 1, yScaleStart = 1,
            xScaleEnd = 2, yScaleEnd = 2,
            xStart = 0, yStart = 0,
            xEnd = -centerX, yEnd = -centerY,
            alphaStart = 1, alphaEnd = 0,
        },
        to = {
            xScaleStart = 2, yScaleStart = 2,
            xScaleEnd = 1, yScaleEnd = 1,
            xStart = -centerX, yStart = -centerY,
            xEnd = 0, yEnd = 0,
            alphaStart = 0, alphaEnd = 1,
        },
        hideOnOut = true,
    },
    flip = {
        from = {
            xScaleStart = 1, xScaleEnd = 0.001,
            xStart = 0, xEnd = centerX,
        },
        to = {
            xScaleStart = 0.001, xScaleEnd = 1,
            xStart = centerX, xEnd = 0,
        },
    },
    flipFadeOutIn = {
        from = {
            xScaleStart = 1, xScaleEnd = 0.001,
            xStart = 0, xEnd = centerX,
            alphaStart = 1, alphaEnd = 0,
        },
        to = {
            xScaleStart = 0.001, xScaleEnd = 1,
            xStart = centerX, xEnd = 0,
            alphaStart = 0, alphaEnd = 1,
        },
    },
    zoomOutInRotate = {
        from = {
            xScaleStart = 1, yScaleStart = 1,
            xScaleEnd = 0.001, yScaleEnd = 0.001,
            xStart = 0, yStart = 0,
            xEnd = centerX, yEnd = centerY,
            rotationStart = 0, rotationEnd = -360,
        },
        to = {
            xScaleStart = 0.001, yScaleStart = 0.001,
            xScaleEnd = 1, yScaleEnd = 1,
            xStart = centerX, yStart = centerY,
            xEnd = 0, yEnd = 0,
            rotationStart = -360, rotationEnd = 0,
        },
        hideOnOut = true,
    },
    zoomOutInFadeRotate = {
        from = {
            xScaleStart = 1, yScaleStart = 1,
            xScaleEnd = 0.001, yScaleEnd = 0.001,
            xStart = 0, yStart = 0,
            xEnd = centerX, yEnd = centerY,
            alphaStart = 1, alphaEnd = 0,
            rotationStart = 0, rotationEnd = -360,
        },
        to = {
            xScaleStart = 0.001, yScaleStart = 0.001,
            xScaleEnd = 1, yScaleEnd = 1,
            xStart = centerX, yStart = centerY,
            xEnd = 0, yEnd = 0,
            alphaStart = 0, alphaEnd = 1,
            rotationStart = -360, rotationEnd = 0,
        },
        hideOnOut = true,
    },
    zoomInOutRotate = {
        from = {
            xScaleStart = 1, yScaleStart = 1,
            xScaleEnd = 2, yScaleEnd = 2,
            xStart = 0, yStart = 0,
            xEnd = -centerX, yEnd = -centerY,
            rotationStart = 0, rotationEnd = -360,
        },
        to = {
            xScaleStart = 2, yScaleStart = 2,
            xScaleEnd = 1, yScaleEnd = 1,
            xStart = -centerX, yStart = -centerY,
            xEnd = 0, yEnd = 0,
            rotationStart = -360, rotationEnd = 0,
        },
        hideOnOut = true,
    },
    zoomInOutFadeRotate = {
        from = {
            xScaleStart = 1, yScaleStart = 1,
            xScaleEnd = 2, yScaleEnd = 2,
            xStart = 0, yStart = 0,
            xEnd = -centerX, yEnd = -centerY,
            alphaStart = 1, alphaEnd = 0,
            rotationStart = 0, rotationEnd = -360,
        },
        to = {
            xScaleStart = 2, yScaleStart = 2,
            xScaleEnd = 1, yScaleEnd = 1,
            xStart = -centerX, yStart = -centerY,
            xEnd = 0, yEnd = 0,
            alphaStart = 0, alphaEnd = 1,
            rotationStart = -360, rotationEnd = 0,
        },
        hideOnOut = true,
    },
    fromRight = {
        from = { xStart = 0, yStart = 0, xEnd = 0, yEnd = 0 },
        to = { xStart = contentWidth, yStart = 0, xEnd = 0, yEnd = 0, transition = easing.outQuad },
        concurrent = true, sceneAbove = true,
    },
    fromLeft = {
        from = { xStart = 0, yStart = 0, xEnd = 0, yEnd = 0 },
        to = { xStart = -contentWidth, yStart = 0, xEnd = 0, yEnd = 0, transition = easing.outQuad },
        concurrent = true, sceneAbove = true,
    },
    fromTop = {
        from = { xStart = 0, yStart = 0, xEnd = 0, yEnd = 0 },
        to = { xStart = 0, yStart = -contentHeight, xEnd = 0, yEnd = 0, transition = easing.outQuad },
        concurrent = true, sceneAbove = true,
    },
    fromBottom = {
        from = { xStart = 0, yStart = 0, xEnd = 0, yEnd = 0 },
        to = { xStart = 0, yStart = contentHeight, xEnd = 0, yEnd = 0, transition = easing.outQuad },
        concurrent = true, sceneAbove = true,
    },
    slideLeft = {
        from = { xStart = 0, yStart = 0, xEnd = -contentWidth, yEnd = 0, transition = easing.outQuad },
        to = { xStart = contentWidth, yStart = 0, xEnd = 0, yEnd = 0, transition = easing.outQuad },
        concurrent = true, sceneAbove = true,
    },
    slideRight = {
        from = { xStart = 0, yStart = 0, xEnd = contentWidth, yEnd = 0, transition = easing.outQuad },
        to = { xStart = -contentWidth, yStart = 0, xEnd = 0, yEnd = 0, transition = easing.outQuad },
        concurrent = true, sceneAbove = true,
    },
    slideDown = {
        from = { xStart = 0, yStart = 0, xEnd = 0, yEnd = contentHeight, transition = easing.outQuad },
        to = { xStart = 0, yStart = -contentHeight, xEnd = 0, yEnd = 0, transition = easing.outQuad },
        concurrent = true, sceneAbove = true,
    },
    slideUp = {
        from = { xStart = 0, yStart = 0, xEnd = 0, yEnd = -contentHeight, transition = easing.outQuad },
        to = { xStart = 0, yStart = contentHeight, xEnd = 0, yEnd = 0, transition = easing.outQuad },
        concurrent = true, sceneAbove = true,
    },
}

storyboard.effectList = effectList

--------------------------------------------------------------------------------
-- Private helper functions
--------------------------------------------------------------------------------

local function debugPrint(message)
    if storyboard.isDebug then
        print("STORYBOARD > " .. tostring(message))
    end
end

local function findSceneModIndex(sceneName)
    for i, name in ipairs(storyboard.loadedSceneMods) do
        if name == sceneName then
            return i
        end
    end
    return nil
end

local function removeFromLoadedMods(sceneName)
    local index = findSceneModIndex(sceneName)
    if index then
        table.remove(storyboard.loadedSceneMods, index)
    end
end

local function touchToEndOfLoadedMods(sceneName)
    removeFromLoadedMods(sceneName)
    storyboard.loadedSceneMods[#storyboard.loadedSceneMods + 1] = sceneName
end

local function createTouchBlocker()
    local blocker = display.newRect(screenOriginX, screenOriginY, fullWidth, fullHeight)
    blocker:setFillColor(0, 0, 0, 0)
    blocker.isVisible = false
    blocker.isHitTestable = true
    if not isV1Compatible then
        blocker.anchorX = 0
        blocker.anchorY = 0
    end
    blocker:addEventListener("touch", function() return true end)
    blocker:addEventListener("tap", function() return true end)
    return blocker
end

local function cleanupPreviousScene(sceneView, newSceneName, noEffect)
    if not sceneView then return nil end

    if noEffect and sceneView then
        sceneView.isVisible = false
    end

    -- Remove enterFrame listeners from children
    if sceneView.numChildren then
        for i = sceneView.numChildren, 1, -1 do
            local child = sceneView[i]
            if child then
                Runtime:removeEventListener("enterFrame", child)
            end
        end
    end

    -- Dispatch exitScene on current scene
    if currentSceneName then
        local scene = storyboard.scenes[currentSceneName]
        if scene then
            scene:dispatchEvent({ name = "exitScene" })
            debugPrint("exitScene dispatched for: " .. currentSceneName)
        end
    end

    currentSceneName = newSceneName
    return sceneView
end

--------------------------------------------------------------------------------
-- Transition helper
--------------------------------------------------------------------------------

local function applyEffectStartProps(view, effectDef)
    if not effectDef then return end
    if effectDef.xStart then view.x = effectDef.xStart end
    if effectDef.yStart then view.y = effectDef.yStart end
    if effectDef.alphaStart then view.alpha = effectDef.alphaStart end
    if effectDef.xScaleStart then view.xScale = effectDef.xScaleStart end
    if effectDef.yScaleStart then view.yScale = effectDef.yScaleStart end
    if effectDef.rotationStart then view.rotation = effectDef.rotationStart end
end

local function buildTransitionParams(effectDef, time, onComplete)
    local params = { time = time }
    if effectDef.xEnd then params.x = effectDef.xEnd end
    if effectDef.yEnd then params.y = effectDef.yEnd end
    if effectDef.alphaEnd then params.alpha = effectDef.alphaEnd end
    if effectDef.xScaleEnd then params.xScale = effectDef.xScaleEnd end
    if effectDef.yScaleEnd then params.yScale = effectDef.yScaleEnd end
    if effectDef.rotationEnd then params.rotation = effectDef.rotationEnd end
    if effectDef.transition then params.transition = effectDef.transition end
    if onComplete then params.onComplete = onComplete end
    return params
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

function storyboard.newScene(moduleName)
    local scene = Runtime._super:new()
    if moduleName and not storyboard.scenes[moduleName] then
        storyboard.scenes[moduleName] = scene
    end
    return scene
end

function storyboard.getCurrentSceneName()
    return currentSceneName
end

function storyboard.getPrevious()
    return previousSceneName
end

function storyboard.getScene(sceneName)
    local scene = storyboard.scenes[sceneName]
    if not scene then
        debugPrint("Scene not found: " .. tostring(sceneName))
    end
    return scene
end

function storyboard.printMemUsage()
    if not storyboard.isDebug then return nil end
    collectgarbage()
    local sysMem = collectgarbage("count") / 1024
    local texMem = system.getInfo("textureMemoryUsed") / (1024 * 1024)
    print(string.format("STORYBOARD > System memory: %.2f MB | Texture memory: %.2f MB", sysMem, texMem))
    return true
end

function storyboard.purgeScene(sceneName)
    local scene = storyboard.scenes[sceneName]
    if scene and scene.view then
        scene:dispatchEvent({ name = "destroyScene" })
        removeFromLoadedMods(sceneName)
        display.remove(scene.view)
        scene.view = nil
        collectgarbage("collect")
        debugPrint("purgeScene: " .. sceneName)
    else
        debugPrint("purgeScene: scene not found or has no view — " .. tostring(sceneName))
    end
end

function storyboard.purgeAll()
    local purgeCount = 0
    for i = #storyboard.loadedSceneMods, 1, -1 do
        local name = storyboard.loadedSceneMods[i]
        if name ~= currentSceneName then
            storyboard.purgeScene(name)
            purgeCount = purgeCount + 1
        end
    end
    debugPrint("purgeAll: purged " .. purgeCount .. " scenes")
end

function storyboard.removeScene(sceneName)
    storyboard.purgeScene(sceneName)
    storyboard.scenes[sceneName] = nil
    package.loaded[sceneName] = nil
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

function storyboard.loadScene(sceneName, dontLoadView, params)
    if type(dontLoadView) ~= "boolean" then
        params = dontLoadView
        dontLoadView = false
    end

    local scene = storyboard.scenes[sceneName]

    if scene then
        -- Scene already exists
        if not scene.view and not dontLoadView then
            scene.view = display.newGroup()
            scene:dispatchEvent({ name = "createScene", params = params })
            touchToEndOfLoadedMods(sceneName)
        end
    else
        -- Load new scene
        local ok, result = pcall(require, sceneName)
        if ok then
            scene = storyboard.scenes[sceneName] or result
            if not storyboard.scenes[sceneName] then
                storyboard.scenes[sceneName] = scene
            end
            if not dontLoadView then
                if not scene.view then
                    scene.view = display.newGroup()
                end
                scene:dispatchEvent({ name = "createScene", params = params })
                touchToEndOfLoadedMods(sceneName)
            end
        else
            print("STORYBOARD ERROR: Failed to load scene '" .. sceneName .. "': " .. tostring(result))
            return nil
        end
    end

    if not dontLoadView and scene and scene.view then
        scene.view.isVisible = false
        stage:insert(1, scene.view)
    end

    return scene
end

function storyboard.gotoScene(...)
    local args = { ... }
    local sceneName, effect, effectTime, params

    -- Handle colon syntax detection
    if type(args[1]) == "table" and args[1] == storyboard then
        debugPrint("WARNING: gotoScene called with colon syntax. Use dot syntax.")
        table.remove(args, 1)
    end

    sceneName = args[1]

    if type(args[2]) == "table" then
        local options = args[2]
        effect = options.effect
        effectTime = options.time
        params = options.params
    elseif type(args[2]) == "string" then
        effect = args[2]
        effectTime = args[3]
    end

    local noEffect = (effect == nil or effect == "")
    if not noEffect and not effectTime then
        effectTime = 500
    end
    if noEffect then
        effectTime = 0
    end

    -- Hide any overlay
    storyboard.hideOverlay()

    -- Same scene: reload
    if sceneName == currentSceneName then
        storyboard.reloadScene()
        return
    end

    -- Track previous scene
    if currentSceneName then
        previousSceneName = currentSceneName
    end

    -- Get effect definition
    local effectDef = effectList[effect]

    -- Cleanup previous scene
    local fromView = cleanupPreviousScene(currentSceneView, sceneName, noEffect)

    -- Create/get touch blocker
    if not touchBlocker then
        touchBlocker = createTouchBlocker()
        stage:insert(touchBlocker)
    end
    touchBlocker.isHitTestable = true

    -- Load target scene
    local scene = storyboard.scenes[sceneName]
    if scene then
        if not scene.view then
            scene.view = display.newGroup()
            scene:dispatchEvent({ name = "createScene", params = params })
        end
    else
        local ok, result = pcall(require, sceneName)
        if ok then
            scene = storyboard.scenes[sceneName] or result
            if not storyboard.scenes[sceneName] then
                storyboard.scenes[sceneName] = scene
            end
            if not scene.view then
                scene.view = display.newGroup()
            end
            scene:dispatchEvent({ name = "createScene", params = params })
        else
            print("STORYBOARD ERROR: Failed to load scene '" .. sceneName .. "': " .. tostring(result))
            touchBlocker.isHitTestable = false
            return
        end
    end

    if type(scene) == "boolean" then
        print("STORYBOARD ERROR: Scene module '" .. sceneName .. "' returned boolean. Did you forget 'return scene'?")
        touchBlocker.isHitTestable = false
        return
    end

    local toView = scene.view
    currentSceneView = toView

    -- Insert into stage
    if effectDef and effectDef.sceneAbove then
        stage:insert(toView)
    else
        stage:insert(1, toView)
    end

    -- Keep touch blocker on top
    stage:insert(touchBlocker)

    toView.isVisible = false

    if not noEffect and effectDef then
        -- Apply start properties to incoming scene
        applyEffectStartProps(toView, effectDef.to)

        -- Transition incoming scene
        local function transitionIn()
            -- Dispatch didExitScene on previous
            if previousSceneName then
                local prevScene = storyboard.scenes[previousSceneName]
                if prevScene then
                    prevScene:dispatchEvent({ name = "didExitScene" })
                end
            end

            -- Dispatch willEnterScene on current
            scene:dispatchEvent({ name = "willEnterScene", params = params })

            local function onInComplete()
                touchBlocker.isHitTestable = false
                if fromView then
                    fromView.isVisible = false
                end
                if currentSceneName and storyboard.scenes[currentSceneName] then
                    touchToEndOfLoadedMods(currentSceneName)
                    storyboard.scenes[currentSceneName]:dispatchEvent({ name = "enterScene", params = params })
                end
                if storyboard.purgeOnSceneChange then
                    storyboard.purgeAll()
                end
                debugPrint("enterScene dispatched for: " .. tostring(currentSceneName))
            end

            if effectDef.hideOnOut and fromView then
                fromView.isVisible = false
            end

            toView.isVisible = true
            local inParams = buildTransitionParams(effectDef.to, effectTime, onInComplete)
            transition.to(toView, inParams)
        end

        if effectDef.concurrent then
            -- Run both transitions simultaneously
            if fromView then
                applyEffectStartProps(fromView, effectDef.from)
                local outParams = buildTransitionParams(effectDef.from, effectTime)
                transition.to(fromView, outParams)
            end
            transitionIn()
        else
            -- Sequential: outgoing first, then incoming
            if fromView then
                applyEffectStartProps(fromView, effectDef.from)
                local outParams = buildTransitionParams(effectDef.from, effectTime, function()
                    transitionIn()
                end)
                outParams.delay = 1
                transition.to(fromView, outParams)
            else
                transitionIn()
            end
        end
    else
        -- No effect: immediate switch
        toView.isVisible = true

        if previousSceneName then
            local prevScene = storyboard.scenes[previousSceneName]
            if prevScene then
                prevScene:dispatchEvent({ name = "didExitScene" })
            end
        end

        scene:dispatchEvent({ name = "willEnterScene", params = params })
        touchToEndOfLoadedMods(sceneName)
        scene:dispatchEvent({ name = "enterScene", params = params })
        touchBlocker.isHitTestable = false

        if storyboard.purgeOnSceneChange then
            storyboard.purgeAll()
        end

        debugPrint("gotoScene (no effect): " .. sceneName)
    end
end

function storyboard.showOverlay(sceneName, options)
    options = options or {}
    local effect = options.effect
    local effectTime = options.time or 500
    local params = options.params
    local isModal = options.isModal

    -- Hide any existing overlay
    storyboard.hideOverlay()

    -- Load overlay scene
    local scene = storyboard.scenes[sceneName]
    if not scene then
        local ok, result = pcall(require, sceneName)
        if ok then
            scene = storyboard.scenes[sceneName] or result
            if not storyboard.scenes[sceneName] then
                storyboard.scenes[sceneName] = scene
            end
        else
            print("STORYBOARD ERROR: Failed to load overlay scene '" .. sceneName .. "': " .. tostring(result))
            return
        end
    end

    if not scene.view then
        scene.view = display.newGroup()
        scene:dispatchEvent({ name = "createScene", params = params })
    end

    overlayScene = scene
    overlayScene.name = sceneName

    -- Create modal blocker if needed
    if isModal then
        modalRect = display.newRect(centerX, centerY, fullWidth, fullHeight)
        modalRect:setFillColor(0, 0, 0, 0)
        modalRect.isVisible = false
        modalRect.isHitTestable = true
        modalRect:addEventListener("touch", function() return true end)
        modalRect:addEventListener("tap", function() return true end)
        stage:insert(modalRect)
    end

    -- Insert overlay into stage
    stage:insert(scene.view)

    -- Dispatch willEnterScene
    scene:dispatchEvent({ name = "willEnterScene", params = params })

    local function onComplete()
        scene:dispatchEvent({ name = "enterScene", params = params })
        -- Dispatch overlayBegan on parent scene
        if currentSceneName then
            local parentScene = storyboard.scenes[currentSceneName]
            if parentScene then
                parentScene:dispatchEvent({ name = "overlayBegan", sceneName = sceneName, params = params })
            end
        end
        if touchBlocker then
            touchBlocker.isHitTestable = false
        end
    end

    local effectDef = effectList[effect]
    if effect and effectDef then
        if touchBlocker then
            touchBlocker.isHitTestable = true
            stage:insert(touchBlocker)
        end
        applyEffectStartProps(scene.view, effectDef.to)
        scene.view.isVisible = true
        local inParams = buildTransitionParams(effectDef.to, effectTime, onComplete)
        transition.to(scene.view, inParams)
    else
        scene.view.isVisible = true
        onComplete()
    end
end

function storyboard.hideOverlay(shouldPurgeOnly, effect, effectTime)
    -- Remove modal rect
    if modalRect then
        display.remove(modalRect)
        modalRect = nil
    end

    local overlay = overlayScene
    overlayScene = nil

    if not overlay then return end

    -- Handle colon syntax
    if type(shouldPurgeOnly) == "string" then
        effectTime = effect
        effect = shouldPurgeOnly
        shouldPurgeOnly = nil
    end

    local function onComplete()
        overlay:dispatchEvent({ name = "didExitScene" })

        local overlayName = overlay.name
        if overlayName then
            if findSceneModIndex(overlayName) then
                storyboard.purgeScene(overlayName)
            else
                storyboard.removeScene(overlayName)
            end
        end

        -- Dispatch overlayEnded on parent scene
        if currentSceneName then
            local parentScene = storyboard.scenes[currentSceneName]
            if parentScene then
                parentScene:dispatchEvent({ name = "overlayEnded", sceneName = overlayName })
            end
        end

        if touchBlocker then
            touchBlocker.isHitTestable = false
        end
    end

    overlay:dispatchEvent({ name = "exitScene" })

    local effectDef = effectList[effect]
    if effect and effectDef then
        if touchBlocker then
            touchBlocker.isHitTestable = true
            stage:insert(touchBlocker)
        end
        applyEffectStartProps(overlay.view, effectDef.from)
        local outParams = buildTransitionParams(effectDef.from, effectTime or 500, onComplete)
        transition.to(overlay.view, outParams)
    else
        onComplete()
    end
end

function storyboard.reloadScene()
    if not currentSceneName then return end

    storyboard.hideOverlay()

    local scene = storyboard.scenes[currentSceneName]
    if not scene then return end

    scene:dispatchEvent({ name = "exitScene" })

    timer.performWithDelay(1, function()
        scene:dispatchEvent({ name = "didExitScene" })

        timer.performWithDelay(1, function()
            if not scene.view then
                scene.view = display.newGroup()
                scene:dispatchEvent({ name = "createScene" })
                currentSceneView = scene.view
                stage:insert(scene.view)
            end

            timer.performWithDelay(1, function()
                scene:dispatchEvent({ name = "willEnterScene" })

                timer.performWithDelay(1, function()
                    scene:dispatchEvent({ name = "enterScene" })
                end)
            end)
        end)
    end)
end

--------------------------------------------------------------------------------
-- Memory warning handler
--------------------------------------------------------------------------------

Runtime:addEventListener("memoryWarning", function()
    if not storyboard.disableAutoPurge then
        if #storyboard.loadedSceneMods >= 3 then
            local oldest = storyboard.loadedSceneMods[1]
            if oldest and oldest ~= currentSceneName then
                storyboard.purgeScene(oldest)
                debugPrint("Auto-purged oldest scene: " .. oldest)
            end
        end
    else
        debugPrint("Memory warning received but auto-purge is disabled")
    end
end)

return storyboard
