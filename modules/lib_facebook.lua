-- lib_facebook.lua — Facebook SDK wrapper (offline stub)
-- Facebook integration disabled for rebuilt version.

local facebook = {}

facebook.FB_App_ID = "_UNDEFINED_"
facebook.FB_Access_Token = nil
facebook.isDebug = false

function facebook.isLoggedIn()
    return false
end

function facebook.login(params)
    print("[lib_facebook] login (offline stub)")
end

function facebook.request(path, params, ...)
    print("[lib_facebook] request (offline stub)")
end

function facebook.showDialog(params)
    print("[lib_facebook] showDialog (offline stub)")
end

function facebook.logout()
    print("[lib_facebook] logout (offline stub)")
    facebook.FB_Access_Token = nil
end

return facebook
