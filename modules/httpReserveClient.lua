-- httpReserveClient.lua — HTTP reserve/fallback client (offline stub)
-- Original servers are offline. This provides the expected API surface.

local storyboard = require("modules.storyboard")

local httpReserveClient = {}

function httpReserveClient.checkStatus(callback)
    print("[httpReserveClient] checkStatus (offline stub)")
    if callback then
        timer.performWithDelay(100, function()
            callback({ status = "ok" })
        end)
    end
end

return httpReserveClient
