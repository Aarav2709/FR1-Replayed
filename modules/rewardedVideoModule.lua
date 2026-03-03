-- rewardedVideoModule.lua — Rewarded video ads (disabled stub)
-- All ad networks are disabled for the rebuilt version.

local storyboard = require("modules.storyboard")

local rewardedVideoModule = {}

function rewardedVideoModule.init()
    print("[rewardedVideoModule] init (disabled)")
end

function rewardedVideoModule.isAvailable()
    return false
end

function rewardedVideoModule.show(callback)
    print("[rewardedVideoModule] show (disabled)")
    if callback then callback(false) end
end

function rewardedVideoModule.shouldShowMainMenuRewardedVideo()
    return false
end

function rewardedVideoModule.setActiveVideoData(data, coins, type)
    -- no-op
end

function rewardedVideoModule.getMainMenuRewardedVideoCoinsToEarn()
    return 0
end

function rewardedVideoModule.clearActiveVideoData()
    -- no-op
end

return rewardedVideoModule
