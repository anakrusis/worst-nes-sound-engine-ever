    .inesprg 1 ;1x 16kb PRG code
    .ineschr 0 ;0x 8kb CHR data
    .inesmap 0 ; mapper 0 = NROM, no bank swapping
    .inesmir 1 ;background mirroring (vertical mirroring = horizontal scrolling)


;----- first 8k bank of PRG-ROM    
    .bank 0
    .org $C000
    
irq:
nmi:
    rti

reset:
    sei	
    cld
    
	jsr engine_init

    
	ldx #$00
    lda FreqLookupTbl,x   
    sta $4002
	inx
    lda FreqLookupTbl,x
    sta $4003
	
engine_init:
	lda #$0f
    sta $4015 ;enable all the channels except dpc >:C
    
    lda #%01111111 ;set duty, no length counter stuff and volume f (last 4 bytes)
	sta $4000
	rts
    
forever:
    jmp forever
    
;----- second 8k bank of PRG-ROM    
    .bank 1
    .org $E000
	
FreqLookupTbl:
	.db $ab, $09, $93, $09 
	
;---- vectors
    .org $FFFA     ;first of the three vectors starts here
    .dw nmi        ;when an NMI happens (once per frame if enabled) the 
                   ;processor will jump to the label NMI:
    .dw reset      ;when the processor first turns on or is reset, it will jump
                   ;to the label reset:
    .dw irq        ;external interrupt IRQ is not used in this tutorial
    