.include "LAMAlib.inc"
.include "LAMAlib-sprites.inc"

; Ball Sprite Code
* = $3000
ball_sprite
    BYTE $00,$00,$00,$00,$00,$00,$00,$00
    BYTE $00,$00,$18,$3C,$3C,$3C,$3C,$18
    BYTE $00,$00,$00,$00,$00,$00,$00,$00
    BYTE $00,$00,$00,$00,$00,$00,$00,$00
    BYTE $00,$00,$00,$00,$00,$00,$00,$00
    BYTE $00,$00,$00,$00,$00,$00,$00,$00
    BYTE $00,$00,$00,$00,$00,$00,$00,$00
    BYTE $00,$00,$00
; Player Paddle Sprite Code
* = $3040
playerpaddle_sprite
    BYTE $00,$18,$18,$18,$18,$18,$18,$18
    BYTE $18,$18,$18,$18,$18,$18,$18,$18
    BYTE $18,$18,$18,$18,$18,$18,$18,$00
    BYTE $00,$00,$00,$00,$00,$00,$00,$00
    BYTE $00,$00,$00,$00,$00,$00,$00,$00
    BYTE $00,$00,$00,$00,$00,$00,$00,$00
    BYTE $00,$00,$00,$00,$00,$00,$00,$00
    BYTE $00,$00,$00
; CPU Paddle Sprite Code
* = $3080
cpupaddle_sprite
     BYTE $0F,$FF,$F0,$0F,$FF,$F0,$0F,$FF,$F0
    BYTE $0F,$FF,$F0,$0F,$FF,$F0,$0F,$FF,$F0
    BYTE $0F,$FF,$F0,$0F,$FF,$F0,$0F,$FF,$F0
    BYTE $0F,$FF,$F0,$0F,$FF,$F0,$0F,$FF,$F0
    BYTE $0F,$FF,$F0,$0F,$FF,$F0,$0F,$FF,$F0
    BYTE $0F,$FF,$F0,$0F,$FF,$F0,$0F,$FF,$F0
    BYTE $0F,$FF,$F0

      * = $0801

        BYTE $0b, $08, $01, $00, $9e, $20, $32, $30, $36, $34, $00, $00, $00

; --------------------------
; MENU CODE STARTS AT $0810
; --------------------------
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
    jsr clear_screen
    jsr print_game
    jsr wait_for_key
    jsr clear_screen

    jsr $2000        ; CALL THE GAME CODE AT $2000!
    jsr clear_screen
    jmp menu_loop

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

; =================================================================
;                       GAME CODE STARTS HERE
; =================================================================
        * = $2000

game_start

        SEI
        LDX #$00
        STX $D020       ; Border
        LDA #$0E
        STA $D021       ; Background: Light Blue

        ; Sprite pointers
        LDA #64
        STA $07F8       ; Ball at $3000
        LDA #65
        STA $07F9       ; Player paddle at $3040
        LDA #66
        STA $07FA       ; CPU paddle at $3080

        ; Enable sprites 0–2
        LDA #%00000111
        STA $D015

        ; Sprite colors
        LDA #$02
        STA $D027       ; Ball = red
        LDA #$05
        STA $D028       ; Player = green
        LDA #$07
        STA $D029       ; CPU = yellow

        ; Initial positions

        LDA #100
        STA ball_x
        LDA #80
        STA ball_y

        LDA #80
        STA player_y
        STA cpu_y

mainloop
        JSR read_input
        JSR move_ball
        JSR move_cpu
        JSR draw_sprites
        JSR delay
        JMP mainloop

read_input
        LDA $DC00
        STA joy_state

        LDA joy_state
        AND #%00000010      ; Bit 1 = UP
        BEQ try_up

        LDA joy_state
        AND #%00000100      ; Bit 2 = DOWN
        BEQ try_down

        RTS

try_up
        LDA player_y
        CMP #20
        BEQ skip_up
        DEC player_y
skip_up
        RTS

try_down
        LDA player_y
        CMP #200
        BCS skip_down
        INC player_y
skip_down
        RTS

move_cpu
     INC cpu_counter
    LDA cpu_counter
    AND #%00000001      ; only bit 0, so every other frame
    BNE skip_cpu
    LDA ball_y
    CMP cpu_y
    BEQ skip_cpu
    BCC cpu_up

        ; Move down
 LDA cpu_y
    CLC
    ADC #2
    CMP #200
    BCS skip_cpu
    STA cpu_y
    RTS

cpu_up
         LDA cpu_y
    CMP #20
    BEQ skip_cpu
    DEC cpu_y
skip_cpu
        RTS

move_ball
        LDA ball_dir_x
        CLC
        ADC ball_x
        STA ball_x

        LDA ball_dir_y
        CLC
        ADC ball_y
        STA ball_y

        ; Bounce top/bottom
        LDA ball_y
        CMP #10
        BCC invert_y
        CMP #230
        BCS invert_y
        JMP check_paddles

invert_y
        LDA ball_dir_y
        EOR #$FF
        CLC
        ADC #1
        STA ball_dir_y
        RTS

check_paddles
        ; Player paddle
        LDA ball_x
        CMP #30
        BCC miss_left
        CMP #40
        BCS check_cpu

        LDA ball_y
        SEC
        SBC player_y
        CMP #20
        BCC bounce_x
        RTS

check_cpu
        LDA ball_x
        CMP #210
        BCS miss_right
        CMP #200
        BCC skip_check

        LDA ball_y
        SEC
        SBC cpu_y
        CMP #20
        BCC bounce_x
        RTS

skip_check
        RTS

miss_left
miss_right
        ; Reset ball center
        LDA #100
        STA ball_x
        LDA #80
        STA ball_y

        ; Invert horizontal dir
        LDA ball_dir_x
        EOR #$FF
        CLC
        ADC #1
        STA ball_dir_x
        RTS

bounce_x
        LDA ball_dir_x
        EOR #$FF
        CLC
        ADC #1
        STA ball_dir_x
        RTS

draw_sprites
        LDA ball_x
        STA $D000
        LDA ball_y
        STA $D001

        LDA #24
        STA $D002
        LDA player_y
        STA $D003

        LDA #232
        STA $D004
        LDA cpu_y
        STA $D005
        RTS

delay
        LDX #$FF
delay_outer
        LDY #$40
delay_inner
        DEY
        BNE delay_inner
        DEX
        BNE delay_outer
        RTS

; Variables for Game
ball_x      BYTE 100
ball_y      BYTE 80
player_y    BYTE 80
cpu_y       BYTE 80
cpu_counter BYTE 0
joy_state   BYTE 0
ball_dir_x  BYTE 1
ball_dir_y  BYTE 1

; END OF FILE
