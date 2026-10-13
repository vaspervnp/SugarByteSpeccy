; gfx.asm — η οθόνη του Spectrum: διευθύνσεις, ρουτίνες blit, κείμενο
;
; Όλα πέφτουν σε όρια χαρακτήρων (8x8): τα candies κινούνται ένα χαρακτήρα τη
; φορά, ώστε κάθε candy να έχει δικά του attributes (planzx.md §4). Το bg_attr
; κρατάει το attribute του φόντου κάθε χαρακτήρα: ένα candy παίρνει από εκεί το
; paper και βάζει το δικό του ink.

; B = γραμμή, C = στήλη χαρακτήρων -> HL = η πρώτη γραμμή pixels του.
; Δεν πειράζει BC, DE.
char_addr:
        ld a,b
        and #18
        or #40
        ld h,a
        ld a,b
        rrca
        rrca
        rrca
        and #E0
        or c
        ld l,a
        ret

; B = γραμμή, C = στήλη -> HL = το attribute του. Δεν πειράζει BC, DE.
attr_addr:
        ld a,b
        rrca
        rrca
        rrca
        ld l,a
        and 3
        or #58
        ld h,a
        ld a,l
        and #E0
        or c
        ld l,a
        ret

; A = κελί -> B = γραμμή, C = στήλη χαρακτήρων της πάνω αριστερής γωνίας
cell_xy:
        ld b,a
        and 7
        ld c,a
        add a,a
        add a,c
        add a,BOARD_COL
        ld c,a
        ld a,b
        rrca
        rrca
        rrca
        and 7
        ld b,a
        add a,a
        add a,b
        add a,BOARD_ROW
        ld b,a
        ret

; HL = πίνακας από words, A = δείκτης -> DE = το word. Δεν πειράζει BC.
ptr_lookup:
        add a,a
        add a,l
        ld l,a
        jr nc,.nc
        inc h
.nc     ld e,(hl)
        inc hl
        ld d,(hl)
        ret

; ---------------------------------------------------------------------------
; A = attribute: σβήνει όλη την οθόνη, και το bg_attr.
cls:
        push af
        ld hl,SCR
        ld de,SCR+1
        ld bc,#1800
        ld (hl),0
        ldir
        pop af
        ld hl,ATTRS
        ld de,ATTRS+1
        ld bc,767
        ld (hl),a
        ldir
        ld hl,BG_ATTR
        ld de,BG_ATTR+1
        ld bc,767
        ld (hl),a
        ldir
        ret

; B = γραμμή, C = στήλη, D = ύψος, E = πλάτος (χαρακτήρες), A = attribute:
; σβήνει τα pixels και βάζει το attribute (και στο bg_attr).
fill_rect:
        push af
        push bc
        push de
.row    push bc
        call char_addr
        ld c,8
.line   push hl
        ld b,e
.x      ld (hl),0
        inc l
        djnz .x
        pop hl
        inc h
        dec c
        jr nz,.line
        pop bc
        inc b
        dec d
        jr nz,.row
        pop de
        pop bc
        pop af
        ; fall through

; B = γραμμή, C = στήλη, D = ύψος, E = πλάτος, A = attribute: μόνο τα
; attributes (και το bg_attr).
fill_attr:
.row    push bc
        push af
        call attr_addr
        pop af
        push af
        ld b,e
.a      ld (hl),a
        ld c,a
        ld a,h
        add a,BG_OFS
        ld h,a
        ld (hl),c
        sub BG_OFS
        ld h,a
        ld a,c
        inc l
        djnz .a
        pop af
        pop bc
        inc b
        dec d
        jr nz,.row
        ret

; B = γραμμή, C = στήλη, DE = πηγή: blit_w bytes ανά γραμμή pixels, blit_h
; γραμμές χαρακτήρων. Αδιαφανές. Το DE μένει μετά την πηγή· BC όπως ήταν.
blit_bits:
        push bc
        ld a,(blit_h)
