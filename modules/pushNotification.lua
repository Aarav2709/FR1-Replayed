-- pushNotification.lua — Local push notification scheduling
-- Reconstructed from decompiled pushNotification.lu.lua
-- Schedules 3-day, 7-day, and 30-day reminder notifications

local storyboard = require("modules.storyboard")
local database = storyboard.database

-- Try to load notifications plugin (may not be available in Simulator)
local notifications = nil
if system.getInfo("environment") ~= "simulator" then
    local ok, result = pcall(require, "plugin.notifications")
    if ok then notifications = result end
end

local pushNotification = {}

--------------------------------------------------------------------------------
-- Notification messages
--------------------------------------------------------------------------------

local threeDayMessages = {
    "Want to race?",
    "Miss the feel of sawblades?",
}

local sevenDayMessages = {
    "Haven't been struck by lightning in a while?",
    "You just got magneted back into this game!",
}

local thirtyDayMessages = {
    "Want more Fun Run in your life? Check out Fun Run 2!",
}

--------------------------------------------------------------------------------
-- Helper: get random message from table
--------------------------------------------------------------------------------

local function getRandomMessage(messageTable)
    local index = math.random(1, #messageTable)
    return messageTable[index]
end

--------------------------------------------------------------------------------
-- Helper: schedule a notification after given seconds
-- Only schedules if player exists and notifications are enabled
--------------------------------------------------------------------------------

local function scheduleNotification(seconds, messageTable)
    -- Check if player exists and notifications are enabled
    if not database then
        return
    end

    local playerInfo = database.getPlayerInformation()
    if not playerInfo then
        return
    end

    if database.getNotification() ~= 1 then
        return
    end

    local message = getRandomMessage(messageTable)

    local platformName = system.getInfo("platformName")

    if platformName == "Android" then
        -- Android uses system.scheduleNotification
        local options = {
            alert = message,
            badge = 1,
        }
        system.scheduleNotification(seconds, options)

    else
        -- iOS uses plugin.notifications
        if notifications then
            local options = {
                alert = message,
                badge = 1,
            }
            notifications.scheduleNotification(seconds, options)
        end
    end
end

--------------------------------------------------------------------------------
-- Queue 3-day notification (259200 seconds = 3 days)
--------------------------------------------------------------------------------

function pushNotification.queue3DayNotification()
    scheduleNotification(259200, threeDayMessages)
end

--------------------------------------------------------------------------------
-- Queue 7-day notification (604800 seconds = 7 days)
--------------------------------------------------------------------------------

function pushNotification.queue7DayNotification()
    scheduleNotification(604800, sevenDayMessages)
end

--------------------------------------------------------------------------------
-- Queue 30-day notification (2592000 seconds = 30 days)
--------------------------------------------------------------------------------

function pushNotification.queue30DayNotification()
    scheduleNotification(2592000, thirtyDayMessages)
end

--------------------------------------------------------------------------------
-- Clear all local push notifications
--------------------------------------------------------------------------------

function pushNotification.clearLocalPushNotificationQueue()
    local platformName = system.getInfo("platformName")

    if platformName == "Android" then
        system.cancelNotification()
    else
        if notifications then
            notifications.cancelNotification()
        end
    end
end

-- Store on storyboard for global access
storyboard.notification = pushNotification

return pushNotification
