local state = {}

local LOBBY_STATE = "lobby"

local mainMenu = modules.menu.new(300)
mainMenu:add('Button', true, 'New Game', function() modules.states.load(LOBBY_STATE) end)
mainMenu:add('Button', true, 'Settings', function() modules.states.load("settings") end)
mainMenu:add('Button', true, 'Quit', function() love.event.quit(0) end)

local DELTA_WIDTH = modules.fonts.get("ui", 1):getWidth("Δ")
local function drawLogo(x, y, s)
  local dw = DELTA_WIDTH * s --_G.WS is declared in main.lua
  love.graphics.setColor(1, 0, 0)
  modules.fonts.print("ui", s, "Tri", x, y)
  love.graphics.setColor(0, 1, 0)
  modules.fonts.print("ui", s, "P NG", x + dw * 3, y)
  love.graphics.setColor(0, 0, 1)
  modules.fonts.print("ui", s, "Δ", x + dw * 4 * 0.975, y)
end

local TAN30 = math.tan(math.pi / 6)
local function drawField(x, y, w, h)
  local cx = x + w / 2, y
  love.graphics.setColor(1, 0, 0)
  love.graphics.line(cx, y, cx - h * TAN30 , y + h)
  love.graphics.setColor(0, 1, 0)
  love.graphics.line(cx, y, cx + h * TAN30 , y + h)
  love.graphics.setColor(0, 0, 1)
  love.graphics.line(cx - h * TAN30 , y + h, cx + h * TAN30 , y + h)
end

love.graphics.setDefaultFilter("nearest", "nearest")
local machine = love.graphics.newImage("assets/sprites/machine.png")
local machineBG = love.graphics.newImage("assets/sprites/machine_bg.png")
local mTextWink = true
local mTextWinkTimer = 0
local function drawMachine(x, y, s)
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(machineBG, x, y, 0, s * 3)
  drawLogo(x + (22 * s * 3), y + (3 * s), s)
  drawField(x + 32 * s, y + 58 * s, 186 * s, 96 * s)
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(machine, x, y, 0, s * 3)
  s = s * WS
  if mTextWink then
    modules.fonts.print("ui", s * 0.5, "INSERT COIN", 
      x + 26 * s, y + 72 * s, 195 * s, "center")
  end
end

function state.update(dt)
  mTextWinkTimer = mTextWinkTimer + dt
  if mTextWinkTimer >= .75 then
    mTextWink = not mTextWink
    mTextWinkTimer = mTextWinkTimer - .75
  end
end

function state.draw()  
  love.graphics.setBackgroundColor(0, 0, 0)
  
  drawLogo(0, 0, 2)
  drawMachine(400, 140, 1.5)
  
  modules.fonts.print("ui", 0.4, 
    "Code & sprites by AlexanDDOS\nSound by SubspaceAudio\nv. 1.0.2", 
    496, 550, 300, "right")
  
  mainMenu:draw(8, 462, "left")
end

function state.unload()
  mainMenu.selected = 1
end

function state.keypressed(key, scancode, repeats)
  mainMenu:input(scancode)
end

return state