---------------------------------------------------------------------------------
-- marketplace.lua — Full item marketplace / shop
-- Reconstructed from decompiled marketplace.lu.lua
-- 4 categories: Avatars, Hats, Items, Boots
-- Fully offline — purchases use local coins
---------------------------------------------------------------------------------
local storyboard = require("modules.storyboard")
local scene = storyboard.newScene()

local accessories = require("modules.accessories")

-- Module-level variables
local homeButton
local keyListener
local background
local leftBar
local categoryTabs = {}       -- 4 tab images
local selectedCategory = 1    -- 1=Avatar, 2=Hat, 3=Item, 4=Boots
local moneyText
local coinIcon
local itemNameText
local itemPriceText
local priceIcon
local statusText
local buyButton
local previewImage            -- currently shown thumbnail
local scrollGroup             -- horizontal list container
local scrollContent           -- inner content group
local selectedIndex = 1       -- selected item in current list
local avatarData              -- current avatar { avatar, hat, item, boots }
local ownedItems              -- storyboard.databaseData.items
local currentList = {}        -- active category item list
local cellImages = {}         -- cell display objects

-- Match decompiled coordinates exactly
local CELL_SIZE = 80
local CELL_PAD = 4
local SCROLL_Y = 264          -- bottom-anchored in original
local SCROLL_X = 145
local SCROLL_W = 310
local SCROLL_H = 80

local PREVIEW_X = 290
local PREVIEW_Y = 120
local PREVIEW_SIZE = 80

local TAB_NAMES = { "Avatars", "Hats", "Items", "Boots" }

---------------------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------------------
local function formatPrice(n)
    if n >= 1000000000 then return string.format("%.0fB", n / 1000000000)
    elseif n >= 1000000 then return string.format("%.1fM", n / 1000000)
    elseif n >= 10000 then return string.format("%.0fK", n / 1000)
    else return tostring(n) end
end

local function isOwned(category, itemId)
    if not ownedItems then return false end
    local catItems = ownedItems[category]
    if not catItems then return false end
    for _, id in ipairs(catItems) do
        if id == itemId then return true end
    end
    return false
end

local function isEquipped(category, itemId)
    if not avatarData then return false end
    if category == 1 then return avatarData[1] == itemId end
    if category == 2 then return avatarData[2] == itemId end
    if category == 3 then return avatarData[3] == itemId end
    if category == 4 then return avatarData[4] == itemId end
    return false
end

