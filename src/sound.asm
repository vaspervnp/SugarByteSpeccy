; sound.asm — ο ήχος: ο AY του 128K, ή ο beeper του 48K (planzx.md §6)
;
; Τρέχει στη διακοπή, 50 φορές το δευτερόλεπτο, ώστε το τέμπο να μένει
; σταθερό όσο κι αν κρατάει η σχεδίαση ενός καρέ. Κανάλια A + B: μουσική
; (μελωδία, μπάσο). Κανάλι C: εφέ. Ο AY του Spectrum χτυπάει στα 1,7734 MHz
; (του CPC στο 1 MHz): οι περίοδοι είναι του CPC επί AYF.
;
; Στον 48K τα ίδια βήματα γεμίζουν μόνο το psg_shadow, και ο beeper παίζει από
; εκεί ό,τι περισσεύει από κάθε καρέ (beeper_frame): το εφέ, αλλιώς τη μελωδία.

AYF     equ 1.7734              ; ο AY του Spectrum / ο AY του CPC

; --- οι νότες: περίοδος AY = 1,7734 MHz / (16 x συχνότητα) -----------------
REST    equ 1                   ; σιωπή· 0 = η νότα κρατάει
N_C2    equ 2
N_Cs2   equ 3
N_D2    equ 4
N_Ds2   equ 5
N_E2    equ 6
N_F2    equ 7
N_Fs2   equ 8
N_G2    equ 9
N_Gs2   equ 10
N_A2    equ 11
N_As2   equ 12
N_B2    equ 13
N_C3    equ 14
N_Cs3   equ 15
N_D3    equ 16
N_Ds3   equ 17
N_E3    equ 18
N_F3    equ 19
N_Fs3   equ 20
N_G3    equ 21
N_Gs3   equ 22
N_A3    equ 23
N_As3   equ 24
N_B3    equ 25
N_C4    equ 26
N_Cs4   equ 27
N_D4    equ 28
N_Ds4   equ 29
N_E4    equ 30
N_F4    equ 31
N_Fs4   equ 32
N_G4    equ 33
N_Gs4   equ 34
N_A4    equ 35
N_As4   equ 36
N_B4    equ 37
N_C5    equ 38
N_Cs5   equ 39
N_D5    equ 40
N_Ds5   equ 41
N_E5    equ 42
N_F5    equ 43
N_Fs5   equ 44
N_G5    equ 45
N_Gs5   equ 46
N_A5    equ 47
N_As5   equ 48
N_B5    equ 49
N_C6    equ 50
N_Cs6   equ 51
N_D6    equ 52
N_Ds6   equ 53
N_E6    equ 54
N_F6    equ 55
N_Fs6   equ 56
N_G6    equ 57
N_Gs6   equ 58
N_A6    equ 59
N_As6   equ 60
N_B6    equ 61
N_C7    equ 62

note_tab:                       ; από N_C2 = 2
        dw 1695,1600,1509,1426,1344,1270,1199,1131,1068,1007,951,897
        dw 848,800,755,713,672,635,599,566,534,504,475,449
        dw 424,399,378,356,337,317,300,282,266,252,238,225
        dw 211,200,188,177,168,158,149,142,133,126,119,112
        dw 106,99,94,89,83,80,74,71,67,64,60,57
        dw 53

MUS_SPEED       equ 8           ; καρέ ανά όγδοο (≈ 94 BPM)
MEL_VOL         equ 12          ; μελωδία: ξεκινάει εδώ, πέφτει ώς MEL_FLOOR
MEL_FLOOR       equ 8
BASS_VOL        equ 11
BASS_FLOOR      equ 6

