    .inesprg 1 ;1x 16kb PRG code
    .ineschr 1 ;1x 8kb CHR data
    .inesmap 0 ; mapper 0 = NROM, no bank swapping
    .inesmir 1 ;background mirroring (vertical mirroring = horizontal scrolling)

	.rsset $0000
stringPtr  .rs 2 ; Where's the string we're rendering
strPPUAddress .rs 2 ; What address will the string go to in the ppu
	
	.rsset $0300
globalTick .rs 1 ; For everything
noteTick   .rs 1 ; Just local to the current note, determines when to move on to the next one
pulse1Note .rs 1 ; Which note are we currently on, it's an index
testes     .rs 1 ; Logger

;----- first 8k bank of PRG-ROM    
    .bank 0
    .org $C000
	
	.include "engine.asm" ; Sound engine
    
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
	
clearmem:
    lda #$00
    sta $0000, x
    sta $0100, x
    sta $0300, x
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x
    lda #$FE
    sta $0200, x
    inx
    bne clearmem
	
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
	lda #$80 ; 80 is just a stripey tile pattern ,lel
	sta $2007
	sta $2007
	sta $2007
	sta $2007
	inx
	cpx #$f0
	bne BGLoop ; Fills the whole screen with stripes
	
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
	cpx #$80
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
	
StringTest:
	lda #$21
	sta strPPUAddress
	lda #$04
	sta strPPUAddress + 1
	
	lda #LOW(text_Adggfjggfafafafa)
    sta stringPtr
    lda #HIGH(text_Adggfjggfafafafa)
    sta stringPtr+1
	
	jsr drawString
	
	lda #$20
	sta strPPUAddress
	lda #$cc
	sta strPPUAddress + 1
	
	lda #LOW(text_TheLicc)
    sta stringPtr
    lda #HIGH(text_TheLicc)
    sta stringPtr+1
	
	jsr drawString
	
forever:
    jmp forever
	
; drawString works like this: you set stringPtr and strPPUAddress
; before you call this subroutine. As long as you do that, you're good to go!
; Oh, and make sure all your strings end in $ff, or else you get corrupto!!
drawString:
	ldx strPPUAddress
	stx $2006
	ldx strPPUAddress + 1
	stx $2006
	
	ldy #$00
drawStringLoop:
	lda [stringPtr], y
	cmp #$ff
	beq drawStringDone
	
	sta $2007
	iny
	jmp drawStringLoop
	
drawStringDone:
	rts
	
;----- second 8k bank of PRG-ROM    
    .bank 1
    .org $E000
	
PlayerSpriteData:
	.db $80, $00, $00, $80
	.db $80, $00, $40, $88  
	.db $88, $10, $00, $80 
	.db $88, $11, $00, $88 
	
BackgroundPalette:
	.db $3a, $20, $2a, $00, $04, $14, $24, $34, $04, $14, $24, $34, $04, $14, $24, $34 ; bg
	.db $2b, $15, $27, $30, $04, $14, $24, $34, $04, $14, $24, $34, $04, $14, $24, $34 ; sprites
	
text_TheLicc:
	.db $1d, $31, $2e, $24, $15, $32, $2c, $2c, $ff ; "THE LICC"
	
text_Adggfjggfafafafa:
	.db $2a, $2d, $30, $30, $2f, $33, $30, $30, $2f, $2a, $2f, $2a, $2f, $2a, $2f  ; "ADGGFJGGFAFAFAFA 4/11/2020"
	.db $2a, $24, $04, $27, $01, $03, $27, $02, $00, $02, $00, $ff
	
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