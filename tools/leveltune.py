#!/usr/bin/env python3
"""Ρυθμίζει κινήσεις και αστέρια των πιστών με το levelsim.py (plan.md §11).

Για κάθε πίστα ένας στόχος: τι ποσοστό νικών πρέπει να έχει το άπληστο ρομπότ
του levelsim — 95% στην πρώτη, ~55% στην τελευταία, και κάθε πέμπτη λίγο πιο
εύκολη για ανάσα. Το ρομπότ δεν βλέπει αλυσίδες, άρα ένας άνθρωπος κερδίζει
πιο συχνά.

  * πίστες "score": οι κινήσεις μένουν· το 1ο αστέρι (ο στόχος) γίνεται ό,τι
    πιάνει το ποσοστό-στόχος των παρτίδων με όλες τις κινήσεις παιγμένες
  * οι άλλες: δυαδική αναζήτηση στις κινήσεις (10-40)
  * μετά, με τις τελικές τιμές, 2 αστέρια = διάμεσος των νικών, 3 = p85

Γράφει τις γραμμές moves/stars του αρχείου στη θέση τους· ό,τι δεν φτάνει τον
στόχο ούτε με 40 κινήσεις το λέει, και θέλει άλλο σχέδιο.

Οι δυσκολίες (--difficulty): easy 95% -> 55% (το levels.txt), medium
85% -> 40%, hard 70% -> 25% (τα levels_medium.txt, levels_hard.txt, από το
tools/mkdifficulty.py).

  leveltune.py levels/levels.txt [--runs N] [--only 21,22] [--dry]
                                 [--difficulty easy|medium|hard]
"""
import argparse
import multiprocessing as mp
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from levels import parse, check  # noqa: E402
from levelsim import play, pct, r500, G_SCORE  # noqa: E402

MOVES_MIN, MOVES_MAX = 10, 40
MIN_WIN = 0.12                      # κάτω από αυτό: ο στόχος της πιο εύκολης
#: ποσοστό νικών του ρομπότ στην πρώτη και στην τελευταία πίστα
CURVES = {'easy': (0.95, 0.55), 'medium': (0.85, 0.40), 'hard': (0.70, 0.25)}
CURVE = CURVES['easy']


def target(n, total):
    first, last = CURVE
    t = first - (first - last) * (n - 1) / max(1, total - 1)
    if n > 5 and n % 5 == 1:          # 6, 11, 16 ...: ανάσα
        t += 0.05
    return min(first, t)


def run(pool, lv, runs, tag):
    seeds = [f"tune:{tag}:{lv['name']}:{i}" for i in range(runs)]
    return pool.starmap(play, [(lv, s, 'greedy') for s in seeds], chunksize=max(1, runs // 32))


def winrate(res):
    return sum(r[0] for r in res) / len(res)


def tune(pool, lv, want, runs, easier=None):
    """easier: the same level one difficulty down. A harder level never has
    more moves, nor a lower goal score; if even its easier one's moves leave
    the robot under MIN_WIN, it takes the easier one's goal (cells,
    ingredients) back and wins harder through fewer moves only."""
    lv = dict(lv)
    note = ''
    cap = easier['moves'] if easier else MOVES_MAX
    if lv['goal'] == G_SCORE:
        res = run(pool, lv, runs, 'full')
        full = sorted(r[3] for r in res)
        s1 = r500(pct(full, 1 - want))
        if easier:
            s1 = max(s1, easier['stars'][0] + 500)
        lv['stars'] = [s1, s1 + 500, s1 + 1000]
    else:
        lv['moves'] = cap
        got = winrate(run(pool, lv, runs, 'm'))
        if got < MIN_WIN and easier and (lv['cells'] != easier['cells'] or
                                         lv['ingredients'] != easier['ingredients']):
            lv['cells'], lv['ingredients'] = easier['cells'], easier['ingredients']
            got = winrate(run(pool, lv, runs, 'm'))
            note = 'ο στόχος της πιο εύκολης'
        if got < want:
            note = (note + ', ' if note else '') + f'ούτε με {cap} κινήσεις'
        else:
            lo, hi = MOVES_MIN, cap
            while lo < hi:
                mid = (lo + hi) // 2
                lv['moves'] = mid
                if winrate(run(pool, lv, runs, 'm')) >= want:
                    hi = mid
                else:
                    lo = mid + 1
            lv['moves'] = hi
    res = run(pool, lv, runs, 'final')
    wins = sorted(r[2] for r in res if r[0])
    if len(wins) >= 5:
        s1 = lv['stars'][0] if lv['goal'] == G_SCORE else r500(pct(wins, 0.15))
        s2 = max(r500(pct(wins, 0.50)), s1 + 500)
        s3 = max(r500(pct(wins, 0.85)), s2 + 500)
        lv['stars'] = [s1, s2, s3]
    return lv, winrate(res), note


def rewrite(path, tuned):
    text = open(path, encoding='utf-8').read()
    for lv in tuned:
        m = re.search(rf"(?m)^level {lv['name']}\n(.*?)(?=^level |\Z)", text, re.S)
        blk = m.group(0)
        blk = re.sub(r"(?m)^moves .*$", f"moves {lv['moves']}", blk)
        blk = re.sub(r"(?m)^stars .*$", 'stars ' + ' '.join(map(str, lv['stars'])), blk)
        if lv['ingredients']:
            blk = re.sub(r"(?m)^ingredients .*$", f"ingredients {lv['ingredients']}", blk)
        c = re.search(r"(?m)^cells\n", blk)
        lines = blk[c.end():].split('\n')
        k = 0
        for i, line in enumerate(lines):
            if k < 8 and line.split('#', 1)[0].strip():
                lines[i] = lv['cells'][k] + line[8:]
                k += 1
        blk = blk[:c.end()] + '\n'.join(lines)
        text = text[:m.start()] + blk + text[m.end():]
    open(path, 'w', encoding='utf-8').write(text)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('levels')
    ap.add_argument('--runs', type=int, default=160)
    ap.add_argument('--only', default='')
    ap.add_argument('--dry', action='store_true')
    ap.add_argument('--difficulty', choices=sorted(CURVES), default='easy')
    ap.add_argument('--easier', help='the same levels one difficulty down: caps the moves, floors the goal')
    o = ap.parse_args()
    global CURVE
    CURVE = CURVES[o.difficulty]
    levels = parse(o.levels)
    for lv in levels:
        check(lv)
    easier = {lv['name']: lv for lv in parse(o.easier)} if o.easier else {}
    only = {s for s in o.only.split(',') if s}
    tuned = []
    with mp.get_context('fork').Pool(os.cpu_count() or 1) as pool:
        for n, lv in enumerate(levels, 1):
            if only and lv['name'] not in only:
                continue
            want = target(n, len(levels))
            t, got, note = tune(pool, lv, want, o.runs, easier.get(lv['name']))
            tuned.append(t)
            print(f"{lv['name']:>3} στόχος {want:4.0%} -> {got:4.0%}  moves {lv['moves']:>2} -> {t['moves']:>2}  "
                  f"stars {' '.join(map(str, t['stars']))}  {note}", flush=True)
    if not o.dry:
        rewrite(o.levels, tuned)


if __name__ == '__main__':
    main()
