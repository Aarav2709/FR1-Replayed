-- helpers.

local util = {}

local function wrap(str, limit, indent, firstIndent)
  indent = indent or ""
  firstIndent = firstIndent or indent
  limit = limit or 72
  local here = 1 - #firstIndent
  return firstIndent .. str:gsub("(%s+)()(%S+)()", function(_, start, word, finish)
    if finish - here > limit then
      here = start - #indent
      return "\n" .. indent .. word
    end
  end)
end
util.wrap = wrap

local function explode(separator, str)
  if separator == "" then
    return false
  end
  local parts = {}
  local position = 0
  for first, last in function() return string.find(str, separator, position, true) end do
    table.insert(parts, string.sub(str, position, first - 1))
    position = last + 1
  end
  table.insert(parts, string.sub(str, position))
  return parts
end
util.explode = explode

function util.wrappedText(text, width, size, font, color, indent, firstIndent)
  local paragraphs = explode("\n", text)
  size = tonumber(size) or 12
  color = color or { 255, 255, 255 }
  font = font or "Helvetica"

  local wrapped = ""
  for i = 1, #paragraphs do
    wrapped = wrapped .. "\n" .. wrap(paragraphs[i], width, indent, firstIndent)
  end
  local lines = explode("\n", wrapped)

  local group = display.newGroup()
  for i = 1, #lines do
    local line = display.newText(lines[i], 0, 0, font, size)
    line.anchorX = 0
    line.anchorY = 1
    line:setFillColor(color[1], color[2], color[3])
    line.x = 0
    line.y = math.floor(size * 1.3 * (i - 1))
    group:insert(line)
  end
  return group
end

return util
