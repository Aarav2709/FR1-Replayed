-- util.lua — Utility functions
-- Reconstructed from decompiled util.lu.lua

local util = {}

local contentWidth = display.contentWidth
local contentHeight = display.contentHeight

--------------------------------------------------------------------------------
-- wrap(text, lineLen, indent, hangIndent) — Word-wrap text to lineLen chars
--------------------------------------------------------------------------------
function util.wrap(text, lineLen, indent, hangIndent)
    lineLen = lineLen or 72
    indent = indent or ""
    hangIndent = hangIndent or ""

    local lines = {}
    local currentLine = indent
    local isFirstLine = true

    for word in text:gmatch("%S+") do
        if #currentLine + #word + 1 > lineLen then
            lines[#lines + 1] = currentLine
            currentLine = hangIndent .. word
        else
            if currentLine == indent or currentLine == hangIndent then
                currentLine = currentLine .. word
            else
                currentLine = currentLine .. " " .. word
            end
        end
    end

    if #currentLine > 0 then
        lines[#lines + 1] = currentLine
    end

    return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- explode(separator, str) — Split string by separator
--------------------------------------------------------------------------------
function util.explode(separator, str)
    local result = {}
    local pattern = "([^" .. separator .. "]+)"
    for match in str:gmatch(pattern) do
        result[#result + 1] = match
    end
    return result
end

--------------------------------------------------------------------------------
-- wrappedText(text, lineLen, fontSize, font, color, indent, hangIndent)
-- Creates a display group of wrapped text lines
--------------------------------------------------------------------------------
function util.wrappedText(text, lineLen, fontSize, font, color, indent, hangIndent)
    fontSize = fontSize or 12
    font = font or "Helvetica"
    color = color or { 1, 1, 1 }

    local wrapped = util.wrap(text, lineLen, indent, hangIndent)
    local lines = util.explode("\n", wrapped)

    local group = display.newGroup()
    local yOffset = 0

    for i, line in ipairs(lines) do
        local textObj = display.newText(line, 0, yOffset, font, fontSize)
        textObj:setFillColor(color[1], color[2], color[3])
        textObj.anchorX = 0
        textObj.anchorY = 0
        group:insert(textObj)
        yOffset = yOffset + fontSize * 1.4
    end

    return group
end

return util
