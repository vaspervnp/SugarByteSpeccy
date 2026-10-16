; hud.asm — το HUD στις στήλες 24-31, όπως του CPC σε μισό πλάτος
;
;   γραμμή  0      ζαχαρωτό
;          1-2     βάζο + πόντοι (ψηλά ψηφία)
;          4-5     βέλη + κινήσεις
;           6      λουκέτο + κωδικός της πίστας
;           7      ζαχαρωτό
;         8-13     οι στόχοι: εικονίδιο ή candy, «× NN» (ή οι πόντοι-στόχος)
;          14      EASY / MEDIUM / HARD
;          15      LEVEL NN
;          16      ζαχαρωτό
;         17-18    τα τρία αστέρια
;          20      ο σωλήνας προόδου
;         22-23    SUGAR / BYTE, σε χρώματα που αλλάζουν (anim.asm)

HUD_CANE1_ROW   equ 0
HUD_SCORE_ROW   equ 1
HUD_MOVES_ROW   equ 4
HUD_CODE_ROW    equ 6
HUD_CANE2_ROW   equ 7
HUD_GOAL_ROW    equ 8
HUD_GOAL_DY     equ 3
HUD_MODE_ROW    equ 14
HUD_LEVEL_ROW   equ 15
HUD_CANE3_ROW   equ 16
HUD_STARS_ROW   equ 17
HUD_BAR_ROW     equ 20
HUD_BAR_SEG     equ 6           ; κομμάτια του σωλήνα ανάμεσα στα καπάκια
HUD_NUM_COL     equ HUD_COL+2
A_LOCK          equ BRIGHT+BLUE*PAPER+YELLOW
A_HUD_TEXT      equ BRIGHT+BLUE*PAPER+YELLOW

; A = εικονίδιο (ICON_*), B = γραμμή, C = στήλη: 16x16. Δεν πειράζει BC.
draw_icon:
        ld l,a                  ; * 36
        ld h,0
        add hl,hl
        add hl,hl
        ld d,h
        ld e,l
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,de
        ld de,icons_gfx
        add hl,de
        ex de,hl
        ld a,2
        ld (blit_w),a
        ld (blit_h),a
        jp blit_chars

; A = γραμμή: ζαχαρωτό σε όλο το πλάτος του HUD.
hud_cane:
        ld (txt_row),a
        ld a,A_CANE
        ld (text_attr),a
        ld c,HUD_COL
.l      ld a,CH_CANE
        call draw_char
        inc c
        ld a,c
        cp HUD_COL+HUD_W
        jr c,.l
        ret

; ---------------------------------------------------------------------------
; Το HUD, μία φορά στην αρχή της πίστας.
hud_init:
        xor a
        ld (txt_tall),a
        ld bc,BOARD_ROW*256+HUD_COL
        ld de,SCR_ROWS*256+HUD_W
        ld a,A_HUD
        call fill_rect
        ld a,HUD_CANE1_ROW
        call hud_cane
        ld a,HUD_CANE2_ROW
        call hud_cane
        ld a,HUD_CANE3_ROW
        call hud_cane
        ld a,ICON_SCORE
        ld bc,HUD_SCORE_ROW*256+HUD_COL
        call draw_icon
        ld a,ICON_MOVES
        ld bc,HUD_MOVES_ROW*256+HUD_COL
        call draw_icon
        ld a,HUD_BAR_ROW        ; τα καπάκια του σωλήνα
        ld (txt_row),a
        ld a,A_BAR
        ld (text_attr),a
        ld a,CH_BAR_L
        ld c,HUD_COL
        call draw_char
        ld a,CH_BAR_R
        ld c,HUD_COL+HUD_W-1
        call draw_char
        ld hl,txt_sugar         ; SUGAR / BYTE: τα χρώματα τα δίνει το anim.asm
        ld a,22
        ld (txt_row),a
        ld a,A_HUD
        ld (text_attr),a
        ld c,HUD_COL+1
        call draw_text
        ld hl,txt_byte
        ld a,23
        ld (txt_row),a
        ld c,HUD_COL+2
        call draw_text
        call title_colours
        ld a,(cur_level)
        call hud_show_code
        call hud_goals_init
        ld a,1
        ld (hud_dirty),a
        ; fall through

