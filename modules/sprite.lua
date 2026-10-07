-- sprite helper.

local sprite = {}

local function getImageSheet(sheet)
  if not sheet.imageSheet then
    local options
    if sheet.format == "simple" then
      options = { width = sheet.width, height = sheet.height, numFrames = sheet.numFrames }
    else
      options = { frames = sheet.frames }
    end
    if sheet.baseDir then
      sheet.imageSheet = graphics.newImageSheet(sheet.filename, sheet.baseDir, options)
    else
      sheet.imageSheet = graphics.newImageSheet(sheet.filename, options)
    end
  end
  return sheet.imageSheet
end

local function newSheet(format, filename, baseDir)
  local sheet = { type = "spriteSheet", format = format, filename = filename, baseDir = baseDir }
  function sheet:dispose()
    self.imageSheet = nil
  end
  return sheet
end

function sprite.newSpriteSheet(filename, ...)
  local args = { ... }
  local baseDir
  if type(args[1]) == "userdata" then
    baseDir = table.remove(args, 1)
  end
  local sheet = newSheet("simple", filename, baseDir)
  sheet.width, sheet.height = args[1], args[2]
  return sheet
end

function sprite.newSpriteSheetFromData(filename, ...)
  local args = { ... }
  local baseDir
  if type(args[1]) == "userdata" then
    baseDir = table.remove(args, 1)
  end
  local sheet = newSheet("complex", filename, baseDir)
  sheet.frames = assert(args[1], "sprite.newSpriteSheetFromData(): frames are missing")
  return sheet
end

function sprite.newSpriteSet(sheet, startFrame, numFrames)
  assert(sheet and sheet.type == "spriteSheet", "sprite.newSpriteSet(): spriteSheet is malformed.")
  return { type = "spriteSet", spriteSheet = sheet, startFrame = startFrame, numFrames = numFrames, sequences = {} }
end

function sprite.add(set, name, startFrame, frameCount, time, loopParam)
  assert(set and set.type == "spriteSet", "sprite.add(): incorrect 'spriteSet.type'.")
  local loopCount, loopDirection = 0, nil
  if loopParam and loopParam ~= 0 then
    loopCount = 1
    if loopParam == -1 then
      loopDirection = "bounce"
    elseif loopParam == -2 then
      loopCount = 0
      loopDirection = "bounce"
    elseif loopParam > 0 then
      loopCount = loopParam
    end
  end
  table.insert(set.sequences, {
    name = name,
    start = startFrame + set.startFrame - 1,
    count = frameCount,
    time = time,
    loopCount = loopCount,
    loopDirection = loopDirection,
  })
end

function sprite.newSprite(set)
  assert(set and set.type == "spriteSet", "sprite.newSprite(): incorrect 'spriteSet.type'.")
  local sheet = set.spriteSheet
  local sequences = {}
  for i = 1, #set.sequences do
    sequences[i] = set.sequences[i]
  end
  sequences[#sequences + 1] = { name = "default", start = set.startFrame, count = set.numFrames }
  if sheet.format == "simple" then
    sheet.numFrames = math.max(sheet.numFrames or 0, set.startFrame + set.numFrames - 1)
  end

  local instance = display.newSprite(getImageSheet(sheet), sequences)
  function instance:prepare(sequenceName)
    self:setSequence(sequenceName)
  end
  instance:prepare("default")
  return instance
end

return sprite
