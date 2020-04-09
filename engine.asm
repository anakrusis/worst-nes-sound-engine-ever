    .inesprg 1 ;1x 16kb PRG code
    .ineschr 0 ;0x 8kb CHR data
    .inesmap 0 ; mapper 0 = NROM, no bank swapping
    .inesmir 1 ;background mirroring (vertical mirroring = horizontal scrolling)

	.rsset $0300
noteTick   .rs 1
pulse1Note .rs 1

;----- first 8k bank of PRG-ROM    
    .bank 0
    .org $C000
    
irq:
nmi:
	jsr music_engine_tick
    rti

reset:
    sei	
    cld
    
	jsr engine_init
	
	lda #$88
    sta $2000   ;enable NMIs

forever:
    jmp forever
	
engine_init:
	lda #$0f
    sta $4015 ;enable all the channels except dpc >:C
    
    lda #%01111111 ;set duty, no length counter stuff and volume f (last 4 bytes)
	sta $4000
	rts
	
	lda #$ab
	sta $4002
    lda #$09
    sta $4003
	
music_engine_tick:
	lda #$ff
	cmp noteTick
	bne .music_engine_tick_end
	inc $4002
	inc $4003
	;ldx pulse1Note
	;lda Song, x
	;lsr a
	;lsr a
	;lsr a
	;lsr a
	;lsr a
	;tax
	;lda NoteLenLookupTbl, x
	;cmp noteTick
	;bne music_engine_tick_end
;	
	;ldx pulse1Note
	;lda Song, x
	;and #$1f
	;tax
	;lda FreqLookupTbl, x
	;sta $4002
	;inx
    ;lda FreqLookupTbl,x
    ;sta $4003
;	
	;inc pulse1Note
	;lda #$00
	;stx noteTick
	
.music_engine_tick_end:
	inc noteTick
	rts
    
;----- second 8k bank of PRG-ROM    
    .bank 1
    .org $E000
	
Song:
	.db $21, $21, $21, $21
	
FreqLookupTbl:
	.db $ab, $09, $93, $09 ; frequencies right now are just C-3 and C#3
	
NoteLenLookupTbl:
	.db $10, $20, $30, $40
	
;---- vectors
    .org $FFFA     ;first of the three vectors starts here
    .dw nmi        ;when an NMI happens (once per frame if enabled) the 
                   ;processor will jump to the label NMI:
    .dw reset      ;when the processor first turns on or is reset, it will jump
                   ;to the label reset:
    .dw irq        ;external interrupt IRQ is not used in this tutorial
