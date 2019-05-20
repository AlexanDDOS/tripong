local state = {}

local displayes = love.window.getDisplayCount()
local fs = love.window.getFullscreen()

local settingsMenu = modules.menu.new(792)
settingsMenu:add("Slider", true, "Sound Volume: ", 0, 100, 5, 
  modules.sounds.sfx.volume * 100, nil, {}, function(v)
    modules.sounds.setSFXVolume(v / 100)
    return true
  end)
settingsMenu:add("Switcher", true, "Fullscreen: ", nil, fs, {}, function(v) 
    fs = v
    return love.window.setFullscreen(v, "exclusive")
  end)
--[[settingsMenu:add("Slider", true, "Window scale: ", 0.5, 4, 0.25, WS, nil, {}, function(v)
    WS = v
    print(WS)
    love.window.updateMode(800 * WS, 600 * WS)
    return true
  end)]]
settingsMenu:add("Button", true, "Return", function() modules.states.load("menu") end)

function state.draw()
  settingsMenu:draw(4, 100, "left")
end

function state.keypressed(key, scancode, repeats)
  settingsMenu:input(scancode)
end

function state.unload()
  
end

return state