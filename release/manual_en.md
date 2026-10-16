# SUGAR BYTE

**ZX SPECTRUM 48K · 128K · +2 · CASSETTE**

*A REVIVE8BIT production · VASPER · © 2026*

> Ελληνικά: [manual_el.md](manual_el.md)

---

## ★ YOUR SPECTRUM HAS A SWEET TOOTH ★

**Sixty boards. Six candies. One very hungry Spectrum.**

Swap two sweets, line up three, and watch the board go **pop**. Line up four and you get a **striped candy** that
wipes out a whole row. Make an L and you get a **wrapped candy** that blows up everything around it. Line up five
and you get the **colour bomb** — swap it with any candy and every candy of that colour on the board disappears at
once.

- **NO COLOUR CLASH WORTH THE NAME.** Every candy lives in its own character cells and has its own shape — ball,
  hexagon, square, diamond, teardrop, heart — so you can tell them apart on any TV, even in black and white.
- **IT TALKS.** *"Sugar Byte!" "Sweet!" "Delicious!" "Sugar Crush!"* — digitised speech from the 128K's sound chip,
  and from the beeper of a 48K.
- **MUSIC ON EVERY MODEL.** The tune and the effects on the AY of a 128K or +2 — and on the beeper of a 48K, in
  between the frames.
- **SUGAR CRUSH!** Finish a level with moves to spare and every leftover move turns into a striped candy — then they
  all go off at once.
- **SIXTY HAND-MADE LEVELS** — jelly to clear, icing to crack, chocolate that spreads, licorice that won't budge,
  cherries and hazelnuts to bring home, and boards shaped like diamonds, hourglasses and rings, where candies slide
  diagonally around the gaps.

---

## LOADING

**48K:** type `LOAD ""` (`J`, then `SYMBOL SHIFT` + `P` twice) and press `ENTER`, then press `PLAY` on the cassette
deck.

**128K / +2:** choose **Tape Loader** from the menu and press `PLAY`.

The title screen appears while the game loads. Then you'll hear *"Sugar Byte!"* and the main menu appears.

---

## THE MAIN MENU

![The main menu.](screenshots/menu.png)

Move the striped pointer **up and down** and choose with **fire**.

| | |
|---|---|
| **PLAY** | Start the level shown under it. |
| **LEVEL NN** | Enter a **level code** to jump to a level you've reached before (see *Level codes*). |
| **EASY / MEDIUM / HARD** | The difficulty: **fire** (or **left** / **right**) changes it. See *Difficulty*. |
| **SOUND ON / OFF** | Turn the music on or off (`M` does the same at any time). |
| **SCORES** | Your best score and stars for every level. Twenty levels to a page: **left** and **right** turn the page, **fire** or `BREAK` goes back. |

---

## CONTROLS

| | Keyboard | Joystick |
|---|---|---|
| Move the cursor | `Q` `A` `O` `P`, or the cursor keys (`CAPS SHIFT` + `5` `6` `7` `8`) | Sinclair (Interface 2, port 1) or Kempston |
| Pick up / swap | `SPACE`, `ENTER` or `0` | fire |
| Music on / off | `M` | |
| Back to the menu | `BREAK` (`CAPS SHIFT` + `SPACE`) | |

A Kempston interface is found by itself when the game starts.

---

## HOW TO PLAY

![Level 17: jelly to clear and two cherries to bring down.](screenshots/level17.png)

The board is 8 × 8. Move the cursor (the white corners) and press **fire** to pick up a candy — cyan corners show it
is picked. Then pick a candy right **next to it** (left, right, above or below) and the two swap places.

- If the swap makes a line of **three or more of the same colour**, across or down, they pop. The candies above fall
  to fill the gap and new ones drop in from the top. If the falling candies make new lines, those pop too — that's a
  **chain**, and every link in the chain multiplies your points.
- If the swap doesn't make a line, the candies swap back and it doesn't cost you a move.
- Pick the same candy again to drop it. Pick one further away and your selection jumps to that one instead.

Every swap that works uses up **one move**.

**Stuck?** Wait five seconds without touching anything and two candies start to hop — that's a move you can make. If
there are no moves left on the whole board, the board is shuffled for free.

---

## THE PANEL

From top to bottom:

- **The jar** — your score.
- **The arrows** — moves left. **The padlock** — this level's code.
- **The goal** — points to reach, jelly squares left to clear, ingredients left to bring down.
- **EASY / MEDIUM / HARD** and **LEVEL NN** — the difficulty and the level you're on.
- **Three stars** and the **progress bar** — they light up as your score passes each star's target.

---

## THE GOALS

Every level has a limited number of moves and one goal:

