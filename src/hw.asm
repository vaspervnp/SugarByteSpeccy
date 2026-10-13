; hw.asm — η διακοπή, ο AY, το πληκτρολόγιο και τα joysticks

; IM 2 μέσα από πίνακα 257 bytes IM2_FILL: ό,τι κι αν έχει ο δίαυλος, το
; διάνυσμα είναι το IM2_JUMP, όπου κάθεται ένα JP στη διακοπή. I >= #80, αλλιώς
; ένας 48K δείχνει «χιόνι».
hw_init:
        ld hl,IM2_TABLE
        ld de,IM2_TABLE+1
        ld bc,256
        ld (hl),IM2_FILL
        ldir
        ld a,#C3                ; JP nn
        ld (IM2_JUMP),a
        ld hl,int_handler
        ld (IM2_JUMP+1),hl
        ld a,IM2_I
        ld i,a
        im 2
        xor a
        ld (frame_count),a
        ld (ay_present),a
        ld (speaking),a
        ei
        call ay_detect
        jp kempston_detect

; Μία φορά το καρέ, στην αρχή του (50 Hz).
int_handler:
        push af
        push bc
        push de
        push hl
        push ix
        ld hl,frame_count
        inc (hl)
        call sound_tick
        pop ix
        pop hl
        pop de
        pop bc
        pop af
        ei
        reti

; Ο AY (128K, +2): η θύρα #FFFD διαβάζει πίσω τον καταχωρητή που της δόθηκε· σε
; έναν 48K είναι ο «αιωρούμενος» δίαυλος, που στο περιθώριο διαβάζει #FF.
ay_detect:
        halt
        ld bc,#FFFD
        xor a
        out (c),a               ; καταχωρητής 0
        ld b,#BF
        ld a,#55
        out (c),a
        ld b,#FF
        in a,(c)
        cp #55
        ret nz
        ld b,#BF
        ld a,#AA
        out (c),a
        ld b,#FF
        in a,(c)
        cp #AA
        ret nz
        ld a,1
        ld (ay_present),a
        ret

; Kempston μόνο αν η θύρα #1F διάβασε σαν joystick (κανένα από τα bits 5-7)
; για δύο ολόκληρα καρέ: χωρίς interface είναι ο αιωρούμενος δίαυλος.
kempston_detect:
        halt
        ld a,(frame_count)
        add a,2
        ld l,a
        ld h,0
.listen in a,(#1F)
        or h
        ld h,a
        ld a,(frame_count)
        cp l
        jr nz,.listen
        ld a,h
        and #E0
        ld a,1
        jr z,.on
        xor a
.on     ld (kempston_on),a
        ret

; Περιμένει την επόμενη διακοπή. Ο βρόχος του παιχνιδιού ξεκινάει εδώ (το
; tools/zxrun.py μετράει καρέ με breakpoint σε αυτή την ετικέτα). Σε 48K, ως
; τότε παίζει ο beeper.
wait_vbl:
        ld a,(ay_present)
        or a
        jp z,beeper_frame
        halt
        ret

; Διαβάζει τις 8 μισές γραμμές του πληκτρολογίου στο keymap (1 = πατημένο).
read_matrix:
        ld hl,keymap
        ld bc,#FEFE
.row    in a,(c)
        cpl
        and #1F
        ld (hl),a
        inc hl
        rlc b
        jr c,.row
        ret

; joy = ό,τι κρατιέται, joy_edge = ό,τι πατήθηκε σε αυτό το καρέ.
;
;   QAOP, 6789 0 (Sinclair), τα βελάκια (CAPS SHIFT + 5678), Kempston
;   SPACE, ENTER, 0, fire: επιλογή      M: μουσική      BREAK: πίσω / κωδικός
read_input:
        call read_matrix
        ld c,0
        ld a,(keymap+0)         ; CAPS SHIFT;
        and 1
        jr z,.nocaps
        ld a,(keymap+7)         ; ... και SPACE: BREAK, όχι επιλογή
        and 1
        jr z,.cursor
        ld c,J_ESC
        ld hl,keymap+7
        res 0,(hl)
.cursor ld a,(keymap+4)         ; τα βελάκια: 6 κάτω, 7 πάνω, 8 δεξιά (και το 5
        ld b,a                  ; αριστερά πιο κάτω): όχι Sinclair
        ld hl,cursor_map
        call map_bits
        ld a,(keymap+4)
        and %11100
        cpl
        ld b,a
        ld a,(keymap+4)
        and b
        ld (keymap+4),a
.nocaps ld hl,input_map
.key    ld a,(hl)
        cp #FF
        jr z,.kemp
        inc hl
        ld de,keymap
        add a,e
        ld e,a
        ld a,(de)
        and (hl)
        inc hl
        jr z,.up
        ld a,c
        or (hl)
        ld c,a
.up     inc hl
        jr .key
.kemp   ld a,(kempston_on)
        or a
        jr z,.done
        in a,(#1F)              ; fire, πάνω, κάτω, αριστερά, δεξιά
        ld hl,kemp_map
        ld b,a
        call map_bits
.done   ld a,(joy)
        ld (joy_prev),a
        cpl
        and c
        ld (joy_edge),a
        ld a,c
        ld (joy),a
        ret

; B = bits, HL = πίνακας 5 τιμών J_* (bit 0 πρώτο): C |= όσων είναι 1.
map_bits:
        ld e,5
.l      rr b
        jr nc,.n
        ld a,c
        or (hl)
        ld c,a
.n      inc hl
        dec e
        jr nz,.l
        ret

cursor_map:     db 0,0,J_RIGHT,J_UP,J_DOWN          ; 0 9 8 7 6 με CAPS SHIFT
kemp_map:       db J_RIGHT,J_LEFT,J_DOWN,J_UP,J_FIRE

; μισή γραμμή, bits, J_*
input_map:
        db 2,%00001,J_UP        ; Q
        db 1,%00001,J_DOWN      ; A
        db 5,%00010,J_LEFT      ; O
        db 5,%00001,J_RIGHT     ; P
        db 3,%10000,J_LEFT      ; 5 (βελάκι)
        db 4,%10000,J_LEFT      ; 6: Sinclair
        db 4,%01000,J_RIGHT     ; 7
        db 4,%00100,J_DOWN      ; 8
        db 4,%00010,J_UP        ; 9
        db 4,%00001,J_FIRE      ; 0
        db 7,%00001,J_FIRE      ; SPACE
        db 6,%00001,J_FIRE      ; ENTER
        db 7,%00100,J_MUSIC     ; M
        db #FF

; A = οι κατευθύνσεις που πρέπει να εκτελεστούν σε αυτό το καρέ: αμέσως στο
; πάτημα, μετά από REP_FIRST καρέ αν κρατιέται, και ύστερα κάθε REP_NEXT.
get_dir:
        ld a,(joy)
        and J_UP|J_DOWN|J_LEFT|J_RIGHT
        jr nz,.held
        ld (rep_cnt),a
        ret
.held   ld b,a
        ld a,(joy_edge)
        and J_UP|J_DOWN|J_LEFT|J_RIGHT
        jr z,.rep
        ld a,REP_FIRST
        ld (rep_cnt),a
        ld a,b
        ret
.rep    ld hl,rep_cnt
        dec (hl)
        ld a,0
        ret nz
        ld (hl),REP_NEXT
        ld a,b
        ret
