;-----------------------------------------------------------------------
; window_chrout
; Prints characters that are output via $FFD2 within a window
;
; Jan-2022 V0.3
; Wilfried Elmenreich
; License: The Unlicense
;
; Routine is almost twice as fast as the KERNAL routine
;
; Note that control character keypresses in direct mode are not handled
; via FFD2, therefore pressing for example CLR/HOME will leave the
; window.
;
; The page of the textscreen (stored in $288 / 648) is used to determine
; the output screen, but if you change the screen, the routine
; _enable_chrout2window needs to be called again.
;
; limitations: no backspace, no insert
;
; Needs to be linked with window_parameters.o
;-----------------------------------------------------------------------

.include "../LAMAlib-macros16.inc"
.include "../LAMAlib-structured.inc"

.macpack longbranch

.export _chrout2window, _enable_chrout2window, _disable_chrout2window
.export _clear_window

.import _window_x1,_window_y1,_window_x2,_window_y2
.import _fill_window

.import _mul40_tbl_lo,_mul40_tbl_hi
mul40_lo:=_mul40_tbl_lo
mul40_hi:=_mul40_tbl_hi

; switch for adding fileio support
support_fileio=1	;set this to 0 if fileio is not needed while windowing is enabled
			;removing fileio support will save 15 cycles and 17 bytes

; the following memory addresses are used the same way the Kernal 
; uses them for output of a character

.importzp _CURSORX,_CURSORY,_REVERSE_MODE_SWITCH,_CURRENT_OUTPUT_DEVICE_NUMBER
.import _DEFAULT_OUTPUT,_TEXTCOLOR_ADDR,_PTRSCRHI

cursorx  =_CURSORX
cursory  =_CURSORY
rvs_mode =_REVERSE_MODE_SWITCH
charcolor = _TEXTCOLOR_ADDR
scrpage =   _PTRSCRHI

_enable_chrout2window:
	pokew $0326,_chrout2window

	;move cursorpos into window if necessary
	lda _window_x1
	cmp cursorx
	if cs
	  sta cursorx
	endif

	lda _window_x2
	cmp cursorx
	if cc
	  sta cursorx
	endif

	lda _window_y1
	cmp cursory
	if cs
	  sta cursory
	endif

	lda _window_y2
	cmp cursory
	if cc
	  sta cursory
	endif

	;set screen and color pointers to cursor pos
	ldy cursory
	lda mul40_lo,y
	sta scrptr
	sta colptr
	lda mul40_hi,y
	pha
	clc
	adc scrpage
	sta scrptr+1
	pla	;get value of mul40_hi,y again
	;clc
	adc #$D8
	sta colptr+1

	rts

_disable_chrout2window:
	pokew $0326,_DEFAULT_OUTPUT	;Kernal routine for character output

rts_address:
	rts

;---------------------------------------------------
; poor man's replacement for CHROUT
;---------------------------------------------------
.import _OUTPUT_BYTE_TO_DATASETTE_OR_RSR232,_OUTPUT_BYTE_TO_SERIAL_BUS

_chrout2window:
.if support_fileio = 1
	pha
	lda _CURRENT_OUTPUT_DEVICE_NUMBER		;get device number to write to
	cmp #$03	;screen?
	beq output_to_screen
	bcc datasette_or_rsr232	;lower than 3?
	pla
	jmp _OUTPUT_BYTE_TO_SERIAL_BUS  	;output byte to serial bus
datasette_or_rsr232:
	jmp _OUTPUT_BYTE_TO_DATASETTE_OR_RSR232	;output byte to device 1 or 2
output_to_screen:
	pla
.endif
	store A		;preserve registers
	store X
	store Y

	bit rts_address	;anded with #%01100000
	beq check_control_codes  

;---------------------------------------------------
;print normal char
;---------------------------------------------------

printablechar:
;convert to screencode
	cmp #$ff
	bne L0
	lda #126     ;pi character
L0:
        cmp #$60
        bcc L1+1
	cmp #$80
	bcs L2
	and #$df     ;delete bit $20 to handle uppercase chars
L2:
        ora #$40
        and #$7f
L1:
        bit $3f29    ;contains command AND #$3f 

	eor rvs_mode

	ldx cursorx
;copy char
scrptr=*+1
	sta $0400,x

;copy color
	lda charcolor
colptr=*+1
	sta $d800,x

	;fallthrough!

;---------------------------------------------------
;cursor right
;---------------------------------------------------
chr_right:
	lda cursorx
	cmp _window_x2
	if cs
	  jmp chr_return
	endif
	inc cursorx
        jmp exit_routine

;---------------------------------------------------
;check control codes
;---------------------------------------------------
check_control_codes:
	cmp #$0d
	beq clr_rvs_and_return

	cmp #29		;crsr right
	beq chr_right

	cmp #$11	;crsr down
	beq chr_down

	cmp #$13	;home
	jeq home_pos

	cmp #145	;crsr up
	beq chr_up

	cmp #157	;crsr left
	beq chr_left

	cmp #18		;rvs on
	if eq
	  lda #$80
