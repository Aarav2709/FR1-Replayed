-- local storage.

require("sqlite3")
local storyboard = require("modules.storyboard")

local database = {}

local DB_PATH = system.pathForFile("data.sqlite3", system.DocumentsDirectory)

local function freshCache()
  return { items = { {}, {}, {}, {} }, money = nil }
end
storyboard.databaseData = freshCache()

local function withDb(fn)
  local db = sqlite3.open(DB_PATH)
  local ok, result = pcall(fn, db)
  db:close()
  if not ok then
    error(result, 2)
  end
  return result
end

local function exec(sql)
  withDb(function(db) db:exec(sql) end)
end

local function selectValue(sql, column, default)
  return withDb(function(db)
    local value
    for row in db:nrows(sql) do
      value = row[column]
    end
    if value == nil then
      return default
    end
    return value
  end)
end

local function quote(s)
  return "'" .. tostring(s):gsub("'", "''") .. "'"
end

function database.setupTables()
  exec([[
    CREATE TABLE IF NOT EXISTS user_settings (id INTEGER PRIMARY KEY, username VARCHAR(15), playerId INTEGER, token VARCHAR(64));
    CREATE TABLE IF NOT EXISTS user_avatar (id INTEGER PRIMARY KEY, avatar INTEGER, hat INTEGER, item INTEGER, boots INTEGER);
    CREATE TABLE IF NOT EXISTS settings (id INTEGER PRIMARY KEY, sound INTEGER);
    CREATE TABLE IF NOT EXISTS rateApp (id INTEGER PRIMARY KEY, value INTEGER);
    CREATE TABLE IF NOT EXISTS createAccount (id INTEGER PRIMARY KEY, value INTEGER);
    CREATE TABLE IF NOT EXISTS funrunpopup (id INTEGER PRIMARY KEY, haveShown INTEGER);
    CREATE TABLE IF NOT EXISTS marketNotification (id INTEGER PRIMARY KEY, version INTEGER, number INTEGER);
    CREATE TABLE IF NOT EXISTS chat (id INTEGER PRIMARY KEY, state INTEGER);
    CREATE TABLE IF NOT EXISTS notifications (id INTEGER PRIMARY KEY, state INTEGER);
    CREATE TABLE IF NOT EXISTS statistics (id INTEGER PRIMARY KEY, value INTEGER);
    CREATE TABLE IF NOT EXISTS earnCoins (id INTEGER PRIMARY KEY, value INTEGER);
    CREATE TABLE IF NOT EXISTS languageSettings (id INTEGER PRIMARY KEY, value INTEGER);
  ]])
end

function database.setPlayerInformation(username, playerId, token)
  exec("INSERT OR REPLACE INTO user_settings VALUES(1, " .. quote(username) .. ", " ..
    tonumber(playerId) .. ", " .. quote(token) .. ");")
  storyboard.databaseData.playerInformation = nil
  storyboard.databaseData.playerInformation = database.getPlayerInformation()
end

function database.getPlayerInformation()
  if storyboard.databaseData.playerInformation then
    return storyboard.databaseData.playerInformation
  end
  local info = withDb(function(db)
    local result
    for row in db:nrows("SELECT playerId, username, token FROM user_settings;") do
      result = { playerId = row.playerId, username = row.username, token = row.token }
    end
    return result
  end)
  storyboard.databaseData.playerInformation = info
  return info
end

function database.setAvatarData(avatar)
  if avatar == "null" then
    exec("INSERT OR REPLACE INTO user_avatar VALUES(1,1,1,1,1);")
  else
    exec("INSERT OR REPLACE INTO user_avatar VALUES(1," .. avatar[1] .. ", " .. avatar[2] .. ", " ..
      avatar[3] .. ", " .. avatar[4] .. ");")
  end
  storyboard.databaseData.avatarData = avatar
end

function database.getAvatarData()
  if storyboard.databaseData.avatarData then
    return storyboard.databaseData.avatarData
  end
  local avatar = withDb(function(db)
    local result = {}
    for row in db:nrows("SELECT avatar, hat, item, boots FROM user_avatar;") do
      result = { row.avatar, row.hat, row.item, row.boots }
    end
    return result
  end)
  storyboard.databaseData.avatarData = avatar
  return avatar
end

function database.setItems(items)
  storyboard.databaseData.items = items
end

function database.getItems()
  return storyboard.databaseData.items
end

