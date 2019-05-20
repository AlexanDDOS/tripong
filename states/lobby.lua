local state = {}

local input = require "input"
local rebinded = {nil, 0 , 0} --Rebinded action table: {action, player, entryID}

local ready = {false, false, false}
local ai = {false, nil, nil} --false = real player, true = AI, nil = not stated

local playerSections = {}
local selectedSection = 1
local optionMenu = modules.menu.new(640)
local optionsSelected = false

optionMenu:add("Slider", true, "Time: ", 0, 30, 2, 0, "%d minutes", {[0] = "unlimited"})
optionMenu:add("Slider", true, "Goal score: ", 1, 30, 1, 5)
optionMenu:add("Button", true, "Return", function() modules.states.load("menu") end)

local function getButton(action, player, prefix)
  local key = input.actions[action][player]
  if rebinded[1] then
    key = "???"
  elseif not key then
    key = "NOT SET"
  else
    key = key:match(".*_(.*)$")
  end
  return (prefix and prefix .. ": " or "") .. key:upper()
end

local function setBinded(action, player, entryID)
  rebinded[1] = action
  rebinded[2] = player
  rebinded[3] = entryID
end

local function bind(action, player, key)
  input.actions[action][player] = "KEY_" .. key
  rebinded[1] = nil
end

local function keyButton(action, player, prefix, entryID)
  local function localRefresh() 
    setBinded(action, player, entryID)
    playerSections[player].entries[entryID].text = getButton(action, player, prefix)
  end
  return getButton(action, player, prefix), localRefresh
end

local function compare(t, from, to, with)
  local c = 0
  for i = from, to do
    if t[i] == with then
      c = c + 1
    end
  end
  return c
end

local refresh --Menu refresh function

local function playerMenu(id)
  local menu = modules.menu.new(200)
  if ready[id] then
    local name
    if ai[id] then
      name = "AI " .. id
    else
      name = "PLAYER " .. id
    end
    menu:add('Button', false, name)
    menu:add('Button', false, "IS READY")
    menu:add('Button', true, "Cancel", 
      function()
        ready[id], ai[id] = false, nil
        ready[3], ai[3] = false, nil
        refresh(id)
      end
    )
    menu.selected = 3
  elseif ai[id] == false then
    menu:add('Button', true, keyButton("move_up", id, "Up", 1))
    menu:add('Button', true, keyButton("move_down", id, "Down", 2))
    menu:add('Button', true, "Ready", function() ready[id] = true; refresh(id) end)
  elseif ai[id] == true then
    menu:add('Button', true, "Ready", function() ready[id] = true; refresh(id) end)
  elseif compare(ai, 1, id - 1, nil) == 0 then
    menu:add('Button', false, "FREE SLOT")
    menu:add('Button', true, "Add player", function() ai[id] = false; refresh(id) end)
    menu:add('Button', true, "Add AI", function() ai[id] = true; refresh(id) end)
    menu.selected = 2
  else
    menu:add('Button', false, "LOCKED")
    menu.selected = 0
    selectedSection = 1
  end
  return menu
end

refresh = function(id)
  local start = true
  for i = 1, 3 do
    playerSections[i] = playerMenu(i)
    if ai[i] ~= nil and not ready[i] then
      start = false
    end
  end
  if start and ai[2] ~= nil then
    modules.states.load("game", {#ai, ai, optionMenu.entries[1].value, optionMenu.entries[2].value})
  end
end

function state.load(args)
  ready = {false, false, false}
  ai = {false, nil, nil}
  for i = 1, 3 do
    refresh(i) --Menu initialization
  end
end

function state.draw()
  love.graphics.setBackgroundColor(0, 0, 0)
  for i = 0, 2 do
    playerSections[i+1]:draw(70 + i * (200 + 20), 
      100, "center", i + 1 ~= selectedSection or optionsSelected)
  end
  optionMenu:draw(70, 300, "left", not optionsSelected)
end

function state.unload()
  
end

function state.keypressed(key, scancode, repeats)
  if rebinded[1] then
    local action, player, entryID = unpack(rebinded)
    if scancode == "escape" then
      setBinded(nil, 0, 0)
    else
      bind(action, player, scancode)
    end
    local entry = playerSections[player].entries[entryID]
    local prefix = entry.text:match("^(.*): ")
    entry.text = getButton(action, player, prefix)
    return 
  end
  
  if optionsSelected then
    if optionMenu:input(scancode) then
      return
    end
    
    if input.isKeySet(scancode, 'menu_up', 0) then
      optionMenu.sound("move")
      optionsSelected = false
    end
  else
    local ps = playerSections[selectedSection]
    if ps and ps.entries[ps.selected] and ps:input(scancode) then
      return
    end
    
    if input.isKeySet(scancode, 'menu_down', 0) then
      optionMenu.sound("move")
      optionsSelected = true
    elseif input.isKeySet(scancode, 'menu_right', 0) then
      optionMenu.sound("move")
      selectedSection = selectedSection + 1
      if selectedSection > 3 then
        selectedSection = 1
      end
    elseif input.isKeySet(scancode, 'menu_left', 0) then
      optionMenu.sound("move")
      selectedSection = selectedSection - 1
      if selectedSection < 1 then
        selectedSection = 3
      end
    end
  end
end

return state