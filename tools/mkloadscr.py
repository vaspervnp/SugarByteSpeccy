#!/usr/bin/env python3
"""The tape's loading screen: the game's own menu, as a SCREEN$.

    tools/mkloadscr.py build/sugar.bin build/sugar.sym build/loading.scr [--png build/loading.png]

Runs the game on tools/zxrun.py until the menu is up and keeps the 6912 bytes
of the screen: the title, the plates and the candies are on the TV while the
tape loads, and the game draws the same picture over it when it starts.
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import zxrun  # noqa: E402

MENU_FRAMES = 40


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("binary")
    ap.add_argument("sym")
    ap.add_argument("out")
    ap.add_argument("--png")
    a = ap.parse_args()
    syms = zxrun.load_symbols(a.sym)
    spec = zxrun.Spectrum(open(a.binary, "rb").read(), syms["BIN_ORG"], syms)
    spec.run_frames(MENU_FRAMES)
    if spec.peek(syms["STATE"]) != 9:
        sys.exit("mkloadscr: the menu is not up")
    open(a.out, "wb").write(bytes(spec.m.memory[0x4000:0x5B00]))
    if a.png:
        spec.screenshot(a.png)


if __name__ == "__main__":
    main()
