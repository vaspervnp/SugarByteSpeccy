#!/usr/bin/env python3
"""Headless ZX Spectrum harness for Sugar Byte (after the CPC's tools/cpcrun.py).

Runs the game binary on a bare Z80 (the `z80` module, no ROM), emulating only
what the game touches: the 50 Hz interrupt (IM 2, the bus reads #FF), the
keyboard half-rows on port #FE, the border and the beeper, the Kempston port,
and on --model 128 the AY on #FFFD/#BFFD (on a 48K, #FFFD reads #FF, so the
game finds no AY). Memory contention is not modelled. Drives the game from a
script and saves screenshots / checks variables.

  zxrun.py build/sugar.bin --sym build/sugar.sym --script tests/smoke.txt --out build/shots

Script lines (';' starts a comment): those of cpcrun.py -
  run <frames> [key+key...]     hold keys (or none) for N frames
  shot <name>                   save <out>/<name>.png
  expect <addr> <value>         assert byte at addr == value (decimal or #hex)
  poke / pokew <addr> <value>   write a byte / a word
  until <addr> <value> [keys] [max]   run frames until the byte equals value
  print <addr> [count]          print bytes (hex)
  board                         print the 8x8 board
  setboard <row0> ... <row7>    write the board and queue every cell for redraw
  setcells / expectcells / countcells / expectboard   as on the CPC
  psg <reg> <value>             assert an AY register (128K)
  psgon <reg>                   assert an AY volume register is non-zero
  beep / nobeep                 assert the beeper moved / kept still since the last
                                beep or nobeep (48K)
  attr <row> <col> <value>      assert an attribute byte of the screen
and frames are game-loop iterations (arrivals at wait_vbl), as there.

--wav <file> renders what the AY (128K) or the beeper (48K) played.

Keys: up down left right fire esc mus (Q A O P SPACE BREAK M), the Sinclair
joystick jup jdown jleft jright jfire (9 8 6 7 0), the cursor keys cup cdown
cleft cright (CAPS SHIFT + 7 6 5 8), and kup kdown kleft kright kfire on the
Kempston (--kempston).
"""
import argparse
import os
import sys

import z80
from PIL import Image

MODELS = {'48': (224 * 312, 3_500_000, 32), '128': (228 * 311, 3_546_900, 36)}
SLICE_T = 64

# key -> (half-row 0-7 as matrix index of port #FE A8..A15, bit)
KEYS = {
    'up': [(2, 0)], 'down': [(1, 0)], 'left': [(5, 1)], 'right': [(5, 0)],
    'fire': [(7, 0)], 'esc': [(0, 0), (7, 0)], 'mus': [(7, 2)],
    'jup': [(4, 1)], 'jdown': [(4, 2)], 'jleft': [(4, 4)], 'jright': [(4, 3)], 'jfire': [(4, 0)],
    'cup': [(0, 0), (4, 3)], 'cdown': [(0, 0), (4, 4)], 'cleft': [(0, 0), (3, 4)],
    'cright': [(0, 0), (4, 2)], 'enter': [(6, 0)],
}
KEMPSTON = {'kright': 1, 'kleft': 2, 'kdown': 4, 'kup': 8, 'kfire': 16}

NORMAL = [(0, 0, 0), (0, 0, 215), (215, 0, 0), (215, 0, 215),
          (0, 215, 0), (0, 215, 215), (215, 215, 0), (215, 215, 215)]
BRIGHT = [(0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255),
          (0, 255, 0), (0, 255, 255), (255, 255, 0), (255, 255, 255)]


def load_symbols(path):
    syms = {}
    if path:
        for line in open(path):
            parts = line.split()
            if len(parts) >= 2 and parts[1].startswith('#'):
                syms[parts[0].upper()] = int(parts[1][1:], 16)
    return syms


