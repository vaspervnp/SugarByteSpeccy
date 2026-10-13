; menu.asm — το μενού, όπως το mockup_menu του CPC
;
; Τίτλος, κολόνες από ζαχαρωτό δεξιά-αριστερά και πόδι (draw_frame), τέσσερα
; πιάτα, ο δείκτης αριστερά από το επιλεγμένο, μια σειρά από candies από κάτω.
;
;   PLAY       η πίστα cur_level από την αρχή
;   LEVEL NN   SPACE: «CODE 0000» — ←→ ψηφίο, ↑↓ τιμή, SPACE δέχεται, BREAK ακυρώνει
;   SOUND ON   SPACE: μουσική ναι/όχι
;   SCORES     οι καλύτεροι πόντοι και τα αστέρια κάθε πίστας

MENU_ITEMS      equ 4
MENU_ROW0       equ 4               ; γραμμή του πρώτου πιάτου
MENU_STEP       equ 4
MENU_TILES      equ 5               ; πιάτο: αριστερό, 3 μέσης, δεξί
MENU_TILE_W     equ 4
MENU_COL        equ 8
MENU_PLATE_W    equ MENU_TILES*MENU_TILE_W
MENU_PTR_COL    equ 3
MENU_CANDY_ROW  equ MENU_ROW0+MENU_ITEMS*MENU_STEP-1
MENU_CREDIT_ROW equ 22
MI_PLAY         equ 0
MI_LEVELS       equ 1
MI_SOUND        equ 2
MI_SCORES       equ 3
A_TITLE         equ BRIGHT+BLACK*PAPER+WHITE

; Η εκκίνηση: όλες οι μεταβλητές (και η μόνιμη πρόοδος) στο μηδέν, και το μενού.
menu_start:
        ld hl,BOARD_PAGE
        ld de,BOARD_PAGE+1
        ld bc,vars_end-BOARD_PAGE-1
        ld (hl),0
        ldir
        xor a
        ld (cur_level),a
        ld (menu_sel),a
        ld (lift),a
        ld hl,best
        ld b,4*MAX_LEVELS&#FF
.best   ld (hl),a
        inc hl
        djnz .best
        assert 4*MAX_LEVELS == 256
        ld (clip_row),a
        ld a,r                  ; ό,τι να 'ναι, αρκεί να μην είναι 0
        or 1
        ld (seed),a
        ld (seed+1),a
        call menu_enter
        ld hl,VOICE_SUGARBYTE
        ld de,VOICE_SUGARBYTE_LEN
        jp say

; Από την αρχή ή από το παιχνίδι (BREAK): ζωγραφίζει όλη την οθόνη του μενού.
menu_enter:
        ld a,S_MENU
        ld (state),a
        xor a
        ld (anim_k),a
        ld a,A_MENU
        call cls
        call draw_frame
        xor a
.plates push af
        call draw_plate
        pop af
        inc a
        cp MENU_ITEMS
        jr c,.plates
        ld c,0                  ; τα έξι χρώματα, πάνω από το πόδι
.candy  push bc
        ld a,c
        add a,a
        add a,a
        add a,5                 ; στήλη 5 + 4 * χρώμα
        ld b,c
        ld c,a
        ld a,b
        ld b,MENU_CANDY_ROW
        call draw_candy_at
        pop bc
        inc c
        ld a,c
        cp 6
        jr c,.candy
        ld a,MENU_CREDIT_ROW    ; οι υπογραφές
        ld (txt_row),a
        ld a,BRIGHT+BLACK*PAPER+CYAN
        ld (text_attr),a
        ld hl,txt_credit
        ld c,(SCR_COLS-CREDIT_LEN)/2
        call draw_text
        jp draw_pointer

txt_credit:
        db "REVIVE8BIT - 2026 - VASPER",0
CREDIT_LEN      equ $-txt_credit-1

; Ο τίτλος (τα γράμματα της γραμματοσειράς x3), οι κολόνες και το πόδι.
draw_frame:
        xor a
        ld (txt_tall),a
        ld hl,title_cols
        ld de,title_gfx
        ld b,TITLE_LETTERS
