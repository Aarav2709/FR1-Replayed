-- httpClient.lua — HTTP client stub (offline)
-- Original servers are offline. This provides the expected API surface
-- with mock responses for local/offline play.

local json = require("json")
local storyboard = require("modules.storyboard")

local httpClient = {}

local receiveCallback = nil

function httpClient.initWithReceiveFunction(fn)
    receiveCallback = fn
end

function httpClient.getPlatformName()
    local platform = system.getInfo("platformName")
    if platform == "iPhone OS" then return 1
    elseif platform == "Android" then return 2
    else return 0
    end
end

-- Mock response helper
local function mockResponse(action, data)
    if receiveCallback then
        local response = data or {}
        response.action = action
        response.status = "ok"
        timer.performWithDelay(100, function()
            receiveCallback(response)
        end)
    end
end

function httpClient.createUser(email, username, password)
    print("[httpClient] createUser (offline stub): " .. tostring(username))
    mockResponse("createUser", {
        playerId = 1,
        username = username or "Player",
        token = "offline_token_" .. os.time(),
    })
end

function httpClient.createFacebookUser(username, facebookId, ...)
    print("[httpClient] createFacebookUser (offline stub)")
    mockResponse("createFacebookUser", {
        playerId = 1,
        username = username or "FBPlayer",
        token = "offline_fb_token_" .. os.time(),
    })
end

function httpClient.addUserInformation(...)
    print("[httpClient] addUserInformation (offline stub)")
    mockResponse("addUserInformation", {})
end

function httpClient.changeEmail(...)
    print("[httpClient] changeEmail (offline stub)")
    mockResponse("changeEmail", {})
end

function httpClient.changePassword(...)
    print("[httpClient] changePassword (offline stub)")
    mockResponse("changePassword", {})
end

function httpClient.loginUser(username, password, playerId, token, ...)
    print("[httpClient] loginUser (offline stub): " .. tostring(username))
    mockResponse("loginUser", {
        playerId = playerId or 1,
        username = username or "Player",
        token = token or "offline_token_" .. os.time(),
    })
end

function httpClient.addFacebookInformation(...)
    print("[httpClient] addFacebookInformation (offline stub)")
    mockResponse("addFacebookInformation", {})
end

function httpClient.loginFacebookUser(...)
    print("[httpClient] loginFacebookUser (offline stub)")
    mockResponse("loginFacebookUser", {
        playerId = 1,
        username = "FBPlayer",
        token = "offline_fb_token_" .. os.time(),
    })
end

function httpClient.forgotPassword(...)
    print("[httpClient] forgotPassword (offline stub)")
    mockResponse("forgotPassword", {})
end

return httpClient