---------------------------------------------------------------------------------
-- CREATE SCENE
---------------------------------------------------------------------------------
function scene:createScene(event)
    local view = self.view
    local gui = require("modules.gui")
    local font = storyboard.gameDataTable.font
    local fontSize = 18
    local textColor = {1, 1, 1, 1}

    -- Load current state
    avatarData = storyboard.database.getAvatarData() or {100, 200, 300, 400}
    ownedItems = storyboard.database.getItems() or {{}, {}, {}, {}}

    -- Ensure starter items are owned
    if #ownedItems[1] == 0 then
        ownedItems[1] = { 100 }  -- Fox is free
    end

    ---------------------------------------------------------------------------
    -- Background (380×410, anchored top-right, shifted 90px above viewport)
    ---------------------------------------------------------------------------
    background = display.newImageRect("images/gui/background/marketPlace.png", 380, 410)
    background.anchorX = 1
    background.anchorY = 0
    background.x = display.contentWidth
    background.y = -90
    view:insert(background)

    ---------------------------------------------------------------------------
    -- Left sidebar (100×410, same y offset as background)
    ---------------------------------------------------------------------------
    leftBar = display.newImageRect("images/gui/background/marketLeftBar.png", 100, 410)
    leftBar.anchorX = 0
    leftBar.anchorY = 0
    leftBar.x = 0
    leftBar.y = -90
    view:insert(leftBar)

    ---------------------------------------------------------------------------
    -- Category tabs (4 buttons on left sidebar, anchorY=0 = top edge)
    ---------------------------------------------------------------------------
    local tabPositions = { 36, 90, 144, 199 }
    for i = 1, 4 do
        local tabImg = display.newImageRect("images/gui/market/categorySelected_.png", 86, 50)
        tabImg.anchorX = 0
        tabImg.anchorY = 0
        tabImg.x = 5
        tabImg.y = tabPositions[i]
        view:insert(tabImg)

        local tabLabel = display.newText({
            text = TAB_NAMES[i],
            x = 48,
            y = tabPositions[i] + 25,
            font = font,
            fontSize = 13,
        })
        tabLabel:setFillColor(1, 1, 1)
        view:insert(tabLabel)

        local function onTabTap()
            selectedCategory = i
            selectedIndex = 1
            scene:refreshCategory()
            return true
        end
        tabImg:addEventListener("tap", onTabTap)
        tabLabel:addEventListener("tap", onTabTap)

        categoryTabs[i] = { bg = tabImg, label = tabLabel }
    end

    ---------------------------------------------------------------------------
    -- Money display (matches decompiled: coin at x=120,y=45, text at x=140,y=45)
    ---------------------------------------------------------------------------
    coinIcon = display.newImageRect("images/gui/extra/coin.png", 15, 15)
    coinIcon.anchorX = 0
    coinIcon.x = 120
    coinIcon.y = 45
    view:insert(coinIcon)

    local money = storyboard.database.getMoney() or 0
    moneyText = display.newText(tostring(money), 0, 0, font, fontSize * 2)
    moneyText:setFillColor(1, 1, 1)
    moneyText.xScale = 0.5
    moneyText.yScale = 0.5
    moneyText.anchorX = 0
    moneyText.x = 140
    moneyText.y = 45
    view:insert(moneyText)

    ---------------------------------------------------------------------------
    -- Preview area (right side) — thumbnail of selected item
    ---------------------------------------------------------------------------
    previewImage = display.newImageRect("images/transparent.png", PREVIEW_SIZE, PREVIEW_SIZE)
    previewImage.x = PREVIEW_X
    previewImage.y = PREVIEW_Y
    view:insert(previewImage)

    ---------------------------------------------------------------------------
    -- Item name text (right of preview)
    ---------------------------------------------------------------------------
    itemNameText = display.newText("", 0, 0, font, fontSize * 2.4)
    itemNameText:setFillColor(1, 1, 1)
    itemNameText.xScale = 0.5
    itemNameText.yScale = 0.5
    itemNameText.x = 390
    itemNameText.y = PREVIEW_Y - 10
    view:insert(itemNameText)

    ---------------------------------------------------------------------------
    -- Item price / status text (below name, right side)
    ---------------------------------------------------------------------------
    priceIcon = display.newImageRect("images/gui/extra/coin.png", 12, 12)
    priceIcon.x = 370
    priceIcon.y = PREVIEW_Y + 15
    priceIcon.isVisible = false
    view:insert(priceIcon)

    itemPriceText = display.newText("", 0, 0, font, fontSize * 2)
    itemPriceText:setFillColor(1, 0.84, 0)
    itemPriceText.xScale = 0.5
    itemPriceText.yScale = 0.5
    itemPriceText.x = 395
    itemPriceText.y = PREVIEW_Y + 15
    view:insert(itemPriceText)

    ---------------------------------------------------------------------------
    -- Status text (bottom center — buy result messages)
    ---------------------------------------------------------------------------
    statusText = display.newText("", 0, 0, font, fontSize * 2)
    statusText:setFillColor(1, 1, 1)
    statusText.xScale = 0.5
    statusText.yScale = 0.5
    statusText.x = display.contentWidth * 0.5
    statusText.y = display.contentHeight * 0.95
    view:insert(statusText)

    ---------------------------------------------------------------------------
    -- Buy / Equip button
    ---------------------------------------------------------------------------
    local function onBuyTap()
        local item = currentList[selectedIndex]
        if not item then return true end

        local cat = selectedCategory
        local itemId = item.id

        -- Check if already equipped
        if isEquipped(cat, itemId) then
            statusText.text = "Already equipped!"
            return true
        end

        -- Check if owned → equip
        if isOwned(cat, itemId) or item.price == 0 then
            -- Equip
            avatarData[cat] = itemId
            storyboard.database.setAvatarData(avatarData)
            statusText.text = item.name .. " equipped!"
            scene:refreshCategory()
            return true
        end

        -- Try to buy
        local money = storyboard.database.getMoney() or 0
        if money < item.price then
            statusText.text = "Not enough coins!"
            return true
        end

        -- Purchase
        storyboard.database.decreaseMoney(item.price)
        storyboard.database.addItem(cat, itemId)
        ownedItems = storyboard.database.getItems()

        -- Equip immediately
        avatarData[cat] = itemId
        storyboard.database.setAvatarData(avatarData)

        -- Update money display
        local newMoney = storyboard.database.getMoney() or 0
        moneyText.text = tostring(newMoney)

        statusText.text = item.name .. " purchased & equipped!"
        scene:refreshCategory()
        return true
    end

    buyButton = gui.newButton({
        image = "images/gui/button/buy.png",
        width = 79,
        height = 50,
        x = 430,
        y = 290,
        onRelease = onBuyTap,
        displayGroup = view,
    })

    ---------------------------------------------------------------------------
    -- Horizontal scroll area (item cells, bottom-anchored at y=264)
    ---------------------------------------------------------------------------
    scrollGroup = display.newGroup()
    scrollGroup.x = SCROLL_X
    scrollGroup.y = SCROLL_Y - SCROLL_H  -- bottom edge at SCROLL_Y
    view:insert(scrollGroup)

    -- Clipping background for scroll area
    local scrollBg = display.newRect(scrollGroup, SCROLL_W * 0.5, SCROLL_H * 0.5, SCROLL_W, SCROLL_H)
    scrollBg:setFillColor(0, 0, 0, 0.15)

    scrollContent = display.newGroup()
    scrollGroup:insert(scrollContent)

    -- Drag-to-scroll (horizontal)
    local scrollOffset = 0
    local maxScroll = 0

    scrollBg:addEventListener("touch", function(event)
        if event.phase == "began" then
            display.getCurrentStage():setFocus(event.target)
            event.target._startX = event.x
            event.target._startOffset = scrollContent.x
        elseif event.phase == "moved" then
            local dx = event.x - event.target._startX
            local newX = event.target._startOffset + dx
            newX = math.min(0, math.max(-maxScroll, newX))
            scrollContent.x = newX
        elseif event.phase == "ended" or event.phase == "cancelled" then
            display.getCurrentStage():setFocus(nil)
            scrollOffset = -scrollContent.x
        end
        return true
    end)

    -- Store reference to maxScroll updater
    scene._updateMaxScroll = function(totalW)
        maxScroll = math.max(0, totalW - SCROLL_W)
    end

    ---------------------------------------------------------------------------
    -- Home button
    ---------------------------------------------------------------------------
    local function onHomeTap(event)
        -- Save avatar on exit
        storyboard.database.setAvatarData(avatarData)
        require("modules.createSprite").updateAvatar(avatarData)
        storyboard.gotoScene("scenes.mainMenu")
        storyboard.purgeScene("scenes.marketplace")
        return true
    end

    homeButton = gui.newButton({
        image = "images/gui/button/home.png",
        width = storyboard.gameDataTable.backButton[1],
        height = storyboard.gameDataTable.backButton[2],
        x = storyboard.gameDataTable.backButton[3],
        y = storyboard.gameDataTable.backButton[4],
        onRelease = onHomeTap,
        displayGroup = view,
    })

    ---------------------------------------------------------------------------
    -- Key listener (Android back)
    ---------------------------------------------------------------------------
    keyListener = function(event)
        if event.keyName == "back" and event.phase == "up" then
            onHomeTap(event)
            return true
        end
    end
    Runtime:addEventListener("key", keyListener)

    ---------------------------------------------------------------------------
    -- Initial load — show avatars
    ---------------------------------------------------------------------------
    scene:refreshCategory()
