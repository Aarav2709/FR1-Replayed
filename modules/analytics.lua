-- analytics.lua — Analytics module (disabled/stub)
-- All analytics providers are disabled for the rebuilt version.

local storyboard = require("modules.storyboard")

local analytics = {}

-- Stub analytics plugin
analytics.plugin = {
    init = function() end,
    logEvent = function() end,
    newEvent = function() end,
}

function analytics.newEvent(name, params)
    -- No-op: analytics disabled
end

function analytics.storyboardEvent(name, params)
    -- No-op: analytics disabled
end

return analytics