function database.addItem(category, itemId)
  local owned = storyboard.databaseData.items[category]
  owned[#owned + 1] = itemId
end

function database.increaseMoney(amount)
  storyboard.databaseData.money = storyboard.databaseData.money + amount
end

function database.decreaseMoney(amount)
  storyboard.databaseData.money = storyboard.databaseData.money - amount
end

function database.setMoney(amount)
  storyboard.databaseData.money = amount
end

function database.getMoney()
  return storyboard.databaseData.money or 0
end

local function cachedFlag(cacheKey, table_, column)
  if storyboard[cacheKey] == nil then
    storyboard[cacheKey] = selectValue("SELECT " .. column .. " FROM " .. table_ .. ";", column, 1)
  end
  return storyboard[cacheKey]
end

local function setFlag(cacheKey, table_, value)
  if value == 1 or value == 0 then
    exec("INSERT OR REPLACE INTO " .. table_ .. " VALUES(1, " .. value .. ");")
    storyboard[cacheKey] = value
  end
end

function database.setSound(on)
  setFlag("soundState", "settings", on)
end

function database.getSound()
  return cachedFlag("soundState", "settings", "sound")
end

function database.setNotification(on)
  setFlag("notificationState", "notifications", on)
end

function database.getNotification()
  return cachedFlag("notificationState", "notifications", "state")
end

function database.setChat(on)
  setFlag("chatState", "chat", on)
end

function database.getChat()
  return cachedFlag("chatState", "chat", "state")
end

function database.usePhoneLanguage(use)
  setFlag("languageSetting", "languageSettings", use and 1 or 0)
end

function database.usingPhoneLanguage()
  return cachedFlag("languageSetting", "languageSettings", "value") == 1
end

function database.haveShownFunRunPopup()
  exec("INSERT OR REPLACE INTO funrunpopup VALUES(1, 1);")
end

function database.shouldSownFunRunPopup()
  if database.getNumberOfGamesPlayed() < (storyboard.minGamesBeforeShowPopup or 10) then
    return false
  end
  return selectValue("SELECT haveShown FROM funrunpopup;", "haveShown", 0) == 0
end

function database.postponeRating()
  exec("INSERT OR REPLACE INTO rateApp VALUES(1, " .. os.time() .. ");")
end

function database.getLastRateAppTime()
  return selectValue("SELECT value FROM rateApp WHERE id = 1;", "value", 0)
end

function database.neverShowRateAppAgain()
  exec("INSERT OR REPLACE INTO rateApp VALUES(2, 1);")
end

function database.showRateApp()
  return selectValue("SELECT value FROM rateApp WHERE id = 2;", "value", 0) == 0
end

function database.showCreateAccountPopup()
  return selectValue("SELECT value FROM createAccount WHERE id = 1;", "value", 0) == 0
end

function database.neverShowCreateAccountPopup()
  exec("INSERT OR REPLACE INTO createAccount VALUES(1, 1);")
end

function database.getNumberOfGamesPlayed()
  return tonumber(selectValue("SELECT value FROM statistics WHERE id = 1;", "value", 0)) or 0
end

function database.setNumberOfGamesPlayed(count)
  exec("INSERT OR REPLACE INTO statistics VALUES(1, " .. tonumber(count) .. ");")
end

function database.incrementNumberOfGamesPlayed()
  database.setNumberOfGamesPlayed(database.getNumberOfGamesPlayed() + 1)
end

function database.getMarketNotification()
  if storyboard.databaseData.marketNotification then
    return storyboard.databaseData.marketNotification
  end
  local newItems = storyboard.config.newItems
  local stored = withDb(function(db)
    local result = { version = 0, number = 0 }
    for row in db:nrows("SELECT version, number FROM marketNotification;") do
      result = { version = row.version, number = row.number }
    end
    return result
  end)
  if stored.version ~= newItems.version then
    exec("INSERT OR REPLACE INTO marketNotification VALUES(1, " .. newItems.version .. ", " .. #newItems.items .. ");")
    storyboard.databaseData.marketNotification = { version = newItems.version, number = #newItems.items }
  else
    storyboard.databaseData.marketNotification = stored
  end
  return storyboard.databaseData.marketNotification
end

function database.resetMarketNotification()
  exec("UPDATE marketNotification SET number = 0;")
  if storyboard.databaseData.marketNotification then
    storyboard.databaseData.marketNotification.number = 0
  end
end

function database.setEarnCoins(list)
  if list == nil then
    return
  end
  withDb(function(db)
    db:exec("DELETE FROM earnCoins;")
    for _, entry in ipairs(list) do
      if entry.i and entry.c then
        db:exec("INSERT OR REPLACE INTO earnCoins VALUES(" .. tonumber(entry.i) .. ", " .. tonumber(entry.c) .. ");")
      end
    end
  end)
end

function database.getEarnCoins()
  return withDb(function(db)
    local list = {}
    for row in db:nrows("SELECT * FROM earnCoins;") do
      list[#list + 1] = { i = row.id, c = row.value }
    end
    return list
  end)
end

function database.hasClaimedEarnCoins(offerId, times)
  if not offerId then
    return
  end
  times = times or 1
  for _, entry in ipairs(database.getEarnCoins()) do
    if entry.i == offerId and entry.c and times <= entry.c then
      return true
    end
  end
  return false
end

function database.resetWithoutReceipts()
  storyboard.databaseData = freshCache()
  withDb(function(db)
    db:exec("DELETE FROM user_settings;")
    db:exec("DELETE FROM user_avatar;")
    db:exec("DELETE FROM earnCoins;")
    db:exec("DELETE FROM statistics;")
    db:exec("DELETE FROM funrunpopup;")
    db:exec("DELETE FROM createAccount;")
  end)
end

function database.reset()
  storyboard.gamesPlayed = 0
  storyboard.totalGamesPlayed = 0
  database.resetWithoutReceipts()
  return true
end

return database
