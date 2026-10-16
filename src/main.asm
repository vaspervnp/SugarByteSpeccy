; Sugar Byte — match-3 για ZX Spectrum 48K / 128K
;
;   rasm src/main.asm -os build/sugar.sym -s -sl   -> build/sugar.bin (LOAD_BASE)
;
; Το παιχνίδι του CPC (../SugarByteCPC): η λογική του ταμπλό αυτούσια, η
; εικόνα, ο ήχος, η είσοδος και η κασέτα του Spectrum. Ο χάρτης της μνήμης
; είναι στο src/const.asm και στο planzx.md.

        include "const.asm"
        include "vars.asm"
        assert (board&#FF) == 0 && (BG_ATTR&#3FF) == 0
        assert vars_end-vars_start < 256 && snd_end <= LOAD_BASE
        assert (gap&#FF)+2*COLS < 256 && (spawn&#FF)+COLS < 256

; --- #6200: τα γραφικά και οι πίστες (μνήμη με contention: διαβάζονται λίγο) --
        org LOAD_BASE
bin_start:
        include "../build/gfx.asm"
        include "../build/levels.asm"
        assert NLEVELS <= MAX_LEVELS
NLEVELS_BCD     equ floor(NLEVELS/10)*6+NLEVELS   ; το rasm διαιρεί με δεκαδικά

; --- ο κώδικας ------------------------------------------------------------------
start:
        di
        ld sp,STACK_TOP
        xor a
        ld (border_col),a
        out (#FE),a
        call hw_init            ; IM 2, ο AY, το Kempston
        call snd_init
        call menu_start
        jp main_loop

        include "hw.asm"
        include "gfx.asm"
        include "board.asm"
        include "special.asm"
        include "cells.asm"
        include "ingred.asm"
        include "sound.asm"
        include "anim.asm"
        include "voice.asm"
        include "level.asm"
        include "codes.asm"
        include "menu.asm"
        include "game.asm"
        include "hud.asm"
code_end:

; Πάνω από τον κώδικα, όχι στην κασέτα: οι καλύτεροι πόντοι, μία σελίδα ανά
; δυσκολία (best_ptr).
        nocode
        align 256
best            defs 256*NDIFFICULTIES  ; ανά πίστα: πόντοι BCD (3), αστέρια (1)
best_end
        code
        assert best_end <= IM2_JUMP && 4*MAX_LEVELS == 256

        save "build/sugar.bin",bin_start,code_end-bin_start
LOAD_ADDR       equ start
BIN_ORG         equ bin_start
