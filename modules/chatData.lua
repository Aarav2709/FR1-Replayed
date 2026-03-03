-- chatData.lua — Chat data module (offline stub)
local storyboard = require("modules.storyboard")
local chatData = {}

chatData.messages = {}

function chatData.getMessages(friendId)
    return {}
end

function chatData.addMessage(friendId, message, isSent)
    -- Offline stub
end

function chatData.clearMessages(friendId)
    chatData.messages = {}
end

return chatData
