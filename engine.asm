music_engine_init:
	lda #$0f
    sta $4015 ;enable all the channels except dpc >:C
    
    lda #$7f ;set duty, no length counter stuff and volume f (last 4 bytes)
	sta $4000
	sta $4004
	sta $400c
	
	rts
	
music_engine_tick:

sq2_tick:

	lda #$00
	cmp pulse1Tick
	bne .music_engine_tick_new
	
	ldx pulse1Note ; reading pitch data
	lda Song, x 
	
	and #$1f
	cmp #$1f ; xxxf ffff is The Note Cut
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

	ldx pulse1Note
	lda Song, x
		
	inc pulse1Note 	
	
	cmp #$ff
	bne .music_engine_tick_new
	
	lda #$00 ; loops song back to note 0 if it gets to the last note, indicated by $ff
	sta pulse1Note
	sta pulse1Tick
	jmp .music_engine_tick_end
	
.music_engine_tick_new:
	
	inc pulse1Tick

	ldx pulse1Note ; reading tempo data 
	lda Song-1, x
	lsr a
	lsr a
	lsr a
	lsr a
	lsr a
	tax
	lda NoteLenLookupTbl, x
	cmp pulse1Tick
	bne .music_engine_tick_end
	
	lda #$00 ; goes on to the next note if we reach the relative tick that corresponds to the note's length
	sta pulse1Tick
	
.music_engine_tick_end:
	inc globalTick
	jmp sq2_tick_done

.music_engine_note_cut:
	inc pulse1Tick
	lda #$70 ;silence sq1
	sta $4000
	
	jmp .music_engine_new_note

sq2_tick_done:
	
noise_tick:
	lda #$00
	cmp noiseTick
	bne .noise_tick_new
	
	ldx noiseNote ; reading pitch data
	lda SongNoise, x 
	inc noiseNote
	
	sta $400e
		
	cmp #$ff
	bne .noise_tick_new
	
	lda #$00 ; loops song back to note 0 if it gets to the last note, indicated by $ff
	sta noiseNote
	sta noiseTick
	jmp .noise_tick_end
	
.noise_tick_new:
	inc noiseTick
	
	ldx noiseNote ; reading tempo data 
	lda SongNoise-1, x
	lsr a
	lsr a
	lsr a
	lsr a
	lsr a
	tax
	lda NoteLenLookupTbl, x
	cmp noiseTick
	bne .noise_tick_end
	
	lda #$00 ; goes on to the next note if we reach the relative tick that corresponds to the note's length
	sta noiseTick
	
.noise_tick_end:
	rts