end

---------------------------------------------------------------------------------
-- refreshCategory — rebuild the horizontal item list and preview
---------------------------------------------------------------------------------
function scene:refreshCategory()
    local font = storyboard.gameDataTable.font

    -- Update tab highlights
    for i = 1, 4 do
        local selImg = (i == selectedCategory) and "images/gui/market/categorySelected.png" or "images/gui/market/categorySelected_.png"
        local selW = (i == selectedCategory) and 87 or 86
        categoryTabs[i].bg:removeSelf()
        categoryTabs[i].bg = display.newImageRect(selImg, selW, 50)
        categoryTabs[i].bg.anchorX = 0
        categoryTabs[i].bg.anchorY = 0
        categoryTabs[i].bg.x = 5
        local tabPositions = { 36, 90, 144, 199 }
        categoryTabs[i].bg.y = tabPositions[i]
        self.view:insert(categoryTabs[i].bg)
        categoryTabs[i].label:toFront()
        self.view:insert(categoryTabs[i].label)

        -- Re-add tap listener
        local idx = i
        local function onTabTap()
            selectedCategory = idx
            selectedIndex = 1
            scene:refreshCategory()
            return true
        end
        categoryTabs[i].bg:addEventListener("tap", onTabTap)
        categoryTabs[i].label:addEventListener("tap", onTabTap)
    end

    -- Get the item list for the current category
    if selectedCategory == 1 then
        currentList = accessories.getAvatarList()
    elseif selectedCategory == 2 then
        currentList = accessories.getHatList()
    elseif selectedCategory == 3 then
        currentList = accessories.getItemList()
    elseif selectedCategory == 4 then
        currentList = accessories.getBootsList()
    end

    -- Clear old cells
    for i = #cellImages, 1, -1 do
        if cellImages[i] and cellImages[i].removeSelf then
            cellImages[i]:removeSelf()
        end
        cellImages[i] = nil
    end
    -- Remove all children from scrollContent
    while scrollContent.numChildren > 0 do
        local child = scrollContent[1]
        if child then child:removeSelf() end
    end

    -- Build cells
    local totalW = 0
    for i, item in ipairs(currentList) do
        local cellGroup = display.newGroup()
        local cellX = (i - 1) * (CELL_SIZE + CELL_PAD)
        cellGroup.x = cellX + CELL_SIZE * 0.5
        cellGroup.y = SCROLL_H * 0.5

        -- Cell background
        local cellBg = display.newImageRect("images/gui/market/cellBackground.png", CELL_SIZE, CELL_SIZE)
        cellGroup:insert(cellBg)

        -- Thumbnail
        local thumbPath = accessories.getThumbnail(selectedCategory, item)
        local thumb = display.newImageRect(thumbPath, CELL_SIZE - 8, CELL_SIZE - 8)
        if thumb then
            cellGroup:insert(thumb)
        end

        -- Owned check mark or price tag
        local owned = isOwned(selectedCategory, item.id) or item.price == 0
        local equipped = isEquipped(selectedCategory, item.id)

        if equipped then
            -- Green border for equipped
            local border = display.newRoundedRect(0, 0, CELL_SIZE - 2, CELL_SIZE - 2, 4)
            border:setFillColor(0, 0, 0, 0)
            border:setStrokeColor(0, 1, 0, 0.9)
            border.strokeWidth = 3
            cellGroup:insert(border)
        elseif owned then
            -- Subtle blue border for owned
            local border = display.newRoundedRect(0, 0, CELL_SIZE - 2, CELL_SIZE - 2, 4)
            border:setFillColor(0, 0, 0, 0)
            border:setStrokeColor(0.3, 0.6, 1, 0.7)
            border.strokeWidth = 2
            cellGroup:insert(border)
        else
            -- Price tag at bottom
            local priceBg = display.newImageRect("images/gui/market/priceBackground.png", CELL_SIZE - 4, 14)
            priceBg.y = CELL_SIZE * 0.5 - 9
            cellGroup:insert(priceBg)

            local priceLabel = display.newText({
                text = formatPrice(item.price),
                x = 0,
                y = CELL_SIZE * 0.5 - 9,
                font = font,
                fontSize = 18,
            })
            priceLabel:setFillColor(0.36, 0.22, 0.06)
            priceLabel.xScale = 0.5
            priceLabel.yScale = 0.5
            cellGroup:insert(priceLabel)
        end

        -- Selection highlight
        if i == selectedIndex then
            local sel = display.newRoundedRect(0, 0, CELL_SIZE + 2, CELL_SIZE + 2, 4)
            sel:setFillColor(0, 0, 0, 0)
            sel:setStrokeColor(1, 1, 0, 1)
            sel.strokeWidth = 3
            cellGroup:insert(sel)
        end

        -- Tap to select
        local ci = i
        cellBg:addEventListener("tap", function()
            selectedIndex = ci
            scene:updatePreview()
            scene:refreshCategory()
            return true
        end)

        scrollContent:insert(cellGroup)
        cellImages[i] = cellGroup
        totalW = cellX + CELL_SIZE
    end

    -- Update max scroll
    if scene._updateMaxScroll then
        scene._updateMaxScroll(totalW + CELL_PAD)
    end

    -- Update preview for selected item
    scene:updatePreview()
