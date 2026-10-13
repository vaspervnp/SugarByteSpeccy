; anim.asm — ό,τι στον CPC έκαναν τα raster: ο τίτλος αλλάζει χρώματα γράμμα
; γράμμα, και οι ρίγες του ζαχαρωτού τρέχουν. Εδώ είναι μόνο attributes: τα
; γράμματα του τίτλου έχουν το καθένα τους δικούς του χαρακτήρες, και οι ρίγες
; του ζαχαρωτού είναι διαγώνιες μισές-μισές, άρα όταν το ink και το paper
; αλλάζουν θέση μοιάζουν να προχωράνε κατά μισή περίοδο.

ANIM_ROT_FRAMES equ 8           ; καρέ ανά βήμα του κύκλου του τίτλου
ANIM_CANE_FRAMES equ 4          ; καρέ ανά βήμα των ριγών
A_CANE2         equ BRIGHT+WHITE*PAPER+RED

; Μία φορά το καρέ.
anim_frame:
        ld hl,anim_t
        inc (hl)
        ld a,(hl)
        and ANIM_CANE_FRAMES-1
        call z,cane_step
        ld a,(anim_t)
        and ANIM_ROT_FRAMES-1
        ret nz
        ld hl,title_rot      ; ο κύκλος των χρωμάτων: 0-5
        inc (hl)
        ld a,(hl)
        cp 6
        jr c,.rot
        ld (hl),0
.rot    jp title_colours

; -> Z αν η οθόνη είναι του μενού (μενού, κωδικός, πίνακας), όχι του παιχνιδιού
menu_screen:
        ld a,(state)
        cp S_MENU
        ret z
        cp S_SCORES
        ret z
        cp S_CODE
        ret

; Το ζαχαρωτό: ink και paper αλλάζουν θέση.
cane_step:
        call menu_screen
        ld hl,cane_game
        jr nz,.go
        ld hl,cane_menu
.go     ld a,(hl)
        cp #FF
        ret z
        ld b,a
        inc hl
        ld c,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld e,(hl)
        inc hl
        push hl
        call cane_flip
        pop hl
        jr .go

; B, C, D, E: όποιο attribute είναι ζαχαρωτό αλλάζει φάση.
cane_flip:
.row    push bc
        call attr_addr
        ld b,e
.x      ld a,(hl)
        cp A_CANE
        ld c,A_CANE2
        jr z,.put
        cp A_CANE2
        ld c,A_CANE
        jr nz,.next
.put    ld (hl),c
.next   inc l
        djnz .x
        pop bc
        inc b
        dec d
        jr nz,.row
        ret

; γραμμή, στήλη, ύψος, πλάτος
cane_game:
        db HUD_CANE1_ROW,HUD_COL,1,HUD_W
        db HUD_CANE2_ROW,HUD_COL,1,HUD_W
        db HUD_CANE3_ROW,HUD_COL,1,HUD_W
        db #FF
cane_menu:
        db 3,0,20,1
        db 3,31,20,1
        db 23,0,1,32
        db #FF

; Τα χρώματα των γραμμάτων του τίτλου, γυρισμένα κατά τη φάση του κύκλου: στο
; μενού το μεγάλο SUGAR BYTE, στο παιχνίδι το μικρό του HUD.
title_colours:
        call menu_screen
        jr nz,.hud
        ld hl,title_cols
        ld c,0                  ; C = γράμμα
.big    ld a,c
        call title_ink
        or BRIGHT+BLACK*PAPER
        push bc
        push hl
        ld c,(hl)
        ld b,TITLE_ROW
        ld de,#0303
        call fill_attr
        pop hl
        pop bc
        inc hl
        inc c
        ld a,c
        cp TITLE_LETTERS
        jr c,.big
        ret
.hud    ld hl,hud_title_pos
        ld c,0
.small  ld a,c
        call title_ink
        or BRIGHT+BLUE*PAPER
        ld e,a
        ld a,(hl)
        inc hl
        push hl
        push bc
        ld b,a
        ld c,(hl)
        call attr_addr
        ld (hl),e
        pop bc
        pop hl
        inc hl
        inc c
        ld a,c
        cp TITLE_LETTERS
        jr c,.small
        ret

; A = γράμμα 0-8 -> A = το ink του τώρα. Δεν πειράζει BC, HL.
title_ink:
        push hl
        ld hl,title_rot
        add a,(hl)
.mod    cp 6
        jr c,.ok
        sub 6
        jr .mod
.ok     ld hl,title_pal
        add a,l
        ld l,a
        jr nc,.nc
        inc h
.nc     ld a,(hl)
        pop hl
        ret

title_pal:
        db RED,YELLOW,GREEN,CYAN,MAGENTA,WHITE
TITLE_ROW       equ 0
title_cols:                     ; S U G A R _ B Y T E
        db 1,4,7,10,13,19,22,25,28
hud_title_pos:                  ; γραμμή, στήλη: SUGAR / BYTE στο κάτω μέρος του HUD
        db 22,25, 22,26, 22,27, 22,28, 22,29
        db 23,26, 23,27, 23,28, 23,29