.row    push af
        push bc
        call char_addr
        ld c,8
.line   push hl
        ld a,(blit_w)
        ld b,a
.byte   ld a,(de)
        ld (hl),a
        inc de
        inc l
        djnz .byte
        pop hl
        inc h
        dec c
        jr nz,.line
        pop bc
        inc b
        pop af
        dec a
        jr nz,.row
        pop bc
        ret

; B, C, DE = blit_w x blit_h attributes: στην οθόνη και στο bg_attr.
put_attrs:
        push bc
        ld a,(blit_h)
.row    push af
        push bc
        call attr_addr
        ld a,(blit_w)
        ld b,a
.a      ld a,(de)
        inc de
        ld (hl),a
        ld c,a
        ld a,h
        add a,BG_OFS
        ld h,a
        ld (hl),c
        sub BG_OFS
        ld h,a
        inc l
        djnz .a
        pop bc
        inc b
        pop af
        dec a
        jr nz,.row
        pop bc
        ret

; B, C, DE, blit_w, blit_h: τα pixels και μετά τα attributes τους.
blit_chars:
        call blit_bits
        jr put_attrs

; DE = πηγή με μάσκα 24x24 (tools/zxgfx.py: 24 γραμμές των 3 ζευγαριών
; μάσκα,δεδομένα, μετά 9 inks), B = γραμμή (με πρόσημο), C = στήλη. Ό,τι είναι
; πάνω από το clip_row κόβεται. Με lift > 0 το candy ανεβαίνει τόσες γραμμές.
; Δεν πειράζει BC.
draw_masked_at:
        ld (ml_src),de
        push bc
        ld a,(lift)             ; η πηγή αρχίζει lift γραμμές πιο κάτω
        ld l,a
        add a,a
        add a,l
        add a,a
        ld l,a
        ld h,0
        add hl,de               ; HL = η πρώτη γραμμή της πηγής
        ld a,(lift)
        neg
        add a,24
        ld (ml_left),a          ; γραμμές που ζωγραφίζονται
        ld a,3
        ld (ml_rows),a
.row    ld a,(clip_row)
        ld e,a
        ld a,b
        sub e
        jp m,.skip
        push bc
        ex de,hl
        call char_addr
        ex de,hl                ; HL = πηγή, DE = οθόνη
        ld c,8
.line   ld a,(ml_left)
        or a
        jr z,.rdone
        dec a
        ld (ml_left),a
        ld a,(de)
        and (hl)                ; μάσκα
        inc hl
        or (hl)                 ; δεδομένα
        inc hl
        ld (de),a
        inc e
        ld a,(de)
        and (hl)
        inc hl
        or (hl)
        inc hl
        ld (de),a
        inc e
        ld a,(de)
        and (hl)
        inc hl
        or (hl)
        inc hl
        ld (de),a
        dec e
        dec e
        inc d
        dec c
        jr nz,.line
.rdone  pop bc
        jr .next
.skip   ld de,48                ; μια γραμμή χαρακτήρων της πηγής
        add hl,de
        ld a,(ml_left)
        sub 8
        jr nc,.sk
        xor a
.sk     ld (ml_left),a
.next   inc b
        ld a,(ml_rows)
        dec a
        ld (ml_rows),a
        jr nz,.row
        pop bc
        ; τα inks: το paper του φόντου (bg_attr) με το ink του καρέ
        push bc
        ld hl,(ml_src)
        ld de,144
        add hl,de
        ex de,hl
        ld a,3
        ld (ml_rows),a
.arow   ld a,(clip_row)
        ld l,a
        ld a,b
        sub l
        jp m,.askip
        push bc
        call attr_addr
        ld c,3
.ai     ld a,(de)
        inc de
        cp #FF
        jr z,.keep
        ld b,a
        ld a,h
        add a,BG_OFS
        ld h,a
        ld a,(hl)
        and #F8
        or b
        ld b,a
        ld a,h
        sub BG_OFS
        ld h,a
        ld (hl),b
