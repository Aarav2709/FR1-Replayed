-- database.lua — SQLite database wrapper for local game data
-- Reconstructed from decompiled database.lu.lua

local sqlite3 = require("sqlite3")
local crypto = require("crypto")
local storyboard = require("modules.storyboard")

local dbPath = system.pathForFile("data.sqlite3", system.DocumentsDirectory)
local db = nil

-- Cached player info
local cachedPlayerInfo = nil

-- Module table
local database = {}

--------------------------------------------------------------------------------
-- Database Data (in-memory state stored on storyboard)
--------------------------------------------------------------------------------

storyboard.databaseData = {
    friends = {},
    friendRequests = {},
    items = { {}, {}, {}, {} },
    money = nil,
}

--------------------------------------------------------------------------------
-- Table setup
--------------------------------------------------------------------------------

function database.setupTables()
    db = sqlite3.open(dbPath)

    db:exec([[
        CREATE TABLE IF NOT EXISTS user_settings (
            id INTEGER PRIMARY KEY,
            username VARCHAR(15),
            playerId INTEGER,
            token VARCHAR(64)
        );
    ]])

    db:exec([[
        CREATE TABLE IF NOT EXISTS user_avatar (
            id INTEGER PRIMARY KEY,
            avatar INTEGER,
            hat INTEGER,
            item INTEGER,
            boots INTEGER
        );
    ]])

    db:exec([[
        CREATE TABLE IF NOT EXISTS receipts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            value TEXT,
            hash VARCHAR(16),
            productId VARCHAR(40)
        );
    ]])

    db:exec([[
        CREATE TABLE IF NOT EXISTS iap_confirm (
            id INTEGER PRIMARY KEY,
            value INTEGER
        );
    ]])

    db:exec([[
        CREATE TABLE IF NOT EXISTS settings (
            id INTEGER PRIMARY KEY,
            sound INTEGER
        );
    ]])

    db:exec([[
        CREATE TABLE IF NOT EXISTS deviceSync (
            id INTEGER PRIMARY KEY,
            value INTEGER
        );
    ]])

    db:exec([[
        CREATE TABLE IF NOT EXISTS facebook (
            id INTEGER PRIMARY KEY,
            facebookId INTEGER
        );
    ]])

    db:exec([[
        CREATE TABLE IF NOT EXISTS adTime (
            id INTEGER PRIMARY KEY,
            value INTEGER
        );
    ]])

    db:exec([[
        CREATE TABLE IF NOT EXISTS rateApp (
            id INTEGER PRIMARY KEY,
            value INTEGER
        );
    ]])

    db:exec([[
        CREATE TABLE IF NOT EXISTS createAccount (
            id INTEGER PRIMARY KEY,
            value INTEGER
        );
    ]])

    db:exec([[
        CREATE TABLE IF NOT EXISTS funrunpopup (
            id INTEGER PRIMARY KEY,
            haveShown INTEGER
        );
    ]])

    db:exec([[
        CREATE TABLE IF NOT EXISTS marketNotification (
            id INTEGER PRIMARY KEY,
            version INTEGER,
            number INTEGER
        );
    ]])

    db:exec([[
        CREATE TABLE IF NOT EXISTS chat (
            id INTEGER PRIMARY KEY,
            state INTEGER
        );
    ]])

    db:exec([[
        CREATE TABLE IF NOT EXISTS notifications (
            id INTEGER PRIMARY KEY,
            state INTEGER
        );
    ]])

    db:exec([[
        CREATE TABLE IF NOT EXISTS statistics (
            id INTEGER PRIMARY KEY,
            value INTEGER
        );
    ]])

    db:exec([[
        CREATE TABLE IF NOT EXISTS rewardedVideoTypeCounter (
            id INTEGER PRIMARY KEY,
            value INTEGER
        );
    ]])

    db:exec([[
        CREATE TABLE IF NOT EXISTS earnCoins (
            id INTEGER PRIMARY KEY,
            value INTEGER
        );
    ]])

    db:exec([[
        CREATE TABLE IF NOT EXISTS languageSettings (
            id INTEGER PRIMARY KEY,
            value INTEGER
        );
    ]])

    db:close()
    db = nil
end

--------------------------------------------------------------------------------
-- Player Information
--------------------------------------------------------------------------------