; Ένα όγδοο τη γραμμή: μελωδία, μπάσο. #FF = από την αρχή.
music:
        db N_C5,N_C3
        db N_E5,0
        db N_G5,N_G3
        db N_E5,0
        db N_C6,N_C3
        db N_G5,0
        db N_E5,N_G3
        db N_G5,0

        db N_A4,N_F2
        db N_C5,0
        db N_F5,N_C3
        db N_C5,0
        db N_A5,N_F2
        db N_F5,0
        db N_C5,N_C3
        db N_F5,0

        db N_G4,N_G2
        db N_B4,0
        db N_D5,N_D3
        db N_G5,0
        db N_F5,N_G2
        db N_D5,0
        db N_B4,N_D3
        db N_D5,0

        db N_C5,N_C3
        db N_E5,0
        db N_G5,N_G2
        db N_C6,0
        db N_G5,N_C3
        db 0,0
        db REST,REST
        db REST,0

        db N_E5,N_C3
        db 0,0
        db N_G5,N_G3
        db 0,0
        db N_A5,N_A2
        db N_G5,0
        db N_E5,N_E3
        db N_C5,0

        db N_D5,N_D3
        db 0,0
        db N_F5,N_A3
        db 0,0
        db N_A5,N_F2
        db N_G5,0
        db N_F5,N_C3
        db N_D5,0

        db N_E5,N_C3
        db N_G5,0
        db N_C6,N_G2
        db N_G5,0
        db N_F5,N_F2
        db N_A5,0
        db N_D6,N_C3
        db N_A5,0

        db N_G5,N_G2
        db N_F5,0
        db N_E5,N_B2
        db N_D5,0
        db N_C5,N_C3
        db 0,0
        db REST,REST
        db REST,0

        db #FF

; --- τα εφέ: καρέ των 4 bytes — περίοδος (0 = χωρίς τόνο), ένταση, θόρυβος
; (0 = χωρίς). Τελειώνει με ένταση #FF.
sfx_select:
        dw 213
        db 12,0
        dw 160
        db 10,0
        db 0,0,#FF,0
sfx_swap:
        dw 567
        db 11,0
        dw 461
        db 11,0
        dw 372
        db 10,0
        dw 301
        db 8,0
        db 0,0,#FF,0
sfx_bad:
        dw 887
        db 13,0
        dw 993
        db 12,0
        dw 1117
        db 11,0
        dw 1241
        db 10,0
        dw 1419
        db 8,0
        dw 1596
        db 6,0
        db 0,0,#FF,0
sfx_beam:
        repeat 10,n
        dw floor((40+n*6)*AYF+0.5)
        db 15-n,3
        rend
        db 0,0,#FF,0
sfx_wrap:
        repeat 12,n
        dw 0
        db 16-n,8+n
        rend
        db 0,0,#FF,0
sfx_bomb:
        repeat 15,n
        dw floor((600+n*40)*AYF+0.5)
        db 15-n/2,12+n
        rend
        db 0,0,#FF,0
sfx_collect:                    ; C6 E6 G6 C7, 3 καρέ η καθεμία
        repeat 3
        dw 106
        db 13,0
        rend
        repeat 3
        dw 85
        db 13,0
        rend
        repeat 3
        dw 71
        db 13,0
        rend
        repeat 6,n
        dw 53
        db 14-n,0
        rend
        db 0,0,#FF,0
sfx_over:                       ; G4 E4 C4, κατεβαίνοντας
        repeat 8,n
        dw 282
        db 13-n/2,0
        rend
        repeat 8,n
        dw 337
        db 12-n/2,0
        rend
        repeat 16,n
        dw 424
        db 12-n*3/4,0
        rend
        db 0,0,#FF,0

sfx_win:                        ; C4 E4 G4 C5, και το C5 κρατάει
        repeat 4
        dw 424
        db 13,0
        rend
        repeat 4
        dw 337
        db 13,0
        rend
        repeat 4
        dw 282
        db 13,0
        rend
        repeat 14,n
        dw 211
        db 14-n,0
        rend
        db 0,0,#FF,0

; Το σκάσιμο: ένα «ποπ» που ανεβαίνει, ψηλότερα σε κάθε βαθμίδα της αλυσίδας.
pop_tab:
        dw 355,316,282,252,223,199

; ---------------------------------------------------------------------------
; Ο player

snd_init:
        ld hl,snd_clear
        ld b,snd_end-snd_clear
        xor a
.clr    ld (hl),a
        inc hl
        djnz .clr
        ld hl,music
        ld (mus_ptr),hl
        ld a,1
        ld (mus_wait),a
        ld (mus_on),a
        ld a,#38
        ld (psg_shadow+7),a
        ld hl,#ACE1
        ld (noise_seed),hl
        ret

