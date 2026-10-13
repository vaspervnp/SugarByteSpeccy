; voice.asm — φωνή: «Sugar Byte!», «Sweet!», «Delicious!», «Sugar Crush!»
;
; Τα δείγματα (tools/voice.py) είναι 4-bit, δύο το byte, 5.500 το δευτερόλεπτο,
; τα ίδια με του CPC.
;
; 128K: ο AY δεν έχει DAC· με τόνο και θόρυβο κλειστούς, η ένταση γίνεται το
; κύμα. Η κλίμακά του είναι λογαριθμική, γι' αυτό παίζουν και τα τρία κανάλια
; μαζί: κάθε δείγμα είναι μια τριάδα εντάσεων (voice_tri) με γραμμικό άθροισμα.
;
; 48K: ο beeper έχει δύο στάθμες· κάθε δείγμα είναι ένας παλμός (PWM) που μένει
; αναμμένος όσο μεγαλύτερο είναι.
;
; Το say κρατάει τη μηχανή όσο μιλάει (~0,5-1 s): η μουσική σωπαίνει. Τα
; διαστήματα είναι μετρημένα για ~640 T το δείγμα στο tools/zxrun.py.

VOICE_D1        equ 31          ; djnz ανάμεσα στο 1ο και το 2ο δείγμα του byte (AY)
VOICE_D2        equ 27          ; ... και μετά το 2ο, όπου ο βρόχος κοστίζει ήδη
BEEP_PAD1       equ 9           ; ό,τι λείπει από τον παλμό του beeper ως τα 640 T
BEEP_PAD2       equ 5

; HL = η φράση (VOICE_*), DE = το μήκος της (VOICE_*_LEN).
say:
        ld a,1
        ld (speaking),a         ; η διακοπή δεν αγγίζει τον ήχο
        push hl
        push de
        ld a,(ay_present)
        or a
        jr z,say_beeper
        ld a,7                  ; μίκτης: τόνοι και θόρυβοι κλειστοί
        ld e,#3F
        call psg_write
        pop ix                  ; IX = bytes
        pop iy                  ; IY = δεδομένα
.byte   ld a,(iy+0)             ; το πάνω nibble
        rrca
        rrca
        rrca
        rrca
        call .sample
        ld b,VOICE_D1
.w1     djnz .w1
        ld a,(iy+0)             ; το κάτω
        call .sample
        inc iy
        dec ix
        ld a,ixh
        or ixl
        ld b,VOICE_D2
.w2     djnz .w2
        jr nz,.byte
        xor a
        ld (speaking),a         ; η επόμενη διακοπή ξαναγράφει τα πάντα
        ret

; A = δείγμα (κάτω nibble): η τριάδα του στα κανάλια A, B, C.
.sample and 15
        add a,a
        add a,a
        add a,voice_tri&#FF
        ld e,a
        ld d,voice_tri>>8
        ld hl,#0800             ; L = 0, H = καταχωρητής 8 (ένταση A)
        repeat 3
        ld bc,#FFFD
        out (c),h               ; ο καταχωρητής
        ld b,#BF
        ld a,(de)
        out (c),a               ; η ένταση
        inc e
        inc h
        rend
        ret

; Ο beeper: ο παλμός μένει αναμμένος 2v+1 βήματα των 13 T και σβηστός 31-2v.
say_beeper:
        pop ix
        pop iy
.byte   ld a,(iy+0)
        rrca
        rrca
        rrca
        rrca
        call .pulse
        ld b,BEEP_PAD1
.w1     djnz .w1
        ld a,(iy+0)
        call .pulse
        inc iy
        dec ix
        ld a,ixh
        or ixl
        ld b,BEEP_PAD2
.w2     djnz .w2
        jr nz,.byte
        ld a,(border_col)
        out (#FE),a
        xor a
        ld (speaking),a
        ret
.pulse  and 15
        add a,a
        inc a
        ld b,a                  ; B = 2v+1
        neg
        add a,32
        ld c,a                  ; C = 31-2v
        ld a,(border_col)
        or #10
        out (#FE),a
.on     djnz .on
        and #07
        out (#FE),a
        ld b,c
.off    djnz .off
        ret

; Ο έπαινος στο τέλος μιας κίνησης: όσο πιο μακριά η αλυσίδα, τόσο πιο γλυκός.
; Το chain μετράει τα RESOLVE: 2 = καμία αλυσίδα.
say_praise:
        ld a,(chain)
        cp 6
        jr c,.sweet
        ld hl,VOICE_DELICIOUS
        ld de,VOICE_DELICIOUS_LEN
        jp say
.sweet  cp 4
        ret c
        ld hl,VOICE_SWEET
        ld de,VOICE_SWEET_LEN
        jp say

        align 64
        include "../build/voice.asm"
        assert (voice_tri&#FF)+16*4 <= 256
voice_data:
        incbin "../build/voice.bin"