.keep   inc l
        dec c
        jr nz,.ai
        pop bc
        jr .anext
.askip  inc de
        inc de
        inc de
.anext  inc b
        ld a,(ml_rows)
        dec a
        ld (ml_rows),a
        jr nz,.arow
        pop bc
        ret

; ---------------------------------------------------------------------------
; Τα κομμάτια ενός κελιού

; A = κελί: το φόντο του (αδιαφανές — σβήνει ό,τι υπήρχε).
draw_bg:
        ld c,a
        push bc
        call cell_frame
        ld hl,cells_ptr
        call ptr_lookup
        pop bc
        ld a,c
        call cell_xy
        ld a,3
        ld (blit_w),a
        ld (blit_h),a
        jp blit_chars

; A = τιμή board[], C = στήλη, B = γραμμή χαρακτήρων (πάνω από το clip_row:
; κόβεται, για τα candies που μπαίνουν). Δεν πειράζει BC.
draw_candy_at:
        call candy_frame
        ret c
        ld hl,candy_ptr
        call ptr_lookup
        jp draw_masked_at

; A = τιμή board[] -> A = καρέ του candy_gfx· carry αν δεν ζωγραφίζεται τίποτα.
candy_frame:
        cp EMPTY
        scf
        ret z
        bit 5,a
        jr nz,.ingredient
        push bc
        ld b,a
        and 7
        cp 6
        jr z,.bomb
        ld c,a                  ; χρώμα
        ld a,b
        rrca
        rrca
        rrca
        and 3                   ; μορφή
        ld b,a
        add a,a
        add a,b
        add a,a                 ; μορφή * 6
        add a,c
        pop bc
        ret
.bomb   pop bc
        ld a,CANDY_BOMB
        or a
        ret
.ingredient
        and 1
        add a,CANDY_INGREDIENT
        ret

; A = κελί: το candy του στη θέση του
draw_candy_cell:
        push af
        call cell_xy
        pop af
        ld l,a
        ld h,board>>8
        ld a,(hl)
        jp draw_candy_at

; A = κελί, D = καρέ επικάλυψης
draw_overlay:
        call cell_xy
        ld a,d
        ld hl,overlay_ptr
        call ptr_lookup
        jp draw_masked_at

; A = κελί: φόντο, candy, και δείκτης ή επιλογή αν είναι εκεί.
draw_cell:
        ld (dc_i),a
        call draw_bg
        ld a,(dc_i)
        call draw_candy_cell
        ld a,(dc_i)
        ld c,a
        ld a,(sel)
        cp c
        ld d,OVERLAY_CURSOR+1   ; η επιλογή: κυανή, σταθερή
        jr z,.over
        ld a,(state)
        cp S_IDLE
        ret nz
        ld a,(cursor)
        cp c
        ret nz
        ld a,(blink_t)
        and 16
        ret nz
        ld d,OVERLAY_CURSOR     ; ο δείκτης: άσπρος, αναβοσβήνει
.over   ld a,c
        jp draw_overlay

; Όλο το ταμπλό — μόνο στην αρχή.
draw_board_all:
        xor a
.l      push af
        call draw_cell
        pop af
        inc a
        cp COLS*ROWS
        jr c,.l
        ret

; ---------------------------------------------------------------------------
; Η λίστα των βρώμικων

; A = κελί: θα ξαναζωγραφιστεί. Δεν πειράζει BC, DE.
mark_dirty:
        push hl
        push af
        or cell&#FF
        ld l,a
        ld h,cell>>8
        bit 7,(hl)
        jr nz,.already
        set 7,(hl)
        ld hl,dq_n
        inc (hl)
        ld a,(dq_tail)
        ld l,a
        inc a
        and 63
        ld (dq_tail),a
        ld a,l
        or dirty_q&#FF
        ld l,a
        ld h,dirty_q>>8
        pop af
        ld (hl),a
        pop hl
        ret
.already
        pop af
        pop hl
        ret

