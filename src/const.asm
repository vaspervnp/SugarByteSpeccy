; const.asm — σταθερές του παιχνιδιού και ο χάρτης της μνήμης (planzx.md)

; --- η οθόνη του Spectrum: 256x192, 32x24 χαρακτήρες ------------------------
;   στήλες  0..23   το ταμπλό, 8x8 κελιά των 3x3 χαρακτήρων (24x24 pixels)
;   στήλες 24..31   το HUD
SCR             equ #4000
ATTRS           equ #5800
SCR_COLS        equ 32
SCR_ROWS        equ 24

; --- το ταμπλό ---------------------------------------------------------------
BOARD_COL       equ 0           ; πρώτη στήλη χαρακτήρων του ταμπλό
BOARD_ROW       equ 0           ; πρώτη γραμμή χαρακτήρων
CELL_CW         equ 3           ; χαρακτήρες ανά κελί, και οριζόντια και κάθετα
COLS            equ 8
ROWS            equ 8

EMPTY           equ 7           ; board[]: χρώμα 7 = κενό κελί
BOMB            equ 6           ; board[]: χρώμα 6 = βόμβα χρώματος
INGREDIENT      equ #20         ; board[] bit 5: υλικό· bit 0: 0 κεράσι, 1 φουντούκι
G_SCORE         equ 0           ; στόχοι πίστας
G_JELLY         equ 1
G_INGREDIENTS   equ 2
G_BOTH          equ 3
G_ENDLESS       equ #FF         ; χωρίς στόχο (τα tests)
F_STRIPED_H     equ 1<<3        ; board[] bits 3-4: η μορφή
F_STRIPED_V     equ 2<<3
F_WRAPPED       equ 3<<3
MAX_RUNS        equ 24
MAX_LEVELS      equ 64          ; ο πίνακας best[]: 4 bytes η πίστα, offset σε 8 bits

; cell[]: τύπος στα bits 0-2
C_NORMAL        equ 0
C_HOLE          equ 1
C_ICING         equ 2
C_CHOCOLATE     equ 3
C_LICORICE      equ 4
ICING_SHIFT     equ 3
ICING_MASK      equ 3<<ICING_SHIFT
JELLY_SHIFT     equ 5
JELLY_MASK      equ 3<<JELLY_SHIFT

; matched[]: bit 4 = εμπόδιο που παθαίνει ζημιά
M_BLOCKER_BIT   equ 4
M_BLOCKER       equ 1<<M_BLOCKER_BIT
MAX_SPAWN       equ 16
FORM_SHIFT      equ 3           ; board[] bits 3-4: η μορφή του candy

; --- τα χρώματα ----------------------------------------------------------------
BLACK           equ 0
BLUE            equ 1
RED             equ 2
MAGENTA         equ 3
GREEN           equ 4
CYAN            equ 5
YELLOW          equ 6
WHITE           equ 7
PAPER           equ 8           ; PAPER*χρώμα
BRIGHT          equ #40
FLASH           equ #80

A_BOARD         equ BRIGHT+BLUE*PAPER+WHITE     ; το ταμπλό (tools/zxgfx.py)
A_HUD           equ BRIGHT+BLUE*PAPER+WHITE     ; το φόντο του HUD
A_DIGITS        equ BRIGHT+BLACK*PAPER+WHITE    ; τα ψηφία, σε μαύρο κουτί
A_CANE          equ BRIGHT+RED*PAPER+WHITE      ; ζαχαρωτό: άσπρες ρίγες σε κόκκινο
A_MENU          equ BRIGHT+BLACK*PAPER+WHITE    ; το φόντο του μενού
A_LABEL         equ BRIGHT+BLACK*PAPER+WHITE    ; ετικέτα πιάτου
A_BAR           equ BRIGHT+BLACK*PAPER+YELLOW   ; ο σωλήνας προόδου

; --- το HUD (στήλες 24..31) ---------------------------------------------------
HUD_COL         equ 24
HUD_W           equ 8

