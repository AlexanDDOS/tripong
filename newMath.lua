local newMath = {}

function newMath.distSq(x1, y1, x2, y2) --The square of the distance between (x1, y1) to (x2, y2)
  local dx, dy = x2 - x1, y2 - y1
  return dx * dx + dy * dy
end

function newMath.dist(x1, y1, x2, y2) --The distance between (x1, y1) to (x2, y2)
  return math.sqrt(newMath.distSq(x1, y1, x2, y2))
end

function newMath.moveTime(x1, y1, x2, y2, s) --Time to move from (x1, y1) to (x2, y2) with vector speed s
  return newMath.dist(x1, y1, x2, y2) / s
end

return newMath