#!/usr/bin/env python3
"""levels/levels.txt (EASY) -> levels/levels_medium.txt, levels/levels_hard.txt:
the same sixty boards with harder goals.

    mkdifficulty.py levels/levels.txt levels/levels_medium.txt levels/levels_hard.txt

What gets harder, on top of the robot's lower win rates (leveltune.py
--difficulty medium / hard sets the moves and the stars afterwards):

  MEDIUM  one ingredient more to bring down; icing of 1 layer has 2
  HARD    two ingredients more; all jelly is double; icing has one layer
          more (up to 3)

The score levels change through their stars only: the tuner puts the first
star (the goal) where fewer of the robot's games reach it.

This is a starting point: run it once, then the tuner, and edit the files
by hand from there on (make does not run it).
"""
import re
import sys

RULES = {
    'medium': {'ingredients': 1, 'cells': {'1': '2'}},
    'hard': {'ingredients': 2, 'cells': {'j': 'J', '1': '2', '2': '3'}},
}
HEADER = {
    'medium': "# MEDIUM: οι πίστες του levels.txt με πιο δύσκολους στόχους (tools/mkdifficulty.py,\n"
              "# μετά tools/leveltune.py --difficulty medium). Ένα υλικό παραπάνω, γλάσο\n"
              "# ενός στρώματος -> δύο, και λιγότερες νίκες του ρομπότ: 85% -> 40%.\n",
    'hard': "# HARD: οι πίστες του levels.txt με τους πιο δύσκολους στόχους (tools/mkdifficulty.py,\n"
            "# μετά tools/leveltune.py --difficulty hard). Δύο υλικά παραπάνω, όλο το ζελέ\n"
            "# διπλό, το γλάσο ένα στρώμα παραπάνω, και νίκες του ρομπότ 70% -> 25%.\n",
}


def transform(text, rule):
    out, in_cells, rows = [], False, 0
    for line in text.splitlines():
        body = line.split('#', 1)[0].rstrip()
        if in_cells and body:
            line = ''.join(rule['cells'].get(ch, ch) for ch in body)
            rows += 1
            in_cells = rows < 8
        elif body.startswith('cells'):
            in_cells, rows = True, 0
        elif body.startswith('ingredients'):
            n = int(body.split()[1])
            line = f"ingredients {n + rule['ingredients']}"
        out.append(line)
    return '\n'.join(out) + '\n'


def main():
    src, medium, hard = sys.argv[1:]
    text = open(src, encoding='utf-8').read()
    start = re.search(r'(?m)^level ', text).start()
    for name, path in (('medium', medium), ('hard', hard)):
        open(path, 'w', encoding='utf-8').write(HEADER[name] + '\n\n' + transform(text[start:], RULES[name]))
        print(f"{path}: {name}")


if __name__ == '__main__':
    main()
