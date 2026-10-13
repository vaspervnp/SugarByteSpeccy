-- cells.lua — the 10 cells of the board, 24x24, opaque (see common.lua).
--
--   0 plain        bright blue, dotted grid on the right and at the bottom
--   1 plain_alt    the other square of the board: three dots
--   2 hole         outside the board: black
--   3 jelly1       a cyan rim (the rim, not the middle: a candy hides that)
--   4 jelly2       a double rim with gumdrop corners
--   5-7 icing      three layers: whole, cracked, crumbling
--   8 chocolate    a bar of four squares (spreads if not broken)
--   9 licorice     a wheel (blocks the cell)
-- A candy on a cell keeps the cell's paper and puts its own ink, so the
-- marks of a cell a candy can sit on (plain, jelly) take the candy's colour.
dofile(ROOT .. "tools/aseprite/common.lua")

local abs = math.abs
local frames = {}
local function add(g) frames[#frames + 1] = g end

local function plain()
  local g = grid(24, 24, "B")
  for k = 1, 23, 4 do px(g, 23, k, "W") px(g, k, 23, "W") end
  return g
end
add(plain())
do
  local g = plain()
  for _, d in ipairs({{5, 6}, {16, 10}, {9, 17}}) do rect(g, d[1], d[2], d[1] + 1, d[2], "W") end
  add(g)
end
add(grid(24, 24, "k"))

local function rim(g, inset, thick, ink)
  for y = 0, 23 do
    for x = 0, 23 do
      local dx = math.min(x, 23 - x) - inset
      local dy = math.min(y, 23 - y) - inset
      local d = math.min(dx, dy)
      if dx >= 0 and dy >= 0 and d < thick and dx + dy >= 1 then px(g, x, y, ink) end
    end
  end
end
do
  local g = grid(24, 24, "B")
  rim(g, 0, 2, "C")
  add(g)
end
do
  local g = grid(24, 24, "B")
  rim(g, 0, 2, "C")
  for y = 4, 19 do
    for x = 4, 19 do
      if (x == 4 or x == 19 or y == 4 or y == 19) and (x + y) % 2 == 0 then px(g, x, y, "C") end
    end
  end
  for _, c in ipairs({{2, 2}, {19, 2}, {2, 19}, {19, 19}}) do rect(g, c[1], c[2], c[1] + 2, c[2] + 2, "C") end
  add(g)
end

-- icing: white frosting, its edge shaded blue, cracks as it breaks
local function icing(level)
  local g = grid(24, 24, "W")
  for y = 0, 23 do
    for x = 0, 23 do
      if x >= 22 or y >= 22 then px(g, x, y, ((x + y) % 2 == 0) and "B" or "W") end
      if x == 23 or y == 23 then px(g, x, y, "B") end
    end
  end
  if level <= 2 then                                  -- a crack
    paste(g, {"B.....", ".B....", ".BB...", "...B..", "...B..", "....BB", "......B", "......B"}, 4, 3)
    paste(g, {"..B", ".B.", "B..", "B..", ".B."}, 15, 13)
  end
  if level <= 1 then                                  -- crumbling: half gone
    for y = 0, 23 do
      for x = 0, 23 do
        if x + y >= 20 and (x + y) % 2 == 0 then px(g, x, y, "B") end
        if x + y >= 30 and (x * 3 + y) % 4 ~= 0 then px(g, x, y, "B") end
      end
    end
  end
  return g
end
add(icing(3))
add(icing(2))
add(icing(1))

do                                                    -- chocolate
  local g = grid(24, 24, "r")
  for sy = 0, 1 do
    for sx = 0, 1 do
      local x0, y0 = sx * 12 + 1, sy * 12 + 1
      rect(g, x0, y0, x0 + 9, y0, "y")               -- the light edges
      rect(g, x0, y0, x0, y0 + 9, "y")
      for y = y0 + 2, y0 + 8 do
        for x = x0 + 2, x0 + 8 do
          if (x + y) % 4 == 0 then px(g, x, y, "y") end
        end
      end
    end
  end
  add(g)
end
do                                                    -- licorice
  local g = grid(24, 24, "k")
  for y = 0, 23 do
    for x = 0, 23 do
      local u, v = uv(x, y)
      local d = math.sqrt(u * u + v * v)
      if d <= 11 and ((d >= 2.2 and d < 3.6) or (d >= 5.4 and d < 6.8) or (d >= 8.6 and d <= 11)) then
        px(g, x, y, "w")
      end
      if d < 1.5 then px(g, x, y, "W") end
    end
  end
  -- a bright centre needs a bright cell: keep the centre grey too
  rect(g, 11, 11, 12, 12, "w")
  add(g)
end

finish("cells", frames, {{"board", 0, 2}, {"jelly", 3, 4}, {"icing", 5, 7}, {"blocker", 8, 9}}, 5)
