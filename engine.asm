    .inesprg 1 ;1x 16kb PRG code
    .ineschr 1 ;1x 8kb CHR data
    .inesmap 0 ; mapper 0 = NROM, no bank swapping
    .inesmir 1 ;background mirroring (vertical mirroring = horizontal scrolling)

	.rsset $0300
globalTick .rs 1
noteTick   .rs 1
pulse1Note .rs 1
testes     .rs 1

;----- first 8k bank of PRG-ROM    
    .bank 0
    .org $C000
    
irq:
nmi:
	
BlinkAnim:	;; Silly blink animation test
	lda #$00
	sta $0201 ; 201 and 205 are the addresses of the two tile index bytes of the head sprites
	sta $0205
	
	lda globalTick
	and #%00111111 ; Blinks every 64 frames for 8 frames
	cmp #$08
	bcs BlinkAnimDone
	
	lda #$01
	sta $0201
	sta $0205
	
BlinkAnimDone:

	lda #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
	sta $2000
	lda #%00011110   ; enable sprites, enable background, no clipping on left side
	sta $2001
	lda #$00  ; no scrolling
	sta $2005
	sta $2005
	
	lda #$00
	sta $2003  
	lda #$02
	sta $4014 ; oam dma

	jsr music_engine_tick
    rti

reset:
    sei	
    cld
	jsr music_engine_init
	
vblankwait1:
	bit $2002
	bpl vblankwait1
	
vblankwait2:
	bit $2002
	bpl vblankwait2
	
	lda $2002
	lda #$3F
	sta $2006   
	lda #$00
	sta $2006    
	ldx #$00
paletteLoop:
	lda BackgroundPalette, x
	sta $2007
	inx
	cpx #$20
	bne paletteLoop
	
loadBG:
	lda $2002
	lda #$20
	sta $2006
	lda #$00
	sta $2006
	ldx #$00
BGLoop:
	lda Background, x
	sta $2007
	inx
	cpx #$a0 ; background is 0xa0 (160) long rn
	bne BGLoop
	
loadAttr:
	lda $2002   
	lda #$23
	sta $2006   
	lda #$C0
	sta $2006   
	ldx #$00
attrLoop:
	lda #$00 ; They're all zero! all of them! yay!
	sta $2007 
	inx
	cpx #$20
	bne attrLoop
	
	ldx #$00 ; Cute little test sprite!
SpriteTest:
	lda PlayerSpriteData, x
	sta $0200, x
	inx
	cpx #$10
	bne SpriteTest
	
BlankOtherSprites: ; This is so you don't see the other 60 sprites in the top left corner, lol
	lda #$ff
	sta $0200, x
	inx
	cpx #$ff
	bne BlankOtherSprites
	
	lda #$90
    sta $2000   ;enable NMIs
	
	lda #%00011110 ; background and sprites enabled
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

	lda #$00
	cmp noteTick
	bne .music_engine_tick_new
	
	ldx pulse1Note ; reading pitch data
	lda Song, x 
	and #$1f ; bitmask of ---x xxxx for pitches in a byte
	
	cmp #$1f ; and ---1 1111 is the note cut
	beq .music_engine_note_cut
	
	asl a ; multiplied by 2 because each pitch is two bytes!! >.<
	tax
	lda FreqLookupTbl, x
	sta $4002
	sta $400a
	inx
    lda FreqLookupTbl,x
    sta $4003
	sta $400b
	
	lda #$7f
	sta $4000 ; not silent sq1
	
.music_engine_new_note:

	inc pulse1Note 
	lda SongLengths
	sta testes
	cmp pulse1Note
	bne .music_engine_tick_new
	
	lda #$00 ; loops song back to note 0 if it gets to the last note
	sta pulse1Note
	sta noteTick
	jmp .music_engine_tick_end
	
.music_engine_tick_new:
	
	inc noteTick

	ldx pulse1Note ; reading tempo data 
	lda Song-1, x
	lsr a
	lsr a
	lsr a
	lsr a
	lsr a
	tax
	lda NoteLenLookupTbl, x
	cmp noteTick
	bne .music_engine_tick_end
	
	lda #$00 ; goes on to the next note if we reach the relative tick that corresponds to the note's length
	sta noteTick
	
.music_engine_tick_end:
	inc globalTick
	rts

.music_engine_note_cut:
	inc noteTick
	lda #$70 ;silence sq1
	sta $4000
	
	jmp .music_engine_new_note
 
;----- second 8k bank of PRG-ROM    
    .bank 1
    .org $E000
	
PlayerSpriteData:
	.db $80, $00, $00, $80
	.db $80, $00, $40, $88  
	.db $88, $10, $00, $80 
	.db $88, $11, $00, $88 
	
BackgroundPalette:
	.db $0f, $20, $10, $00, $04, $14, $24, $34, $04, $14, $24, $34, $04, $14, $24, $34 ; bg
	.db $0f, $15, $27, $30, $04, $14, $24, $34, $04, $14, $24, $34, $04, $14, $24, $34 ; sprites
	
Background:
	.db $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24  ; the background, and yeah
	.db $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24
	
	.db $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24
	.db $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24
	
	.db $24, $1d, $11, $0e, $24, $15, $12, $0c, $0c, $24, $24, $24, $24, $24, $24, $24  ; "THE LICC"
	.db $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24
	
	.db $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24
	.db $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24
	
	.db $24, $0a, $0d, $10, $10, $0f, $13, $10, $10, $0f, $0a, $0f, $0a, $0f, $0a, $0f  ; "ADGGFJGGFAFAFAFA 4/11/2020"
	.db $0a, $24, $04, $2c, $01, $01, $2c, $02, $2d, $02, $2d, $24, $24, $24, $24, $24
	
SongLengths:
	.db $09
	
Song:
	.db $02, $04, $05, $07 ; the licc
	.db $24, $00, $02, $5f
	
FreqLookupTbl:
	.db $ab, $09, $93, $09 ; C-3, C#3  0, 1
	.db $7c, $09, $67, $09 ; D-3, D#3  2, 3
	.db $52, $09, $3f, $09 ; E-3, F-3  4, 5
	.db $2d, $09, $1c, $09 ; F#3, G-3  6, 7
	
NoteLenLookupTbl:
	.db $0c, $18, $30, $60
	
;---- vectors
    .org $FFFA     ;first of the three vectors starts here
    .dw nmi        ;when an NMI happens (once per frame if enabled) the 
                   ;processor will jump to the label NMI:
    .dw reset      ;when the processor first turns on or is reset, it will jump
                   ;to the label reset:
    .dw irq        ;external interrupt IRQ is not used in this tutorial
	
	.bank 2
    .org $0000
    .incbin "funtus.chr"