-- title.lua — the letters of SUGAR BYTE for the menu, 24x24 each: the font
-- three times over, its corners rounded and a glint in each stroke. One
-- ink a letter (the menu turns their colours round, src/anim.asm).
dofile(ROOT .. "tools/aseprite/common.lua")
dofile(ROOT .. "tools/aseprite/font_defs.lua")

local frames = {}
for ch in ("SUGARBYTE"):gmatch(".") do
  local rows = FONT[ch]
  local function on(x, y)
    if x < 0 or y < 0 or x > 7 or y > 7 then return false end
    return rows[y + 1]:sub(x + 1, x + 1) == "#"
  end
  local g = grid(24, 24)
  for gy = 0, 7 do
    for gx = 0, 7 do
      if on(gx, gy) then
        rect(g, gx * 3, gy * 3, gx * 3 + 2, gy * 3 + 2, "W")
        -- round the outer corners: none of the two neighbours that meet there
        for _, c in ipairs({{-1, -1, 0, 0}, {1, -1, 2, 0}, {-1, 1, 0, 2}, {1, 1, 2, 2}}) do
          if not on(gx + c[1], gy) and not on(gx, gy + c[2]) then
            px(g, gx * 3 + c[3], gy * 3 + c[4], ".")
          end
        end
        -- a glint on the top left of each stroke
        if not on(gx - 1, gy) and not on(gx, gy - 1) then px(g, gx * 3 + 1, gy * 3 + 1, "k") end
      end
    end
  end
  frames[#frames + 1] = g
end
finish("title", frames, {{"letters", 0, 8}}, 9)