class Spectrum:
    def __init__(self, binary, org, syms, model='48', kempston=False):
        self.frame_t, self.hz, self.int_len = MODELS[model]
        self.model = model
        self.m = z80.Z80Machine()
        self.m.set_memory_block(org, binary)
        self.m.pc = syms.get('START', org)
        self.m.sp = 0x5CFE
        self.org, self.end = org, org + len(binary)
        self.t = 0
        self.border = 0
        self.speaker = 0
        self.beep_log = []      # (T, level)
        self.beeps = 0
        self.ay_sel = 0
        self.ay = [0] * 16
        self.ay_log = []        # (T, register, value)
        self.matrix = [0] * 8   # bits set = pressed
        self.kemp = 0
        self.kempston = kempston
        self.busy = []
        self.frame_no = 0
        self.at_wait = False
        self.booted = False
        self.wait_vbl = syms.get('WAIT_VBL')
        self.loop_work = syms.get('LOOP_WORK')
        self.loop_start_t = None
        self.int_pending = False
        self.m.set_output_callback(self.on_out)
        self.m.set_input_callback(self.on_in)
        self.m.set_get_int_vector_callback(lambda: 0xFF)
        if self.wait_vbl is not None:
            self.m.set_breakpoint(self.wait_vbl)
        if self.loop_work is not None:
            self.m.set_breakpoint(self.loop_work)

    def now(self):
        return self.t + SLICE_T - self.m.ticks_to_stop

    def on_out(self, addr, val):
        if not addr & 1:                                    # ULA
            self.border = val & 7
            s = (val >> 4) & 1
            if s != self.speaker:
                self.speaker = s
                self.beep_log.append((self.now(), s))
                self.beeps += 1
        if self.model == '128':
            if addr & 0xC002 == 0xC000:                     # #FFFD: select
                self.ay_sel = val & 15
            elif addr & 0xC002 == 0x8000:                   # #BFFD: write
                self.ay[self.ay_sel] = val
                self.ay_log.append((self.now(), self.ay_sel, val))

    def on_in(self, addr):
        if not addr & 1:
            hi = addr >> 8
            v = 0x1F
            for row in range(8):
                if not hi & (1 << row):
                    v &= ~self.matrix[row] & 0x1F
            return 0xA0 | v
        if addr & 0xFF == 0x1F:
            return self.kemp if self.kempston else 0xFF
        if self.model == '128' and addr & 0xC002 == 0xC000:
            return self.ay[self.ay_sel]
        return 0xFF

    def set_keys(self, names):
        self.matrix = [0] * 8
        self.kemp = 0
        for n in names:
            if n in KEMPSTON:
                self.kemp |= KEMPSTON[n]
                continue
            for row, bit in KEYS[n]:
                self.matrix[row] |= 1 << bit

    def run_frames(self, n):
        """n game-loop iterations: stop when the game enters wait_vbl for the
        n-th time, so every frame's work is complete when a script looks."""
        loops = 0
        while loops < n:
            if self.m.pc == self.wait_vbl and self.at_wait:
                self.m.clear_breakpoint(self.wait_vbl)      # step past the breakpoint
                self.m.ticks_to_stop = 1
                self.m.run()
                self.t += 4
                self.m.set_breakpoint(self.wait_vbl)
                self.at_wait = False
            self.m.ticks_to_stop = SLICE_T
            events = self.m.run()
            t0 = self.t
            self.t += SLICE_T - self.m.ticks_to_stop
            if self.t // self.frame_t != t0 // self.frame_t:
                self.int_pending = True
            if self.int_pending and self.t % self.frame_t < self.int_len + SLICE_T \
                    and self.m.pc != self.wait_vbl and self.m.on_handle_active_int():
                self.int_pending = False
            elif self.t % self.frame_t >= self.int_len + SLICE_T:
                self.int_pending = False                    # the ULA's INT is short
            pc = self.m.pc
            if pc == self.loop_work and events & z80.Z80Machine._BREAKPOINT_HIT:
                self.loop_start_t = self.t
                self.m.clear_breakpoint(self.loop_work)
                self.m.ticks_to_stop = 1
                self.m.run()
                self.t += 17
                self.m.set_breakpoint(self.loop_work)
                continue
            if pc == self.wait_vbl and events & z80.Z80Machine._BREAKPOINT_HIT:
                self.at_wait = True
                if not self.booted:
                    self.booted = True
                    continue
                loops += 1
                if self.loop_start_t is not None:
                    self.busy.append((self.frame_no, self.t - self.loop_start_t))
                    self.loop_start_t = None
                self.frame_no += 1
            if not (self.org <= pc < self.end or pc == 0xFCFC):
                raise RuntimeError(f"PC escaped the program: #{pc:04X}")

    def peek(self, addr):
        return self.m.memory[addr & 0xFFFF]

    def poke(self, addr, value):
        self.m.memory[addr & 0xFFFF] = value & 0xFF

    def resolve(self, expr, syms):
        deref = expr.startswith('*')
        name, _, off = expr.lstrip('*').partition('+')
        addr = syms[name.upper()] if not name.startswith('#') else int(name[1:], 16)
        if deref:
            addr = self.peek(addr) | (self.peek(addr + 1) << 8)
        return addr + (int(off) if off else 0)

    def screenshot(self, path, scale=2, flash=False):
        mem = self.m.memory
        bw = 16
        img = Image.new('RGB', (256 + 2 * bw, 192 + 2 * bw), NORMAL[self.border])
        px = img.load()
        for y in range(192):
            base = 0x4000 | ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
            for cx in range(32):
                b = mem[base + cx]
                a = mem[0x5800 + (y >> 3) * 32 + cx]
                pal = BRIGHT if a & 0x40 else NORMAL
                ink, paper = pal[a & 7], pal[(a >> 3) & 7]
                if flash and a & 0x80:
                    ink, paper = paper, ink
                for k in range(8):
                    px[bw + cx * 8 + k, bw + y] = ink if b & (0x80 >> k) else paper
        img.resize((img.width * scale, img.height * scale), Image.NEAREST).save(path)


