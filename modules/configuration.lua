-- configuration.lua — Game configuration
-- Reconstructed from decompiled configuration.lu.lua
-- Sets storyboard.config with version, server URLs, API keys, etc.

local storyboard = require("modules.storyboard")

storyboard.config = {}

-- Game version
storyboard.config.version = "2.24"
storyboard.config.fullVersion = "2.24.1"
storyboard.config.serverVersion = 36

-- New items notification
storyboard.config.newItems = {
    version = 19,
    items = { 137, 241 },
}

-- Server endpoints (original — servers are offline)
storyboard.config.tcpSocial = "social3.dirtybit.no"
storyboard.config.httpClient = "https://login1.dirtybit.no/userAPI.php"
storyboard.config.httpReserveClient = "http://funrunstatus.dirtybit.no/status.html"
storyboard.config.inappAndroid = "https://purchase1.dirtybit.no/validateBillingv3.php"
storyboard.config.inappiOS = "https://purchase1.dirtybit.no/validatePurchase.php"
storyboard.config.inappAmazon = "https://purchase1.dirtybit.no/validateAmazonPurchase.php"

-- Analytics keys
storyboard.config.flurryAndroid = "6BZYN53JK6SBZX2PBCSH"
storyboard.config.flurryiOS = "G6GNT88TXRTNGTQHC8TQ"
storyboard.config.GAGameKey = "8d59762cab96315445204fa549f30b93"
storyboard.config.GASecretKey = "a9daba8aa8bc2c686f693735715a6af676452cd5"
storyboard.config.gameAnalytics = false  -- Disabled for rebuilt version

-- Facebook app ID
storyboard.config.facebook = "430526537005729"

-- Ad network IDs
storyboard.config.vungleAndroid = "no.dirtybit.funrun"
storyboard.config.vungleiOS = "547201991"
storyboard.config.adrallyAndroid = "e9db23b9-9828-473c-a01f-46e4e149d822"
storyboard.config.adrallyOS = "c273e039-c1ff-4b43-aa77-8b03dfa838f7"
storyboard.config.revmobAndroid = "50b4ac7de4068c1000000064"
storyboard.config.revmobiOS = "50b4b07369103eaa00000037"
storyboard.config.revmobAmazon = "5224b1a1d1dc1e035800002e"
storyboard.config.cbIdAndroid = "5305bebef8975c7806cbca80"
storyboard.config.cbSignartureAndroid = "66e1d295e8490903424cfd56ad844de2b069fd09"
storyboard.config.cbIdOS = "53060ff89ddc357a11b62507"
storyboard.config.cbSignartureOS = "1f71d91f5698b65b44204d74096b8878e2fe0be6"

-- Feature flags
storyboard.config.tutorial = false
storyboard.config.testMode = false

-- Test mode overrides
if storyboard.config.testMode then
    storyboard.config.openPostLobby = false
    storyboard.config.tcpSocial = "socialdev.dirtybit.no"
    storyboard.config.httpClient = "https://socialdev.dirtybit.no/userAPI.php"
    storyboard.config.httpReserveClient = "https://socialdev.dirtybit.no/status.php"
    storyboard.config.inappAndroid = "https://socialdev.dirtybit.no/validateBilling.php"
    storyboard.config.inappiOS = "https://socialdev.dirtybit.no/validatePurchase.php"
    storyboard.config.inappAmazon = "https://socialdev.dirtybit.no/validateAmazonPurchase.php"
end