; Ό,τι αλλάζει — μόνο όταν άλλαξε.
hud_update:
        ld a,(hud_dirty)
        or a
        ret z
        xor a
        ld (hud_dirty),a
        ld a,1
        ld (txt_tall),a
        ld a,A_DIGITS
        ld (text_attr),a
        ld a,HUD_SCORE_ROW
        ld (txt_row),a
        ld hl,score
        ld b,3
        ld c,HUD_NUM_COL
        call draw_bcd
        ld a,HUD_MOVES_ROW
        ld (txt_row),a
        ld hl,moves
        ld b,1
        ld c,HUD_NUM_COL
        call draw_bcd
        call hud_goals_update
        xor a
        ld (txt_tall),a
        call hud_stars
        jp hud_bar

txt_sugar:      db "SUGAR",0
txt_byte:       db "BYTE",0

; Τα τρία αστέρια: γεμάτα όσα κερδήθηκαν ώς τώρα.
hud_stars:
        call stars_now
        ld e,a
        ld c,HUD_COL
        ld b,3
.l      push bc
        ld a,ICON_STAR_ON
        dec e
        jp p,.on
        ld a,ICON_STAR_OFF
.on     ld b,HUD_STARS_ROW
        push de
        call draw_icon
        pop de
        pop bc
        inc c
        inc c
        inc c
        djnz .l
        ret

; Ο σωλήνας προόδου: γεμάτος ώς τους πόντους των 3 αστεριών.
hud_bar:
        call progress
        ld e,a
        ld a,HUD_BAR_ROW
        ld (txt_row),a
        ld a,A_BAR
        ld (text_attr),a
        ld c,HUD_COL+1
        ld b,HUD_BAR_SEG
.l      ld a,CH_BAR_F           ; γεμάτο
        dec e
        jp p,.full
        ld a,CH_BAR_E           ; άδειο
.full   call draw_char
        inc c
        djnz .l
        ret

; -> A = κομμάτια του σωλήνα (0..6): πόντοι * 6 / πόντοι 3 αστεριών.
progress:
        ld hl,score             ; πόντοι / 100, δυαδικά
        call bcd4_bin
        push hl
        ld hl,lv_star3
        call bcd4_bin
        ex de,hl                ; DE = όριο 3 αστεριών
        pop hl                  ; HL = πόντοι
        or a
        sbc hl,de
        ld a,HUD_BAR_SEG
        ret nc                  ; έφτασε: γεμάτος
        add hl,de
        ld b,h                  ; HL = πόντοι * 6
        ld c,l
        add hl,hl
        add hl,bc
        add hl,hl
        ld b,h
        ld c,l                  ; BC = πόντοι * 6
        ld hl,0
        xor a
.l      add hl,de               ; κάθε κομμάτι = ένα ακόμα όριο/6
        push hl
        or a
        sbc hl,bc
        pop hl
        ret nc
        inc a
        jr .l
        assert HUD_BAR_SEG == 6

; HL = 2 bytes BCD (MSB πρώτο) -> HL = δυαδικό 0..9999
bcd4_bin:
        ld a,(hl)
        inc hl
        push hl
        call bcd2bin
        ld l,a                  ; * 100 = * 64 + * 32 + * 4
        ld h,0
        add hl,hl
        add hl,hl
        ld d,h
        ld e,l                  ; DE = * 4
        add hl,hl
        add hl,hl
        add hl,hl
        push hl                 ; * 32
        add hl,hl               ; * 64
        add hl,de
        pop de
        add hl,de
        ex de,hl
        pop hl
        ld a,(hl)
        call bcd2bin
        ld l,a
        ld h,0
        add hl,de
        ret

