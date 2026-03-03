-- tableView.lua — Scrollable table/list view module
-- Provides a scrollable list widget for settings, friends, rankings, etc.

local storyboard = require("modules.storyboard")

local tableView = {}

--------------------------------------------------------------------------------
-- newTableView(params)
-- Creates a scrollable table view
-- params:
--   x, y           : position
--   width, height   : dimensions
--   rowHeight       : height of each row (default 40)
--   rows            : array of row data tables
--   onRowRender     : function(event) called to render each row
--   onRowTouch      : function(event) called when a row is tapped
--   displayGroup    : optional parent group
--   backgroundColor : optional {r,g,b,a} background color
--------------------------------------------------------------------------------
function tableView.newTableView(params)
    params = params or {}

    local x = params.x or display.contentCenterX
    local y = params.y or display.contentCenterY
    local width = params.width or 300
    local height = params.height or 200
    local rowHeight = params.rowHeight or 40
    local rows = params.rows or {}
    local onRowRender = params.onRowRender
    local onRowTouch = params.onRowTouch
    local bgColor = params.backgroundColor or { 0, 0, 0, 0.2 }
    local displayGroup = params.displayGroup

    -- Container group
    local container = display.newGroup()
    container.x = x
    container.y = y

    -- Background
    local bg = display.newRect(container, 0, 0, width, height)
    bg:setFillColor(bgColor[1] or 0, bgColor[2] or 0, bgColor[3] or 0, bgColor[4] or 0.2)

    -- Scroll view using a simple group + masking approach
    local scrollGroup = display.newGroup()
    container:insert(scrollGroup)

    -- Content group inside scrollGroup
    local contentGroup = display.newGroup()
    scrollGroup:insert(contentGroup)

    -- Render rows
    local totalContentHeight = 0
    for i, rowData in ipairs(rows) do
        local rowGroup = display.newGroup()
        rowGroup.y = (i - 1) * rowHeight - (height / 2) + (rowHeight / 2)
        contentGroup:insert(rowGroup)

        -- Row background
        local rowBg = display.newRect(rowGroup, 0, 0, width, rowHeight)
        rowBg:setFillColor(0, 0, 0, 0)

        -- Callback for custom row rendering
        if onRowRender then
            onRowRender({
                row = rowGroup,
                index = i,
                data = rowData,
                width = width,
                height = rowHeight,
            })
        end

        -- Touch handling
        if onRowTouch then
            rowBg:addEventListener("touch", function(event)
                if event.phase == "ended" then
                    onRowTouch({
                        index = i,
                        data = rowData,
                        target = rowGroup,
                    })
                end
                return true
            end)
        end

        totalContentHeight = i * rowHeight
    end

    -- Simple drag-to-scroll
    local scrollOffset = 0
    local maxScroll = math.max(0, totalContentHeight - height)

    bg:addEventListener("touch", function(event)
        if event.phase == "began" then
            display.getCurrentStage():setFocus(event.target)
            event.target._startY = event.y
            event.target._startOffset = scrollOffset
        elseif event.phase == "moved" then
            local dy = event.y - event.target._startY
            scrollOffset = event.target._startOffset - dy
            scrollOffset = math.max(0, math.min(scrollOffset, maxScroll))
            contentGroup.y = -scrollOffset
        elseif event.phase == "ended" or event.phase == "cancelled" then
            display.getCurrentStage():setFocus(nil)
        end
        return true
    end)

    if displayGroup then
        displayGroup:insert(container)
    end

    -- Public methods
    container.scrollToTop = function()
        scrollOffset = 0
        contentGroup.y = 0
    end

    container.scrollToBottom = function()
        scrollOffset = maxScroll
        contentGroup.y = -maxScroll
    end

    container.getContentHeight = function()
        return totalContentHeight
    end

    return container
end

--------------------------------------------------------------------------------
-- newList(params)
-- Legacy Corona-style list API used by settings credits, friends lists, etc.
-- params:
--   data      : array of item tables
--   default   : default row image path (used as row bg if provided)
--   width     : row width
--   height    : row height per item
--   onRelease : callback when list touched
--   top       : top padding
--   bottom    : bottom boundary (total visible height)
--   callback  : function(item) → returns a display group for the row
--------------------------------------------------------------------------------
function tableView.newList(params)
    params = params or {}
    local data       = params.data or {}
    local rowWidth   = params.width or 200
    local rowHeight  = params.height or 28
    local callback   = params.callback
    local onRelease  = params.onRelease
    local topPad     = params.top or 0
    local bottom     = params.bottom or 200

    -- Container group (this is what gets :insert()-ed into the scene view)
    local container = display.newGroup()

    -- Content group holds all rendered rows
    local contentGroup = display.newGroup()
    container:insert(contentGroup)

    -- Render each data item
    local totalContentHeight = 0
    for i, item in ipairs(data) do
        local rowGroup
        if callback then
            rowGroup = callback(item)
        else
            rowGroup = display.newGroup()
        end
        if rowGroup then
            rowGroup.y = topPad + (i - 1) * rowHeight
            contentGroup:insert(rowGroup)
        end
        totalContentHeight = topPad + i * rowHeight
    end

    -- Track content height on container for auto-scroll calculations
    container.height = totalContentHeight

    -- Internal scroll state
    local scrollY = 0
    local scrollTransition = nil

    -- Public method: getY — returns current scroll offset
    function container:getY()
        return contentGroup.y
    end

    -- Public method: scrollTo — animate content to targetY over duration ms
    function container:scrollTo(targetY, duration)
        if scrollTransition then
            transition.cancel(scrollTransition)
            scrollTransition = nil
        end
        scrollTransition = transition.to(contentGroup, {
            y = targetY,
            time = duration or 1000,
            onComplete = function()
                scrollY = contentGroup.y
                scrollTransition = nil
            end
        })
    end

    -- Public method: cleanUp — remove everything
    function container:cleanUp()
        if scrollTransition then
            transition.cancel(scrollTransition)
            scrollTransition = nil
        end
        container:removeSelf()
    end

    -- Simple drag-to-scroll on the content area
    local maxScroll = math.max(0, totalContentHeight - bottom)
    container:addEventListener("touch", function(event)
        if event.phase == "began" then
            -- Stop any ongoing auto-scroll
            if scrollTransition then
                transition.cancel(scrollTransition)
                scrollTransition = nil
            end
            display.getCurrentStage():setFocus(event.target)
            event.target._startY = event.y
            event.target._startOffset = contentGroup.y
            if onRelease then onRelease(event) end
        elseif event.phase == "moved" then
            local dy = event.y - event.target._startY
            local newY = event.target._startOffset + dy
            newY = math.min(topPad, math.max(-maxScroll, newY))
            contentGroup.y = newY
        elseif event.phase == "ended" or event.phase == "cancelled" then
            display.getCurrentStage():setFocus(nil)
            scrollY = contentGroup.y
        end
        return true
    end)

    return container
end

return tableView
