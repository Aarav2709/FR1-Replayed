-- loadingAnimation.lua — Loading/spinner animation utility module
-- Shows/hides a loading spinner overlay during async operations

local storyboard = require("modules.storyboard")

local loadingAnimation = {}

--------------------------------------------------------------------------------
-- newLoadingAnimation()
-- Creates a new loading spinner instance with its own display group.
-- Returns { displayGroup, startLoader(), stopLoader() }
--------------------------------------------------------------------------------
function loadingAnimation.newLoadingAnimation()
    local instance = {}
    local spinning = false
    local enterFrameRef = nil

    -- Create display group for the spinner
    instance.displayGroup = display.newGroup()
    instance.displayGroup.isVisible = false

    -- Spinner circle
    local circle = display.newCircle(instance.displayGroup, 0, 0, 12)
    circle:setFillColor(0, 0, 0, 0)
    circle:setStrokeColor(1, 1, 1, 0.9)
    circle.strokeWidth = 2

    -- Indicator dot on rim
    local dot = display.newCircle(instance.displayGroup, 0, -12, 3)
    dot:setFillColor(1, 1, 1)

    -- Start spinning
    function instance.startLoader()
        if spinning then return end
        spinning = true
        instance.displayGroup.isVisible = true
        local function spin()
            if instance.displayGroup and instance.displayGroup.removeSelf then
                instance.displayGroup.rotation = instance.displayGroup.rotation + 10
            end
        end
        Runtime:addEventListener("enterFrame", spin)
        enterFrameRef = spin
    end

    -- Stop spinning
    function instance.stopLoader()
        if not spinning then return end
        spinning = false
        instance.displayGroup.isVisible = false
        if enterFrameRef then
            Runtime:removeEventListener("enterFrame", enterFrameRef)
            enterFrameRef = nil
        end
    end

    return instance
end

return loadingAnimation