function database.setPlayerInformation(username, playerId, token)
    db = sqlite3.open(dbPath)
    db:exec("DELETE FROM user_settings;")
    local stmt = db:prepare("INSERT INTO user_settings (username, playerId, token) VALUES (?, ?, ?);")
    stmt:bind_values(username, playerId, token)
    stmt:step()
    stmt:finalize()
    db:close()
    db = nil
    -- Update cache
    cachedPlayerInfo = { username = username, id = playerId, token = token }
end

function database.getPlayerInformation()
    if cachedPlayerInfo then
        return cachedPlayerInfo
    end

    db = sqlite3.open(dbPath)
    local result = nil
    for row in db:nrows("SELECT username, playerId, token FROM user_settings LIMIT 1;") do
        result = { username = row.username, id = row.playerId, token = row.token }
    end
    db:close()
    db = nil

    cachedPlayerInfo = result
    return result
end

--------------------------------------------------------------------------------
-- Avatar Data
--------------------------------------------------------------------------------

function database.setAvatarData(avatarArray)
    -- avatarArray = { avatar, hat, item, boots }
    db = sqlite3.open(dbPath)
    db:exec("DELETE FROM user_avatar;")
    local stmt = db:prepare("INSERT INTO user_avatar (avatar, hat, item, boots) VALUES (?, ?, ?, ?);")
    stmt:bind_values(avatarArray[1], avatarArray[2], avatarArray[3], avatarArray[4])
    stmt:step()
    stmt:finalize()
    db:close()
    db = nil
end

function database.getAvatarData()
    db = sqlite3.open(dbPath)
    local result = nil
    for row in db:nrows("SELECT avatar, hat, item, boots FROM user_avatar LIMIT 1;") do
        result = { row.avatar, row.hat, row.item, row.boots }
    end
    db:close()
    db = nil
    return result
end

--------------------------------------------------------------------------------
-- Fun Run 2 Popup
--------------------------------------------------------------------------------

function database.haveShownFunRunPopup()
    db = sqlite3.open(dbPath)
    db:exec("DELETE FROM funrunpopup;")
    local stmt = db:prepare("INSERT INTO funrunpopup (haveShown) VALUES (?);")
    stmt:bind_values(1)
    stmt:step()
    stmt:finalize()
    db:close()
    db = nil
end

function database.shouldShowFunRunPopup()
    -- Only show if played at least 10 games
    local gamesPlayed = database.getNumberOfGamesPlayed()
    if gamesPlayed < 10 then
        return false
    end

    db = sqlite3.open(dbPath)
    local haveShown = false
    for row in db:nrows("SELECT haveShown FROM funrunpopup LIMIT 1;") do
        haveShown = (row.haveShown == 1)
    end
    db:close()
    db = nil

    return not haveShown
end

--------------------------------------------------------------------------------
-- Friends (in-memory)
--------------------------------------------------------------------------------