; Στη διακοπή.
sound_tick:
        ld a,(speaking)         ; μιλάει: ο ήχος είναι του say
        or a
        ret nz
        call music_tick
        call sfx_tick
        ld a,(ay_present)
        or a
        ret z
        ld hl,psg_shadow        ; οι καταχωρητές 0-10 στον AY
        xor a
.w      ld e,(hl)
        call psg_write
        inc hl
        inc a
        cp 11
        jr c,.w
        ret

; A = καταχωρητής, E = τιμή. Δεν πειράζει A, HL.
psg_write:
        ld bc,#FFFD
        out (c),a
        ld b,#BF
        out (c),e
        ret

music_tick:
        ld a,(mus_on)
        or a
        jr nz,.on
        ld (psg_shadow+8),a
        ld (psg_shadow+9),a
        ret
.on     ld hl,mus_wait
        dec (hl)
        jr nz,.decay
        ld (hl),MUS_SPEED
        ld hl,(mus_ptr)
        ld a,(hl)
        cp #FF
        jr nz,.row
        ld hl,music
        ld a,(hl)
.row    inc hl
        ld e,(hl)
        inc hl
        ld (mus_ptr),hl
        push de
        ld hl,psg_shadow+0
        ld de,psg_shadow+8
        ld c,MEL_VOL
        call start_note
        pop de
        ld a,e
        ld hl,psg_shadow+2
        ld de,psg_shadow+9
        ld c,BASS_VOL
        jp start_note
.decay  ld a,(hl)               ; κάθε δεύτερο καρέ, ένα σκαλί πιο σιγά
        and 1
        ret nz
        ld hl,psg_shadow+8
        ld a,(hl)
        cp MEL_FLOOR+1
        jr c,.bass
        dec (hl)
.bass   inc hl
        ld a,(hl)
        cp BASS_FLOOR+1
        ret c
        dec (hl)
        ret

; A = νότα (0 κρατάει, REST σιωπή), HL = καταχωρητής περιόδου, DE = έντασης,
; C = αρχική ένταση.
start_note:
        or a
        ret z
        cp REST
        jr nz,.play
        xor a
        ld (de),a
        ret
.play   push hl
        sub 2
        add a,a
        ld hl,note_tab
        call add_hl_a
        ld a,(hl)
        inc hl
        ld b,(hl)
        pop hl
        ld (hl),a
        inc hl
        ld (hl),b
        ld a,c
        ld (de),a
        ret

sfx_tick:
        ld hl,(sfx_ptr)
        ld a,h
        or l
        jr z,.silent
        ld a,(sfx_pop)
        or a
        jr nz,.pop
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld a,(hl)
        inc hl
        ld c,(hl)
        inc hl
        cp #FF
        jr z,.end
        ld (sfx_ptr),hl
.set    ld (psg_shadow+10),a    ; DE = περίοδος, A = ένταση, C = θόρυβος
        ld (psg_shadow+4),de
        ld a,c
        ld (psg_shadow+6),a
        ld b,#38                ; μίκτης: τόνοι ανοιχτοί, θόρυβοι κλειστοί
        ld a,d
        or e
        jr nz,.tone
        set 2,b
.tone   ld a,c
        or a
        jr z,.mix
        res 5,b
.mix    ld a,b
        ld (psg_shadow+7),a
        ret
.pop    dec a
        ld (sfx_pop),a
        jr z,.end
        ld hl,(pop_per)         ; η περίοδος πέφτει 1/8 το καρέ: ο τόνος ανεβαίνει
        ld d,h
        ld e,l
        srl d
        rr e
        srl d
        rr e
        srl d
        rr e
        or a
        sbc hl,de
        ld (pop_per),hl
        ex de,hl
        ld a,(sfx_pop)
        add a,a
        add a,a
        cp 15
        jr c,.pv
        ld a,15
.pv     ld c,0
        jr .set
.end    ld hl,0
        ld (sfx_ptr),hl
        xor a
        ld (sfx_pop),a