def render_wav(spec, path, rate=22050):
    import array
    import wave
    end_t = spec.t
    out = array.array('h')
    n_samples = int(end_t / spec.hz * rate)
    if spec.model == '128':
        log = spec.ay_log
        ay_hz = 1_773_400
        vol = [0.0] + [2 ** ((v - 15) / 2) for v in range(1, 16)]
        regs = [0] * 16
        regs[7] = 0x3F
        phase = [0.0, 0.0, 0.0]
        noise_phase, lfsr, noise_bit = 0.0, 1, 1
        i, dc = 0, 0.0
        for n in range(n_samples):
            t = n * spec.hz / rate
            while i < len(log) and log[i][0] <= t:
                regs[log[i][1]] = log[i][2]
                i += 1
            np_ = (regs[6] & 31) or 1
            noise_phase += ay_hz / (16 * np_) / rate
            while noise_phase >= 1:
                noise_phase -= 1
                bit = (lfsr ^ (lfsr >> 3)) & 1
                lfsr = (lfsr >> 1) | (bit << 16)
                noise_bit = lfsr & 1
            acc = 0.0
            for ch in range(3):
                p = (regs[2 * ch] | (regs[2 * ch + 1] & 15) << 8) or 1
                phase[ch] = (phase[ch] + ay_hz / (16 * p) / rate) % 1.0
                tone_on = not (regs[7] >> ch) & 1
                noise_on = not (regs[7] >> (3 + ch)) & 1
                level = ((phase[ch] < 0.5) or not tone_on) and (noise_bit or not noise_on)
                if level:
                    acc += vol[regs[8 + ch] & 15]
            dc += (acc - dc) * 0.002
            out.append(max(-32767, min(32767, int((acc - dc) * 12000))))
    else:
        log = spec.beep_log
        i, level, dc = 0, 0, 0.0
        step = spec.hz / rate
        for n in range(n_samples):
            t0, t1 = n * step, (n + 1) * step
            acc, t = 0.0, t0
            while i < len(log) and log[i][0] < t1:
                acc += level * (log[i][0] - t)
                t = log[i][0]
                level = log[i][1]
                i += 1
            acc += level * (t1 - t)
            v = acc / step
            dc += (v - dc) * 0.002
            out.append(max(-32767, min(32767, int((v - dc) * 16000))))
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(out.tobytes())


# A character per board[] cell: 0-5 plain, A-F striped across, a-f striped
# down, u-z wrapped, * bomb, k cherry, n nut, . empty.
def cell_value(ch):
    if ch == '.':
        return 7
    if ch == '*':
        return 6
    if ch in 'kn':
        return 0x20 + (ch == 'n')
    for base, form in (('0', 0), ('A', 8), ('a', 16), ('u', 24)):
        if 0 <= ord(ch) - ord(base) < 6:
            return form + ord(ch) - ord(base)
    raise ValueError(f"unknown board cell '{ch}'")


