-- menu.lua — the menu's 32x24 tiles on black: a magenta plate (middle, left
-- end, right end; the label goes in a black box over its middle row) and the
-- pointer in two phases, its stripes moving.
dofile(ROOT .. "tools/aseprite/common.lua")

local abs = math.abs
local frames = {}

local function plate(kind)
  local g = grid(32, 24, "k")
  for y = 2, 21 do
    for x = 0, 31 do
      local inside = true
      local cx
      if kind == "l" and x < 12 then cx = 12 end
      if kind == "r" and x > 19 then cx = 19 end
      if cx then
        local u, v = x + 0.5 - cx, y + 0.5 - 12
        inside = u * u + v * v <= 10.2 * 10.2
      end
      if inside then
        local ch = "M"
        if y >= 18 and (x + y) % 2 == 0 then ch = "k" end      -- shade underneath
        if y == 4 and (kind == "m" or (x >= 6 and x <= 25)) then ch = "k" end  -- shine line
        px(g, x, y, ch)
      end
    end
  end
  return g
end
frames[1] = plate("m")
frames[2] = plate("l")
frames[3] = plate("r")

local function pointer(phase)
  local g = grid(32, 24, "k")
  for y = 0, 23 do
    for x = 4, 27 do
      local half = (27 - x) * 10.5 / 23
      if abs(y + 0.5 - 12) <= half then
        local edge = abs(y + 0.5 - 12) > half - 1.2 or x == 4
        local stripe = (x - y + phase) % 8 < 3
        px(g, x, y, (edge or not stripe) and "R" or "k")
      end
    end
  end
  return g
end
frames[4] = pointer(0)
frames[5] = pointer(4)

finish("menu", frames, {{"plate", 0, 2}, {"pointer", 3, 4}}, 5)
