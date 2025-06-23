;****************************************************
;* Ping Pong Game
;*
;* Player 1 vs Player 2 (Two Players)
;* Player 1: Joystick Port 2, Player 2: Joystick Port 1
;* Code based on Hunted Duck framework
;*
;* Build with: ass pingpong.s
;****************************************************

.include "LAMAlib.inc"
.include "LAMAlib-sprites.inc"

SCREEN_BASE = $400
MUSIC_BASE  = $C000
SPRITE_BASE = $3000

; Game constants
PADDLE_SPEED = 3
BALL_SPEED = 1
SCREEN_TOP = 80
SCREEN_BOTTOM = 180
SCREEN_LEFT = 80
SCREEN_RIGHT = 200
PADDLE_HEIGHT = 40
WINNING_SCORE = 5

install_file "playerpaddle.prg",SPRITE_BASE
install_file "cpupaddle.prg",SPRITE_BASE+$40
install_file "ball.prg",SPRITE_BASE+$80
install_file "pingpongmusic.prg",MUSIC_BASE

        lda #0          ;select first tune
        jsr MUSIC_BASE  ;initialize music with tune in A
        clrscr

        ; Show starting menu first
        jsr showStartMenu
        jsr waitForStart

;****************************************************
;* Initialize sprites
;****************************************************

initializeGame:

        setSpriteMultiColor1 1  ; White
        setSpriteMultiColor2 0  ; Black

        ; Player 1 paddle (sprite 0) - left side
        setSpriteCostume 0,SPRITE_BASE
        setSpriteXY 0,90,130
        updateSpriteAttributes 0
        showSprite 0

        ; Player 2 paddle (sprite 1) - right side  
        setSpriteCostume 1,SPRITE_BASE
        setSpriteXY 1,190,130
        updateSpriteAttributes 1
        showSprite 1

        ; Ball (sprite 2) - center
        setSpriteCostume 2,SPRITE_BASE+$40
        setSpriteXY 2,140,130
        updateSpriteAttributes 2
        showSprite 2

        ; Initialize game variables
        lda #BALL_SPEED
        sta ballDX
        lda #1
        sta ballDY
        
        lda #0
        sta player1Score
        sta player2Score

        ; Draw game field
        jsr drawField
        jsr updateScore

        set_raster_irq 50,isr

;****************************************************
;* Main game loop
;****************************************************

MainLoop:
        sync_to_rasterline256
        
        jsr player1Control      ; Handle player 1 input (joystick 2)
        jsr player2Control      ; Handle player 2 input (joystick 1)
        jsr moveBall           ; Update ball position
        jsr checkCollisions   ; Check all collisions
        jsr checkScore        ; Check if point scored
        
        jmp MainLoop

;****************************************************
;* Player 1 control (Joystick Port 2)
;****************************************************

player1Control:
        lda $dc00       ; Read joystick port 2
        sta joyvalue1
        
        lsr joyvalue1   ; Bit 0 (up)
        if cc
            lda $d001   ; Get current Y position
            sec
            sbc #PADDLE_SPEED
            cmp #SCREEN_TOP
            if cs
                sta $d001   ; Update player 1 paddle Y
            endif
        endif

        lsr joyvalue1   ; Bit 1 (down)
        if cc
            lda $d001   ; Get current Y position
            clc
            adc #PADDLE_SPEED
            cmp #SCREEN_BOTTOM-PADDLE_HEIGHT
            if cc
                sta $d001   ; Update player 1 paddle Y
            endif
        endif
        rts

;****************************************************
;* Check for winner (first to 5 points)
;****************************************************

checkWinner:
        ; Check if Player 1 won
        lda player1Score
        cmp #WINNING_SCORE
        if eq
            jsr displayPlayer1Win
            jsr gameOverLoop
        endif

        ; Check if Player 2 won  
        lda player2Score
        cmp #WINNING_SCORE
        if eq
            jsr displayPlayer2Win
            jsr gameOverLoop
        endif
        rts

;****************************************************
;* Display Player 1 Win message
;****************************************************

displayPlayer1Win:
        ; Clear background and center area first
        jsr clearBackground
        ; Display win message
        ldx #0
winMsg1Loop:
        lda player1WinText,x
        if eq
            rts
        endif
        sta SCREEN_BASE + 10*40 + 12,x
        inx
        jmp winMsg1Loop

;****************************************************
;* Display Player 2 Win message  
;****************************************************