.title  push bc
        ld c,(hl)
        inc hl
        push hl
        ld b,TITLE_ROW
        ld a,3
        ld (blit_w),a
        ld (blit_h),a
        call blit_bits          ; το DE προχωράει στο επόμενο γράμμα
        pop hl
        pop bc
        djnz .title
        call title_colours
        ld a,A_CANE
        ld (text_attr),a
        ld b,3                  ; οι κολόνες
.post   ld a,b
        ld (txt_row),a
        ld a,CH_CANE
        ld c,0
        call draw_char
        ld a,CH_CANE
        ld c,SCR_COLS-1
        call draw_char
        inc b
        ld a,b
        cp SCR_ROWS-1
        jr c,.post
        ld a,SCR_ROWS-1         ; το πόδι
        ld (txt_row),a
        ld c,0
.foot   ld a,CH_CANE
        call draw_char
        inc c
        ld a,c
        cp SCR_COLS
        jr c,.foot
        ret

; A = επιλογή: το πιάτο της και η ετικέτα της.
draw_plate:
        ld (menu_tmp),a
        call menu_item_row
        ld b,a
        ld c,MENU_COL
        ld a,MENU_TILE_W
        ld (blit_w),a
        ld a,3
        ld (blit_h),a
        ld e,0                  ; E = πλακάκι
.tile   push de
        ld a,e
        ld de,menu_gfx+1*MENU_SZ        ; plate_l
        or a
        jr z,.got
        ld de,menu_gfx+2*MENU_SZ        ; plate_r
        cp MENU_TILES-1
        jr z,.got
        ld de,menu_gfx+0*MENU_SZ        ; plate_m
.got    call blit_chars
        ld a,c
        add a,MENU_TILE_W
        ld c,a
        pop de
        inc e
        ld a,e
        cp MENU_TILES
        jr c,.tile
        ; η ετικέτα, στο κέντρο, σε μαύρο κουτί
        ld a,(menu_tmp)
        call menu_label         ; HL = κείμενο
        push hl
        ld b,0                  ; μήκος
.len    ld a,(hl)
        or a
        jr z,.lend
        inc hl
        inc b
        jr .len
.lend   ld a,MENU_PLATE_W       ; στήλη = MENU_COL + (πλάτος - μήκος) / 2
        sub b
        srl a
        add a,MENU_COL
        ld c,a
        ld a,(menu_tmp)
        call menu_item_row
        inc a
        ld (txt_row),a
        ld a,A_LABEL
        ld (text_attr),a
        xor a
        ld (txt_tall),a
        pop hl
        jp draw_text

; A = επιλογή -> A = η γραμμή του πιάτου της
menu_item_row:
        add a,a
        add a,a
        add a,MENU_ROW0
        ret
        assert MENU_STEP == 4

; A = επιλογή -> HL = η ετικέτα της (στο menu_buf αν αλλάζει)
menu_label:
        or a
        ld hl,txt_play
        ret z
        dec a
        jr z,.levels
        dec a
        jr z,.sound
        ld hl,txt_scores
        ret
.sound  ld hl,txt_sound_on
        ld a,(mus_on)
        or a
        ret nz
        ld hl,txt_sound_off
        ret
.levels ld a,(state)
        cp S_CODE
        jr z,.code
        ld hl,txt_level_nn      ; «LEVEL NN»
        ld de,menu_buf
        ld bc,6
        ldir
        ld a,(cur_level)
        inc a
        call bin2bcd
        call put_bcd_digits
        jr .end
.code   ld hl,txt_code          ; «CODE dddd» — το ψηφίο που αλλάζει αναβοσβήνει
        ld de,menu_buf
        ld bc,5
        ldir
        ld hl,code_dig
        ld b,0
.dig    ld a,(hl)
        add a,"0"
        ld c,a
        ld a,(code_pos)
        cp b
        jr nz,.show
        ld a,(anim_k)
        and 8
        jr z,.show
        ld c," "
.show   ld a,c
        ld (de),a
        inc de
        inc hl
        inc b
        ld a,b
        cp 4
        jr c,.dig
.end    xor a
        ld (de),a
        ld hl,menu_buf
        ret

