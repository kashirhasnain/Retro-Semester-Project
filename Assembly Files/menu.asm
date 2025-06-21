.include "LAMAlib.inc"
.include "LAMAlib-sprites.inc"
.import source "playerpaddle.prg",$3040  
install_file "cpupaddle.prg",$3080
install_file "ball.prg",$3000 

       
* = $0801
* = $2000
.include game.asm

; BASIC SYS header for RUN/LOAD (SYS2064)
        BYTE $0b, $08, $01, $00, $9e, $20, $32, $30, $36, $34, $00, $00, $00

        * = $0810

start
    jsr clear_screen

menu_loop
    jsr print_menu

wait_key
    jsr get_key
    cmp #'1'
    beq start_game
    cmp #'2'
    beq show_credits
    cmp #'3'
    beq exit_program
    jmp wait_key

start_game
    start_game
    jsr clear_screen
    ; Optional: Print a "starting game" message
    jsr print_game
    jsr wait_for_key
    jsr clear_screen
    jsr $2000        ; Call the game in game.asm at $2000 (MUST end with RTS!)
    jsr clear_screen
    jmp menu_loop    ; Return to menu after game ends


show_credits
    jsr clear_screen
    jsr print_credits
    jsr wait_for_key
    jsr clear_screen
    jmp menu_loop

exit_program
    jsr clear_screen
    jsr print_exit
    rts

; ----- Print Main Menu -----
print_menu
    ldx #0
pm_loop
    lda menu_text,x
    beq pm_done
    jsr $ffd2
    inx
    jmp pm_loop
pm_done
    rts

menu_text
    BYTE 13,13
    BYTE "==============================",13
    BYTE "        WELCOME TO PING PONG GAME",13
    BYTE "==============================",13
    BYTE "  1. Start Game",13
    BYTE "  2. Credits",13
    BYTE "  3. Exit",13
    BYTE "------------------------------",13
    BYTE "Select option (1-3): ",0

; ----- Print Game -----
print_game
    ldx #0
pg_loop
    lda game_text,x
    beq pg_done
    jsr $ffd2
    inx
    jmp pg_loop
pg_done
    rts

game_text

    BYTE 13,13,"*** GAME STARTING... ***",13
    BYTE "(Press any key to return to menu)",13,0

; ----- Print Credits -----
print_credits
    ldx #0
pc_loop
    lda credits_text,x
    beq pc_done
    jsr $ffd2
    inx
    jmp pc_loop
pc_done
    rts

credits_text
    BYTE 13,13,"*** CREDITS ***",13
    BYTE "Developed by Kashir Hasnain",13
    BYTE "Sprites Made by OpenSprites",13
    BYTE "(Press any key to return to menu)",13,0

; ----- Print Exit -----
print_exit
    ldx #0
pe_loop
    lda exit_text,x
    beq pe_done
    jsr $ffd2
    inx
    jmp pe_loop
pe_done
    rts

exit_text
    BYTE 13,13,"Goodbye!",13,0

; ----- Clear Screen -----
clear_screen
    lda #$93
    jsr $ffd2
    rts

; ----- Wait For Any Key -----
wait_for_key
    lda $cb      ; Clear buffer
wfk_wait
    lda $dc01
    cmp #$ff
    beq wfk_wait
wfk_release
    lda $dc01
    cmp #$ff
    bne wfk_release
    rts

; ----- Get Key (ASCII in A) -----
get_key
    lda $cb
gk_wait
    lda $dc01
    cmp #$ff
    beq gk_wait
    ldx $d010
    jsr $ffe4    ; GETIN
    rts