st_rvs:
	  sta rvs_mode
	  jmp exit_routine
	endif

	cmp #146	;rvs off
	if eq
	  lda #00
	  beq st_rvs
	endif

	cmp #147	;clrscr
	beq _clear_window
	
	;must be a color code
	ldy #8
checkcolors:
	cmp color_codes,y
	bne nohit
	sty charcolor
	jmp exit_routine
nohit:
	dey
	bpl checkcolors
	sec
	sbc #140
	sta charcolor
	jmp exit_routine

;---------------------------------------------------
;cursor left
;---------------------------------------------------
chr_left:
;go back one char
	lda _window_x1
	cmp cursorx
	bcs up_and_to_end_of_line	;we are already at the left side of the window
	dec cursorx
        jmp exit_routine

up_and_to_end_of_line:
	lda _window_x2
	sta cursorx

	;fallthrough!

;---------------------------------------------------
;cursor up
;---------------------------------------------------
chr_up:
	lda _window_y1
	cmp cursory
	if cs
	  jmp exit_routine	;we are already at the top of the window
	endif
	dec cursory	

	lda scrptr
	sbc #39		;40-1 because carry is clear
	sta scrptr
	sta colptr
	if cc
	  dec scrptr+1
	  dec colptr+1
	endif
        jmp exit_routine

;---------------------------------------------------
;cursor return
;---------------------------------------------------
clr_rvs_and_return:
	poke rvs_mode,0
chr_return:
	lda _window_x1
	sta cursorx

	;fallthrough!

;---------------------------------------------------
;cursor down
;---------------------------------------------------
chr_down:
	lda cursory
	cmp _window_y2
	bcc ok_down
	jsr scrollup
	jmp exit_routine
ok_down:
	inc cursory
	lda scrptr
	adc #40		;because carry is clear
	sta scrptr
	sta colptr
	if cs
	  inc scrptr+1
	  inc colptr+1
	endif
	jmp exit_routine

;---------------------------------------------------
;clear screen (or rather the window in our case)
;---------------------------------------------------
_clear_window:
	lda #$20
	jsr _fill_window
	;fallthrough!

;---------------------------------------------------
;crsr home
;---------------------------------------------------
home_pos:
	lda _window_x1
	sta cursorx
	ldy _window_y1
	sty cursory

	lda mul40_lo,y
	sta scrptr
	sta colptr
	lda mul40_hi,y
	clc
	adc scrpage
	sta scrptr+1
	lda mul40_hi,y
	adc #$d8
	sta colptr+1
	
	;fallthrough!

;---------------------------------------------------
;exit routine
;---------------------------------------------------
exit_routine:
	restore A
	restore X
	restore Y
	clc
	rts

;---------------------------------------------------
;scroll up and clear last line in window
;---------------------------------------------------
scrollup:
	ldy _window_y1
	lda _window_x1
	clc
	adc mul40_lo,y
	sta scr_to_ptr
	sta col_to_ptr
	php
	lda mul40_hi,y
	adc scrpage
	sta scr_to_ptr+1
	sta scr_from_ptr+1
	plp	;recover carry bit
	lda mul40_hi,y			;todo: use x to keep value
	adc #$d8
	sta col_to_ptr+1
	sta col_from_ptr+1

	lda scr_to_ptr
	adc #40
	sta scr_from_ptr
	sta col_from_ptr
	if cs
	  inc scr_to_ptr+1
	  inc col_to_ptr+1
	endif

	lda _window_x2
	sec
	sbc _window_x1
	sta line_width

scroll_lines:
	cpy _window_y2
	bcs clear_last_line

line_width=*+1
	ldx #00

copy_line:
scr_from_ptr=*+1
	lda $428,x
scr_to_ptr=*+1
	sta $400,x
col_from_ptr=*+1
	lda $D828,x
col_to_ptr=*+1
	sta $D800,x	
	dex
	bpl copy_line
	
	lda scr_from_ptr
	sta scr_to_ptr
	sta col_to_ptr
	ldx scr_from_ptr+1
	stx scr_to_ptr+1
	ldx col_from_ptr+1
	stx col_to_ptr+1
	clc
	adc #40
	if cs
	  inc scr_from_ptr+1
	  inc col_from_ptr+1
	endif
	sta scr_from_ptr
	sta col_from_ptr

	iny
	bne scroll_lines

clear_last_line:
	lda scr_to_ptr
	sta scr_clr_ptr
	sta col_clr_ptr
	lda scr_to_ptr+1
	sta scr_clr_ptr+1
	lda col_to_ptr+1
	sta col_clr_ptr+1

	ldx line_width
clr_loop:
	lda #$20
scr_clr_ptr=*+1
	sta $400,x
	lda charcolor
col_clr_ptr=*+1
	sta $d800,x
	dex
	bpl clr_loop

	rts

;---------------------------------------------------
;tables
;---------------------------------------------------

color_codes:
.byte 144,5,28,159,156,30,31,158,129
