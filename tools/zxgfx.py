#!/usr/bin/env python3
"""The Spectrum's art (assets/sheets/*.png, drawn by the Aseprite scripts of
tools/aseprite/) as bytes: build/gfx.asm.

    tools/zxgfx.py build/gfx.asm [--preview build/gfx.png]

The sheets are in the Spectrum's colours (tools/aseprite/common.lua): each
frame in its place in rows of `columns` (assets/sheets/<name>.json). This
checks what the machine can show and stops if a frame breaks it:

  masked    (candy, overlay) transparent pixels keep the screen, black is
            paper, any other colour ink; one ink per 8x8 cell. A cell with
            no ink takes the frame's (candies) or keeps the screen's (#FF,
            overlays).
  opaque    (cells, icons, menu) two colours per 8x8 cell at most, of one
            brightness (black goes with both); the set's paper is the paper
            where it is one of the two.
  font      8x8 glyphs from ASCII 32, ink is whatever is not black.
  title     the letters of SUGAR BYTE, 24x24, bits only (the menu colours
            them).

Formats (gfx.asm):
  masked sprite   24 lines x 3 bytes as mask,data pairs (screen AND mask OR
                  data), then 9 inks, one a character cell (#FF: keep)  = 153
  cell            24 lines x 3 bytes, then 9 attributes                 = 81
  icon            16 lines x 2 bytes, then 4 attributes                 = 36
  menu tile       24 lines x 4 bytes, then 12 attributes                = 108
  font            8 bytes a glyph, from ASCII 32
  title           24 lines x 3 bytes a letter                            = 72
"""
import argparse
import json
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SHEETS = os.path.join(HERE, '..', 'assets', 'sheets')

K, B, R, M, G, C, Y, W = range(8)
BRIGHT = 0x40
RGB_N = [(0, 0, 0), (0, 0, 215), (215, 0, 0), (215, 0, 215),
         (0, 215, 0), (0, 215, 215), (215, 215, 0), (215, 215, 215)]
RGB_B = [(0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255),
         (0, 255, 0), (0, 255, 255), (255, 255, 0), (255, 255, 255)]
COLOUR = {}
for i, c in enumerate(RGB_N):
    COLOUR[c] = (i, 0)
for i, c in enumerate(RGB_B):
    COLOUR[c] = (i, 1)
COLOUR[(0, 0, 0)] = (0, None)                  # black: either brightness
BOARD_PAPER = B


class ArtError(Exception):
    pass