displayPlayer2Win:
        ; Clear background and center area first  
        jsr clearBackground
        ; Display win message
        ldx #0
winMsg2Loop:
        lda player2WinText,x
        if eq
            rts
        endif
        sta SCREEN_BASE + 10*40 + 12,x
        inx
        jmp winMsg2Loop

;****************************************************
;* Clear background screen
;****************************************************

clearBackground:
        ; Clear entire screen
        ldx #0
        lda #32         ; Space character (screen code)
clearScreenLoop:
        sta SCREEN_BASE,x
        sta SCREEN_BASE+256,x
        sta SCREEN_BASE+512,x
        sta SCREEN_BASE+768,x
        inx
        bne clearScreenLoop
        rts

;****************************************************
;* Game Over Loop - wait for fire button to restart
;****************************************************

gameOverLoop:
        ; Hide ball sprite
        hideSprite 2
        
        ; Flash the winning message
        lda #60
        sta flashCounter
        
gameOverWait:
        sync_to_rasterline256
        
        ; Flash effect
        dec flashCounter
        if eq
            lda #60
            sta flashCounter
            lda $d021       ; Background color
            eor #$01        ; Toggle bit 0
            sta $d021
        endif
        
        ; Check for fire button on either joystick to restart
        lda $dc00       ; Player 1 joystick
        and #$10        ; Fire button
        if eq
            jmp restartGame
        endif
        
        lda $dc01       ; Player 2 joystick  
        and #$10        ; Fire button
        if eq
            jmp restartGame
        endif
        
        jmp gameOverWait

;****************************************************
;* Restart the game
;****************************************************

restartGame:
        ; Reset scores
        lda #0
        sta player1Score
        sta player2Score
        
        ; Reset background color
        lda #6          ; Blue background
        sta $d021
        
        ; Go back to start menu instead of directly restarting
        jsr showStartMenu
        jmp waitForStart

;****************************************************
;* Show starting menu
;****************************************************

showStartMenu:
        ; Clear screen first
        jsr clearBackground
        
        ; Display game title "PING PONG"
        ldx #0
titleLoop:
        lda gameTitle,x
        if eq
            ; Title done, now show controls
            jsr showControls
            rts
        endif
        sta SCREEN_BASE + 5*40 + 15,x   ; Row 5, column 15
        inx
        jmp titleLoop

;****************************************************
;* Show control instructions
;****************************************************

showControls:
        ; Show player 1 controls
        ldx #0
controls1Loop:
        lda player1Controls,x
        if eq
            ; P1 controls done, show P2 controls
            ldx #0
controls2Loop:
            lda player2Controls,x
            if eq
                rts
            endif
            sta SCREEN_BASE + 15*40 + 5,x   ; Row 15, column 5
            inx
            jmp controls2Loop
        endif
        sta SCREEN_BASE + 13*40 + 5,x   ; Row 13, column 5
        inx
        jmp controls1Loop

;****************************************************
;* Wait for space key to start game
;****************************************************

waitForStart:
        lda #0
        sta flashTimer
        
startMenuLoop:
        sync_to_rasterline256
        
        ; Handle flashing "Press space to start"
        inc flashTimer
        lda flashTimer
        cmp #30         ; Flash every 30 frames (half second)
        if cs
            lda #0
            sta flashTimer
            lda flashState
            eor #1
            sta flashState
            
            if eq
                ; Hide message
                jsr hideStartMessage
            else
                ; Show message
                jsr showStartMessage
            endif
        endif
        
        ; Check for space key
        lda $dc01       ; Read keyboard
        and #$10        ; Space key is bit 4
        if eq
            ; Space pressed, start game
            jsr clearBackground
            jmp initializeGame
        endif
        
        jmp startMenuLoop

;****************************************************
;* Show "Press space to start" message
;****************************************************

showStartMessage:
        ldx #0
startMsgLoop:
        lda startMessage,x
        if eq
            rts
        endif
        sta SCREEN_BASE + 18*40 + 8,x   ; Row 18, column 8
        inx
        jmp startMsgLoop

;****************************************************
;* Hide "Press space to start" message
;****************************************************

hideStartMessage:
        ldx #0
hideMsgLoop:
        lda startMessage,x
        if eq
            rts
        endif
        lda #32         ; Space character
        sta SCREEN_BASE + 18*40 + 8,x   ; Row 18, column 8
        inx
        jmp hideMsgLoop

