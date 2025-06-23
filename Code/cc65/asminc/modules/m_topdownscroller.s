;***********************************************************************
;* Module: polychars
;* Version 0.34
;* by Wil
;*
;* Purpose:
;* This module provides a routine to hardscroll one or more character
;* strings. Each string will scroll in a predefined column on the screen.
;* Different speeds and string lengths are possible. When all strings
;* have scrolled through, the run procedure returns with a set carry flag.
;*
;* Configuration and Inclusion:
;* To use this module in your program:
;* .scope topdownscroller
;*   string1: str_enc0 "\x9ein a galaxy far, far away..."
;*   .include "m_topdownscroller.s"
;* .endscope
;* 
;* Main Program Usage:
;* m_init topdownscroller               ; Initializes the screen addresses based on 
;* m_run topdownscroller  		; To be run after rasterline 250, returns with carry set if all strings are through
;*
;***********************************************************************

.include "LAMAlib.inc"

;***********************************************************************
;* parameters - can be overwritten from main file
;* without a default value the constant must be set by the main program

def_const DELAY1,4		;number of delay frames between a scroll
def_const REPEAT1,1		;if ne then text is repeated after one scroll

.code

;***********************************************************************
;* Procedure: init
;* Resets the pointers for the strings
;* Resets scroll_done flags
;* Checks where the screen is and sets the respective pointers
;***********************************************************************
.proc init
	
        rts
.endproc

;***********************************************************************
;* Procedure: run
;* Scrolls each string down whenever the respective delay timer
;* expires. 
;* Returns with a set carry if all strings have scrolled through,
;* otherwise carry is cleared. A repeaeted string is considered done
;* after the first iteration
;***********************************************************************
.proc run

	
.endproc

.repeat 40,i	;maximum 40 parallel strings
.ifdef .ident(.sprintf("string%d",i+1))
.out .sprintf("string%d",i+1)
.endif
.endrep