end

---------------------------------------------------------------------------------
-- updatePreview — show the selected item's name/price/thumbnail
---------------------------------------------------------------------------------
function scene:updatePreview()
    local item = currentList[selectedIndex]
    if not item then return end

    -- Update thumbnail
    if previewImage then
        previewImage:removeSelf()
        previewImage = nil
    end
    local thumbPath = accessories.getThumbnail(selectedCategory, item)
    previewImage = display.newImageRect(thumbPath, PREVIEW_SIZE, PREVIEW_SIZE)
    previewImage.x = PREVIEW_X
    previewImage.y = PREVIEW_Y
    self.view:insert(previewImage)

    -- Update name
    itemNameText.text = item.name or ""

    -- Update price / status
    local owned = isOwned(selectedCategory, item.id) or item.price == 0
    local equipped = isEquipped(selectedCategory, item.id)

    if equipped then
        itemPriceText.text = "Equipped"
        itemPriceText:setFillColor(0, 1, 0)
        priceIcon.isVisible = false
    elseif owned then
        itemPriceText.text = "Owned"
        itemPriceText:setFillColor(0.3, 0.6, 1)
        priceIcon.isVisible = false
    else
        itemPriceText.text = tostring(item.price)
        itemPriceText:setFillColor(1, 0.84, 0)
        priceIcon.isVisible = true
        priceIcon.x = itemPriceText.x - (string.len(tostring(item.price)) * 4) - 10
    end

    -- Clear status
    statusText.text = ""

    -- Bring UI to front
    itemNameText:toFront()
    itemPriceText:toFront()
    priceIcon:toFront()
    statusText:toFront()
