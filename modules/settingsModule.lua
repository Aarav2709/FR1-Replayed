---------------------------------------------------------------------------------
-- settingsModule.lua — Creates the settings tab bar (General, Account, Help)
---------------------------------------------------------------------------------
local settingsModule = {}

local storyboard = require("modules.storyboard")
local gui = require("modules.gui")

function settingsModule.create()
    local group = display.newGroup()

    local buttonWidth = 112
    local buttonHeight = 50
    local baseX = 160
    local y = 290
    local spacing = 120

    local generalButton
    local accountButton
    local helpButton

    ---------------------------------------------------------------------------
    -- Button handlers: open overlay scenes
    ---------------------------------------------------------------------------
    local function onGeneralTap()
        storyboard.showOverlay("scenes.generalSettings", {isModal = true})
    end

    local function onAccountTap()
        storyboard.showOverlay("scenes.accountSettings", {isModal = true})
    end

    local function onHelpTap()
        storyboard.showOverlay("scenes.helpSettings", {isModal = true})
    end

    ---------------------------------------------------------------------------
    -- Create buttons
    ---------------------------------------------------------------------------
    generalButton = gui.newButton({
        image = "images/gui/button/general.png",
        width = buttonWidth,
        height = buttonHeight,
        onRelease = onGeneralTap,
        x = baseX + spacing,
        y = y,
        displayGroup = group
    })

    accountButton = gui.newButton({
        image = "images/gui/button/account.png",
        width = buttonWidth,
        height = buttonHeight,
        onRelease = onAccountTap,
        x = baseX,
        y = y,
        displayGroup = group
    })

    helpButton = gui.newButton({
        image = "images/gui/button/help.png",
        width = buttonWidth,
        height = buttonHeight,
        onRelease = onHelpTap,
        x = baseX + 2 * spacing,
        y = y,
        displayGroup = group
    })

    ---------------------------------------------------------------------------
    -- Add/remove all button listeners
    ---------------------------------------------------------------------------
    function group.addButtonListeners()
        accountButton.addListener()
        generalButton.addListener()
        helpButton.addListener()
    end

    function group.removeButtonListeners()
        accountButton.removeListener()
        generalButton.removeListener()
        helpButton.removeListener()
    end

    ---------------------------------------------------------------------------
    -- Clean up (remove listeners and display group)
    ---------------------------------------------------------------------------
    function group.clean()
        group.removeButtonListeners()
        group:removeSelf()
    end

    return group
end

return settingsModule
