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
 