end

---------------------------------------------------------------------------------
-- ENTER SCENE
---------------------------------------------------------------------------------
function scene:enterScene(event)
    -- Refresh money
    local money = storyboard.database.getMoney() or 0
    if moneyText then moneyText.text = tostring(money) end

    -- Re-add buy button listener
    if buyButton then buyButton.addListener() end

    -- Refresh display
    scene:refreshCategory()
end

---------------------------------------------------------------------------------
-- EXIT SCENE
---------------------------------------------------------------------------------
function scene:exitScene(event)
    -- Save avatar
    if avatarData then
        storyboard.database.setAvatarData(avatarData)
        require("modules.createSprite").updateAvatar(avatarData)
    end

    if buyButton then buyButton.removeListener() end
    Runtime:removeEventListener("key", keyListener)
end

---------------------------------------------------------------------------------
-- DESTROY SCENE
---------------------------------------------------------------------------------
function scene:destroyScene(event)
    background = nil
    leftBar = nil
    homeButton = nil
    moneyText = nil
    coinIcon = nil
    itemNameText = nil
    itemPriceText = nil
    priceIcon = nil
    statusText = nil
    buyButton = nil
    previewImage = nil
    scrollGroup = nil
    scrollContent = nil
    categoryTabs = {}
    cellImages = {}
    currentList = {}
    avatarData = nil
    ownedItems = nil
    keyListener = nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