; A = BCD -> δύο χαρακτήρες στο (DE)
put_bcd_digits:
        push af
        rrca
        rrca
        rrca
        rrca
        and 15
        add a,"0"
        ld (de),a
        inc de
        pop af
        and 15
        add a,"0"
        ld (de),a
        inc de
        ret

txt_play:       db "PLAY",0
txt_level_nn:   db "LEVEL "
txt_code:       db "CODE "
txt_sound_on:   db "SOUND ON",0
txt_sound_off:  db "SOUND OFF",0
txt_scores:     db "SCORES",0

; Ο δείκτης δίπλα στο επιλεγμένο, στη φάση του (οι ρίγες «τρέχουν»).
draw_pointer:
        ld a,(menu_sel)
        call menu_item_row
        ld b,a
        ld c,MENU_PTR_COL
        ld de,menu_gfx+3*MENU_SZ        ; pointer1
        ld a,(anim_k)
        and 8
        jr z,.p1
        ld de,menu_gfx+4*MENU_SZ        ; pointer2
.p1     ld a,MENU_TILE_W
        ld (blit_w),a
        ld a,3
        ld (blit_h),a
        jp blit_chars

; A = επιλογή: σβήνει τον δείκτη της
erase_pointer:
        call menu_item_row
        ld b,a
        ld c,MENU_PTR_COL
        ld de,3*256+MENU_TILE_W
        ld a,A_MENU
        jp fill_rect

st_menu:
        ld hl,anim_k
        inc (hl)
        ld a,(hl)
        and 7
        call z,draw_pointer
        ld a,(joy_edge)         ; το M: και εδώ η μουσική, και το πιάτο της
        and J_MUSIC
        ld a,MI_SOUND
        call nz,draw_plate
        call get_dir
        and J_UP|J_DOWN
        jr z,.fire
        ld b,a
        ld a,(menu_sel)
        push bc
        push af
        call erase_pointer
        pop af
        pop bc
        bit 0,b
        jr z,.down
        dec a
        jp p,.set
        ld a,MENU_ITEMS-1
.down   bit 1,b
        jr z,.set
        inc a
        cp MENU_ITEMS
        jr c,.set
        xor a
.set    ld (menu_sel),a
        call draw_pointer
        ld hl,sfx_select
        call play_sfx
.fire   ld a,(joy_edge)
        and J_FIRE
        ret z
        ld a,(menu_sel)
        or a
        jr nz,.notplay
        ld a,(anim_t)           ; ο χρόνος στο μενού ανακατεύει τον σπόρο
        ld hl,seed
        xor (hl)
        ld (hl),a
        pop hl                  ; PLAY: έξω από το step_state, στο παιχνίδι
        jp game_new
.notplay
        dec a
        jr nz,.notlevels
        jp start_code           ; LEVELS: ο κωδικός
.notlevels
        dec a
        jr nz,scores_enter      ; SCORES
        call toggle_music       ; SOUND
        ld a,MI_SOUND
        jp draw_plate

; ---------------------------------------------------------------------------
; SCORES: σελίδες των 20 πιστών σε δύο στήλες — πίστα, καλύτεροι πόντοι,
; αστέρια. ←→ αλλάζει σελίδα, SPACE / BREAK πίσω στο μενού.
SCORES_ROW0     equ 6
SCORES_PER_PAGE equ 20
SCORES_PAGES    equ floor((NLEVELS+SCORES_PER_PAGE-1)/SCORES_PER_PAGE)   ; το rasm διαιρεί με δεκαδικά
SCORES_COL_A    equ 3
SCORES_COL_B    equ 17
        assert SCORES_PAGES <= 9
scores_enter:
        xor a
        ld (scores_pg),a
        ld a,S_SCORES
        ld (state),a
