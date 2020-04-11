    .inesprg 1 ;1x 16kb PRG code
    .ineschr 0 ;0x 8kb CHR data
    .inesmap 0 ; mapper 0 = NROM, no bank swapping
    .inesmir 1 ;background mirroring (vertical mirroring = horizontal scrolling)

	.rsset $0300
noteTick   .rs 1
pulse1Note .rs 1
testes     .rs 1

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
    
	jsr music_engine_init
	
	lda #$88
    sta $2000   ;enable NMIs
	
	lda #$08 ; background enabled, no sprites
	lda $2001

forever:
    jmp forever
	
music_engine_init:
	lda #$0f
    sta $4015 ;enable all the channels except dpc >:C
    
    lda #$7f ;set duty, no length counter stuff and volume f (last 4 bytes)
	sta $4000
	
	lda #$00 ; init player state I guess
	sta noteTick
	sta pulse1Note
	
	rts
	
music_engine_tick:
	ldx pulse1Note ; reading tempo data 
	lda Song, x
	lsr a
	lsr a
	lsr a
	lsr a
	lsr a
	tax
	lda NoteLenLookupTbl, x
	
	;lda #$10 ; can substitute this line, all notes will be 0x10 ticks long
	
	cmp noteTick
	bne .music_engine_tick_end
	
	ldx pulse1Note ; reading pitch data
	lda Song, x 
	and #$1f ; bitmask of ---x xxxx for pitches in a byte
	
	cmp #$1f ; and ---1 1111 is the note cut
	beq .music_engine_note_cut
	
	asl a ; multiplied by 2 because each pitch is two bytes!! >.<
	tax
	lda FreqLookupTbl, x
	sta $4002
	inx
    lda FreqLookupTbl,x
    sta $4003
	
	lda #$7f
	sta $4000 ; not silent sq1
	
.music_engine_new_note:
	lda #$00
	sta noteTick 
	
	inc pulse1Note ; loops song if it gets to the last note
	lda SongLengths
	sta testes
	cmp pulse1Note
	bne .music_engine_tick_end
	
	lda #$00
	sta pulse1Note
	
.music_engine_tick_end:
	inc noteTick
	rts

.music_engine_note_cut:
	inc noteTick
	lda #$70 ;silence sq1
	sta $4000
	jmp .music_engine_new_note
 
;----- second 8k bank of PRG-ROM    
    .bank 1
    .org $E000
	
SongLengths:
	.db $0c
	
Song:
	.db $02, $04, $05, $07 ; the licc
	.db $04, $04, $00, $02
	.db $1f, $1f, $1f, $1f
	
FreqLookupTbl:
	.db $ab, $09, $93, $09 ; C-3, C#3  0, 1
	.db $7c, $09, $67, $09 ; D-3, D#3  2, 3
	.db $52, $09, $3f, $09 ; E-3, F-3  4, 5
	.db $2d, $09, $1c, $09 ; F#3, G-3  6, 7
	
NoteLenLookupTbl:
	.db $0c, $20, $30, $40
	
;---- vectors
    .org $FFFA     ;first of the three vectors starts here
    .dw nmi        ;when an NMI happens (once per frame if enabled) the 
                   ;processor will jump to the label NMI:
    .dw reset      ;when the processor first turns on or is reset, it will jump
                   ;to the label reset:
    .dw irq        ;external interrupt IRQ is not used in this tutorial
	
	.bank 4
    .org $0000
    .incbin "funtus.chr"