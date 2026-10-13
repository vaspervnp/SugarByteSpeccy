; vars.asm — η κατάσταση του παιχνιδιού (δεν είναι στην κασέτα)
;
; Οι τέσσερις πίνακες των 64 κάθονται στη μία σελίδα των 256, ώστε ο δείκτης κελιού
; να είναι κατευθείαν το L: board = σελίδα+i, matched = board | #40,
; cell = board | #80, dirty_q = board | #C0.

        org BOARD_PAGE
        nocode
board           defs 64         ; τι κάθεται στο κελί
matched         defs 64         ; σκάει: bit 0 γραμμή, 1 κολόνα, 2 «δεσμευμένο»,
                                ; 3 το χτύπησε ειδικό, 4 εμπόδιο με ζημιά,
                                ; 7 έχει ήδη πυροδοτηθεί
cell            defs 64         ; τι είναι το κελί· bit 7 = βρώμικο
dirty_q         defs 64         ; δακτύλιος με τα βρώμικα κελιά

        org VARS_ORG
vars_start
dq_head         defs 1
dq_tail         defs 1
dq_n            defs 1
joy             defs 1          ; J_* που κρατιούνται τώρα
joy_prev        defs 1
joy_edge        defs 1          ; J_* που πατήθηκαν μόλις
rep_cnt         defs 1
state           defs 1
anim_k          defs 1          ; καρέ μέσα στο animation της κατάστασης
cursor          defs 1          ; κελί του δείκτη
sel             defs 1          ; επιλεγμένο κελί, #FF = κανένα
swap_a          defs 1
swap_b          defs 1
chain           defs 1          ; πολλαπλασιαστής αλυσίδας
nmatch          defs 1          ; σειρές που βρήκε το find_matches
moves           defs 1          ; BCD
score           defs 3          ; BCD, το πιο σημαντικό byte πρώτο
hud_dirty       defs 1
blink_t         defs 1
ncolours        defs 1
gap             defs COLS       ; ανά κολόνα: το χαμηλότερο κενό, #FF = κανένα
nextc           defs COLS       ; ανά κολόνα: το candy που μπαίνει από πάνω
segtop          defs COLS       ; ανά κολόνα: πρώτη γραμμή του τμήματος που πέφτει
spawn           defs COLS       ; ανά κολόνα: 1 = το τμήμα γεμίζει από πάνω
clip_row        defs 1          ; γραμμή χαρακτήρων: πάνω της τα candies κόβονται
fall_c0         defs 1
nb              defs 4          ; οι γείτονες ενός κελιού
choc_broken     defs 1          ; έσπασε σοκολάτα σε αυτή την κίνηση
ingr_left       defs 1          ; BCD: υλικά που μένουν να κατέβουν
ingr_spawn      defs 1          ; υλικά που μένουν να μπουν από την κορυφή
ingr_board      defs 1          ; υλικά στο ταμπλό τώρα
ingr_odds       defs 1          ; μάσκα: 7 = μία φορά στις 8
scan_bit        defs 1          ; 1 = σάρωση γραμμών, 2 = κολονών
nruns           defs 1
runs            defs 3*MAX_RUNS ; πρώτο κελί, μήκος, βήμα
nspawn          defs 1
spawns          defs 2*MAX_SPAWN ; κελί, τιμή board[] του ειδικού που γεννιέται
sp_changed      defs 1
nbeams          defs 1
beams           defs MAX_BEAMS  ; γραμμή 0-7, ή κολόνα | #80
clear_n         defs 1          ; πόσα κελιά σκάνε
beam_fr         defs 1
beam_step       defs 1
lv_goal         defs 1          ; η κεφαλίδα της πίστας (tools/levels.py)
lv_star1        defs 2
lv_moves        defs 1
lv_colours      defs 1
lv_ingr         defs 1
lv_star2        defs 2
lv_star3        defs 2
lv_number       defs 1
win_n           defs 1
code_dig        defs 4          ; ο κωδικός που γράφεται, ένα ψηφίο το byte
code_pos        defs 1
menu_tmp        defs 1
scores_pg       defs 1          ; η σελίδα του SCORES
menu_buf        defs 12         ; η ετικέτα ενός πιάτου που αλλάζει
boom            defs 1          ; έσκασε περιτύλιγμα σε αυτό το RESOLVE
dc_i            defs 1          ; προσωρινά των ρουτινών σχεδίασης
pop_ph          defs 1
fall_y          defs 1
hint_t          defs 1          ; καρέ αδράνειας στο IDLE, ώς HINT_WAIT
hint_ph         defs 1          ; η φάση του κουνήματος
hint_on         defs 1          ; 1 = τα candies της υπόδειξης είναι ανασηκωμένα
hint_a          defs 1          ; η κίνηση που δείχνει
hint_b          defs 1
slide_s         defs 1          ; το διαγώνιο γλίστρημα: από ...
slide_t         defs 1          ; ... προς
lift            defs 1          ; γραμμές που ανασηκώνεται το candy (η υπόδειξη)
vars_end

; Έξω από τα vars_start..vars_end: το game_new δεν τα μηδενίζει.
seed            defs 2
cur_level       defs 1          ; η πίστα, από 0
menu_sel        defs 1          ; η επιλογή του μενού
keymap          defs 8          ; οι 8 μισές γραμμές του πληκτρολογίου (1 = πατημένο)
kempston_on     defs 1
text_attr       defs 1          ; το attribute που παίρνουν τα γράμματα
txt_row         defs 1          ; η γραμμή χαρακτήρων του κειμένου
txt_tall        defs 1          ; 1 = γράμματα 8x16
ml_left         defs 1          ; προσωρινά του draw_masked_at
ml_rows         defs 1
ml_src          defs 2
blit_w          defs 1          ; προσωρινά του blit_chars
blit_h          defs 1
anim_t          defs 1          ; καρέ, για τα χρώματα του τίτλου και τις ρίγες
title_rot       defs 1          ; ο κύκλος των χρωμάτων του τίτλου, 0-5
border_col      defs 1          ; το χρώμα του περιθωρίου (και το byte του #FE)
best            defs 4*MAX_LEVELS      ; ανά πίστα: πόντοι BCD (3), αστέρια (1)

; Ο ήχος: η διακοπή τα πειράζει.
snd_start
frame_count     defs 1          ; +1 σε κάθε διακοπή
ay_present      defs 1          ; 1 = 128K: ο AY
snd_clear                       ; από εδώ τα μηδενίζει το snd_init
psg_shadow      defs 11         ; οι καταχωρητές 0-10 του AY
speaking        defs 1          ; 1 = το say κρατάει τον ήχο
mus_on          defs 1
mus_ptr         defs 2
mus_wait        defs 1
sfx_ptr         defs 2          ; 0 = σιωπή
sfx_pop         defs 1          ; καρέ που μένουν από το ποπ, 0 = άλλο εφέ
pop_per         defs 2
noise_seed      defs 2          ; ο θόρυβος του beeper
snd_end
        code
