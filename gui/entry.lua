local GUIEntry = {}

GUIEntry.colors = { --Entry text colors
  normal = {1, 1, 1},
  hovered = {0, 1, 0},
  activated = {1, 0, 0},
  locked = {0.5, 0.5, 0.5}
}

local fonts = require "fonts"
local GUI_FONT = "ui" --GUI font tag
local GUI_FONT_SCALE = 1.0 --GUI font scale

local SB_V_WIDTH = 256 --Value text size
local SB_V_POS = 64 + SB_V_WIDTH / 2 --Distance from the right button edge to the value text

local function nullAction()
  return true--Dummy function for buttons without onPress or onSwitch
end

local defaultSwitcher = {false, true} --Default switcher values

local function find(t, found) --look for value 'found' in table 't' and return its key
  for k, v in pairs(t) do
    if v == found then
      return k
    end
  end
end

local function setRespectiveColor(code) -- Set the respective for state 'code' draw color
  local key
  if code == -1 then
    key = "locked"
  elseif code == 0 then
    key = "normal"
  elseif code == 1 then
    key = "hovered"
  elseif code > 1 then
    key = "activated"
  end
  
  if key then
    love.graphics.setColor(GUIEntry.colors[key])
  end
end

function GUIEntry.__index(t, k)
  return rawget(t, k) or GUIEntry[k]
end

function GUIEntry.newButton(text, onPress) --Create a button entry
  local t = {}
  t.text = text or ""
  t.type = "button"
  t.onPress = onPress or nullAction
  t.selectable = true
  return setmetatable(t, GUIEntry)
end

function GUIEntry.newSlider(text, from, to, step, default, pattern, valueNames, onSwitch) --Create a number slider for range [from; to]
  local t = {}
  t.text = text or ""
  t.type = "slider"
  t.range = {from, to}
  t.step = step
  t.value = default or from
  t.pattern = pattern or "%s"
  t.valueNames = valueNames or {} --Displyed value names
  t.hovered = 0 --1 = right button hovered, -1 = left button hovered
  t.selectable = true
  t.onSwitch = onSwitch or nullAction --Function, called with the new value and returning if it shouldn't be skipped
  return setmetatable(t, GUIEntry)
end

function GUIEntry.newSwitcher(text, values, default, valueNames, onSwitch) --Create a switcher
  local t = {}
  t.text = text or ""
  t.type = "switcher"
  t.values = values or defaultSwitcher --Value list
  t.values_n = #t.values
  t.valueNames = valueNames or {} --Displyed value names
  t.selected = find(t.values, default) or default --Selected value key
  t.selectable = true
  t.hovered = 0 --1 = right button hovered, -1 = left button hovered
  t.onSwitch = onSwitch or nullAction --Function, called with the new value and returning if it shouldn't be skipped
  return setmetatable(t, GUIEntry)
end

local function valueText(v, min, max, text)
  text = text or tostring(v)
  if v > min then
    text = "<" .. text
  else
    text = " " .. text
  end
  if v < max then
    text = text .. ">"
  else
    text = text .. " "
  end
  return text
end

function GUIEntry.draw(t, x, y, w, state, align)
  if t.type == 'button' then
    align = align or 'left'
  else
    align = 'left'
  end
  state = state or 0 --0 = unhovered, 1 = hovered, 2 = activated
  setRespectiveColor(state)
  fonts.print(GUI_FONT, GUI_FONT_SCALE, t.text, x, y, w, align)
  if t.type == "slider" then
    fonts.print(GUI_FONT, GUI_FONT_SCALE, 
      valueText(t.value, t.range[1], t.range[2], 
        t.valueNames[t.value] or string.format(t.pattern, t.value)),
      x + w - SB_V_POS, y, SB_V_WIDTH, "center")
  elseif t.type == "switcher" then
    fonts.print(GUI_FONT, GUI_FONT_SCALE, 
      valueText(t.selected, 1, t.values_n, 
        t.valueNames[t.selected] or tostring(t.values[t.selected])), 
      x + w - SB_V_POS, y, SB_V_WIDTH, "center")
  end
end

function GUIEntry.switch(t, side)
  if t.type == "switcher" then
    if (side < 0 and t.selected > 1) or (side > 0 and t.selected < t.values_n) then
      t.selected = t.selected + side
    end
    if not t.onSwitch(t.values[t.selected]) then
      t:switch(side)
    end
  elseif t.type == "slider" then
    t.value = t.value + side * t.step
    if t.value < t.range[1] then
      t.value = t.range[1]
    elseif t.value > t.range[2] then
      t.value = t.range[2]
    end
    if not t.onSwitch(t.value) then
      t:switch(side)
    end
  elseif t.type == "button" then
    t.onPress()
  end
end

return GUIEntry
