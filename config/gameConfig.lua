-- config/gameConfig.lua
-- Game Configuration and Constants

local M = {}

-- Display settings
M.CONTENT_WIDTH = 1024
M.CONTENT_HEIGHT = 768

-- Game settings
M.MAX_PLAYERS = 4
M.RACE_DURATION = 60 -- seconds
M.POWER_UP_SPAWN_RATE = 0.3 -- per second

-- Physics settings
M.GRAVITY = 9.8
M.PLAYER_SPEED = 200
M.JUMP_FORCE = -400

-- Network settings
M.SERVER_URL = "ws://localhost:8080"
M.RECONNECT_ATTEMPTS = 3

-- Audio settings
M.MUSIC_VOLUME = 0.7
M.SFX_VOLUME = 0.8

-- Character settings
M.CHARACTERS = {
    "fox",
    "lizard", 
    "rabbit",
    "squirrel"
}

-- Power-ups
M.POWERUPS = {
    "speed_boost",
    "shield",
    "lightning",
    "magnet",
    "bomb",
    "spring"
}

-- Track themes
M.THEMES = {
    "forest",
    "cave",
    "ice",
    "volcano"
}

return M
