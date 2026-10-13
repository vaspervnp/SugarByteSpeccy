-- common.lua — helpers for the Aseprite scripts that draw Sugar Byte's art.
--
-- Run inside Aseprite (the aseprite MCP's run_lua_script, or aseprite -b
-- --script): each script dofile()s this one, draws its frames and calls
-- finish(), which saves assets/aseprite/<name>.aseprite and exports the
-- sheet assets/sheets/<name>.png + .json that tools/zxgfx.py reads.
--
-- Colours are the Spectrum's, by letter:
--   k b r m g c y w   black blue red magenta green cyan yellow white
--   K B R M G C Y W   the same BRIGHT
--   .                 transparent (masked sprites only)
-- In a masked sprite black is "paper" (opaque, the board shows through in
-- its own colour) and any other colour is ink; every 8x8 cell of a frame
-- uses one ink at most. Opaque pictures (cells, icons, menu) use at most
-- two colours per 8x8 cell, of one brightness (black goes with both).

ROOT = ROOT or "//wsl.localhost/Ubuntu/home/vasilhs/repos/SugarByteSpeccy/"

local N = 215
local RGB = {
  k = {0, 0, 0}, b = {0, 0, N}, r = {N, 0, 0}, m = {N, 0, N},
  g = {0, N, 0}, c = {0, N, N}, y = {N, N, 0}, w = {N, N, N},
  K = {0, 0, 0}, B = {0, 0, 255}, R = {255, 0, 0}, M = {255, 0, 255},
  G = {0, 255, 0}, C = {0, 255, 255}, Y = {255, 255, 0}, W = {255, 255, 255},
}

function col(ch)
  if ch == "." or ch == nil then return Color{r = 0, g = 0, b = 0, a = 0} end
  local p = RGB[ch]
  assert(p, "unknown colour " .. tostring(ch))
  return Color{r = p[1], g = p[2], b = p[3], a = 255}
end

-- A frame being drawn: a grid of letters, w x h, all `fill`.
function grid(w, h, fill)
  local g = {w = w, h = h}
  for y = 0, h - 1 do
    g[y] = {}
    for x = 0, w - 1 do g[y][x] = fill or "." end
  end
  return g
end

function px(g, x, y, ch)
  if x >= 0 and y >= 0 and x < g.w and y < g.h then g[y][x] = ch end
end

function get(g, x, y)
  if x >= 0 and y >= 0 and x < g.w and y < g.h then return g[y][x] end
  return "."
end

function rect(g, x0, y0, x1, y1, ch)
  for y = y0, y1 do for x = x0, x1 do px(g, x, y, ch) end end
end

-- ASCII rows ("." keeps what is there) at x0, y0, letters through `map`.
function paste(g, rows, x0, y0, map)
  for dy, row in ipairs(rows) do
    for dx = 1, #row do
      local ch = row:sub(dx, dx)
      if ch ~= "." then
        px(g, x0 + dx - 1, y0 + dy - 1, map and map[ch] or ch)
      end
    end
  end
end

-- A list of frames (grids) -> a sprite, its tags {name, from, to} (0-based),
-- saved and exported as a sheet `columns` frames wide.
function finish(name, frames, tags, columns)
  local w, h = frames[1].w, frames[1].h
  local spr = Sprite(w, h, ColorMode.RGB)
  for i = 2, #frames do spr:newEmptyFrame() end
  for i, g in ipairs(frames) do
    local img = Image(w, h, ColorMode.RGB)
    img:clear(col("."))
    for y = 0, h - 1 do
      for x = 0, w - 1 do
        if g[y][x] ~= "." then img:drawPixel(x, y, col(g[y][x])) end
      end
    end
    spr:newCel(spr.layers[1], spr.frames[i], img, Point(0, 0))
  end
  for _, t in ipairs(tags or {}) do
    local tag = spr:newTag(t[2] + 1, t[3] + 1)
    tag.name = t[1]
  end
  spr:saveAs(ROOT .. "assets/aseprite/" .. name .. ".aseprite")
  spr:close()
  -- the sheet: frames in rows of `columns`, and what tools/zxgfx.py needs
  columns = math.min(columns or 9, #frames)
  local rows = (#frames + columns - 1) // columns
  local sheet = Sprite(w * columns, h * rows, ColorMode.RGB)
  local img = Image(w * columns, h * rows, ColorMode.RGB)
  img:clear(col("."))
  for i, g in ipairs(frames) do
    local x0, y0 = ((i - 1) % columns) * w, ((i - 1) // columns) * h
    for y = 0, h - 1 do
      for x = 0, w - 1 do
        if g[y][x] ~= "." then img:drawPixel(x0 + x, y0 + y, col(g[y][x])) end
      end
    end
  end
  sheet.cels[1].image = img
  sheet:saveAs(ROOT .. "assets/sheets/" .. name .. ".png")
  sheet:close()
  local f = io.open(ROOT .. "assets/sheets/" .. name .. ".json", "w")
  local t = {}
  for _, tg in ipairs(tags or {}) do
    t[#t + 1] = string.format('{"name": "%s", "from": %d, "to": %d}', tg[1], tg[2], tg[3])
  end
  f:write(string.format('{"name": "%s", "w": %d, "h": %d, "frames": %d, "columns": %d,\n "tags": [%s]}\n',
    name, w, h, #frames, columns, table.concat(t, ", ")))
  f:close()
  print(name .. ": " .. #frames .. " frames")
end

-- Shapes on a 24x24 candy: u, v from the centre (pixel centres).
function uv(x, y, n)
  n = n or 24
  return x + 0.5 - n / 2, y + 0.5 - n / 2
end

-- Fill a shape (inside(u, v) -> bool) with ink, shaded the Spectrum way:
-- a solid rim, a solid lit side (top left), a dithered shadow side (bottom
-- right), and a glint of paper near the top left. opts: glint (bool),
-- stripes ("h", "v" or nil), shade (threshold, nil: none)
function candy_shape(g, inside, ink, opts)
  opts = opts or {}
  local n = g.w
  local function ins(x, y)
    if x < 0 or y < 0 or x >= n or y >= n then return false end
    local u, v = uv(x, y, n)
    return inside(u, v)
  end
  for y = 0, n - 1 do
    for x = 0, n - 1 do
      if ins(x, y) then
        local rim = not (ins(x - 1, y) and ins(x + 1, y) and ins(x, y - 1) and ins(x, y + 1))
        local inner = ins(x - 2, y) and ins(x + 2, y) and ins(x, y - 2) and ins(x, y + 2)
        local u, v = uv(x, y, n)
        local ch = ink
        if not rim then
          if opts.stripes == "h" and inner and (y // 3) % 2 == 1 then ch = "k"
          elseif opts.stripes == "v" and inner and (x // 3) % 2 == 1 then ch = "k"
          elseif opts.shade and (u + v) > opts.shade and inner and (x + y) % 2 == 1 then ch = "k"
          end
          if opts.glint and inner and not opts.stripes then
            local gu, gv = u + 4.5, v + 4.5
            local d = gu * gu + gv * gv
            if d > 4 and d < 9.5 and gu + gv < 0 then ch = "k" end
          end
        end
        px(g, x, y, ch)
      end
    end
  end
end