.silent xor a
        ld (psg_shadow+10),a
        ld a,#38
        ld (psg_shadow+7),a
        ret

; HL = εφέ: παίζει στο κανάλι C, στη θέση όποιου έπαιζε.
play_sfx:
        di
        ld (sfx_ptr),hl
        xor a
        ld (sfx_pop),a
        ei
        ret

; Το σκάσιμο, με το ύψος της βαθμίδας της αλυσίδας.
play_pop:
        ld a,(chain)
        or a
        jr nz,.c
        inc a
.c      cp 7
        jr c,.ok
        ld a,6
.ok     dec a
        add a,a
        ld hl,pop_tab
        call add_hl_a
        ld e,(hl)
        inc hl
        ld d,(hl)
        di
        ld (pop_per),de
        ld a,8
        ld (sfx_pop),a
        ld hl,1                 ; όχι μηδέν: «παίζει κάτι»
        ld (sfx_ptr),hl
        ei
        ret

; Το εφέ του σκασίματος που ξεκινάει: βόμβα αν σκάνε πολλά, έκρηξη αν σκάει
; περιτύλιγμα, αλλιώς ποπ.
play_clear_sfx:
        ld a,(clear_n)
        cp BIG_CLEAR
        ld hl,sfx_bomb
        jr nc,play_sfx
        ld a,(boom)
        or a
        ld hl,sfx_wrap
        jr nz,play_sfx
        jr play_pop

; ---------------------------------------------------------------------------
; Ο beeper του 48K: ως την επόμενη διακοπή παίζει το κανάλι του εφέ (C), ή αν
; σωπαίνει τη μελωδία (A), από το psg_shadow. Μισή περίοδος τετραγωνικού είναι
; περίοδος AY x 15,8 T· ο θόρυβος αλλάζει στάθμη στην τύχη κάθε περίοδο θορύβου
; x 31,6 T. Ένταση κάτω από BEEP_MIN: σιωπή. Το περιθώριο κρατάει το χρώμα του.
BEEP_MIN        equ 4

beeper_frame:
        ld a,(psg_shadow+10)    ; το εφέ
        cp BEEP_MIN
        jr c,.music
        ld a,(psg_shadow+7)
        bit 5,a                 ; 0 = θόρυβος στο C
        jr z,.noise
        ld hl,(psg_shadow+4)
        jr .tone
.music  ld a,(psg_shadow+8)     ; η μελωδία (0 όταν η μουσική είναι κλειστή)
        cp BEEP_MIN
        jr c,.quiet
        ld hl,(psg_shadow+0)
.tone   ld a,h
        or l
        jr z,.quiet
        ld d,h                  ; μετρητής = P * 5/8: ο βρόχος του είναι 26 T
        ld e,l
        srl d
        rr e
        ld h,d
        ld l,e
        srl d
        rr e
        srl d
        rr e
        add hl,de
        ex de,hl                ; DE = μετρητής
        ld a,(border_col)
        ld c,a
        ld a,(frame_count)
        ld b,a
.cycle  ld a,c
        xor #10
        ld c,a
        out (#FE),a
        ld h,d
        ld l,e
.d      dec hl
        ld a,h
        or l
        jr nz,.d
        ld a,(frame_count)
        cp b
        jr z,.cycle
        ret
.noise  ld a,(psg_shadow+6)     ; περίοδος θορύβου 1-31: μετρητής 5/4 της
        and 31
        jr nz,.np
        inc a
.np     ld e,a
        srl a
        srl a
        add a,e
        ld e,a                  ; E = μετρητής (βρόχος 16 T: djnz + nop)
        ld a,(frame_count)
        ld d,a
        ld hl,(noise_seed)
.nstep  add hl,hl               ; LFSR: ένα bit στην τύχη στο κρατούμενο
        sbc a,a
        ld c,a
        jr nc,.n0
        ld a,l
        xor #2D
        ld l,a
.n0     ld a,c
        and #10
        ld c,a
        ld a,(border_col)
        or c
        out (#FE),a
        ld b,e
.nd     nop
        djnz .nd
        ld a,(frame_count)
        cp d
        jr z,.nstep
        ld (noise_seed),hl
        ret
.quiet  halt
        ret
