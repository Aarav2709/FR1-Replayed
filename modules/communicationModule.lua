-- communicationModule.lua — Network coordination module (offline stub)
-- Wraps httpClient + tcpSocial. Original servers offline.
-- Provides expected API surface with offline-compatible behavior.

local storyboard = require("modules.storyboard")

local comm = {}

local callback = nil

function comm.setCallback(fn)
    callback = fn
end

-- Account functions (delegate to httpClient stubs)
function comm.createUser(email, username, password)
    local httpClient = storyboard.httpClient
    if httpClient then httpClient.createUser(email, username, password) end
end

function comm.createFacebookUser(username, facebookId, ...)
    local httpClient = storyboard.httpClient
    if httpClient then httpClient.createFacebookUser(username, facebookId, ...) end
end

function comm.addUserInformation(...)
    local httpClient = storyboard.httpClient
    if httpClient then httpClient.addUserInformation(...) end
end

function comm.changePassword(...)
    local httpClient = storyboard.httpClient
    if httpClient then httpClient.changePassword(...) end
end

function comm.changeEmail(...)
    local httpClient = storyboard.httpClient
    if httpClient then httpClient.changeEmail(...) end
end

function comm.loginUser(...)
    local httpClient = storyboard.httpClient
    if httpClient then httpClient.loginUser(...) end
end

function comm.addFacebookInformation(...)
    local httpClient = storyboard.httpClient
    if httpClient then httpClient.addFacebookInformation(...) end
end

function comm.loginFacebookUser(...)
    local httpClient = storyboard.httpClient
    if httpClient then httpClient.loginFacebookUser(...) end
end

function comm.forgotPassword(...)
    local httpClient = storyboard.httpClient
    if httpClient then httpClient.forgotPassword(...) end
end

-- Social TCP functions (stubs — servers offline)
function comm.startSocialTCP(callback)
    print("[comm] startSocialTCP (offline stub)")
    if callback then callback({ m = "l", a = 1 }) end
end

function comm.stopTCPSocial()
    local tcpSocial = storyboard.tcpSocial
    if tcpSocial then tcpSocial.closeTCP() end
end

function comm.getGameServerAddress(...)
    print("[comm] getGameServerAddress (offline stub)")
end

function comm.sendFriendRequest(...)
    print("[comm] sendFriendRequest (offline stub)")
end

function comm.deleteFriendRequest(...)
    print("[comm] deleteFriendRequest (offline stub)")
end

function comm.acceptFriendRequest(...)
    print("[comm] acceptFriendRequest (offline stub)")
end

function comm.getFriends()
    print("[comm] getFriends (offline stub)")
end

function comm.getOnlineFriends()
    print("[comm] getOnlineFriends (offline stub)")
end

function comm.repportPlayer(...)
    print("[comm] repportPlayer (offline stub)")
end

function comm.getRepports(...)
    print("[comm] getRepports (offline stub)")
end

function comm.rewardedVideo(...)
    print("[comm] rewardedVideo (offline stub)")
end

function comm.deleteFriend(...)
    print("[comm] deleteFriend (offline stub)")
end

function comm.sendGameInvite(...)
    print("[comm] sendGameInvite (offline stub)")
end

function comm.deleteGameInvite(...)
    print("[comm] deleteGameInvite (offline stub)")
end

function comm.acceptGameInvite(...)
    print("[comm] acceptGameInvite (offline stub)")
end

function comm.getTopList()
    print("[comm] getTopList (offline stub)")
end

function comm.getFriendList()
    print("[comm] getFriendList (offline stub)")
end

function comm.getWeeklyList()
    print("[comm] getWeeklyList (offline stub)")
end

function comm.getDaliyChallanges()
    print("[comm] getDaliyChallanges (offline stub)")
end

function comm.viewedWholeVideo(...)
    print("[comm] viewedWholeVideo (offline stub)")
end

function comm.getNumberOfNotifications()
    return 0
end

function comm.getMyItems()
    print("[comm] getMyItems (offline stub)")
end

function comm.buyItem(...)
    print("[comm] buyItem (offline stub)")
end

function comm.setAvatarData(...)
    print("[comm] setAvatarData (offline stub)")
end

function comm.addMoney(...)
    print("[comm] addMoney (offline stub)")
end

function comm.sendUnvalidatedReceipts()
    print("[comm] sendUnvalidatedReceipts (offline stub)")
end

function comm.getEarnCoins()
    print("[comm] getEarnCoins (offline stub)")
end

function comm.claimEarnCoins(data)
    print("[comm] claimEarnCoins (offline stub)")
end

return comm
