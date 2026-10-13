-- overlay.lua — the 14 overlays drawn over a cell, 24x24, masked.
--
--   0-1    cursor (white, blinking) and selection (cyan): brackets in the
--          four corner character cells only, so the candy keeps its colour
--   2-3    cage, marmalade (blockers the levels do not use yet)
--   4-7    pop: flash, ring, sparks, dust
--   8-11   beams of a striped candy: across thick, thin; down thick, thin
--   12-13  stars: small, big (a special is born, an ingredient is home, the
--          stars of a win)
dofile(ROOT .. "tools/aseprite/common.lua")

local abs, sin, cos, pi = math.abs, math.sin, math.cos, math.pi
local frames = {}
local function add(g) frames[#frames + 1] = g end

local function brackets(ink)
  local g = grid(24, 24)
  for _, c in ipairs({{0, 0, 1, 1}, {23, 0, -1, 1}, {0, 23, 1, -1}, {23, 23, -1, -1}}) do
    local x0, y0, dx, dy = c[1], c[2], c[3], c[4]
    for k = 0, 5 do
      for t = 0, 1 do
        px(g, x0 + dx * k, y0 + dy * t, ink)
        px(g, x0 + dx * t, y0 + dy * k, ink)
      end
    end
  end
  return g
end
add(brackets("W"))
add(brackets("C"))

do                                                  -- cage
  local g = grid(24, 24)
  for y = 0, 23 do
    for _, x in ipairs({2, 3, 11, 12, 20, 21}) do px(g, x, y, "W") end
  end
  rect(g, 0, 3, 23, 4, "W")
  rect(g, 0, 19, 23, 20, "W")
  add(g)
end
do                                                  -- marmalade
  local g = grid(24, 24)
  for y = 0, 23 do
    for x = 0, 23 do
      if (x + y) % 2 == 0 or x == 0 or y == 0 or x == 23 or y == 23 then px(g, x, y, "Y") end
    end
  end
  add(g)
end

-- pop
do
  local g = grid(24, 24)                            -- flash: a fat plus
  rect(g, 10, 9, 13, 14, "W")
  rect(g, 9, 10, 14, 13, "W")
  add(g)
end
do
  local g = grid(24, 24)                            -- ring
  for y = 0, 23 do
    for x = 0, 23 do
      local u, v = uv(x, y)
      local d = u * u + v * v
      if d >= 3.2 ^ 2 and d <= 5.3 ^ 2 then px(g, x, y, "W") end
    end
  end
  add(g)
end
local function sparks(r, n, size, ink, phase)
  local g = grid(24, 24)
  for k = 0, n - 1 do
    local a = 2 * pi * k / n + phase
    local cx, cy = 12 + r * cos(a), 12 + r * sin(a)
    for y = 0, 23 do
      for x = 0, 23 do
        if abs(x + 0.5 - cx) <= size and abs(y + 0.5 - cy) <= size then px(g, x, y, ink) end
      end
    end
  end
  return g
end
add(sparks(7, 8, 1.0, "C", 0.2))
add(sparks(10, 12, 0.5, "C", 0.5))

-- beams
do
  local g = grid(24, 24) rect(g, 0, 7, 23, 16, "W") rect(g, 0, 9, 23, 14, "W") add(g)
  g = grid(24, 24) rect(g, 0, 10, 23, 13, "W") add(g)
  g = grid(24, 24) rect(g, 7, 0, 16, 23, "W") add(g)
  g = grid(24, 24) rect(g, 10, 0, 13, 23, "W") add(g)
end

-- stars: five points, pointing up
local function star(rout, ink, glint)
  local g = grid(24, 24)
  local pts = {}
  for k = 0, 9 do
    local r = (k % 2 == 0) and rout or rout * 0.45
    local a = -pi / 2 + k * pi / 5
    pts[#pts + 1] = {r * cos(a), r * sin(a) + rout * 0.08}
  end
  local function inside(u, v)
    local c = false
    local j = #pts
    for i = 1, #pts do
      local xi, yi, xj, yj = pts[i][1], pts[i][2], pts[j][1], pts[j][2]
      if ((yi > v) ~= (yj > v)) and (u < (xj - xi) * (v - yi) / (yj - yi) + xi) then c = not c end
      j = i
    end
    return c
  end
  candy_shape(g, inside, ink, {glint = glint, shade = glint and 2 or nil})
  return g
end
add(star(5, "Y", false))
add(star(11.5, "Y", true))

finish("overlay", frames, {
  {"cursor", 0, 1}, {"blocker", 2, 3}, {"pop", 4, 7},
  {"beam_h", 8, 9}, {"beam_v", 10, 11}, {"star", 12, 13},
}, 7)
