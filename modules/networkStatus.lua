-- networkStatus.lua — Network status checker
-- Checks WiFi vs mobile data connection status.

local storyboard = require("modules.storyboard")

local networkStatus = {}

function networkStatus.checkStatus()
    -- In offline/simulator mode, default to WiFi on
    local ok, result = pcall(function()
        return network.getConnectionStatus()
    end)

    if ok and result then
        if result.isConnected then
            storyboard.wifiOn = (result.connectionType == "wifi")
        else
            storyboard.wifiOn = false
        end
    else
        storyboard.wifiOn = true  -- Default to true in simulator
    end
end

return networkStatus
