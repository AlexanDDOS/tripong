local state = {}

local PlatModule = require 'platform'
local ball = require 'ball'
local newMath = require 'newMath'

local sleeping = false
local paused = false
local gameOver = false
local winners = {}
local sleepTimer = 0
local afterSleep --Function called after sleeping
local topBorder = 32
local bottomBorder = 600

--Game timer
local timer = 0 -- in seconds
local timerCount = 1 --1 = count up, -1 = count down, 0 = pause
local maxTime
local maxScore

-- Platform & Players Block
local playerN
local platforms
local lost = {false, false, false}
local lost_n = 0
local lastCollided = 0
local wink = false
local winkTimer = 0

local ai = {false, false, false} --If the platform i is controlled by AI
local aiData = {{}, {}, {}} --AI Data for each player

-- Pause menu
local pauseMenu = modules.menu.new(200)
pauseMenu:add('Button', true, 'Resume', function() paused = false end)
pauseMenu:add('Button', true, 'Quit', function() modules.states.load("menu") end)

-- Game functions
local function sleep(t, after)
  sleepTimer = t or math.huge
  sleeping = true
  afterSleep = after
end

local function predictAI(dt)
  local bx1, by1 = ball.pos[1], ball.pos[2]
  local bx2, by2 = ball.predict(dt)
  for i = 1, playerN do
    local ix, iy = platforms[i]:rayIntersects(bx1, by1, bx2, by2, i == 3)
    if iy and ai[i] then
      local bd = newMath.dist(bx1, bx2, ix, iy) --Ball distance
      aiData[i].bt = bd / ball.speed --Ball reach time
      local aad = 32 --Absolute allowed deviation
      if aiData[i].bt > 1 then
        aad = aad + aiData[i].bt * love.math.random(1, 3)
      end
      
      local dev --Reach point deviation
      if i == 3 and (aiData[1].ry or aiData[2].ry) then
        dev = 0
        if aiData[1].ry then
          aiData[1].ry = iy
          local y = platforms[1]:getCurY()
          local x = platforms[1]:getX(y)
          aiData[1].rt = newMath.moveTime(x, y, ix, iy, 128) --Reaction time
        elseif aiData[2].ry then
          local y = platforms[2]:getCurY()
          local x = platforms[2]:getX(y)
          aiData[2].rt = newMath.moveTime(x, y, ix, iy, 128) --Reaction time
          aiData[2].ry = iy
        end
      else
        dev = love.math.random(-aad, aad)
      end
      
      local rx, ry = ix + dev, iy + dev
      aiData[i].rx = rx --Reached X
      aiData[i].ry = ry --Reached Y
      
      local y = platforms[i]:getCurY()
      local x = platforms[i]:getX(y)
      if i == 3 then
        x = x - platforms[i].offset
      end
      aiData[i].rt = newMath.moveTime(x, y, rx, ry, 128) --Reaction time
      aiData[i].rt = aiData[i].rt * (2 + love.math.random())
    elseif ai[i] then
      aiData[i].rx = nil
      aiData[i].ry = nil
      aiData[i].rt = math.huge
      aiData[i].bt = math.huge
    end
  end
end

local function init(pn) 
  -- (Re)initalize the ball and platforms.
  -- If 'pn' is 0 then just reset the existing ones' positions, else set pn platforms.
  
  --Initalize the ball
  ball.speed = 120
  local chance = love.math.random(4)
  ball.init(400, 300, math.pi * (0.25 + chance / 2)) --PI/4 + PI/2 * chance
  
  --Initalize platforms
  lastCollided = 0
  aiData = {{}, {}, {}}
  if pn and pn > 0 then
    playerN = math.min(pn, 3)
    platforms = {}
    
     --WARRING: the lateral lines' initial centers are set in their intersection point
     --and to be corrected (moved where they should be) after the initialization
    if pn > 2 then
      platforms[1] = PlatModule.new(-math.pi / 3, 400, 300, 32, 540, not ai[1])
      platforms[2] = PlatModule.new(math.pi / 3, 400, 300, 540, 32, not ai[2])
    else
      platforms[1] = PlatModule.new(-math.pi / 3, 400, 300, 32, 600, not ai[1])
      platforms[2] = PlatModule.new(math.pi / 3, 400, 300, 600, 32, not ai[2])
    end
    
    --Correct the lateral lines' centers
    platforms[1].center[1] = 2 * platforms[1].center[1] - platforms[1]:getX(32)
    platforms[2].center[1] = 2 * platforms[2].center[1] - platforms[2]:getX(32)
    if pn > 2 then
      platforms[3] = PlatModule.new(math.pi, 400, 540, platforms[1]:getX(540), 
        platforms[2]:getX(540), not ai[3])
    end
  end
  
  for i = 1, playerN do
    platforms[i].offset = 0
    lost[i] = false
  end
  lost_n = 0
  predictAI(0.1)