- **SCORE** — reach the target score.
- **JELLY** — clear every jelly square (the squares with a cyan rim). Jelly sits **under** the candies; it goes when a
  candy pops on top of it. Double jelly needs two pops.
- **INGREDIENTS** — bring the cherries and hazelnuts down to the bottom. They don't match and don't pop: clear the
  candies underneath them and they fall. They leave the board when they reach the bottom row — **or when they sit
  right on top of a gap**.
- **JELLY + INGREDIENTS** — both at once.

Reach the goal and you win, however many moves you have left. Then comes **Sugar Crush**: every move you didn't use
turns a random candy striped, and then everything goes off at once, for points.

When the level is won, the stars you earned appear on the board: **one** for winning, **two** and **three** for higher
scores. Press **fire** to go on to the next level, with its code shown in the panel.

If you run out of moves first, the border flashes. Press **fire** to try the same level again, or `BREAK` for the
menu.

---

## DIFFICULTY

The same sixty boards, three ways:

| | |
|---|---|
| **EASY** | The levels as they always were. |
| **MEDIUM** | Higher score targets, fewer moves, one more ingredient to bring down, and single-layer icing comes with two layers. |
| **HARD** | Higher targets and fewer moves still, two more ingredients, **all jelly is double**, and every piece of icing has an extra layer. |

The panel shows the difficulty above **LEVEL NN**. Codes work on every difficulty, and the best scores are kept
separately for each one — the **SCORES** table shows the difficulty you have chosen.

---

## SPECIAL CANDIES

| Line up | You get | It does |
|---|---|---|
| 4 in a row | **Striped candy** | When it pops, it clears its whole row — or its whole column — with a beam. |
| An L or a T shape | **Wrapped candy** | When it pops, it blows up the 3 × 3 square around it. |
| 5 in a row | **Colour bomb** | Swap it with any candy: every candy of that colour pops. |

![A striped candy goes off.](screenshots/beam.png)

**Swap two special candies together** for something much bigger:

| Swap | Effect |
|---|---|
| Striped + striped | A whole row **and** a whole column. |
| Striped + wrapped | A cross three candies wide. |
| Wrapped + wrapped | A 5 × 5 explosion. |
| Bomb + striped | Every candy of that colour turns striped — and they all go off. |
| Bomb + wrapped | Every candy of that colour turns wrapped — and they all go off. |
| Bomb + bomb | The whole board. |

---

## WHAT'S ON THE BOARD

| | |
|---|---|
| **Jelly** | A cyan rim under the candies. Pop a candy on top to clear one layer. |
| **Icing** (1–3 layers) | A white block. Each line popped next to it, or a special candy's beam, breaks one layer. |
| **Chocolate** | A block that **spreads**: if you finish a move without breaking any chocolate, it grows onto a candy next to it. |
| **Licorice** | A wheel that blocks the square; it breaks the way icing does. |
| **Gaps** | Black holes in the board. Nothing ever goes there. |

Candies can't fall **through** a block or a gap. Instead they **slide diagonally** around it, so even the oddest
boards fill up again.

---

## SCORING

| | Points |
|---|---|
| A line of 3 | 60 |
| A line of 4 | 120 |
| A line of 5 | 200 |
| Each candy hit by a special | 60 |
| Each layer of jelly | 100 |
| Each ingredient brought down | 1,000 |

**Everything is multiplied by the chain:** the first pop counts once, the pops caused by falling candies count
twice, the next ones three times, and so on. A long chain also gets a *"Sweet!"* — and a really long one,
*"Delicious!"*

---

## LEVEL CODES

Every level has its own four-digit code. It's shown next to the **padlock** while you play, and when you win a level
the panel shows the code for the **next** one. Write them down.

To use a code, choose **LEVEL NN** in the menu and press **fire**. The plate turns into `CODE 0000`:

- **left / right** pick a digit (it flashes),
- **up / down** change it,
- **fire** to accept, `BREAK` to cancel.

The first one's free: level 1 is **4721**.

*Best scores and stars are kept for as long as the computer stays on.*

---

## HINTS FROM THE KITCHEN

- **Play low.** Moves near the bottom of the board shake up everything above them.
- **Make special candies before you need them.** A line of four in the right place saves you three moves later.
- **Never leave chocolate alone.** Break at least one piece every move, or it takes over.
- **Keep moves for the end.** Every move you don't use becomes a striped candy during Sugar Crush.

---

## CREDITS

**Design, code, graphics:** VASPER · **A REVIVE8BIT production · 2026**

Written in Z80 assembly with rasm; graphics drawn in Aseprite. A Spectrum version of the Amstrad CPC game.

## **SUGAR BYTE — Pop it. Swap it. Crush it.**
