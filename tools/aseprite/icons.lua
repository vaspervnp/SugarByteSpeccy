-- icons.lua — the HUD's 16x16 icons, opaque on its bright blue paper.
--   0 score (a jar of sweets)  1 moves (swap arrows)  2 time  3 goal (lollipop)
--   4 jelly  5 star (won)  6 star (not yet)  7 lock (the level's code)
-- Each 8x8 quarter has one ink.
dofile(ROOT .. "tools/aseprite/common.lua")

local pi, cos, sin = math.pi, math.cos, math.sin
local frames = {}
local function icon(rows, map)
  local g = grid(16, 16, "B")
  paste(g, rows, 0, 0, map)
  frames[#frames + 1] = g
end

icon({                                  -- jar: a white lid, sweets in two colours
  "................",
  "...WWWWWWWWWW...",
  "...WWWWWWWWWW...",
  "....W......W....",
  "...W........W...",
  "..W..........W..",
  "..W..........W..",
  "..W.WW....WW.W..",
  "..M.MMM..YYY.Y..",
  "..M.MMM..YYY.Y..",
  "..M..M..YYYY.Y..",
  "..M.MMM..YY..Y..",
  "..M.MMM..YYY.Y..",
  "..M.....YYYY.Y..",
  "...MMMMMYYYYYY..",
  "................",
})
icon({                                  -- moves: one arrow each way
  "................",
  "..........W.....",
  "..........WW....",
  "..WWWWWWWWWWW...",
  "..WWWWWWWWWWWW..",
  "..WWWWWWWWWWW...",
  "..........WW....",
  "..........W.....",
  ".....W..........",
  "....WW..........",
  "...WWWWWWWWWWW..",
  "..WWWWWWWWWWWW..",
  "...WWWWWWWWWWW..",
  "....WW..........",
  ".....W..........",
  "................",
})
icon({                                  -- hourglass
  "..YYYYYYYYYYYY..",
  "..YYYYYYYYYYYY..",
  "...Y........Y...",
  "...YY......YY...",
  "....YYYYYYYY....",
  ".....YYYYYY.....",
  "......YYYY......",
  ".......YY.......",
  ".......YY.......",
  "......Y..Y......",
  ".....Y....Y.....",
  "....Y..YY..Y....",
  "...Y.YYYYYY.Y...",
  "...YYYYYYYYYY...",
  "..YYYYYYYYYYYY..",
  "..YYYYYYYYYYYY..",
})
icon({                                  -- lollipop: a magenta swirl on a white stick
  "....MMMMMMMM....",
  "...MM......MM...",
  "..MM..MMMM..MM..",
  "..M..MM..MM..M..",
  "..M..M..M.M..M..",
  "..M..M.MM.M..M..",
  "..MM..MM..M.MM..",
  "...MM....MM.M...",
  "....WWWWWW......",
  ".......WW.......",
  ".......WW.......",
  ".......WW.......",
  ".......WW.......",
  ".......WW.......",
  ".......WW.......",
  "......WWWW......",
})
icon({                                  -- jelly: a wobbly cyan block
  "................",
  "................",
  "....CCCCCCCC....",
  "...CC.CCCCCCC...",
  "..CC.CCCCCCCCC..",
  "..C.CCCCCCCCCC..",
  "..CCCCCCCCCCCC..",
  "..CCCCCCCCCCCC..",
  "..CCCCCCCCCCCC..",
  "..CCCCCCCCC.CC..",
  "..CCCCCCCC.CCC..",
  "..CCCCCCCCCCCC..",
  "...CCCCCCCCCC...",
  "..C.C.C.C.C.C...",
  "................",
  "................",
})

local function star(ink, outline)
  local g = grid(16, 16, "B")
  local pts = {}
  for k = 0, 9 do
    local r = (k % 2 == 0) and 7.6 or 3.3
    local a = -pi / 2 + k * pi / 5
    pts[#pts + 1] = {r * cos(a), r * sin(a) + 0.7}
  end
  local function inside(u, v)
    local c, j = false, #pts
    for i = 1, #pts do
      local xi, yi, xj, yj = pts[i][1], pts[i][2], pts[j][1], pts[j][2]
      if ((yi > v) ~= (yj > v)) and (u < (xj - xi) * (v - yi) / (yj - yi) + xi) then c = not c end
      j = i
    end
    return c
  end
  for y = 0, 15 do
    for x = 0, 15 do
      local u, v = uv(x, y, 16)
      if inside(u, v) then
        local rim = not (inside(u - 1, v) and inside(u + 1, v) and inside(u, v - 1) and inside(u, v + 1))
        if not outline or rim then px(g, x, y, ink) end
      end
    end
  end
  frames[#frames + 1] = g
end
star("Y", false)
star("K", true)

icon({                                  -- padlock
  "................",
  ".....YYYYYY.....",
  "....YY....YY....",
  "...YY......YY...",
  "...Y........Y...",
  "...Y........Y...",
  "...Y........Y...",
  "..YYYYYYYYYYYY..",
  "..YYYYYYYYYYYY..",
  "..YYYYY..YYYYY..",
  "..YYYYY..YYYYY..",
  "..YYYYYY.YYYYY..",
  "..YYYYYY.YYYYY..",
  "..YYYYYYYYYYYY..",
  "..YYYYYYYYYYYY..",
  "................",
})

-- the order of ICON_*: score moves time goal jelly star_on star_off lock
finish("icons", frames, {{"icon", 0, 7}}, 8)