;****************************************************
;* Player 2 control (Joystick Port 1)
;****************************************************

player2Control:
        lda $dc01       ; Read joystick port 1
        sta joyvalue2
        
        lsr joyvalue2   ; Bit 0 (up)
        if cc
            lda $d003   ; Get current Y position of player 2 paddle
            sec
            sbc #PADDLE_SPEED
            cmp #SCREEN_TOP
            if cs
                sta $d003   ; Update player 2 paddle Y
            endif
        endif

        lsr joyvalue2   ; Bit 1 (down)
        if cc
            lda $d003   ; Get current Y position of player 2 paddle
            clc
            adc #PADDLE_SPEED
            cmp #SCREEN_BOTTOM-PADDLE_HEIGHT
            if cc
                sta $d003   ; Update player 2 paddle Y
            endif
        endif
        rts

;****************************************************
;* Ball movement
;****************************************************

moveBall:
        ; Move ball horizontally
        lda $d004       ; Ball X position
        clc
        adc ballDX
        sta $d004

        ; Move ball vertically
        lda $d005       ; Ball Y position
        clc
        adc ballDY
        sta $d005

        ; Check top/bottom boundaries
        lda $d005
        cmp #SCREEN_TOP
        if cc
            lda #SCREEN_TOP
            sta $d005
            ; Reverse Y direction
            lda ballDY
            eor #$FF
            clc
            adc #1
            sta ballDY
        endif

        lda $d005
        cmp #SCREEN_BOTTOM-8
        if cs
            lda #SCREEN_BOTTOM-8
            sta $d005
            ; Reverse Y direction
            lda ballDY
            eor #$FF
            clc
            adc #1
            sta ballDY
        endif
        rts

;****************************************************
;* Collision detection
;****************************************************

checkCollisions:
        lda $D01E       ; Read sprite-sprite collision register
        sta collisionTemp ; Store the collision register value
        
        ; Check ball vs player 1 paddle (sprites 0 and 2)
        ; Sprite 0 = bit 0, Sprite 2 = bit 2, so collision = bit 0 AND bit 2 set
        lda collisionTemp
        and #%00000001  ; Check if sprite 0 is involved
        if ne
            lda collisionTemp
            and #%00000100  ; Check if sprite 2 is also involved
            if ne
                ; Ball hit player 1 paddle
                lda ballDX
                if mi           ; Ball moving left
                    lda #BALL_SPEED
                    sta ballDX  ; Reverse to right
                    ; Add some angle based on paddle hit position
                    jsr calculateBounceAngleP1
                endif
            endif
        endif

        ; Check ball vs player 2 paddle (sprites 1 and 2)  
        ; Sprite 1 = bit 1, Sprite 2 = bit 2, so collision = bit 1 AND bit 2 set
        lda collisionTemp
        and #%00000010  ; Check if sprite 1 is involved
        if ne
            lda collisionTemp
            and #%00000100  ; Check if sprite 2 is also involved
            if ne
                ; Ball hit player 2 paddle
                lda ballDX
                if pl           ; Ball moving right
                    lda #$FF-BALL_SPEED+1  ; Negative speed (moving left)
                    sta ballDX
                    ; Add some angle based on paddle hit position
                    jsr calculateBounceAngleP2
                endif
            endif
        endif
        rts

;****************************************************
;* Calculate bounce angle for Player 1 paddle
;****************************************************

calculateBounceAngleP1:
        ; Simple angle calculation based on where ball hits paddle
        lda $d005       ; Ball Y
        sec
        sbc $d001       ; Subtract Player 1 paddle Y
        cmp #15
        if cc
            lda #$FF       ; Hit top of paddle - ball goes up
            sta ballDY
        else
            cmp #25
            if cc
                lda #0     ; Hit middle - ball goes straight
                sta ballDY
            else
                lda #1     ; Hit bottom - ball goes down
                sta ballDY
            endif
        endif
        rts

;****************************************************
;* Calculate bounce angle for Player 2 paddle
;****************************************************

calculateBounceAngleP2:
        ; Simple angle calculation based on where ball hits paddle
        lda $d005       ; Ball Y
        sec
        sbc $d003       ; Subtract Player 2 paddle Y
        cmp #15
        if cc
            lda #$FF       ; Hit top of paddle - ball goes up
            sta ballDY
        else
            cmp #25
            if cc
                lda #0     ; Hit middle - ball goes straight
                sta ballDY
            else
                lda #1     ; Hit bottom - ball goes down
                sta ballDY
            endif
        endif
        rts