function database.addFriend(username, playerId)
    local friends = storyboard.databaseData.friends
    -- Check if already added
    for _, friend in pairs(friends) do
        if friend.id == playerId then
            return
        end
    end
    friends[#friends + 1] = { username = username, id = playerId }
end

function database.removeFriend(playerId)
    local friends = storyboard.databaseData.friends
    for i, friend in pairs(friends) do
        if friend.id == playerId then
            table.remove(friends, i)
            return
        end
    end
end

function database.getFriends()
    return storyboard.databaseData.friends
end

function database.getFriend(playerId)
    local friends = storyboard.databaseData.friends
    for _, friend in pairs(friends) do
        if friend.id == playerId then
            return friend
        end
    end
    return nil
end

function database.setFriends(friendsTable)
    storyboard.databaseData.friends = friendsTable
end

--------------------------------------------------------------------------------
-- Friend Requests (in-memory)
--------------------------------------------------------------------------------

function database.addFriendRequest(username, playerId)
    local requests = storyboard.databaseData.friendRequests
    -- Check if already added
    for _, req in pairs(requests) do
        if req.id == playerId then
            return
        end
    end
    requests[#requests + 1] = { username = username, id = playerId }
end

function database.deleteFriendRequest(playerId)
    local requests = storyboard.databaseData.friendRequests
    for i, req in pairs(requests) do
        if req.id == playerId then
            table.remove(requests, i)
            return
        end
    end
end

function database.getFriendRequests()
    return storyboard.databaseData.friendRequests
end

function database.setFriendRequests(requestsTable)
    storyboard.databaseData.friendRequests = requestsTable
end

function database.getNumberOfFriendRequests()
    local requests = storyboard.databaseData.friendRequests
    local count = 0
    for _ in pairs(requests) do
        count = count + 1
    end
    return count
end

--------------------------------------------------------------------------------
-- Game Invites
--------------------------------------------------------------------------------

function database.getNumberOfGameInvites()
    local invites = storyboard.gameInvites
    if invites == nil then
        return 0
    end
    local count = 0
    for _ in pairs(invites) do
        count = count + 1
    end
    return count
end

--------------------------------------------------------------------------------
-- Items (in-memory)
--------------------------------------------------------------------------------

function database.setItems(items)
    storyboard.databaseData.items = items
end

function database.getItems()
    return storyboard.databaseData.items
end

function database.addItem(category, item)
    local items = storyboard.databaseData.items
    if items[category] == nil then
        items[category] = {}
    end
    items[category][#items[category] + 1] = item
end

--------------------------------------------------------------------------------
-- Money (in-memory)
--------------------------------------------------------------------------------

function database.increaseMoney(amount)
    local currentMoney = storyboard.databaseData.money
    if currentMoney == nil then
        return
    end
    storyboard.databaseData.money = currentMoney + amount
    -- Track AdRally earn if available
    if storyboard.adRally then
        storyboard.adRally.logMoneyEarned(amount)
    end
end

function database.decreaseMoney(amount)
    local currentMoney = storyboard.databaseData.money
    if currentMoney == nil then
        return
    end
    storyboard.databaseData.money = currentMoney - amount
    -- Track AdRally spend if available
    if storyboard.adRally then
        storyboard.adRally.logMoneySpent(amount)
    end
end

function database.setMoney(amount)
    storyboard.databaseData.money = amount
end

function database.getMoney()
    return storyboard.databaseData.money
end

--------------------------------------------------------------------------------
-- Receipts (SQLite with MD5 deduplication)
--------------------------------------------------------------------------------

function database.addReceipt(value, productId)
    local hash = crypto.digest(crypto.md5, value)
    hash = string.sub(hash, 1, 16)

    db = sqlite3.open(dbPath)

    -- Check for duplicate hash
    local exists = false
    for row in db:nrows("SELECT hash FROM receipts WHERE hash = '" .. hash .. "' LIMIT 1;") do
        exists = true
    end

    if not exists then
        local stmt = db:prepare("INSERT INTO receipts (value, hash, productId) VALUES (?, ?, ?);")
        stmt:bind_values(value, hash, productId)
        stmt:step()
        stmt:finalize()
    end

    db:close()
    db = nil
end

function database.removeReceipt(value)
    db = sqlite3.open(dbPath)
    db:exec("DELETE FROM receipts WHERE value = '" .. value .. "';")
    db:close()
    db = nil
end

function database.removeReceiptByHash(hash)
    db = sqlite3.open(dbPath)
    db:exec("DELETE FROM receipts WHERE hash = '" .. hash .. "';")
    db:close()
    db = nil
end

function database.getReceipts()
    db = sqlite3.open(dbPath)
    local receipts = {}
    for row in db:nrows("SELECT value, hash, productId FROM receipts;") do
        receipts[#receipts + 1] = { value = row.value, hash = row.hash, productId = row.productId }
    end
    db:close()
    db = nil
    return receipts
end

--------------------------------------------------------------------------------
-- IAP Social Server Confirmation
--------------------------------------------------------------------------------

function database.addIAPSocialServerConfirm()
    db = sqlite3.open(dbPath)
    db:exec("DELETE FROM iap_confirm;")
    local stmt = db:prepare("INSERT INTO iap_confirm (value) VALUES (?);")
    stmt:bind_values(1)
    stmt:step()
    stmt:finalize()
    db:close()
    db = nil
end

function database.hasIAPSocialServerConfirm()
    db = sqlite3.open(dbPath)
    local hasConfirm = false
    for row in db:nrows("SELECT value FROM iap_confirm LIMIT 1;") do
        hasConfirm = (row.value == 1)
    end
    db:close()
    db = nil
    return hasConfirm
end

function database.removeIAPSocialServerConfirm()
    db = sqlite3.open(dbPath)
    db:exec("DELETE FROM iap_confirm;")
    db:close()
    db = nil
end

--------------------------------------------------------------------------------
-- Notifications Setting
--------------------------------------------------------------------------------

function database.setNotification(value)
    -- value: 0 = disabled, 1 = enabled
    db = sqlite3.open(dbPath)
    db:exec("DELETE FROM notifications;")
    local stmt = db:prepare("INSERT INTO notifications (state) VALUES (?);")
    stmt:bind_values(value)
    stmt:step()
    stmt:finalize()
    db:close()
    db = nil
end

function database.getNotification()
    db = sqlite3.open(dbPath)
    local state = 1 -- default enabled
    for row in db:nrows("SELECT state FROM notifications LIMIT 1;") do
        state = row.state
    end
    db:close()
    db = nil
    return state
end

--------------------------------------------------------------------------------
-- Chat Setting
--------------------------------------------------------------------------------

function database.setChat(value)
    -- value: 0 = disabled, 1 = enabled
    db = sqlite3.open(dbPath)
    db:exec("DELETE FROM chat;")
    local stmt = db:prepare("INSERT INTO chat (state) VALUES (?);")
    stmt:bind_values(value)
    stmt:step()
    stmt:finalize()
    db:close()
    db = nil
end

function database.getChat()
    db = sqlite3.open(dbPath)
    local state = 1 -- default enabled
    for row in db:nrows("SELECT state FROM chat LIMIT 1;") do
        state = row.state
    end
    db:close()
    db = nil
    return state
end

--------------------------------------------------------------------------------
-- Rewarded Video Type Counter
--------------------------------------------------------------------------------

function database.setRewardedVideoTypeCounter(id, value)
    db = sqlite3.open(dbPath)
    -- Delete existing entry with this id
    db:exec("DELETE FROM rewardedVideoTypeCounter WHERE id = " .. id .. ";")
    local stmt = db:prepare("INSERT INTO rewardedVideoTypeCounter (id, value) VALUES (?, ?);")
    stmt:bind_values(id, value)
    stmt:step()
    stmt:finalize()
    db:close()
    db = nil
end

function database.getRewardedVideoTypeCounter(id)
    db = sqlite3.open(dbPath)
    local value = 0
    for row in db:nrows("SELECT value FROM rewardedVideoTypeCounter WHERE id = " .. id .. " LIMIT 1;") do
        value = row.value
    end
    db:close()
    db = nil
    return value
end

--------------------------------------------------------------------------------
-- Sound Setting
--------------------------------------------------------------------------------

function database.setSound(value)
    -- value: 0 = off, 1 = on
    db = sqlite3.open(dbPath)
    db:exec("DELETE FROM settings;")
    local stmt = db:prepare("INSERT INTO settings (sound) VALUES (?);")
    stmt:bind_values(value)
    stmt:step()
    stmt:finalize()
    db:close()
    db = nil
end

function database.getSound()
    db = sqlite3.open(dbPath)
    local sound = 1 -- default on
    for row in db:nrows("SELECT sound FROM settings LIMIT 1;") do
        sound = row.sound
    end
    db:close()
    db = nil
    return sound
end

--------------------------------------------------------------------------------
-- Language Settings
--------------------------------------------------------------------------------

function database.usePhoneLanguage(useBool)
    db = sqlite3.open(dbPath)
    db:exec("DELETE FROM languageSettings;")
    local value = 0
    if useBool then
        value = 1
    end
    local stmt = db:prepare("INSERT INTO languageSettings (value) VALUES (?);")
    stmt:bind_values(value)
    stmt:step()
    stmt:finalize()
    db:close()
    db = nil
end

function database.usingPhoneLanguage()
    db = sqlite3.open(dbPath)
    local value = 1 -- default true (use phone language)
    for row in db:nrows("SELECT value FROM languageSettings LIMIT 1;") do
        value = row.value
    end
    db:close()
    db = nil
    return value == 1
end

--------------------------------------------------------------------------------
-- Device Sync State
--------------------------------------------------------------------------------

function database.setDeviceSyncState(value)
    -- value: 1 = syncing, 2 = synced
    db = sqlite3.open(dbPath)
    db:exec("DELETE FROM deviceSync;")
    local stmt = db:prepare("INSERT INTO deviceSync (value) VALUES (?);")
    stmt:bind_values(value)
    stmt:step()
    stmt:finalize()
    db:close()
    db = nil
end

function database.getDeviceSyncState()
    db = sqlite3.open(dbPath)
    local value = 0 -- default none
    for row in db:nrows("SELECT value FROM deviceSync LIMIT 1;") do
        value = row.value
    end
    db:close()
    db = nil
    return value
end

--------------------------------------------------------------------------------
-- Ad Time Tracking
--------------------------------------------------------------------------------

function database.usedAds()
    local currentTime = os.time()
    db = sqlite3.open(dbPath)
    db:exec("DELETE FROM adTime;")
    local stmt = db:prepare("INSERT INTO adTime (value) VALUES (?);")
    stmt:bind_values(currentTime)
    stmt:step()
    stmt:finalize()
    db:close()
    db = nil
end

function database.getLastTimeAds()
    db = sqlite3.open(dbPath)
    local value = 0
    for row in db:nrows("SELECT value FROM adTime LIMIT 1;") do
        value = row.value
    end
    db:close()
    db = nil
    return value
end

--------------------------------------------------------------------------------
-- Rate App
--------------------------------------------------------------------------------

function database.postponeRating()
    local currentTime = os.time()
    db = sqlite3.open(dbPath)
    db:exec("DELETE FROM rateApp;")
    local stmt = db:prepare("INSERT INTO rateApp (value) VALUES (?);")
    stmt:bind_values(currentTime)
    stmt:step()
    stmt:finalize()
    db:close()
    db = nil
end

function database.getLastRateAppTime()
    db = sqlite3.open(dbPath)
    local value = 0
    for row in db:nrows("SELECT value FROM rateApp LIMIT 1;") do
        value = row.value
    end
    db:close()
    db = nil
    return value
end

function database.neverShowRateAppAgain()
    db = sqlite3.open(dbPath)
    db:exec("DELETE FROM rateApp;")
    local stmt = db:prepare("INSERT INTO rateApp (value) VALUES (?);")
    stmt:bind_values(-1)
    stmt:step()
    stmt:finalize()
    db:close()
    db = nil
end

function database.showRateApp()
    local lastTime = database.getLastRateAppTime()
    if lastTime == -1 then
        return false
    end
    if lastTime == 0 then
        return true
    end
    local currentTime = os.time()
    local diff = currentTime - lastTime
    -- Show again after ~3 days (259200 seconds)
    return diff > 259200
end

--------------------------------------------------------------------------------
-- Create Account Popup
--------------------------------------------------------------------------------

function database.showCreateAccountPopup()
    db = sqlite3.open(dbPath)
    local value = 0
    for row in db:nrows("SELECT value FROM createAccount LIMIT 1;") do
        value = row.value
    end
    db:close()
    db = nil
    return value ~= -1
end

function database.neverShowCreateAccountPopup()
    db = sqlite3.open(dbPath)
    db:exec("DELETE FROM createAccount;")
    local stmt = db:prepare("INSERT INTO createAccount (value) VALUES (?);")
    stmt:bind_values(-1)
    stmt:step()
    stmt:finalize()
    db:close()
    db = nil
end

--------------------------------------------------------------------------------
-- Statistics (Games Played)
--------------------------------------------------------------------------------

function database.getNumberOfGamesPlayed()
    db = sqlite3.open(dbPath)
    local value = 0
    for row in db:nrows("SELECT value FROM statistics LIMIT 1;") do
        value = row.value
    end
    db:close()
    db = nil
    return value
end

function database.incrementNumberOfGamesPlayed()
    local current = database.getNumberOfGamesPlayed()
    database.setNumberOfGamesPlayed(current + 1)
end

function database.setNumberOfGamesPlayed(numGames)
    db = sqlite3.open(dbPath)
    db:exec("DELETE FROM statistics;")
    local stmt = db:prepare("INSERT INTO statistics (value) VALUES (?);")
    stmt:bind_values(numGames)
    stmt:step()
    stmt:finalize()
    db:close()
    db = nil
end

--------------------------------------------------------------------------------
-- Facebook ID
--------------------------------------------------------------------------------

function database.setFacebookId(facebookId)
    db = sqlite3.open(dbPath)
    db:exec("DELETE FROM facebook;")
    local stmt = db:prepare("INSERT INTO facebook (facebookId) VALUES (?);")
    stmt:bind_values(facebookId)
    stmt:step()
    stmt:finalize()
    db:close()
    db = nil
end

function database.getFacebookId()
    db = sqlite3.open(dbPath)
    local facebookId = nil
    for row in db:nrows("SELECT facebookId FROM facebook LIMIT 1;") do
        facebookId = row.facebookId
    end
    db:close()
    db = nil
    return facebookId
end

--------------------------------------------------------------------------------
-- Market Notification
--------------------------------------------------------------------------------

function database.getMarketNotification()
    db = sqlite3.open(dbPath)
    local result = { version = 0, number = 0 }
    for row in db:nrows("SELECT version, number FROM marketNotification LIMIT 1;") do
        result = { version = row.version, number = row.number }
    end
    db:close()
    db = nil
    return result
end

function database.resetMarketNotification()
    local currentVersion = tonumber(system.getInfo("appVersionString")) or 0
    db = sqlite3.open(dbPath)
    db:exec("DELETE FROM marketNotification;")
    local stmt = db:prepare("INSERT INTO marketNotification (version, number) VALUES (?, ?);")
    stmt:bind_values(currentVersion, 0)
    stmt:step()
    stmt:finalize()
    db:close()
    db = nil
end

--------------------------------------------------------------------------------
-- Earn Coins
--------------------------------------------------------------------------------

function database.setEarnCoins(coinList)
    -- coinList = array of { i = id, c = coins }
    db = sqlite3.open(dbPath)
    db:exec("DELETE FROM earnCoins;")
    if coinList then
        for _, entry in ipairs(coinList) do
            local value = entry.i .. "," .. entry.c
            local stmt = db:prepare("INSERT INTO earnCoins (value) VALUES (?);")
            stmt:bind_values(value)
            stmt:step()
            stmt:finalize()
        end
    end
    db:close()
    db = nil
end

function database.getEarnCoins()
    db = sqlite3.open(dbPath)
    local coins = {}
    for row in db:nrows("SELECT value FROM earnCoins;") do
        local parts = {}
        for part in string.gmatch(row.value, "[^,]+") do
            parts[#parts + 1] = tonumber(part)
        end
        if #parts == 2 then
            coins[#coins + 1] = { i = parts[1], c = parts[2] }
        end
    end
    db:close()
    db = nil
    return coins
end

function database.hasClaimedEarnCoins(id, amount)
    local coins = database.getEarnCoins()
    for _, entry in ipairs(coins) do
        if entry.i and entry.c then
            if entry.i == id then
                if amount <= entry.c then
                    return true
                end
            end
        end
    end
    return false
end

--------------------------------------------------------------------------------
-- Reset (full reset including receipts)
--------------------------------------------------------------------------------

function database.reset()
    local receipts = database.getReceipts()
    local receiptCount = 0
    for _ in pairs(receipts) do
        receiptCount = receiptCount + 1
    end

    -- Reset in-memory data
    storyboard.gamesPlayed = 0
    storyboard.totalGamesPlayed = 0

    if receiptCount > 0 then
        return false
    else
        storyboard.databaseData = {
            friends = {},
            friendRequests = {},
            items = { {}, {}, {}, {} },
            money = nil,
        }

        db = sqlite3.open(dbPath)
        db:exec("DELETE FROM user_settings;")
        db:exec("DELETE FROM facebook;")
        db:exec("DELETE FROM user_avatar;")
        db:exec("DELETE FROM receipts;")
        db:exec("DELETE FROM statistics;")
        db:exec("DELETE FROM earnCoins;")
        db:exec("DELETE FROM funrunpopup;")
        db:exec("DELETE FROM createAccount;")
        db:close()
        db = nil

        return true
    end
end

--------------------------------------------------------------------------------
-- Reset Without Receipts (keeps receipts intact)
--------------------------------------------------------------------------------

function database.resetWithoutReceipts()
    storyboard.databaseData = {
        friends = {},
        friendRequests = {},
        items = { {}, {}, {}, {} },
        money = nil,
    }

    db = sqlite3.open(dbPath)
    db:exec("DELETE FROM user_settings;")
    db:exec("DELETE FROM facebook;")
    db:exec("DELETE FROM user_avatar;")
    db:exec("DELETE FROM earnCoins;")
    db:exec("DELETE FROM statistics;")
    db:exec("DELETE FROM funrunpopup;")
    db:exec("DELETE FROM createAccount;")
    db:close()
    db = nil
end

--------------------------------------------------------------------------------
-- Assign to storyboard and return
--------------------------------------------------------------------------------

storyboard.database = database
return database
