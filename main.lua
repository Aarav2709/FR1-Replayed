-- main.lua
-- Fun Run 1: Replayed - Main Entry Point

-- Hide status bar
display.setStatusBar(display.HiddenStatusBar)

-- Require composer for scene management
local composer = require("composer")

-- Load game configuration
local config = require("config.gameConfig")

-- Initialize global game state
_G.gameState = require("utils.gameState")

-- Set up global physics
local physics = require("physics")
physics.start()
physics.setGravity(0, 9.8)

-- Load first scene
composer.gotoScene("scenes.menu", "fade", 500)