; τα εικονίδια 16x16 του icons_gfx
ICON_SCORE      equ 0           ; βάζο
ICON_MOVES      equ 1           ; βέλη ανταλλαγής
ICON_TIME       equ 2           ; κλεψύδρα
ICON_GOAL       equ 3           ; γλειφιτζούρι
ICON_JELLY      equ 4
ICON_STAR_ON    equ 5
ICON_STAR_OFF   equ 6
ICON_LOCK       equ 7

; χαρακτήρες της γραμματοσειράς πέρα από το ASCII (tools/zxgfx.py)
CH_TIMES        equ '*'
CH_STAR_ON      equ '['
CH_STAR_OFF     equ 92          ; '\\'
CH_LOCK         equ ']'
CH_CANE         equ '^'
CH_BAR_L        equ '_'
CH_BAR_E        equ '`'
CH_BAR_F        equ '{'
CH_BAR_R        equ '|'

; --- ο χρόνος ----------------------------------------------------------------
DRAW_BUDGET     equ 4           ; βρώμικα κελιά το καρέ
SWAP_FRAMES     equ 6           ; ένας χαρακτήρας κάθε δεύτερο καρέ
FALL_STEPS      equ 3           ; ένα κελί πτώσης σε 3 βήματα του ενός χαρακτήρα
HINT_WAIT       equ 250         ; 5 δευτερόλεπτα αδράνειας: η υπόδειξη
HINT_LIFT       equ 2           ; γραμμές που πηδάνε τα candies της υπόδειξης
REP_FIRST       equ 12          ; repeat του δείκτη: πρώτη επανάληψη
REP_NEXT        equ 3           ; ... και μετά

; --- η είσοδος ---------------------------------------------------------------
J_UP            equ 1
J_DOWN          equ 2
J_LEFT          equ 4
J_RIGHT         equ 8
J_FIRE          equ 16
J_MUSIC         equ 32
J_ESC           equ 64

; --- οι καταστάσεις ---------------------------------------------------------
S_IDLE         equ 0
S_SWAP         equ 1
S_UNSWAP       equ 2
S_CLEAR        equ 3
S_FALL         equ 4
S_OVER         equ 5
S_BEAM         equ 6
S_WIN          equ 7
S_CODE         equ 8
S_MENU         equ 9
S_SCORES       equ 10
S_CRUSH        equ 11
S_SLIDE        equ 12           ; ένα candy γλιστράει διαγώνια
CRUSH_FRAMES   equ 5            ; καρέ ανά κίνηση που γίνεται ριγέ
MAX_BEAMS       equ 16
BIG_CLEAR       equ 24          ; πάνω από τόσα κελιά: σκάσιμο σε 2 φάσεις, όχι 4

; --- η μνήμη (planzx.md §3) ---------------------------------------------------
;   #4000  η οθόνη
;   #5B00  board, matched, cell, dirty_q (μία σελίδα)      } δεν είναι στην
;   #5C00  bg_attr: τα attributes του φόντου, 768 bytes    } κασέτα: τα στήνει
;   #5F00  οι μεταβλητές, η πρόοδος, ο ήχος               } το παιχνίδι
;   #6200  φορτώνεται: γραφικά και πίστες, μετά ο κώδικας, η φωνή, η μουσική
;   #FCFC  JP στη διακοπή, #FD00 ο πίνακας του IM 2, από κάτω η στοίβα
BOARD_PAGE      equ #5B00
BG_ATTR         equ #5C00       ; ίδια θέση με το ATTRS, +#400
BG_OFS          equ (BG_ATTR-ATTRS)>>8
VARS_ORG        equ #5F00
LOAD_BASE       equ #6200
LOAD_CLEAR      equ LOAD_BASE-1
STACK_TOP       equ #0000       ; η πρώτη ώθηση στο #FFFF
IM2_TABLE       equ #FD00
IM2_I           equ IM2_TABLE>>8
IM2_FILL        equ IM2_I-1
IM2_JUMP        equ IM2_FILL*257        ; #FCFC
