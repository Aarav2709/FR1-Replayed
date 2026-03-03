-- localization.lua — Multi-language localization system
-- Reconstructed from decompiled localization.lu.lua
-- Supports: en, ja, zh, ar, ko, es, fr, de

local storyboard = require("modules.storyboard")
local database = storyboard.database

local localization = {}

-- Current language code
localization.language = "en"

-- Default font size
localization.defaultFontSize = 18

-- Per-language font sizes
local fontSizes = {
    en = 18,
    ja = 16,
    zh = 17,
    ar = 15,
    ko = 16,
    es = 14,
    fr = 15,
    de = 15,
}

--------------------------------------------------------------------------------
-- Translation table — key → { en = "...", ja = "...", zh = "...", ... }
-- NOTE: Non-Latin strings are stored as UTF-8 encoded string literals.
-- For brevity, only English values are included inline. The full translation
-- table with all 8 languages should be populated from the original game data.
--------------------------------------------------------------------------------

localization.translation = {
    -- Account & Settings
    ["SaveYourProgress"]        = { en = "Save your progress" },
    ["AreYouSure"]              = { en = "Are you sure?" },
    ["ValidPassword"]           = { en = "Valid password" },
    ["CurrentPassword"]         = { en = "Current password" },
    ["Language"]                = { en = "Language" },
    ["Phone"]                   = { en = "Phone" },
    ["SetPassword"]             = { en = "Set password" },
    ["SetEmail"]                = { en = "Set email" },
    ["PasswordSettingsInfo"]    = { en = "You can set a password to secure your account. Passwords need to be at least 6 characters long." },
    ["EmailSettingsInfo"]       = { en = "You will be able to use this email to retrieve your password." },
    ["AccountSettingsInfo"]     = { en = "You can set an email and a password in case you lose your phone or want to move to a new device." },
    ["GeneralSettings"]         = { en = "General Settings" },
    ["Help"]                    = { en = "Help" },
    ["AccountSettings"]         = { en = "Account Settings" },
    ["NewEmail"]                = { en = "New email" },
    ["NewPassword"]             = { en = "New password" },
    ["OldPassword"]             = { en = "Password" },
    ["Password"]                = { en = "Password" },
    ["Password too short. "]    = { en = "Password too short. " },

    -- Gameplay
    ["DoyouloveFunRun?"]        = { en = "Do you love Fun Run?" },
    ["WantToRateGame"]          = { en = "Want to rate the game?" },
    ["PlayerDisconnected"]      = { en = "Player disconnected" },
    ["JoinedGame"]              = { en = "Joined game" },
    ["LeftGame"]                = { en = "Left game" },
    ["SelectedMap"]             = { en = "Selected map" },
    ["#YOLO"]                   = { en = "#YOLO" },
    ["OptionalMessage"]         = { en = "Optional message" },

    -- Placement
    ["1st"]                     = { en = "1st" },
    ["2nd"]                     = { en = "2nd" },
    ["3rd"]                     = { en = "3rd" },
    ["4th"]                     = { en = "4th" },

    -- Miscellaneous
    ["DirtybitGame"]            = { en = "A Dirtybit Game" },
    ["NewerVersion"]            = { en = "Newer version" },

    -- Power-up descriptions
    ["HeartDesc"]               = { en = "Absorbs one hit" },
    ["TrapDesc"]                = { en = "Behead opponents" },
    ["ShieldDesc"]              = { en = "Invincible for 6 sec" },
    ["MagnetDesc"]              = { en = "Pull others towards you" },
    ["BoxDesc"]                 = { en = "Punch-in-a-box" },
    ["BoostDesc"]               = { en = "Speed boost" },
    ["LightningDesc"]           = { en = "Shock enemies" },
    ["NinjaSwordDesc"]          = { en = "Target one" },
    ["SawbladeDesc"]            = { en = "Throw a sawblade" },
    ["JumpBoostDesc"]           = { en = "Jump high" },

    -- Power-ups
    ["Heart"]                   = { en = "Heart" },
    ["Sawblade"]                = { en = "Sawblade" },
    ["Lightning"]               = { en = "Lightning" },
    ["Magnet"]                  = { en = "Magnet" },
    ["Shield"]                  = { en = "Shield" },
    ["Trap"]                    = { en = "Trap" },
    ["Boost"]                   = { en = "Boost" },
    ["Box"]                     = { en = "Box" },
    ["NinjaSword"]              = { en = "Ninja Sword" },
    ["JumpBoost"]               = { en = "Jump Boost" },
    ["PowerUps"]                = { en = "Power Ups" },
    ["PowerUpButton"]           = { en = "Power Up Button" },
    ["JumpButton"]              = { en = "Jump Button" },

    -- Social
    ["AddFriend"]               = { en = "Add friend" },
    ["AddFriends"]              = { en = "Add Friends" },
    ["AddInformation"]          = { en = "Add Information" },
    ["InviteFriends"]           = { en = "Invite Friends" },
    ["Friends"]                 = { en = "Friends" },
    ["PlayWithFriends"]         = { en = "Play with friends" },
    ["PlayWithRandomPeople"]    = { en = "Play with random people" },

    -- UI/Menu labels
    ["Cancel"]                  = { en = "Cancel" },
    ["Challenges"]              = { en = "Challenges" },
    ["Chat"]                    = { en = "Chat" },
    ["ComingSoon"]              = { en = "Coming soon" },
    ["ConnectTo"]               = { en = "Connect to" },
    ["Credits"]                 = { en = "Credits" },
    ["Customize"]               = { en = "Customize" },
    ["Email"]                   = { en = "Email" },
    ["Error"]                   = { en = "Error" },
    ["ForgotPassword"]          = { en = "Forgot password" },
    ["Games"]                   = { en = "Games" },
    ["GetMore"]                 = { en = "Get more" },
    ["Go"]                      = { en = "GO!" },
    ["Join"]                    = { en = "Join" },
    ["Loading"]                 = { en = "Loading" },
    ["Login"]                   = { en = "Log in" },
    ["LogOut"]                  = { en = "Log Out" },
    ["LoggingOut"]              = { en = "Logging out" },
    ["MainMenu"]                = { en = "Main Menu" },
    ["Maps"]                    = { en = "Maps" },
    ["No"]                      = { en = "No" },
    ["Notice"]                  = { en = "Notice" },
    ["Ok"]                      = { en = "Ok" },
    ["OKCool"]                  = { en = "Ok, cool!" },
    ["Optional"]                = { en = "Optional" },
    ["PlayMenu"]                = { en = "Play Menu" },
    ["Practice"]                = { en = "Practice" },
    ["Purchasing"]              = { en = "Purchasing..." },
    ["QuickPlay"]               = { en = "Quick Play" },
    ["Quit"]                    = { en = "Quit" },
    ["Rating"]                  = { en = "Rating  " },
    ["Register"]                = { en = "Create User" },
    ["Results"]                 = { en = "Results" },
    ["Save"]                    = { en = "Save" },
    ["Searching"]               = { en = "Searching" },
    ["SearchingForGame"]        = { en = "Searching for game..." },
    ["SelectNumberOfCoins"]     = { en = "Select number of coins" },
    ["Send"]                    = { en = "Send" },
    ["ServerMessage"]           = { en = "Server message" },
    ["Start"]                   = { en = "Start" },
    ["Top50"]                   = { en = "Top 50" },
    ["Tutorial"]                = { en = "Tutorial" },
    ["Use"]                     = { en = "Use" },
    ["Username"]                = { en = "Username" },
    ["VerifyingPurchase"]       = { en = "Verifying purchase..." },
    ["Vote"]                    = { en = "Vote" },
    ["Yes"]                     = { en = "Yes" },

    -- Errors & Messages
    ["ConnectedWithFacebook"]      = { en = "Connected with Facebook" },
    ["ConnectingToFaceBook"]       = { en = "Connecting to Facebook" },
    ["Could not access Facebook"]  = { en = "Could not access Facebook" },
    ["CouldNotConnect"]            = { en = "Could not connect" },
    ["FacebookNoInformation"]      = { en = "Facebook could not give information about your friends" },
    ["CouldNotGetTop50"]           = { en = "Could not get Top 50" },
    ["CouldNotJoin"]               = { en = "Could not join" },
    ["FacebookCouldNotLogin"]      = { en = "Facebook login failed" },
    ["CreatingGame"]               = { en = "Creating game..." },
    ["Disconnected"]               = { en = "Disconnected" },
    ["QuitGame"]                   = { en = "Do you want to quit?" },
    ["QuitGameWithWarning"]        = { en = "Do you want to quit? You will lose rating if you quit before reaching the goal." },
    ["EndingGameOtherPlayersLeft"] = { en = "Other players left" },
    ["EnterEmail"]                 = { en = "Enter email" },
    ["ErrorCantBuyItem"]           = { en = "Error. Please try again later" },
    ["ErrorTryLater"]              = { en = "Error. Please try again later" },
    ["ErrorNoPlayers"]             = { en = "No players found. Please try again later" },
    ["ErrorServerBusy"]            = { en = "Server is busy. Please try again" },
    ["ErrorServerIsDown"]          = { en = "Server is currently down. Please try again later" },
    ["Facebook already in use"]    = { en = "Facebook already in use" },
    ["GameClosed"]                 = { en = "Game closed" },
    ["GameInvites"]                = { en = "Game invites" },
    ["GameFull"]                   = { en = "Game full" },
    ["GameNotAvailable"]           = { en = "Game not available" },
    ["GameStarting"]               = { en = "Game starting" },
    ["GameStartingChat"]           = { en = "Game starting..." },
    ["HostLeft"]                   = { en = "Host left" },
    ["InGame"]                     = { en = "In game" },
    ["InAppNotSupported"]          = { en = "In-app purchase not supported on this device" },
    ["StartToBegin"]               = { en = "Press Start to begin" },
    ["Invalid email"]              = { en = "Invalid email" },
    ["Invalid login token"]        = { en = "Invalid login token" },
    ["Invalid purchase"]           = { en = "Invalid purchase" },
    ["Invalid request"]            = { en = "Invalid request" },
    ["Invalid username"]           = { en = "Invalid username" },
    ["LoadingGame"]                = { en = "Loading game" },
    ["MissingMoney"]               = { en = "Missing money" },
    ["NetworkError"]               = { en = "Network error" },
    ["NewChallenges"]              = { en = "New challenges in:" },
    ["NotAvailable"]               = { en = "Not Avail." },
    ["NotConnected"]               = { en = "Not connected" },
    ["NotEnoughCoins"]             = { en = "Not enough coins, buy more" },
    ["NoVideoAvailable"]           = { en = "No video available, please try again later" },
    ["OldVersion"]                 = { en = "Old version" },
    ["PleaseUpdateApp"]            = { en = "Please update your app to the newest version." },
    ["PurchasesNotAvailable"]      = { en = "Store purchases are not available, please try again later" },
    ["PurchaseFailed"]             = { en = "Purchase failed, type: " },
    ["CancelledByUser"]            = { en = "Purchase cancelled by user" },
    ["WaitingForPlayers"]          = { en = "Waiting for other players" },
    ["LostConnection"]             = { en = "You have lost the connection. Press the ok button to return to the menu." },
    ["YouSuspended"]               = { en = "You suspended the app and closed the connection." },
    ["DidNotMove"]                 = { en = "You did not move for 15 seconds." },
    ["You are logged in on another device, please log out"] = { en = "You are logged in on another device, please log out" },
    ["AccountDevice"]              = { en = "Your account has been used on another device. Log in again to sync your data." },
    ["UnknownError"]               = { en = "Unknown error" },
    ["wrong username or password"] = { en = "wrong username or password" },
    ["Wrong email"]                = { en = "Wrong email" },
    ["Wrong token, please contact us"] = { en = "Wrong token, please contact us" },

    -- Validation messages
    ["UsernameAndPassword"]        = { en = "Please enter email and password" },
    ["EnterPassword"]              = { en = "Please enter password" },
    ["EnterUsername"]               = { en = "Please enter username" },
    ["ValidUsernameAndPassword"]   = { en = "Please enter valid email AND password" },
    ["PleaseEnterEmail"]           = { en = "Please enter your email" },
    ["GoToMarketToSync"]           = { en = "Please go to market to sync your money, requires internet" },
    ["ValidCharacterMessage"]      = { en = "Username can only contain a-z and 0-9" },
    ["UsernameTooShort"]           = { en = "Username is too short" },
    ["Username too long. "]        = { en = "Username too long. " },
    ["Username too short. "]       = { en = "Username too short. " },
    ["PresentUsername"]             = { en = "Username:" },
    ["EmailTooShort"]              = { en = "The email is too short" },
    ["This email is already in use."]           = { en = "This email is already in use." },
    ["This user doesn't exist. Please contact us"] = { en = "This user doesn't exist. Please contact us" },
    ["This username is taken."]    = { en = "This username is taken." },
    ["CheckEmail"]                 = { en = "Thank you, please check your email" },

    -- Facebook
    ["FacebookCanLogIn"]           = { en = "You can now login with Facebook." },
    ["Please register an account without facebook. You can connect later."] = { en = "Please register an account without facebook. You can connect later." },

    -- Earn / Purchase
    ["GotMoreCoins"]               = { en = "You got more coins!" },
    ["SponsoredVideo"]             = { en = "Sponsored video" },
    ["MustWatchWholeVideo"]        = { en = "You must watch the whole video to get coins" },
    ["Click to watch a video"]     = { en = "Click to watch a video" },
    ["AlreadyOwnItem"]             = { en = "You already own this item" },
    ["CantAffordItem"]             = { en = "You can't afford this" },
    ["Buy"]                        = { en = "Buy" },
    ["Buy something"]              = { en = "Buy something" },
    ["LoginToSeeStats"]            = { en = "You have to login to see your own stats" },

    -- Stats
    ["Kills"]                      = { en = "Kills" },
    ["Deaths"]                     = { en = "Deaths" },
    ["Suicides"]                   = { en = "Suicides: " },
    ["Wins"]                       = { en = "Wins: " },
    ["Daily win"]                  = { en = "Daily win" },

    -- Achievements
    ["Addicted"]                   = { en = "Addicted" },
    ["Big Spender"]                = { en = "Big Spender" },
    ["Hot streak"]                 = { en = "Hot streak" },
    ["Number One"]                 = { en = "Number one" },
    ["Rising Star"]                = { en = "Rising Star" },
    ["Terminator"]                 = { en = "Terminator" },
    ["Gain 50 rating"]             = { en = "Gain 50 rating" },
    ["Gain 100 rating"]            = { en = "Gain 100 rating" },
    ["Gain 1000 rating"]           = { en = "Gain 1000 rating" },
    ["Score 100 kills"]            = { en = "Score 100 kills" },
    ["Score 200 kills"]            = { en = "Score 200 kills" },
    ["Score 500 kills"]            = { en = "Score 500 kills" },
    ["Play 25 games"]              = { en = "Play 25 games" },
    ["Play 75 games"]              = { en = "Play 75 games" },
    ["Play 150 games"]             = { en = "Play 150 games" },
    ["Win a game"]                 = { en = "Win a game" },
    ["Win 10 games"]               = { en = "Win 10 games" },
    ["Win 20 games"]               = { en = "Win 20 games" },
    ["Win 50 games"]               = { en = "Win 50 games" },
    ["Win 3 games in a row"]       = { en = "Win 3 games in a row" },
    ["Win 5 games in a row"]       = { en = "Win 5 games in a row" },
    ["Win 10 games in a row"]      = { en = "Win 10 games in a row" },
    ["Die 100 times"]              = { en = "Die 100 times" },
    ["Die 200 times"]              = { en = "Die 200 times" },
    ["Die 500 times"]              = { en = "Die 500 times" },

    -- Tips & Dialogue
    ["TD1"]  = { en = "Tip: Add an email and a password to your Fun Run account in case you lose your phone." },
    ["TD2"]  = { en = "Tip: Have a problem? Find the solution at dirtybit.com/faq.html" },
    ["TD3"]  = { en = "Like Fun Run on Facebook!" },
    ["TD4"]  = { en = "Tip: Follow us on Twitter for the latest news! @dirtyBitGames" },
    ["TD5"]  = { en = "Tweeting about the game? #funrun" },
    ["TD6"]  = { en = "Tip: Avoid traps!" },
    ["TD7"]  = { en = "Fun Run: It's Fun!" },
    ["TD8"]  = { en = "Tip: Got an argument you can't settle? Decide it with a race!" },
    ["TD9"]  = { en = "No animals were harmed in the making of this game." },
    ["TD10"] = { en = "You are looking extra lovely tonight." },
    ["TD11"] = { en = "Looking good. Carry on." },
    ["TD12"] = { en = "You are awesome!" },
    ["TD13"] = { en = "Tip: If you like Fun Run on facebook, you'll live longer. For real." },
    ["TD14"] = { en = "Tip: Repeat pressing jump to climb walls." },
    ["TD15"] = { en = "Tip: Repeat pressing jump to climb walls." },
    ["TD16"] = { en = "Tip: Sawblades bounce off walls." },
    ["TD17"] = { en = "Tip: The Magnet pulls everyone towards you." },
    ["TD18"] = { en = "Tip: Lightning strikes shortly after clouds appear." },
    ["TD19"] = { en = "Tip: The Heart absorbs one hit, and is not limited by time." },
    ["TD20"] = { en = "Tip: The blue shield lasts for 6 seconds and makes you invulnerable!" },
    ["TD21"] = { en = "Tip: Speed gives you an instant boost in addition to increasing top speed." },
    ["TD22"] = { en = "Play with bots, randoms or friends!" },
    ["TD23"] = { en = "Tip: In Practice mode you play versus bots." },
    ["TD24"] = { en = "Tip: See how awesome you are compared to your friends in the Ranking menu." },
    ["TD25"] = { en = "Tip: View the global leaderboards in the Ranking Menu." },
    ["TD26"] = { en = "Tip: View the tutorial from the Settings Menu." },
    ["TD27"] = { en = "Tip: If you reach the goal, you can leave the game without penalty." },
    ["TD28"] = { en = "Tip: Jumping slows you down slightly." },
    ["TD29"] = { en = "Tip: Get new avatars and items in the Marketplace." },
    ["TD30"] = { en = "Tip: There are new challenges every day!" },
    ["TD31"] = { en = "Tip: The ninja sword kills the one marked by the red arrow." },
    ["TD32"] = { en = "Tip: Remember to check the challenges daily!" },
    ["TD33"] = { en = "Tip: The challenges reset every day." },
    ["TD34"] = { en = "Tip: You receive a notification when a challenge is completed." },
    ["TD35"] = { en = "A turtle and a rabbit walk into a bar..." },
    ["TD36"] = { en = "If you like Fun Run, please rate it!" },

    -- Add Friend responses
    ["Already friends"]            = { en = "Already friends" },
    ["CantAddYourself"]            = { en = "Can't add yourself" },
    ["User doesn't exist"]         = { en = "User doesn't exist" },
    ["Friend request sent"]        = { en = "Friend request sent" },
    ["No account with that email"] = { en = "No account with that email" },

    -- Connection
    ["Could not connect to server"] = { en = "Could not connect to server" },
    ["No connection"]               = { en = "No connection" },
    ["Trying to reconnect"]         = { en = "Trying to reconnect" },

    -- Misc
    ["SpecialThanks"]              = { en = "Special thanks to" },
    ["Video time!"]                = { en = "Video time!" },
    ["test"]                       = { en = "test" },

    -- Multi-line keys
    ["\nYou're doing that too often.\nPlease check your email."] = { en = "\nYou're doing that too often.\nPlease check your email." },
    ["\nCan't send to that address.\nPlease contact support@dirtybit.com"] = { en = "\nCan't send to that address.\nPlease contact support@dirtybit.com" },
    ["\nNo account with that email.\nPlease check your spelling."] = { en = "\nNo account with that email.\nPlease check your spelling." },
}

