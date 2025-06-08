-- utils/gameState.lua
-- Global Game State Manager

local M = {}

-- Player data
M.player = {
    id = nil,
    name = "Player",
    character = "fox",
    level = 1,
    coins = 0,
    wins = 0,
    losses = 0
}

-- Current race state
M.race = {
    isActive = false,
    players = {},
    powerUps = {},
    timeRemaining = 0,
    currentTrack = nil
}

-- Settings
M.settings = {
    musicVolume = 0.7,
    sfxVolume = 0.8,
    vibration = true,
    notifications = true
}

-- Network state
M.network = {
    isConnected = false,
    roomId = nil,
    playerId = nil
}

-- Save/Load functions
function M.save()
    local data = {
        player = M.player,
        settings = M.settings
    }
    local json = require("json")
    local path = system.pathForFile("gamedata.json", system.DocumentsDirectory)
    local file = io.open(path, "w")
    if file then
        file:write(json.encode(data))
        file:close()
    end
end

function M.load()
    local json = require("json")
    local path = system.pathForFile("gamedata.json", system.DocumentsDirectory)
    local file = io.open(path, "r")
    if file then
        local contents = file:read("*a")
        file:close()
        local data = json.decode(contents)
        if data then
            M.player = data.player or M.player
            M.settings = data.settings or M.settings
        end
    end
end

-- Initialize
M.load()

return M
