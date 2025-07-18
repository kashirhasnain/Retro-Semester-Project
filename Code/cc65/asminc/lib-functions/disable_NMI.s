.include "../LAMAlib-macros16.inc"

; 'Disable NMI' by Ninja/The Dreams/TempesT
; the trick is to cause an NMI but don't ackowledge it
; based on an idea from https://codebase64.org/doku.php?id=base:nmi_lock

.export _disable_NMI_sr := disableNMI
  
disableNMI:
	php		; store current state of interrupt flag
        sei             ; disable IRQ
        lda #<nmi       ;
        sta $0318       ; change NMI vector
        lda #>nmi       ; to our routine
        sta $0319       ;
        lda #$00        ; 
        sta $DD0E       ; stop CIA2 Timer A
        sta $DD04       ; set Timer A to 0, after starting
        sta $DD05       ; NMI will occur immediately
        lda #$81        ;
        sta $DD0D       ; set Timer A as source for NMI
        lda #$01        ;
        sta $DD0E       ; start Timer A -> NMI
	;nop
        ;lda #$01       
        sta $DD0D       ; clear Timer A as NMI source
	plp		; restore previous state of interrupt flag
	rts 

nmi:        
        rti             ; exit interrupt
                        ; (not acknowledged!)
