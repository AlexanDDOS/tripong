--WS is a global variable, declared in main.lua

local fonts = {}
fonts.all = {}

local function loadFile(path)
  local data, err = love.filesystem.newFileData(path)
  if err then
    error(err)
  end
  return data
end

local function addSubfont(font, scale)
  local sf = love.graphics.newFont(font.file, font.unit * scale * WS)
  font[scale] = sf
  return sf
end

function fonts.add(path, tag, unit)
  unit = unit or 12 --Font size unit (font size while its scale is 1.0)
  local file = loadFile(path)
  local fontData = {}
  fontData.file = file
  fontData.unit = unit
  addSubfont(fontData, 1.0) --Add the standard subfont
  fonts.all[tag] = fontData
  return fontData
end

function fonts.get(tag, scale)
  local font = fonts.all[tag]
  assert(font ~= nil, string.format("font '%s' is not loaded", tag))
  return font[scale] or addSubfont(font, scale)
end

function fonts.reload(tag)
  local font = fonts.all[tag]
  assert(font ~= nil, string.format("font '%s' is not loaded", tag))
  for k, v in pairs(font) do
    local ns = k * WS
    if ns ~= k then
      font[k] = love.graphics.newFont(font.file, font.unit * k * WS)
    end
  end
end

function fonts.print(tag, scale, text, x, y, tw, align)
  local font = fonts.get(tag, scale)
  love.graphics.setFont(font)
  
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.scale(1 / WS)
  if tw then
    love.graphics.printf(text, 0, 0, tw / WS, align)
  else
    love.graphics.print(text, 0, 0)
  end
  love.graphics.pop()
end

return fonts
