local states = require 'states'
local fonts = require 'fonts'
local sounds = require 'sounds'
local input = require 'input'
local menu --GUIMenu module
local fixedTimer = 0
local FIXED_INTERVAL = 1 / 60

-- Window settings
local WW = 800 --Unit width
local WH = 600 --Unit height
WS = 1 --Window scale

function love.load(args)
  if args[#args] == '-debug' then
    require("mobdebug").start()
  end
  
  love.window.updateMode(WW * WS, WH * WS)
  love.window.setTitle("TriPong")
  
  --Add modules to states.commonModules
  states.commonModules.fonts = fonts
  states.commonModules.sounds = sounds
  states.commonModules.input = input
  states.commonModules.states = states
  
  --gui.menu requires some defined assets to be loaded
  fonts.add("assets/fonts/Monoid-Regular.ttf", "ui", 28)
  menu = require 'gui.menu'
  states.commonModules.menu = menu
  
  --Do the definition script
  do
    local defFile, err = loadfile("def.lua")
    assert(love.load ~= nil)
    if defFile then
      setfenv(defFile, states.commonModules)
      defFile()
    else
      error(err)
    end
  end
  
  states.add("states/game.lua", "game")
  states.add("states/menu.lua", "menu")
  states.add("states/lobby.lua", "lobby")
  states.add("states/settings.lua", "settings")
  
  states.load("menu")
end

function love.update(dt)
  states.getFromCurrent('update')(dt)
  if fixedTimer >= FIXED_INTERVAL then
    states.getFromCurrent('fixedUpdate')(FIXED_INTERVAL)
    fixedTimer = fixedTimer - FIXED_INTERVAL
  end
  fixedTimer = fixedTimer + dt
end

function love.draw()
  love.graphics.push()
  love.graphics.scale(WS)
  states.getFromCurrent('draw')()
  love.graphics.pop()
end

function love.keypressed(key, scancode, repeats)
  states.getFromCurrent('keypressed')(key, scancode, repeats)
end