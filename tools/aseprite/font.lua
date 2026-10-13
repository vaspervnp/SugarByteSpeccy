-- font.lua — the font as a sheet of 8x8 glyphs, ASCII 32..124, 16 a row:
-- white ink on black paper (tools/zxgfx.py reads the ink).
dofile(ROOT .. "tools/aseprite/common.lua")
dofile(ROOT .. "tools/aseprite/font_defs.lua")

local frames = {}
for code = FONT_FIRST, FONT_LAST do
  local g = grid(8, 8, "k")
  local rows = FONT[string.char(code)]
  if rows then
    for y = 1, 8 do
      paste(g, {(rows[y]:gsub("#", "W"))}, 0, y - 1)
    end
  end
  frames[#frames + 1] = g
end
finish("font", frames, {{"ascii", 0, FONT_LAST - FONT_FIRST}}, 16)
