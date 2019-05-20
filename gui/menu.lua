local GUIMenu = {}
local GUIEntry = require "gui.entry"
local input = require "input"
local sounds = require "sounds"

local ENTRY_HEIGHT = 36

function GUIMenu.__index(t, k)
  return rawget(t, k) or GUIMenu[k]
end

function GUIMenu.sound(id)
  sounds.playSFX("m_" .. id)
end

function GUIMenu.new(width)
  local t = {}
  t.width = width
  t.entries = {}
  t.len = 0
  t.selected = 1
  t.pressed = 0 --1 = pressed right, -1 = pressed left
  return setmetatable(t, GUIMenu)
end

function GUIMenu.add(t, entryType, selectable, ...)
  local entry = GUIEntry['new' .. entryType](...)
  entry.selectable = selectable
  t.len = t.len + 1
  t.entries[t.len] = entry
end

function GUIMenu.draw(t, x, y, align, unselected)
  local ey = y
  for i = 1, t.len do
    local v = t.entries[i]
    
    local state = 0
    if not v.selectable then
      state = -1
    elseif t.pressed ~= 0 then
      state = 3 * t.pressed
      t.pressed = 0
    elseif i == t.selected then
      state = 1
    end
    
    v:draw(x, y, t.width, unselected and state >= 0 and 0 or state, align)
    y = y + ENTRY_HEIGHT
  end
end

function GUIMenu.switch(t, dir)
  local ns = t.selected + dir
  while ns > 1 and ns < t.len and not t.entries[ns].selectable do
    ns = ns + dir
  end
  if t.entries[ns] and t.entries[ns].selectable then
    t.selected = ns
    return true
  end
  return false
end

function GUIMenu.input(t, scancode) --Common function for checking the menu input
  if input.isKeySet(scancode, 'menu_up', 0) then
    t.sound("move")
    return t:switch(-1)
  elseif input.isKeySet(scancode, 'menu_down', 0) then
    t.sound("move")
    return t:switch(1)
  elseif input.isKeySet(scancode, 'menu_right', 0) then
    local entry = t.entries[t.selected]
    if not entry or entry.type == "button" then
      return false
    else
      t.sound("move")
      entry:switch(1)
    end
  elseif input.isKeySet(scancode, 'menu_left', 0) then
    local entry = t.entries[t.selected]
    if entry.type == "button" then
      return false
    else
      t.sound("move")
      entry:switch(-1)
    end
  elseif input.isKeySet(scancode, 'menu_select', 0) then
    local entry = t.entries[t.selected]
    if entry.type ~= "button" then
      return false
    else
      t.sound("select")
      entry:switch(1)
    end
  else
    return false
  end
  return true
end

return GUIMenu