--------------------------------------------------------------------------------
-- Language update
--------------------------------------------------------------------------------

function localization.updateLanguage()
    -- Check if using phone language
    if database and database.usingPhoneLanguage() then
        local lang = system.getPreference("ui", "language")

        -- Android fallback
        if lang == nil or lang == "" then
            lang = system.getPreference("locale", "language")
        end

        -- Normalize
        if lang then
            lang = string.sub(lang, 1, 2)
            -- Map zh-Hans to zh
            local fullLang = system.getPreference("ui", "language") or ""
            if string.find(fullLang, "zh") then
                lang = "zh"
            end
        end

        -- Check if language is supported
        if lang and fontSizes[lang] then
            localization.language = lang
        else
            localization.language = "en"
        end
    end
end

--------------------------------------------------------------------------------
-- Get translated string
--------------------------------------------------------------------------------

function localization.get(key)
    local entry = localization.translation[key]
    if entry then
        local translated = entry[localization.language]
        if translated then
            return translated
        end
        -- Fallback to English
        if entry.en then
            return entry.en
        end
    end
    -- Return key as fallback
    return key
end

--------------------------------------------------------------------------------
-- Get font size for current language
--------------------------------------------------------------------------------

function localization.getFontSize()
    return fontSizes[localization.language] or localization.defaultFontSize
end

return localization