; Ζωγραφίζει ώς DRAW_BUDGET κελιά από τη λίστα.
render_dirty:
        ld b,DRAW_BUDGET
.l      ld a,(dq_n)
        or a
        ret z
        dec a
        ld (dq_n),a
        ld a,(dq_head)
        ld l,a
        inc a
        and 63
        ld (dq_head),a
        ld a,l
        or dirty_q&#FF
        ld l,a
        ld h,dirty_q>>8
        ld a,(hl)
        or cell&#FF
        ld l,a
        res 7,(hl)
        and 63
        push bc
        call draw_cell
        pop bc
        djnz .l
        ret

; Αδειάζει τη λίστα χωρίς να ζωγραφίσει (μετά από ολόκληρο ταμπλό).
clear_dirty:
        xor a
        ld (dq_n),a
        ld (dq_head),a
        ld (dq_tail),a
        ld hl,cell
        ld b,COLS*ROWS
.l      res 7,(hl)
        inc l
        djnz .l
        ret

; ---------------------------------------------------------------------------
; Κείμενο 8x8: η γραμματοσειρά του tools/zxgfx.py, ASCII από το FONT_FIRST.
; Η γραμμή στο txt_row, ψηλά γράμματα (8x16) αν txt_tall, το attribute στο
; text_attr.

; A = χαρακτήρας, C = στήλη. Δεν πειράζει BC, HL.
draw_char:
        push hl
        push de
        push bc
        sub FONT_FIRST
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,font
        add hl,de
        ex de,hl                ; DE = το σχέδιο
        ld a,(txt_row)
        ld b,a
        call char_addr
        ld a,(txt_tall)
        or a
        jr nz,.tall
        ld b,8
.l      ld a,(de)
        ld (hl),a
        inc de
        inc h
        djnz .l
        jr .attr
.tall   call .half              ; κάθε γραμμή δύο φορές, σε δύο γραμμές χαρακτήρων
        ld a,(txt_row)
        inc a
        ld b,a
        call char_addr
        call .half
        ld a,(txt_row)          ; το attribute της δεύτερης
        inc a
        call .put
.attr   ld a,(txt_row)
        call .put
        pop bc
        pop de
        pop hl
        ret
.half   ld b,4
.h      ld a,(de)
        ld (hl),a
        inc h
        ld (hl),a
        inc h
        inc de
        djnz .h
        ret
.put    ld b,a                  ; A = γραμμή, C = στήλη (το C μένει από την είσοδο)
        call attr_addr
        ld a,(text_attr)
        ld (hl),a
        ld b,a
        ld a,h
        add a,BG_OFS
        ld h,a
        ld (hl),b
        ret

; HL = κείμενο με 0 στο τέλος, C = στήλη. Το C μένει μετά τον τελευταίο.
draw_text:
.l      ld a,(hl)
        or a
        ret z
        inc hl
        call draw_char
        inc c
        jr .l

; HL = BCD, B = bytes, C = στήλη. Το C μένει μετά το τελευταίο ψηφίο.
draw_bcd:
.l      ld a,(hl)
        rrca
        rrca
        rrca
        rrca
        and 15
        add a,'0'
        call draw_char
        inc c
        ld a,(hl)
        and 15
        add a,'0'
        call draw_char
        inc c
        inc hl
        djnz .l
        ret

; ---------------------------------------------------------------------------
; Η διεύθυνση κάθε καρέ: <set>_gfx + καρέ * <SET>_SZ
candy_ptr:
        repeat CANDY_N,n
        dw candy_gfx+(n-1)*CANDY_SZ
        rend
cells_ptr:
        repeat CELLS_N,n
        dw cells_gfx+(n-1)*CELLS_SZ
        rend
overlay_ptr:
        repeat OVERLAY_N,n
        dw overlay_gfx+(n-1)*OVERLAY_SZ
        rend
        assert CANDY_N == 27 && CELLS_N == 10 && OVERLAY_N == 14
