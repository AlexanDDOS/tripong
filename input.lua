local input = {}
input.actions = {}
input.joysticks = love.joystick.getJoysticks()

function input.addAction(name, triggers)
  --'triggers' table struct:
  --{[playerID] = "DEV_TYPE_ID"}
  local action = triggers or {}
  input.actions[name] = triggers
end

function input.addMenuAction(name, keys, hat, axis)
  local triggers = {}
  local trigger_n = 0
  for i, v in ipairs(keys) do
    triggers[i] = "KEY_" .. v
    trigger_n = trigger_n + 1
  end
  for i = 1, #input.joysticks do
    trigger_n = trigger_n + 1
    triggers[trigger_n] = "JOY" .. tostring(i) .. "_AXIS_" .. axis
    triggers[trigger_n] = "JOY" .. tostring(i) .. "_HAT_" .. hat
  end
  input.actions[name] = triggers
end

function input.override(action, player, trigger)
  input.actions[action][player] = trigger
end

function input.isDown(action, player) --0 = any player
  if player == 0 then
    for i, v in ipairs(input.actions[action]) do
      local isDown = input.isDown(action, i)
      if isDown then
        return true
      end
    end
    return false
  end
  
  local trigger = input.actions[action][player]
  if trigger:sub(1, 3) == "JOY" then
    local joyId = tonumber(trigger:sub(4, 4))
    local joy = input.joysticks[joyId]
    local t, id = trigger:match("_(%w+)_(.+)")
    if t == "BUTTON" then
      id = tonumber(id)
      return joy:isDown(id)
    elseif t == "HAT" then
      local hat, id = id:match("(%d+)_(.+)")
      local hatDir = joy:getHat(hat)
      return hatDir == id
    elseif t == "AXIS" then
      local dir = id:sub(1, 1)
      id = id:sub(1)
      local axis = joy:getGamepadAxis(id)
      
      if dir == '-' then
        return axis < 0
      else
        return axis > 0
      end
    end
  elseif trigger:sub(1, 3) == "KEY" then
    local id = trigger:sub(5)
    return love.keyboard.isScancodeDown(id)
  end
  return false
end

function input.getValue(action, player)
  local trigger = input.actions[action][player]
  if trigger:sub(1, 3) == "JOY" then
    local joyId = tonumber(trigger:sub(4, 4))
    local joy = input.joysticks[joyId]
    local t, id = trigger:match("_(%w+)_(.+)")
    if t == "AXIS" then
      local dir = id:sub(1, 1)
      id = id:sub(1)
      return joy:getGamepadAxis(id)
    end
  end
  return input.isDown(action, player) and 1.0 or 0.0
end

function input.isKeySet(scancode, action, player)
  if player == 0 then --0 = any player
    for i = 1, #input.actions[action] do
      if input.isKeySet(scancode, action, i) then
        return true
      end
    end
  elseif input.actions[action][player]:sub(5) == scancode then
    return true
  end
  return false
end

return input
