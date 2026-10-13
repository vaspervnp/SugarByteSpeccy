-- candy.lua — the 27 candies, 24x24, masked (see common.lua).
--
--   0-5    plain: red ball, white hexagon (the CPC's orange), yellow square,
--          green diamond, cyan teardrop (its blue), magenta heart
--   6-11   striped across (clears a row)    12-17  striped down (a column)
--   18-23  wrapped (3x3)                     24     colour bomb
--   25     cherry                            26     nut
-- Each colour keeps its own silhouette: on a small TV, in black and white or
-- to a colour-blind player, the shape is what tells them apart.
dofile(ROOT .. "tools/aseprite/common.lua")

local INK = {"R", "W", "Y", "G", "C", "M"}
local abs = math.abs

local SHAPES = {
  function(u, v) return u * u + v * v <= 10.3 * 10.3 end,                    -- ball
  function(u, v) return abs(v) <= 9.5 and abs(u) + abs(v) * 0.55 <= 10.8 end,  -- hexagon
  function(u, v) return abs(u) <= 9.5 and abs(v) <= 9.5 and abs(u) + abs(v) <= 16.5 end, -- square
  function(u, v) return abs(u) + abs(v) <= 11.2 end,                           -- diamond
  function(u, v)                                                                -- teardrop
    if v >= 2.5 then return u * u + (v - 2.5) * (v - 2.5) <= 8 * 8 end
    return v >= -10.5 and abs(u) <= (v + 10.5) * 8 / 13 + 0.3
  end,
  function(u, v)                                                                -- heart
    local cl = (u + 5) * (u + 5) + (v + 3.5) * (v + 3.5) <= 5.6 * 5.6
    local cr = (u - 5) * (u - 5) + (v + 3.5) * (v + 3.5) <= 5.6 * 5.6
    local tri = v >= -3.5 and v <= 10 and abs(u) <= 10.5 * (10 - v) / 13.5
    return cl or cr or tri
  end,
}

local frames = {}
local function add(g) frames[#frames + 1] = g end

for i = 1, 6 do                                     -- plain
  local g = grid(24, 24)
  candy_shape(g, SHAPES[i], INK[i], {glint = true, shade = 2.5})
  add(g)
end
for i = 1, 6 do                                     -- striped across
  local g = grid(24, 24)
  candy_shape(g, SHAPES[i], INK[i], {stripes = "h"})
  add(g)
end
for i = 1, 6 do                                     -- striped down
  local g = grid(24, 24)
  candy_shape(g, SHAPES[i], INK[i], {stripes = "v"})
  add(g)
end

-- wrapped: a small round sweet in a wrapper twisted at both ends, the same
-- for every colour (only the colour changes)
local function wrapped(u, v)
  if u * u + v * v <= 6.8 * 6.8 then return true end
  local a = abs(u)
  return a >= 6 and a <= 11.5 and abs(v) <= (a - 4) * 1.1
end
for i = 1, 6 do
  local g = grid(24, 24)
  candy_shape(g, wrapped, INK[i], {glint = false, shade = 1.5})
  for y = 0, 23 do                                  -- the twist: a paper pleat
    for x = 0, 23 do
      local u, v = uv(x, y)
      local a = abs(u)
      if a >= 6.6 and a <= 7.6 and abs(v) <= 1.5 then px(g, x, y, "k") end
      if a >= 9.2 and a <= 10.2 and abs(v) <= 3.2 and abs(v) >= 0.5 and get(g, x, y) ~= "." then
        px(g, x, y, "k")
      end
    end
  end
  add(g)
end

-- colour bomb: a dark ball (paper) with a rim and sprinkles of ink, each
-- 8x8 cell its own colour: a rainbow of sprinkles
do
  local g = grid(24, 24)
  local inks = {"R", "Y", "G", "M", "W", "C", "G", "R", "Y"}
  local sprinkles = {{-5, -6}, {2, -7}, {6, -2}, {-7, 1}, {-1, -2}, {4, 4},
                     {-4, 6}, {1, 7}, {7, 6}, {-8, -3}, {3, -3}, {-2, 3}, {6, -7}, {-6, -7}}
  local function ball(u, v) return u * u + v * v <= 10.3 * 10.3 end
  for y = 0, 23 do
    for x = 0, 23 do
      local u, v = uv(x, y)
      if ball(u, v) then
        local ink = inks[(y // 8) * 3 + x // 8 + 1]
        local ch = "k"
        if not (ball(u - 1.5, v) and ball(u + 1.5, v) and ball(u, v - 1.5) and ball(u, v + 1.5)) then ch = ink end
        for _, sp in ipairs(sprinkles) do
          if abs(u - sp[1]) <= 1.1 and abs(v - sp[2]) <= 0.6 then ch = ink end
        end
        px(g, x, y, ch)
      end
    end
  end
  add(g)
end

-- cherry: two red cherries (rows 8-23) on green stalks with a leaf (rows 0-7)
do
  local g = grid(24, 24)
  local function balls(u, v)
    return (u + 4.5) ^ 2 + (v - 5) ^ 2 <= 5.6 ^ 2 or (u - 4.8) ^ 2 + (v - 4) ^ 2 <= 5.6 ^ 2
  end
  candy_shape(g, balls, "R", {shade = 6})
  for y = 0, 23 do                                  -- two glints
    for x = 0, 23 do
      local u, v = uv(x, y)
      if ((u + 6.5) ^ 2 + (v - 3) ^ 2 <= 1.2) or ((u - 2.8) ^ 2 + (v - 2) ^ 2 <= 1.2) then
        px(g, x, y, "k")
      end
    end
  end
  paste(g, {
    "...........GGGG.",
    ".........GGGGGGG",
    "........GG.GGGG.",
    ".......G..G.....",
    "......G....G....",
    ".....G......G...",
    "....G........G..",
    "....G.........G.",
    "...R..........R.",
  }, 4, 0)
  add(g)
end

-- nut: an acorn, its cap crossed, its body shaded
do
  local g = grid(24, 24)
  local function body(u, v)
    return v >= -2 and (u * u) / (7.5 * 7.5) + ((v - 2) ^ 2) / (8.5 * 8.5) <= 1
  end
  local function cap(u, v)
    return v <= -1 and v >= -8.5 and (u * u) / (10 * 10) + ((v + 1) ^ 2) / (7.5 * 7.5) <= 1
  end
  candy_shape(g, body, "Y", {glint = true, shade = 3})
  for y = 0, 23 do
    for x = 0, 23 do
      local u, v = uv(x, y)
      if cap(u, v) then
        local edge = not (cap(u - 1, v) and cap(u + 1, v) and cap(u, v - 1) and cap(u, v + 1))
        px(g, x, y, (edge or (x + y) % 4 ~= 0 and (x - y) % 4 ~= 0) and "Y" or "k")
      end
    end
  end
  rect(g, 11, 1, 12, 3, "Y")                        -- the stalk
  add(g)
end

finish("candy", frames, {
  {"plain", 0, 5}, {"striped_h", 6, 11}, {"striped_v", 12, 17},
  {"wrapped", 18, 23}, {"bomb", 24, 24}, {"ingredient", 25, 26},
}, 9)