def sheet(name):
    """-> list of frames, each rows of (colour 0-7, bright 0/1/None) or None
    for transparent."""
    j = json.load(open(os.path.join(SHEETS, name + '.json')))
    im = Image.open(os.path.join(SHEETS, name + '.png')).convert('RGBA')
    w, h, cols = j['w'], j['h'], j['columns']
    frames = []
    for i in range(j['frames']):
        x0, y0 = (i % cols) * w, (i // cols) * h
        rows = []
        for y in range(h):
            row = []
            for x in range(w):
                r, g, b, a = im.getpixel((x0 + x, y0 + y))
                if a < 128:
                    row.append(None)
                    continue
                if (r, g, b) not in COLOUR:
                    raise ArtError(f"{name} frame {i}: ({x},{y}) #{r:02X}{g:02X}{b:02X} is no Spectrum colour")
                row.append(COLOUR[(r, g, b)])
            rows.append(row)
        frames.append(rows)
    return frames


def pack(bits):
    out = []
    for i in range(0, len(bits), 8):
        v = 0
        for b in bits[i:i + 8]:
            v = v << 1 | b
        out.append(v)
    return out


def masked(name, default_ink):
    """default_ink: 'frame' (the frame's commonest ink) or 0xFF (keep)."""
    out = []
    for i, f in enumerate(sheet(name)):
        data = []
        for row in f:
            mask = [1 if p is None else 0 for p in row]
            bits = [1 if p is not None and p[0] != K else 0 for p in row]
            for m, d in zip(pack(mask), pack(bits)):
                data += [m, d]
        counts = {}
        inks = []
        for cy in range(3):
            for cx in range(3):
                found = set()
                for y in range(cy * 8, cy * 8 + 8):
                    for x in range(cx * 8, cx * 8 + 8):
                        p = f[y][x]
                        if p is not None and p[0] != K:
                            found.add(p[0])
                            counts[p[0]] = counts.get(p[0], 0) + 1
                if len(found) > 1:
                    raise ArtError(f"{name} frame {i}: cell {cx},{cy} has inks {sorted(found)}")
                inks.append(found.pop() if found else None)
        main = max(counts, key=counts.get) if counts else W
        inks = [k if k is not None else (main if default_ink == 'frame' else 0xFF) for k in inks]
        out.append((f"{name} {i}", data + inks))
    return out


def opaque(name, wc, hc, paper):
    out = []
    for i, f in enumerate(sheet(name)):
        lines = [[0] * wc for _ in range(hc * 8)]
        attrs = []
        for cy in range(hc):
            for cx in range(wc):
                px = [f[y][x] for y in range(cy * 8, cy * 8 + 8) for x in range(cx * 8, cx * 8 + 8)]
                if any(p is None for p in px):
                    raise ArtError(f"{name} frame {i}: cell {cx},{cy} is not opaque")
                cols = sorted({p[0] for p in px})
                brights = {p[1] for p in px} - {None}
                if len(cols) > 2:
                    raise ArtError(f"{name} frame {i}: cell {cx},{cy} has colours {cols}")
                if len(brights) > 1:
                    raise ArtError(f"{name} frame {i}: cell {cx},{cy} mixes bright and not")
                br = brights.pop() if brights else 1
                if len(cols) == 1:
                    pp, ii = cols[0], (W if cols[0] != W else B)
                elif paper in cols:
                    pp = paper
                    ii = cols[0] if cols[1] == paper else cols[1]
                else:
                    n0 = sum(1 for p in px if p[0] == cols[0])
                    pp, ii = (cols[0], cols[1]) if n0 >= 32 else (cols[1], cols[0])
                bits = [1 if p[0] == ii and ii != pp else 0 for p in px]
                for r in range(8):
                    lines[cy * 8 + r][cx] = pack(bits[r * 8:r * 8 + 8])[0]
                attrs.append((BRIGHT if br else 0) | pp << 3 | ii)
        out.append((f"{name} {i}", [b for line in lines for b in line] + attrs))
    return out


def bits_only(name):
    out = []
    for i, f in enumerate(sheet(name)):
        data = []
        for row in f:
            data += pack([1 if p is not None and p[0] != K else 0 for p in row])
        out.append((f"{name} {i}", data))
    return out


# ---------------------------------------------------------------------------
def emit(out, label, items, comment):
    out.append(f"\n; {comment}")
    out.append(f"{label}:")
    for name, data in items:
        out.append(f"; {name}")
        for i in range(0, len(data), 16):
            out.append("        db " + ",".join(f"#{b:02X}" for b in data[i:i + 16]))


def preview(path, cand, over, cel, ico, menu, font, title):
    scale = 3
    im = Image.new('RGB', (9 * 26 * scale, 13 * 26 * scale), (40, 40, 40))
    pxl = im.load()

    def put(x0, y0, w, h, bitmap, attrs):
        for y in range(h):
            for x in range(w):
                a = attrs[(y // 8) * (w // 8) + x // 8]
                pal = RGB_B if a & BRIGHT else RGB_N
                c = pal[a & 7] if bitmap[y][x] else pal[(a >> 3) & 7]
                for dy in range(scale):
                    for dx in range(scale):
                        pxl[(x0 + x) * scale + dx, (y0 + y) * scale + dy] = c

    def sprite(x0, y0, data):
        bm = []
        for y in range(24):
            row = []
            for b in range(3):
                d = data[y * 6 + b * 2 + 1]
                row += [d >> (7 - k) & 1 for k in range(8)]
            bm.append(row)
        att = [BRIGHT | BOARD_PAPER << 3 | (W if k == 0xFF else k) for k in data[144:153]]
        put(x0, y0, 24, 24, bm, att)

    def opaq(x0, y0, data, wc, hc, attrs=None):
        bm = []
        for y in range(hc * 8):
            v = data[y * wc:(y + 1) * wc]
            bm.append([b >> (7 - k) & 1 for b in v for k in range(8)])
        put(x0, y0, wc * 8, hc * 8, bm, attrs or data[wc * hc * 8:])

    for i, (_, d) in enumerate(cand):
        sprite((i % 9) * 26, (i // 9) * 26, d)
    for i, (_, d) in enumerate(over):
        sprite((i % 9) * 26, (3 + i // 9) * 26, d)
    for i, (_, d) in enumerate(cel):
        opaq((i % 9) * 26, (5 + i // 9) * 26, d, 3, 3)
    for i, (_, d) in enumerate(ico):
        opaq(i * 26, 7 * 26, d, 2, 2)
    for i, (_, d) in enumerate(menu):
        opaq(i * 36, 8 * 26, d, 4, 3)
    for i, (_, d) in enumerate(title):
        opaq(i * 26, 9 * 26, d, 3, 3, [BRIGHT | [R, Y, G, C, M, W][i % 6]] * 9)
    for n, (_, d) in enumerate(font):
        opaq((n % 28) * 8, 10 * 26 + (n // 28) * 9, d, 1, 1, [BRIGHT | W])
    im.save(path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('--preview')
    a = ap.parse_args()
    try:
        cand = masked('candy', 'frame')
        over = masked('overlay', 0xFF)
        cel = opaque('cells', 3, 3, BOARD_PAPER)
        ico = opaque('icons', 2, 2, B)
        menu = opaque('menu', 4, 3, K)
        font = bits_only('font')
        title = bits_only('title')
    except ArtError as e:
        sys.exit(f"zxgfx: {e}")
    nfont = json.load(open(os.path.join(SHEETS, 'font.json')))['frames']
    out = ["; ΠΑΡΑΓΕΤΑΙ από το tools/zxgfx.py (assets/sheets) — μην το πειράζεις.", "",
           "CANDY_SZ        equ 153", "CANDY_N         equ %d" % len(cand),
           "CANDY_PLAIN     equ 0", "CANDY_STRIPED_H equ 6", "CANDY_STRIPED_V equ 12",
           "CANDY_WRAPPED   equ 18", "CANDY_BOMB      equ 24", "CANDY_INGREDIENT equ 25",
           "OVERLAY_SZ      equ 153", "OVERLAY_N       equ %d" % len(over),
           "OVERLAY_CURSOR  equ 0", "OVERLAY_BLOCKER equ 2", "OVERLAY_POP     equ 4",
           "OVERLAY_BEAM_H  equ 8", "OVERLAY_BEAM_V  equ 10", "OVERLAY_STAR    equ 12",
           "CELLS_SZ        equ 81", "CELLS_N         equ %d" % len(cel),
           "CELLS_BOARD     equ 0", "CELLS_JELLY     equ 3", "CELLS_ICING     equ 5",
           "CELLS_BLOCKER   equ 8",
           "ICONS_SZ        equ 36", "ICONS_N         equ %d" % len(ico),
           "MENU_SZ         equ 108", "MENU_N          equ %d" % len(menu),
           "MENU_PLATE      equ 0", "MENU_POINTER    equ 3",
           "FONT_FIRST      equ 32", "FONT_LAST       equ %d" % (32 + nfont - 1),
           "TITLE_LETTERS   equ %d" % len(title), "TITLE_SZ        equ 72"]
    emit(out, "candy_gfx", cand, "candies: 24x24 masked, 9 inks")
    emit(out, "overlay_gfx", over, "overlays: 24x24 masked, 9 inks (#FF keep)")
    emit(out, "cells_gfx", cel, "board cells: 24x24 opaque, 9 attributes")
    emit(out, "icons_gfx", ico, "HUD icons: 16x16 opaque, 4 attributes")
    emit(out, "menu_gfx", menu, "menu: plate middle, left, right, pointer 1, 2: 32x24, 12 attributes")
    emit(out, "font", font, "font: 8x8, from ASCII 32")
    emit(out, "title_gfx", title, "title: S U G A R B Y T E, 24x24")
    open(a.out, 'w').write("\n".join(out) + "\n")
    if a.preview:
        preview(a.preview, cand, over, cel, ico, menu, font, title)


if __name__ == '__main__':
    main()