def cell_char(v):
    if v == 7:
        return '.'
    if v == 6:
        return '*'
    if v in (0x20, 0x21):
        return 'kn'[v & 1]
    return chr(ord('0Aau'[v >> 3]) + (v & 7)) if v < 32 else f"<{v:x}>"


CELL_CHARS = {'.': 0x00, 'j': 0x20, 'J': 0x40, '1': 0x0A, '2': 0x12, '3': 0x1A,
              'c': 0x03, 'l': 0x04, 'o': 0x01}


def parse_value(v, spec, syms):
    if v.startswith('#'):
        return int(v[1:], 16)
    if v.lstrip('-').isdigit():
        return int(v)
    return spec.resolve(v, syms)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('binary')
    ap.add_argument('--sym')
    ap.add_argument('--org', help='load address (default: BIN_ORG)')
    ap.add_argument('--model', choices=('48', '128'), default='48')
    ap.add_argument('--kempston', action='store_true')
    ap.add_argument('--script')
    ap.add_argument('--out', default='build/shots')
    ap.add_argument('--frames', type=int, default=50)
    ap.add_argument('--wav')
    args = ap.parse_args()

    syms = load_symbols(args.sym)
    org = int(args.org, 16) if args.org else syms.get('BIN_ORG', 0x6200)
    spec = Spectrum(open(args.binary, 'rb').read(), org, syms, args.model, args.kempston)
    os.makedirs(args.out, exist_ok=True)

    steps = []
    if args.script:
        for raw in open(args.script):
            line = raw.split(';', 1)[0].strip()
            if line:
                steps.append(line.split())
    else:
        steps = [['run', str(args.frames)], ['shot', 'final']]

    failures = 0
    for st in steps:
        cmd = st[0]
        if cmd == 'run':
            keys = st[2].split('+') if len(st) > 2 and st[2] != '-' else []
            spec.set_keys(keys)
            spec.run_frames(int(st[1]))
        elif cmd == 'shot':
            path = os.path.join(args.out, st[1] + '.png')
            spec.screenshot(path)
            print(f"shot {path}")
        elif cmd == 'until':
            addr = spec.resolve(st[1], syms)
            want = parse_value(st[2], spec, syms)
            rest = st[3:]
            keys = rest[0].split('+') if rest and rest[0] != '-' else []
            limit = int(rest[1]) if len(rest) > 1 else 3000
            spec.set_keys(keys)
            n = 0
            while spec.peek(addr) != want and n < limit:
                spec.run_frames(1)
                n += 1
            if spec.peek(addr) != want:
                failures += 1
                print(f"FAIL {' '.join(st)}: got {spec.peek(addr)} after {n} frames")
                break
        elif cmd == 'setboard':
            b = syms['BOARD']
            for i, ch in enumerate(''.join(st[1:9])):
                spec.poke(b + i, cell_value(ch))
                spec.poke(syms['CELL'] + i, 0x80)
                spec.poke(syms['DIRTY_Q'] + i, i)
            spec.poke(syms['DQ_HEAD'], 0)
            spec.poke(syms['DQ_TAIL'], 0)
            spec.poke(syms['DQ_N'], 64)
            spec.poke(syms['INGR_SPAWN'], 0)
            spec.poke(syms['LV_GOAL'], 0xFF)
            spec.poke(syms['INGR_BOARD'], sum((spec.peek(b + i) & 0x27) in (0x20, 0x21) for i in range(64)))
        elif cmd == 'setcells':
            for i, ch in enumerate(''.join(st[1:9])):
                v = CELL_CHARS[ch]
                spec.poke(syms['CELL'] + i, v | 0x80)
                if v & 7:
                    spec.poke(syms['BOARD'] + i, 7)
        elif cmd == 'expectcells':
            inv = {v: k for k, v in CELL_CHARS.items()}
            want = ''.join(st[1:9])
            got = ''.join(inv.get(spec.peek(syms['CELL'] + i) & 0x7F, '?') for i in range(64))
            ok = all(w in ('?', g) for w, g in zip(want, got))
            failures += not ok
            print(f"{'ok  ' if ok else 'FAIL'} cells" + ('' if ok else
                  '\n  got      ' + ' '.join(got[i:i + 8] for i in range(0, 64, 8)) +
                  '\n  expected ' + ' '.join(want[i:i + 8] for i in range(0, 64, 8))))
        elif cmd == 'countcells':
            v = CELL_CHARS[st[1]]
            got = sum((spec.peek(syms['CELL'] + i) & 0x7F) == v for i in range(64))
            ok = got == int(st[2])
            failures += not ok
            print(f"{'ok  ' if ok else 'FAIL'} cells '{st[1]}' = {got} (expected {st[2]})")
        elif cmd == 'expectboard':
            b = syms['BOARD']
            want = ''.join(st[1:9])
            got = ''.join(cell_char(spec.peek(b + i)) for i in range(64))
            ok = all(w in ('?', g) or (w == '#' and g != '.') for w, g in zip(want, got))
            failures += not ok
            print(f"{'ok  ' if ok else 'FAIL'} board" + ('' if ok else
                  '\n  got      ' + ' '.join(got[i:i + 8] for i in range(0, 64, 8)) +
                  '\n  expected ' + ' '.join(want[i:i + 8] for i in range(0, 64, 8))))
        elif cmd == 'board':
            b = syms['BOARD']
            for y in range(8):
                print('  ' + ' '.join(cell_char(spec.peek(b + y * 8 + x)) for x in range(8)))
        elif cmd in ('psg', 'psgon'):
            reg = int(st[1])
            if spec.model != '128':
                print(f"skip {cmd} {reg}: no AY on a 48K")
                continue
            got = spec.ay[reg]
            ok = got == int(st[2]) if cmd == 'psg' else (got & 15) != 0
            failures += not ok
            print(f"{'ok  ' if ok else 'FAIL'} psg {reg} = {got}" + (f" (expected {st[2]})" if cmd == 'psg' else " (expected sound)"))
        elif cmd in ('beep', 'nobeep'):
            if spec.model != '48':
                print(f"skip {cmd}: a 128K plays on the AY")
                continue
            ok = (spec.beeps > 0) == (cmd == 'beep')
            failures += not ok
            print(f"{'ok  ' if ok else 'FAIL'} beeper: {spec.beeps} edges")
            spec.beeps = 0
        elif cmd == 'attr':
            row, col = int(st[1]), int(st[2])
            got = spec.peek(0x5800 + row * 32 + col)
            want = parse_value(st[3], spec, syms)
            ok = got == want
            failures += not ok
            print(f"{'ok  ' if ok else 'FAIL'} attr {row},{col} = #{got:02X} (expected #{want:02X})")
        elif cmd == 'print':
            addr = spec.resolve(st[1], syms)
            count = int(st[2]) if len(st) > 2 else 1
            print(f"{st[1]}: " + ' '.join(f"{spec.peek(addr + i):02x}" for i in range(count)))
        elif cmd in ('expect', 'poke', 'pokew'):
            value = parse_value(st[2], spec, syms)
            addr = spec.resolve(st[1], syms)
            if cmd == 'poke':
                spec.poke(addr, value)
                continue
            if cmd == 'pokew':
                spec.poke(addr, value & 0xFF)
                spec.poke(addr + 1, value >> 8)
                continue
            got = spec.peek(addr)
            ok = got == value
            failures += not ok
            print(f"{'ok  ' if ok else 'FAIL'} {st[1]} = {got} (expected {value})")
        else:
            sys.exit(f"unknown script command: {cmd}")

    if args.wav:
        render_wav(spec, args.wav)
        print(f"wav {args.wav}: {spec.t / spec.hz:.1f} s")
    if spec.busy:
        frame, worst = max(spec.busy, key=lambda b: b[1])
        over = [f for f, t in spec.busy if t > spec.frame_t]
        print(f"frames: {len(spec.busy)}, worst per-frame work: {worst} T in loop {frame} "
              f"({100 * worst / spec.frame_t:.0f}% of a frame)"
              + (f"; over a frame in {len(over)} loops" if over else ""))
    if failures:
        sys.exit(f"{failures} expectation(s) failed")


if __name__ == '__main__':
    main()