end

local function timerStr()
  local m = math.floor(timer / 60)
  local s = math.floor(timer) - m * 60
  return string.format("%.2d %.2d", m, s)
end

local function checkInput(dt)
  for i = 1, playerN do
    local dir = dt --Equals to dt for i = 1 or 3, and -dt for i = 2
    if i > 1 then
      dir = -dir
    end
    
    if ai[i] then
      local data = aiData[i]
      data.bt = data.bt - dt
    end
    
    --Check input
    if platforms[i].localPlayer then
      if modules.input.isDown('move_up', i) then
        platforms[i]:move(dir)
      elseif modules.input.isDown('move_down', i) then
        platforms[i]:move(-dir)
      end
    elseif ai[i] and aiData[i].ry then
      local data = aiData[i]
      local y = platforms[i]:getCurY()
      local x = platforms[i]:getX(y)
      local d
      if i == 3 then
        x = x - platforms[i].offset
        d = data.rx - x
      else
        d = y - data.ry
      end
      
      if data.bt <= data.rt or data.ry > bottomBorder then
        if math.abs(d) < 1.5 then
          data.bt = math.huge --To prevent platform shaking
        elseif d > 0 then
          platforms[i]:move(dir)
          data.rt = data.rt - dt
        elseif d < 0 then
          platforms[i]:move(-dir)
          data.rt = data.rt - dt
        end
      end
    end
  end
end

function state.load(args)
  if not args then
    args = {3, {false, false, false}, 0, 5}
  end
  ai = args[2]
  if args[3] == 0 then
    maxTime = math.huge
  else
    maxTime = args[3]
  end
  maxScore = args[4]
  for i = 1, 3 do
    out.score[i] = 0
  end
  gameOver, winners = false, {}
  timer = 0
  paused, sleeping, sleepTimer = false, false, 0
  init(args[1])
end

