;****************************************************
;* Ping Pong Game
;*
;* Player vs Computer
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
BALL_SPEED = 2
SCREEN_TOP = 50
SCREEN_BOTTOM = 230
SCREEN_LEFT = 24
SCREEN_RIGHT = 255
PADDLE_HEIGHT = 40
CPU_REACTION_DELAY = 8

install_file "ball.prg",SPRITE_BASE
install_file "playerpaddle.prg",SPRITE_BASE+$40
install_file "cpupaddle.prg",SPRITE_BASE+$80
install_file "gse_song.prg",MUSIC_BASE

        lda #0          ;select first tune
        jsr MUSIC_BASE  ;initialize music with tune in A
        clrscr

;****************************************************
;* Initialize sprites
;****************************************************

        setSpriteMultiColor1 1  ; White
        setSpriteMultiColor2 0  ; Black

        ; Player paddle (sprite 0) - left side
        setSpriteCostume 0,SPRITE_BASE
        setSpriteXY 0,40,120
        updateSpriteAttributes 0
        showSprite 0

        ; CPU paddle (sprite 1) - right side  
        setSpriteCostume 1,SPRITE_BASE+$40
        setSpriteXY 1,280,120
        updateSpriteAttributes 1
        showSprite 1

        ; Ball (sprite 2) - center
        setSpriteCostume 2,SPRITE_BASE+$80
        setSpriteXY 2,160,120
        updateSpriteAttributes 2
        showSprite 2

        ; Initialize game variables
        lda #BALL_SPEED
        sta ballDX
        lda #1
        sta ballDY
        
        lda #0
        sta playerScore
        sta cpuScore
        sta cpuDelayCounter

        ; Draw game field
        jsr drawField
        jsr updateScore

        set_raster_irq 50,isr

;****************************************************
;* Main game loop
;****************************************************

MainLoop:
        sync_to_rasterline256
        
        jsr playerControl       ; Handle player input
        jsr moveBall           ; Update ball position
        jsr moveCPU            ; Update CPU paddle
        jsr checkCollisions   ; Check all collisions
        jsr checkScore        ; Check if point scored
        
        jmp MainLoop

;****************************************************
;* Player control
;****************************************************

playerControl:
        lda $dc00       ; Read joystick port 2
        sta joyvalue
        
        lsr joyvalue    ; Bit 0 (up)
        if cc
            lda $d001   ; Get current Y position
            sec
            sbc #PADDLE_SPEED
            cmp #SCREEN_TOP
            if cs
                sta $d001   ; Update player paddle Y
            endif
        endif

        lsr joyvalue    ; Bit 1 (down)
        if cc
            lda $d001   ; Get current Y position
            clc
            adc #PADDLE_SPEED
            cmp #SCREEN_BOTTOM-PADDLE_HEIGHT
            if cc
                sta $d001   ; Update player paddle Y
            endif
        endif
        rts

;****************************************************
;* CPU paddle AI
;****************************************************

moveCPU:
        ; Simple AI - follow ball with some delay
        dec cpuDelayCounter
        if eq
            lda #CPU_REACTION_DELAY
            sta cpuDelayCounter
            
            ; Get ball Y position
            lda $d005
            sec
            sbc $d003       ; Compare with CPU paddle Y
            
            if cc           ; Ball is above paddle
                lda $d003
                sec
                sbc #PADDLE_SPEED
                cmp #SCREEN_TOP
                if cs
                    sta $d003
                endif
            else
                if ne       ; Ball is below paddle
                    lda $d003
                    clc
                    adc #PADDLE_SPEED
                    cmp #SCREEN_BOTTOM-PADDLE_HEIGHT
                    if cc
                        sta $d003
                    endif
                endif
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
        
        ; Check ball vs player paddle (sprites 0 and 2)
        and #%00000101  ; Check collision between sprite 0 and 2
        cmp #%00000101
        if eq
            ; Ball hit player paddle
            lda ballDX
            if mi           ; Ball moving left
                lda #BALL_SPEED
                sta ballDX  ; Reverse to right
                ; Add some angle based on paddle hit position
                jsr calculateBounceAngle
            endif
        endif

        lda $D01E       ; Read again (register clears on read)
        ; Check ball vs CPU paddle (sprites 1 and 2)  
        and #%00000110  ; Check collision between sprite 1 and 2
        cmp #%00000110
        if eq
            ; Ball hit CPU paddle
            lda ballDX
            if pl           ; Ball moving right
                lda #$FF-BALL_SPEED+1  ; Negative speed (moving left)
                sta ballDX
                ; Add some angle based on paddle hit position
                jsr calculateBounceAngle
            endif
        endif
        rts

;****************************************************
;* Calculate bounce angle based on paddle hit
;****************************************************

calculateBounceAngle:
        ; Simple angle calculation based on where ball hits paddle
        ; This adds variety to the gameplay
        lda $d005       ; Ball Y
        sec
        sbc $d001       ; Subtract paddle Y (player or CPU)
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
        ; Check if ball went off left side (CPU scores)
        lda $d004
        cmp #SCREEN_LEFT
        if cc
            inc cpuScore
            jsr resetBall
            jsr updateScore
        endif

        ; Check if ball went off right side (Player scores)
        lda $d004
        cmp #SCREEN_RIGHT-20
        if cs
            inc playerScore
            jsr resetBall
            jsr updateScore
        endif
        rts

;****************************************************
;* Reset ball to center
;****************************************************

resetBall:
        setSpriteXY 2,160,120
        
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
        ; Draw center line
        ldy #5
centerLoop:
        lda #124        ; Vertical line character
        sta SCREEN_BASE + 19 + 40*0, y
        sta SCREEN_BASE + 19 + 40*5, y
        sta SCREEN_BASE + 19 + 40*10, y
        sta SCREEN_BASE + 19 + 40*15, y
        sta SCREEN_BASE + 19 + 40*20, y
        dey
        bpl centerLoop
        rts

;****************************************************
;* Update score display
;****************************************************

updateScore:
        ; Player score (left side)
        lda playerScore
        clc
        adc #48         ; Convert to ASCII
        sta SCREEN_BASE + 5
        
        ; CPU score (right side)
        lda cpuScore
        clc
        adc #48         ; Convert to ASCII
        sta SCREEN_BASE + 34
        rts

;****************************************************
;* Game variables
;****************************************************

joyvalue:       .byte 0
ballDX:         .byte 0     ; Ball X velocity
ballDY:         .byte 0     ; Ball Y velocity  
playerScore:    .byte 0
cpuScore:       .byte 0
cpuDelayCounter: .byte 0

;****************************************************
;* Interrupt service routine
;****************************************************

isr:    asl $d019       ; Clear interrupt source
        inc $d020       ; Frame color change for debugging
        jsr MUSIC_BASE+3 ; Play music
        dec $d020       ; Restore frame color
        jmp $ea31       ; Leave via KERNAL standard interrupt routine