local states = {}
states.all = {}
states.common = {} -- Common variables for all the states. Stored in the state environments as 'out'
states.commonModules = {} -- Common module variables for all the states. Stored in the state environments as 'mods'
states.current = nil

local env_mt = {}
function env_mt.__index(t, k)
  return rawget(t, k) or _G[k]
end
function env_mt.__newindex(t, k, v)
  _G[k] = v
end
local function initenv()
  local env = {}
  -- Add main global variables
  -- Add common variable tables
  env.out = states.common
  env.modules = states.commonModules
  
  return setmetatable(env, env_mt)
end

local function null()

end

function states.add(mod, tag)
  local err
  if tag == nil then
    tag = mod
  end
  
  mod, err = loadstring(love.filesystem.read(mod))
  if err then
    error(err)
  else
    local env = initenv()
    setfenv(mod, env)
    mod = mod()
    mod.env = env
    states.all[tag] = mod
    return mod
  end
end

function states.load(tag, args)
  local mod = states.all[tag]
  assert(mod ~= nil, string.format("state '%s' is not initalized", tag))
  
  if states.current ~= nil then
    states.unload()
  end
  states.current = tag
  if mod.load ~= nil then
    mod.load(args)
  end
end

function states.unload()
  local cur = states.getCurrent()
  if cur.unload() then
    cur.unload()
  end
  states.current = nil
end

function states.getCurrent()
  return states.all[states.current]
end

function states.getFromCurrent(k)
  return states.getCurrent()[k] or null
end

function states.cur(k) --Shortcut for states.getCurrent() and states.getFromCurrent()
  local cur = states.getCurrent()
  if k == nil then
    return cur
  end
  return cur[k] or null
end

return states