scores_draw:
        ld bc,3*256+1           ; το εσωτερικό μαύρο
        ld de,20*256+30
        ld a,A_MENU
        call fill_rect
        xor a
        ld (txt_tall),a
        ld hl,txt_scores        ; «SCORES 1/3»
        ld de,menu_buf
        ld bc,6
        ldir
        ex de,hl
        ld (hl),' '
        inc hl
        ld a,(scores_pg)
        add a,'1'
        ld (hl),a
        inc hl
        ld (hl),'/'
        inc hl
        ld (hl),SCORES_PAGES+'0'
        inc hl
        ld (hl),0
        ld a,4
        ld (txt_row),a
        ld a,BRIGHT+BLACK*PAPER+YELLOW
        ld (text_attr),a
        ld hl,menu_buf
        ld c,(SCR_COLS-10)/2
        call draw_text
        ld a,19                 ; πώς φεύγεις
        ld (txt_row),a
        ld a,BRIGHT+BLACK*PAPER+CYAN
        ld (text_attr),a
        ld hl,txt_scores_keys
        ld c,(SCR_COLS-SCORES_KEYS_LEN)/2
        call draw_text
        call .first             ; A = η πρώτη πίστα της σελίδας
.lv     ld (menu_tmp),a
        ld b,a
        call .first
        ld e,a
        ld a,b
        sub e                   ; A = θέση στη σελίδα, 0-19
        ld c,SCORES_COL_A       ; στήλη και γραμμή
        cp 10
        jr c,.col
        sub 10
        ld c,SCORES_COL_B
.col    add a,SCORES_ROW0
        ld (txt_row),a
        ld a,BRIGHT+BLACK*PAPER+WHITE
        ld (text_attr),a
        ld a,(menu_tmp)         ; «NN»
        inc a
        call bin2bcd
        ld (menu_buf),a
        ld hl,menu_buf
        ld b,1
        call draw_bcd
        inc c
        ld a,BRIGHT+BLACK*PAPER+CYAN
        ld (text_attr),a
        ld a,(menu_tmp)         ; οι πόντοι
        add a,a
        add a,a
        ld hl,best
        call add_hl_a
        ld b,3
        call draw_bcd           ; HL μένει στα αστέρια
        inc c
        ld e,(hl)               ; τα αστέρια, μικρά
        ld b,3
.star   ld a,BRIGHT+BLACK*PAPER+YELLOW
        ld (text_attr),a
        ld a,CH_STAR_ON
        dec e
        jp p,.on
        ld a,BRIGHT+BLACK*PAPER+BLUE
        ld (text_attr),a
        ld a,CH_STAR_OFF
.on     call draw_char
        inc c
        djnz .star
        call .first
        add a,SCORES_PER_PAGE-1
        ld b,a
        ld a,(menu_tmp)
        cp b                    ; η τελευταία της σελίδας
        ret z
        inc a
        cp NLEVELS
        jr c,.lv
        ret
.first  ld a,(scores_pg)        ; * 20
        add a,a
        add a,a
        ld e,a
        add a,a
        add a,a
        add a,e
        ret

txt_scores_keys:
        db "<> PAGE   FIRE BACK",0
SCORES_KEYS_LEN equ $-txt_scores_keys-1

st_scores:
        ld a,(joy_edge)
        and J_FIRE|J_ESC
        jp nz,menu_enter
        call get_dir
        ld b,a
        ld a,(scores_pg)
        ld c,a
        bit 2,b                 ; J_LEFT
        jr z,.nleft
        or a
        jr z,.nleft
        dec a
.nleft  bit 3,b                 ; J_RIGHT
        jr z,.nright
        cp SCORES_PAGES-1
        jr nc,.nright
        inc a
.nright cp c
        ret z
        ld (scores_pg),a
        jp scores_draw

; ---------------------------------------------------------------------------
; Στη νίκη: οι πόντοι και τα αστέρια της πίστας, αν είναι οι καλύτεροι ώς τώρα.
record_best:
        ld a,(cur_level)
        add a,a
        add a,a
        ld hl,best
        call add_hl_a
        push hl
        ld de,score             ; BCD, MSB πρώτο: σύγκριση byte-byte
        ld b,3
.cmp    ld a,(de)
        cp (hl)
        jr c,.stars             ; μικρότεροι
        jr nz,.copy             ; μεγαλύτεροι
        inc de
        inc hl
        djnz .cmp
        jr .stars
.copy   pop hl
        push hl
        ld de,score
        ex de,hl
        ld bc,3
        ldir
.stars  pop hl
        inc hl
        inc hl
        inc hl
        ld a,(win_n)
        cp (hl)
        ret c
        ld (hl),a
        ret
