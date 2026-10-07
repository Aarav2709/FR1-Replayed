-- translated strings.

local storyboard = require("modules.storyboard")

local localization = {}

local DEFAULT_LANGUAGE = "en"
local DEFAULT_FONT_SIZE = 18

local phoneLanguage = system.getPreference("ui", "language")
if isAndroid then
  phoneLanguage = system.getPreference("locale", "language")
end
if phoneLanguage == "zh-Hans" then
  phoneLanguage = "zh"
end

localization.translation = require("data.translations")

localization.properties = {
  en = { fontSize = 18 },
  ja = { fontSize = 16 },
  zh = { fontSize = 17 },
  ar = { fontSize = 15 },
  ko = { fontSize = 16 },
  es = { fontSize = 14 },
  fr = { fontSize = 15 },
  de = { fontSize = 15 },
}

function localization.updateLanguage()
  if localization.translation.test[phoneLanguage] ~= nil and storyboard.database.usingPhoneLanguage() then
    localization.language = phoneLanguage
  else
    localization.language = DEFAULT_LANGUAGE
  end
end

function localization.get(key)
  localization.updateLanguage()
  local entry = localization.translation[key]
  if entry ~= nil and entry[localization.language] ~= nil then
    return entry[localization.language]
  end
  return key
end

function localization.getFontSize()
  return localization.properties[localization.language].fontSize or DEFAULT_FONT_SIZE
end

return localization
