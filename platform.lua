local PlatModule = {}
local HPL = 32 --Half PLatform length
local PL = 64 --Full PLatform length
local PW = 8 --Platform width
local ps = 128 --Platform speed
local MD = 0.1 --Maximal deviation

function PlatModule.__index(t, k)
  return rawget(t, k) or PlatModule[k]
end

local function lerp(x, a, b)
  if a > b then
    return lerp(x, b, a)
  elseif x < a then
    return a
  elseif x > b then
    return b
  end
  return x
end

function PlatModule.new(angle, cx, cy, upperLimit, lowerLimit, localPlayer)
  local sin, cos = math.sin(angle), math.cos(angle)
  local t = {}
  t.angle = angle
  t.center = {cx, cy} --Platform line center
  t.limits = {upperLimit, lowerLimit} --Platform Y limits
  if math.abs(sin) < math.sin(0.5) then --Freaking inaccurate trigonometric functions
    t.olimits = {(lowerLimit - cx) - HPL, (upperLimit - cx) + HPL}
  else
    t.olimits = {(lowerLimit - cy) / sin + HPL + PW * cos, (upperLimit - cy) / sin - HPL - PW * cos} --Platform X limits relative to the PLatform line
  end
  t.offset = 0 --X offset relative to the PLatform line
  t.localPlayer = localPlayer --false if the platform is controlled by AI or online player
  return setmetatable(t, PlatModule)
end

function PlatModule.move(t, offset)
  t.offset = lerp(t.offset + offset * ps, t.olimits[1], t.olimits[2])
end

function PlatModule.draw(t)
  love.graphics.push()
  love.graphics.translate(unpack(t.center))
  love.graphics.rotate(t.angle)
  love.graphics.rectangle('fill', t.offset - HPL, -PW, PL, PW)
  love.graphics.pop()
end

-- Ball intersection test functions
--bx, by, br = Ball X, Ball Y, Ball radius
local function intersectionPoints(a, b, c, br)
  local fds = a*a+b*b --Factor vector's dot product with itself
  assert(fds ~= 0, "A and B factors both are equal to zero")
  local d = c*c - br*br*fds
  local ad = math.abs(d)
  local x0, y0 = -a*c/fds, -b*c/fds
  if d > MD then
    return 
  elseif ad < MD then
     return {x0, y0}
  else
    local k = br*br - c*c / fds
    local m = math.sqrt(k / fds)
    return {x0 + b*m, y0 - a*m}, {x0 - b*m, y0 + a*m}
  end
end

local function between(x, a, b)
  if a > b then
    return between(x, b, a)
  end
  return a <= x and x <= b
end

local function getABC(x1, y1, x2, y2)
  return y1 - y2, x2 - x1, x1*y2 - x2*y1
end

local function det(a, b, c, d)
  return a*d - c*b
end

local function intersects(x1, y1, x2, y2, br) --Intersection points of the ball and the platform
  local a, b, c = getABC(x1, y1, x2, y2)
  local i1, i2 = intersectionPoints(a, b, c, br)
  if i1 == nil then
    return
  elseif i2 == nil then
    i2 = i1
  end
  return i1, i2
end

function PlatModule.rayIntersects(t, x3, y3, x4, y4, inside) 
  --(x3, y3) = ray start, (x4, y4) = second ray point, inside = inside the platform limits
  local sin, cos = math.sin(t.angle), math.cos(t.angle)
  local cx, cy = t.center[1], t.center[2]
  local x1, y1 = cx + (t.offset + HPL) * cos, cy + (t.offset + HPL) * sin
  local x2, y2 = cx + (t.offset - HPL) * cos, cy + (t.offset - HPL) * sin
  
  local a1, b1, c1 = getABC(x1, y1, x2, y2)
  local a2, b2, c2 = getABC(x3, y3, x4, y4)
  
  local div = det(a1, b1, a2, b2)
  if div == 0 then
    return
  end
  
  local ix, iy
  ix = -det(c1, b1, c2, b2) / div
  iy = -det(a1, c1, a2, c2) / div
  
  if (ix - x3) * (x4 - x3) < 0 then --Check if the intersection point is on the ray
    return
  end
  if inside then
    if t.angle == math.pi then
      if not between(ix, t.limits[1], t.limits[2]) then
        return
      end
    elseif not between(iy, t.limits[1], t.limits[2]) then
      return
    end
  end
  
  return ix, iy
end

function PlatModule.intersects(t, bx, by, br)
  local sin, cos = math.sin(t.angle), math.cos(t.angle)
  local cx, cy = t.center[1], t.center[2]
  local dx, dy = cx - bx, cy - by
  local x1, y1 = dx + (t.offset + HPL) * cos, dy + (t.offset + HPL) * sin
  local x2, y2 = dx + (t.offset - HPL) * cos, dy + (t.offset - HPL) * sin
  local i1, i2 = intersects(x1, y1, x2, y2, br)
  if i1 ~= nil then
    return between(i1[1], x2, x1) or between(i2[1], x2, x1)
  elseif dx*dx + dy*dy <= br * br then
    return true
  end
end

function PlatModule.getX(t, y)
  local cx, cy = t.center[1], t.center[2]
  local ctg = 1 / math.tan(t.angle)
  if t.angle == math.pi / 2 then
    return cx
  end
  return cx + (y - cy) * ctg
end

function PlatModule.getY(t, x)
  local cx, cy = t.center[1], t.center[2]
  local tg = math.tan(t.angle)
  if t.angle == math.pi / 2 then
    return cy
  end
  return cy + (x - cx) * tg
end

function PlatModule.getCurY(t)
  return t.center[2] + t.offset * math.sin(t.angle)
end

function PlatModule.lost(t, bx, by, br)
  local cx, cy = t.center[1] - bx, t.center[2] - by
  local sin, cos = math.sin(t.angle), math.cos(t.angle)
  local x1, y1 = cx + HPL * cos, cy + HPL * sin
  local i1, i2 = intersects(cx, cy, x1, y1, br)
  if i1 then
    return true
  end
end

return PlatModule