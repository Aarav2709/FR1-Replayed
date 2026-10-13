-- options that only exist on pc. fullscreen, window size and race keys.

local M = {}

local SIZES = { { 1280, 720 }, { 1600, 900 }, { 1920, 1080 } }
local DEFAULT_KEYS = { jump = "space", power = "x" }
local BLOCKED_KEYS = { escape = true, back = true, f11 = true, enter = true, numPadEnter = true }
local KEY_NAMES = {
  space = "Space", up = "Up", down = "Down", left = "Left", right = "Right",
  leftShift = "Left Shift", rightShift = "Right Shift", leftControl = "Left Ctrl", rightControl = "Right Ctrl",
  leftAlt = "Left Alt", rightAlt = "Right Alt", tab = "Tab", backspace = "Backspace",
}

local function getPreference(name, kind)
  local ok, value = pcall(system.getPreference, "app", name, kind)
  if ok then
    return value
  end
end

local function setPreference(name, value)
  pcall(system.setPreferences, "app", { [name] = value })
end

function M.getKey(action)
  local key = getPreference("key_" .. action, "string")
  if key == nil or key == "" then
    key = DEFAULT_KEYS[action]
  end
  return key
end

function M.canBind(keyName)
  return keyName ~= nil and keyName ~= "" and not BLOCKED_KEYS[keyName]
end

function M.setKey(action, keyName)
  if M.canBind(keyName) then
    setPreference("key_" .. action, keyName)
  end
end

function M.keyLabel(action)
  local key = M.getKey(action)
  return KEY_NAMES[key] or (#key == 1 and key:upper()) or key
end

function M.matchesKey(action, keyName)
  local key = M.getKey(action)
  if key == "space" then
    return keyName == "space" or keyName == "spacebar"
  end
  return keyName == key
end

function M.isFullscreen()
  local ok, mode = pcall(native.getProperty, "windowMode")
  return ok and mode == "fullscreen"
end

local function applySize()
  local size = SIZES[M.sizeIndex()]
  pcall(native.setProperty, "windowSize", { width = size[1], height = size[2] })
end

function M.toggleFullscreen()
  local fullscreen = not M.isFullscreen()
  pcall(native.setProperty, "windowMode", fullscreen and "fullscreen" or "normal")
  setPreference("fullscreen", fullscreen and 1 or 0)
  if not fullscreen then
    applySize()
  end
end

function M.sizeIndex()
  local saved = tonumber(getPreference("windowSizeIndex", "number")) or 1
  return math.max(1, math.min(saved, #SIZES))
end

function M.sizeLabel()
  local size = SIZES[M.sizeIndex()]
  return size[1] .. "x" .. size[2]
end

function M.cycleSize()
  setPreference("windowSizeIndex", M.sizeIndex() % #SIZES + 1)
  if not M.isFullscreen() then
    applySize()
  end
end

function M.apply()
  if getPreference("fullscreen", "number") == 0 then
    pcall(native.setProperty, "windowMode", "normal")
    applySize()
  end
end

return M