;****************************************************
;* Check for scoring
;****************************************************

checkScore:
        ; Check if ball went off left side (Player 2 scores)
        lda $d004
        cmp #SCREEN_LEFT
        if cc
            inc player2Score
            jsr resetBall
            jsr updateScore
            jsr checkWinner
        endif

        ; Check if ball went off right side (Player 1 scores)
        lda $d004
        cmp #SCREEN_RIGHT
        if cs
            inc player1Score
            jsr resetBall
            jsr updateScore
            jsr checkWinner
        endif
        rts

;****************************************************
;* Reset ball to center
;****************************************************

resetBall:
        setSpriteXY 2,140,130
        
        ; Random ball direction (simple)
        lda $d012       ; Use raster line as random seed
        and #1
        if eq
            lda #BALL_SPEED
        else
            lda #$FF-BALL_SPEED+1
        endif
        sta ballDX
        
        lda #0
        sta ballDY
        
        ; Small delay before ball starts moving
        ldx #60
delay:
        sync_to_rasterline256
        dex
        bne delay
        rts

;****************************************************
;* Draw playing field
;****************************************************

drawField:
        ; Draw center line in the middle of short field
        ;ldy #8
centerLoop:
        ;lda #124        ; Vertical line character
        ;sta SCREEN_BASE + 17 + 40*8, y
        ;sta SCREEN_BASE + 17 + 40*12, y
        ;sta SCREEN_BASE + 17 + 40*16, y
        ;dey
        ;bpl centerLoop
        
        ; Draw top and bottom boundaries
        ;ldx #15
boundaryLoop:
        ;lda #45         ; Horizontal line character
        ;sta SCREEN_BASE + 10, x     ; Top boundary
        ;sta SCREEN_BASE + 10 + 40*15, x  ; Bottom boundary
        ;dex
        ;bpl boundaryLoop
        ;rts

;****************************************************
;* Update score display
;****************************************************

updateScore:
        ; Player 1 score (left side)
        lda player1Score
        clc
        adc #48         ; Convert to ASCII
        sta SCREEN_BASE + 5
        
        ; Player 2 score (right side)
        lda player2Score
        clc
        adc #48         ; Convert to ASCII
        sta SCREEN_BASE + 34
        rts

;****************************************************
;* Game variables
;****************************************************

joyvalue1:      .byte 0     ; Player 1 joystick value
joyvalue2:      .byte 0     ; Player 2 joystick value
ballDX:         .byte 0     ; Ball X velocity
ballDY:         .byte 0     ; Ball Y velocity  
player1Score:   .byte 0     ; Player 1 score
player2Score:   .byte 0     ; Player 2 score
collisionTemp:  .byte 0     ; Temporary storage for collision register
flashCounter:   .byte 0     ; Counter for flashing effect
flashTimer:     .byte 0     ; Timer for menu flashing
flashState:     .byte 0     ; State for menu flashing

; Menu text (in screen codes)
gameTitle:      .byte 16,9,14,7,32,16,15,14,7,0              ; "PING PONG"
startMessage:   .byte 16,18,5,19,19,32,19,16,1,3,5,32,20,15,32,19,20,1,18,20,0  ; "PRESS SPACE TO START"
player1Controls: .byte 16,12,1,25,5,18,32,49,58,32,10,15,25,19,20,9,3,11,32,50,0  ; "PLAYER 1: JOYSTICK 2"
player2Controls: .byte 16,12,1,25,5,18,32,50,58,32,10,15,25,19,20,9,3,11,32,49,0  ; "PLAYER 2: JOYSTICK 1"

; Win message texts (in screen codes)
player1WinText: .byte 16,12,1,25,5,18,32,49,32,23,9,14,19,33,0  ; "PLAYER 1 WINS!"
player2WinText: .byte 16,12,1,25,5,18,32,50,32,23,9,14,19,33,0  ; "PLAYER 2 WINS!"

;****************************************************
;* Interrupt service routine
;****************************************************

isr:    asl $d019       ; Clear interrupt source
        inc $d020       ; Frame color change for debugging
        jsr MUSIC_BASE+3 ; Play music
        dec $d020       ; Restore frame color
        jmp $ea31       ; Leave via KERNAL standard interrupt routine