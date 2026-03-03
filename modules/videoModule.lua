-- videoModule.lua — Video ads (disabled stub)

local videoModule = {}

function videoModule.init() end
function videoModule.isAvailable() return false end
function videoModule.isVideoAvailable() return false end
function videoModule.show(callback)
    if callback then callback(false) end
end
function videoModule.showVideo(isMuted)
    print("[videoModule] showVideo (disabled)")
end

return videoModule
