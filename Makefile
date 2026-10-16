# Sugar Byte - ZX Spectrum 48K/128K. Build with rasm
# (https://github.com/EdouardBERGE/rasm) and Python 3 (+ Pillow, the `z80`
# module, ffmpeg for the voice).
#
#   make              the game on tape (.tap and .tzx) and as snapshots (.z80,
#                     48K and 128K)
#   make run          the tape in FBZX
#   make test         the scripts of tests/ on tools/zxrun.py, 48K and 128K
#   make check        the tape loaded through the real 48K and 128K ROMs
#   make manuals      docs/manual_en.pdf, docs/manual_el.pdf (fpdf2)
#   make release      the tape, the snapshots and the manuals in release/
#   make clean

SHELL  := /bin/bash
RASM   ?= rasm
PYTHON ?= python3
FBZX   ?= fbzx
B      := build

.PHONY: all run test check manuals release clean

all: $(B)/sugar.tap $(B)/sugar48.z80 $(B)/sugar128.z80

$(B):
	mkdir -p $(B)

# --- data made by the tools ----------------------------------------------------
# The art: assets/aseprite/*.aseprite and their sheets assets/sheets/*, drawn
# by the Aseprite scripts tools/aseprite/*.lua (in Aseprite: dofile them, or
# aseprite -b --script tools/aseprite/candy.lua ...). The sheets are in git.
$(B)/gfx.asm: tools/zxgfx.py $(wildcard assets/sheets/*) | $(B)
	$(PYTHON) tools/zxgfx.py $@ --preview $(B)/gfx.png

# The levels: EASY, MEDIUM, HARD (tools/mkdifficulty.py made the last two from
# the first, tools/leveltune.py --difficulty tuned their moves and stars).
LEVELS := levels/levels.txt levels/levels_medium.txt levels/levels_hard.txt
$(B)/levels.asm: $(LEVELS) tools/levels.py | $(B)
	$(PYTHON) tools/levels.py $(LEVELS) $@

VOICES := sugarbyte sweet delicious crush
$(B)/voice.bin $(B)/voice.asm &: $(VOICES:%=voice/%.wav) tools/voice.py | $(B)
	$(PYTHON) tools/voice.py $(B)/voice.bin $(B)/voice.asm $(foreach v,$(VOICES),$(v)=voice/$(v).wav)


# --- the game ------------------------------------------------------------------
SRC := $(wildcard src/*.asm) $(B)/gfx.asm $(B)/levels.asm $(B)/voice.asm $(B)/voice.bin

$(B)/sugar.bin $(B)/sugar.sym &: $(SRC) | $(B)
	$(RASM) src/main.asm -os $(B)/sugar.sym -s -sa

# the loading screen: the game's own menu (tools/zxrun.py)
$(B)/loading.scr: $(B)/sugar.bin $(B)/sugar.sym tools/mkloadscr.py tools/zxrun.py
	$(PYTHON) tools/mkloadscr.py $(B)/sugar.bin $(B)/sugar.sym $@ --png $(B)/loading.png

$(B)/sugar.tap: $(B)/sugar.bin $(B)/sugar.sym $(B)/loading.scr src/loader.bas tools/mktap.py
	$(PYTHON) tools/mktap.py $@ --sym $(B)/sugar.sym --tzx $(B)/sugar.tzx \
		--basic src/loader.bas SUGARBYTE --screen $(B)/loading.scr SUGARSCR \
		--code $(B)/sugar.bin SUGARBIN BIN_ORG

$(B)/sugar48.z80: $(B)/sugar.bin $(B)/sugar.sym $(B)/loading.scr tools/mkz80.py
	$(PYTHON) tools/mkz80.py $(B)/sugar.bin $(B)/sugar.sym $(B)/loading.scr $@ --model 48

$(B)/sugar128.z80: $(B)/sugar.bin $(B)/sugar.sym $(B)/loading.scr tools/mkz80.py
	$(PYTHON) tools/mkz80.py $(B)/sugar.bin $(B)/sugar.sym $(B)/loading.scr $@ --model 128

run: $(B)/sugar.tap
	$(FBZX) $<

# --- checks --------------------------------------------------------------------
test: $(B)/sugar.bin $(B)/sugar.sym
	@set -e; for m in 48 128; do for t in tests/*.txt; do \
	  echo "== $$t ($$m K)"; \
	  $(PYTHON) tools/zxrun.py $(B)/sugar.bin --sym $(B)/sugar.sym --model $$m \
	    --script $$t --out $(B)/shots/$$m; \
	done; done

check: $(B)/sugar.tap
	@for m in 48 128; do \
		echo "=== the tape through the real ROM, $$m K ==="; \
		$(PYTHON) tools/zxcheck.py $(B)/sugar.tap --sym $(B)/sugar.sym \
			--bin $(B)/sugar.bin --blocks 6 --model $$m; r=$$?; \
		if [ $$r = 2 ]; then echo "    skipped (no emulator or ROM)"; \
		elif [ $$r != 0 ]; then exit 1; fi; done

# The manuals as A5 booklets (fpdf2); the PDFs are in git.
manuals: docs/manual_en.pdf docs/manual_el.pdf

docs/manual_%.pdf: docs/manual_%.md $(wildcard docs/screenshots/*.png) tools/mkmanual.py
	$(PYTHON) tools/mkmanual.py $< $@

RELEASE := $(B)/sugar.tap $(B)/sugar.tzx $(B)/sugar48.z80 $(B)/sugar128.z80

release: all
	rm -rf release
	mkdir -p release
	cp $(RELEASE) release/
	cp docs/manual_en.md docs/manual_el.md release/
	cp docs/manual_en.pdf docs/manual_el.pdf release/
	cd release && sha256sum * > SHA256SUMS
	ls -l release

clean:
	rm -rf $(B)