; ---------------------------------------------------------------------------
; Οι στόχοι της πίστας: ένα εικονίδιο ή candy και «× NN» ή ο στόχος πόντων.
; Κάτω τους, «LEVEL NN».
hud_goals_init:
        ld a,(lv_goal)
        or a
        jr nz,.notscore
        ld a,ICON_SCORE         ; πόντοι: το βάζο και ο στόχος «NNNN00»
        ld bc,HUD_GOAL_ROW*256+HUD_COL
        call draw_icon
        ld a,HUD_GOAL_ROW
        ld (txt_row),a
        ld a,1
        ld (txt_tall),a
        ld a,A_DIGITS
        ld (text_attr),a
        ld hl,lv_star1
        ld b,2
        ld c,HUD_NUM_COL
        call draw_bcd
        ld a,'0'
        call draw_char
        inc c
        ld a,'0'
        call draw_char
        xor a
        ld (txt_tall),a
        jr .level
.notscore
        cp G_ENDLESS
        jr z,.level
        cp G_INGREDIENTS
        jr z,.ingr
        ld a,ICON_JELLY         ; ζελέ
        ld bc,HUD_GOAL_ROW*256+HUD_COL
        call draw_icon
        ld a,HUD_GOAL_ROW
        call hud_times
        ld a,(lv_goal)
        cp G_BOTH
        jr nz,.level
        ld a,HUD_GOAL_ROW+HUD_GOAL_DY
        jr .cherry
.ingr   ld a,HUD_GOAL_ROW
.cherry push af                 ; υλικά: ένα κεράσι
        ld b,a
        ld c,HUD_COL
        ld a,INGREDIENT
        call draw_candy_at
        pop af
        call hud_times
.level  ld a,HUD_MODE_ROW       ; η δυσκολία, στο κέντρο
        ld (txt_row),a
        ld a,A_HUD
        ld (text_attr),a
        ld a,(difficulty)
        ld hl,hud_mode_col
        call add_hl_a
        ld c,(hl)
        ld a,(difficulty)
        ld hl,txt_modes
        call ptr_de_hl
        call draw_text
        ld a,HUD_LEVEL_ROW      ; LEVEL NN
        ld (txt_row),a
        ld a,A_HUD_TEXT
        ld (text_attr),a
        ld hl,txt_level
        ld c,HUD_COL
        call draw_text
        inc c
        ld a,A_DIGITS
        ld (text_attr),a
        ld a,(cur_level)
        inc a
        call bin2bcd
        ld (lv_number),a
        ld hl,lv_number
        ld b,1
        jp draw_bcd

txt_level:
        db "LEVEL",0
hud_mode_col:                   ; EASY, MEDIUM, HARD στο κέντρο των 8 στηλών
        db HUD_COL+2,HUD_COL+1,HUD_COL+2

; A = γραμμή: «×» δίπλα στο εικονίδιο στόχου
hud_times:
        ld (txt_row),a
        ld a,A_HUD
        ld (text_attr),a
        ld a,1
        ld (txt_tall),a
        ld a,CH_TIMES
        ld c,HUD_COL+4
        call draw_char
        xor a
        ld (txt_tall),a
        ret

; Οι αριθμοί των στόχων (ψηλά ψηφία· το txt_tall και το text_attr τα στήνει
; το hud_update).
hud_goals_update:
        ld a,(lv_goal)
        or a
        ret z
        cp G_ENDLESS
        ret z
        cp G_INGREDIENTS
        jr z,.ingr
        call count_jelly        ; ζελέ που μένουν
        call bin2bcd
        ld (lv_number),a
        ld a,HUD_GOAL_ROW
        ld (txt_row),a
        ld hl,lv_number
        ld b,1
        ld c,HUD_COL+5
        call draw_bcd
        ld a,(lv_goal)
        cp G_BOTH
        ret nz
        ld a,HUD_GOAL_ROW+HUD_GOAL_DY
        jr .ingr2
.ingr   ld a,HUD_GOAL_ROW
.ingr2  ld (txt_row),a
        ld hl,ingr_left
        ld b,1
        ld c,HUD_COL+5
        jp draw_bcd
