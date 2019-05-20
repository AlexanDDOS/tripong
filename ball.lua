local ball = {}

ball.pos = {0, 0}
ball.dir = {0, 0}
ball.angle = 0
ball.speed = 120
ball.radius = 8

local DPI = math.pi * 2 -- Double PI
local sin = math.sin
local cos = math.cos

local function format(sx, sy, angle, speed)
  return {sx, sy}, angle, speed, {speed * cos(angle), speed * sin(angle)}
end

local function normalizeAngle(a) --Normalize the angle value for range [0; math.pi)
  local aa = math.abs(a) % DPI
  if a < 0 then
    return DPI - aa
  end
  return aa
end

function ball.init(x, y, a, v)
  a = normalizeAngle(a or ball.angle)
  v = v or ball.speed
  ball.pos, ball.angle, ball.speed, ball.dir = format(x, y, a, v)
end


function ball.setAngle(a)
  a = normalizeAngle(a)
  local s = ball.speed
  ball.angle = a
  ball.dir[1] = s * cos(a)
  ball.dir[2] = s * sin(a)
end

function ball.reflect(angle) --angle = platform angle
  local ba = ball.angle
  local ra = ba - angle
  
  if ba > math.pi then
    ba = DPI - ba
    ra = math.pi - ba - angle
  end
  
  
  local da = math.pi - ra * 2
  da = (math.pi - da) / 2
  
  da = -2 * da
  
  ball.setAngle(ball.angle + da)
end

function ball.predict(t)
  return ball.pos[1] + ball.dir[1] * t, ball.pos[2] + ball.dir[2] * t
end

function ball.move(dt)
  local dx = math.min(ball.dir[1] * dt, ball.radius)
  local dy = math.min(ball.dir[2] * dt, ball.radius)
  ball.pos[1], ball.pos[2] = ball.pos[1] + dx, ball.pos[2] + dy
end

return ball