function state.update(dt)
  winkTimer = winkTimer + dt
  if winkTimer >= 0.25 then
    winkTimer = winkTimer - 0.25
    wink = not wink
  end
  
  if not (paused or sleeping or gameOver) then
    timer = timer + dt * timerCount
    if timer >= maxTime * 60 then
      gameOver = true
      local maxScore = 0
      for i = 1, playerN do
        if out.score[i] > maxScore then
          winners = {i}
          maxScore = i
        elseif out.score[i] == maxScore then
          winners[#winners + 1] = i
        end
      end
    else
      for i = 1, playerN do
        if out.score[i] >= maxScore and not gameOver then
          winners[#winners + 1] = i
        end
      end
      if #winners > 0 then
        gameOver = true
      end
    end
    
  end
  if not paused then
    if sleepTimer > 0 then
      sleepTimer = sleepTimer - dt
    elseif sleeping then
      sleeping = false
      if afterSleep then
        afterSleep()
      end
    end
  end
end

function state.fixedUpdate(dt)
  if not (paused or sleeping or gameOver) then
    checkInput(dt)
    
    local reflected = false -- If the ball is reflected
    ball.move(dt)
    
    for i = 1, playerN do
      if platforms[i]:intersects(ball.pos[1], ball.pos[2], ball.radius) then
        if i ~= lastCollided then
          ball.reflect(platforms[i].angle)
          lastCollided = i
          modules.sounds.playSFX("reflection")
        end
        reflected = true -- This flag is true even if lastCollided == i
      end
    end
      
    if ball.pos[2] - ball.radius <= topBorder or ball.pos[2] + ball.radius >= bottomBorder then
      ball.reflect(0)
      lastCollided = -lastCollided --Minus means a reflected pass 
      modules.sounds.playSFX("reflection")
      reflected = true
    end
    
    if reflected then
      predictAI(dt)
    else
      for i = 1, playerN do
        if platforms[i]:lost(ball.pos[1], ball.pos[2], ball.radius) then
            lost[i] = true
            lost_n = lost_n + 1
        end
      end
    end
    
    if lost_n > 0 then
      local wp = math.abs(lastCollided) -- The round winner (last player, who returned the ball)
      if wp ~= 0 then
        -- The round winner gets: 
        --   1 point for crossing an rival line
        --   2 points for crossing 2 rival lines' intersection
        --   -1 point for crossing their own line (autogoal)
        if lost[wp] then
          out.score[wp] = out.score[wp] - 1
        else
          out.score[wp] = out.score[wp] + lost_n
        end
      else
        --If the initial pass is lost, each player besides the loser get a point
        for i = 1, playerN do
          if not lost[i] then
            out.score[i] = out.score[i] + 1 
          end
        end
      end
      modules.sounds.playSFX("goal")
      sleep(2, init)
    end
  end
end

local function blinkingColor(id)
  return lost[id] and wink and {1, 1, 1} or out.playerColors[id]
end

function state.draw()
  for i = 1, playerN do
    love.graphics.setColor(lost[i] and wink and {1, 1, 1} or out.playerColors[i])
    platforms[i]:draw()
  end
  
  --Draw platform lines
  if playerN == 3 then
    love.graphics.setColor(blinkingColor(1))
    love.graphics.line(platforms[1]:getX(32), 32, platforms[1]:getX(540), 540)
    love.graphics.setColor(blinkingColor(2))
    love.graphics.line(platforms[2]:getX(32), 32, platforms[2]:getX(540), 540)
    love.graphics.setColor(blinkingColor(3))
    love.graphics.line(platforms[1]:getX(540), 540, platforms[2]:getX(540), 540)
  else
    love.graphics.setColor(blinkingColor(1))
    love.graphics.line(platforms[1]:getX(32), 32, platforms[1]:getX(600), 600)
    love.graphics.setColor(blinkingColor(2))
    love.graphics.line(platforms[2]:getX(32), 32, platforms[2]:getX(600), 600)
  end
  
  --Timer
  love.graphics.setColor(1, 1, 1)
  modules.fonts.print("score", 0.5, timerStr(), 0, 0, 800, "center")
  modules.fonts.print("label", 0.5, ":", 0, -4, 800, "center")
  
  --Ball
  love.graphics.setColor(1, 1, 1)
  love.graphics.circle("fill", ball.pos[1], ball.pos[2], ball.radius)
  
  --Draw score
  love.graphics.setFont(modules.fonts.get("score", 1.0))
  love.graphics.setColor(out.playerColors[1])
  modules.fonts.print("score", 1, out.score[1], 0, 200, 236, 'right')
  love.graphics.setColor(out.playerColors[2])
  modules.fonts.print("score", 1, out.score[2], 546, 200)
  if playerN == 3 then
    love.graphics.setColor(out.playerColors[3])
    modules.fonts.print("score", 1, out.score[3], 300, 550, 200, 'center')
  end
  
  --Draw pause/"game over" menu
  if gameOver then
    --TODO: "Game over" screen
    love.graphics.setColor(1, 1, 1)
    modules.fonts.print("ui", 2, "GAME OVER", 0, 328, 800, "center")
    local wn = #winners
    if wn == 1 then
      local w = winners[1]
      love.graphics.setColor(out.playerColors[w])
      modules.fonts.print("ui", 1, "Player " .. w .. " wins!", 0, 436, 800, "center")
    elseif wn == 2 then
      local s = "Players %d & %d win!"
      s = s:format(unpack(winners))
      modules.fonts.print("ui", 1, s, 0, 436, 800, "center")
    else
      modules.fonts.print("ui", 1, "Draw game", 0, 436, 800, "center")
    end
    love.graphics.setColor(1, 1, 1)
    modules.fonts.print("ui", 1, "Press [RETURN] or [SPACE]\nto return to the main menu", 0, 72, 800, "center")
    
  elseif paused then
    love.graphics.setColor(0.25, 0.25, 0.25)
    love.graphics.rectangle('fill', 300, 220, 200, 32 + 36 * 3)
    love.graphics.setColor(1, 0, 0)
    modules.fonts.print("ui", 1.0, "PAUSED", 300, 220, 200, "center")
    pauseMenu:draw(300, 252, "center")
  end
end

function state.unload()
  
end

function state.keypressed(key, scancode, repeats)
  if gameOver then
    if modules.input.isKeySet(scancode, 'menu_select', 0) then
      modules.states.load("menu")
    end
  elseif modules.input.isKeySet(scancode, 'pause', 0) then
    paused = not paused
    pauseMenu.selected = 1
  end
  if paused then
    pauseMenu:input(scancode)
  end
end

return state
