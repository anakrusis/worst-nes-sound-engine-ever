music_engine_init:
	lda #$0f
    sta $4015 ;enable all the channels except dpc >:C
    
    lda #$7f ;set duty, no length counter stuff and volume f (last 4 bytes)
	sta $4000
	sta $4004
	
	lda #$00
	sta pulse1Tick
	
	rts
	
music_engine_tick:

	lda currentChannel ; channelOffset is the 4 byte offset, and currentChannel is just a 1 byte offset
	asl a
	asl a
	sta channelOffset

	ldy currentChannel
	lda #$00
	cmp pulse1Tick, y
	bne .music_engine_tick_new
	
	ldx pulse1Note, y ; reading pitch data
	lda Song, x 
	
	and #$1f
	cmp #$1f ; xxxf ffff is The Note Cut
	beq .music_engine_note_cut
	
.music_engine_write_pitch:

	asl a ; multiplied by 2 because each pitch is two bytes!! >.<
	tax
	lda FreqLookupTbl, x ; pitch low
	
	ldy currentChannel
	cpy #$00
	beq .music_engine_write_pitch_low
	;ror a
	
.music_engine_write_pitch_low:
	ldy channelOffset
	sta $4002, y
	
	ldy currentChannel
	cpy #$00
	beq .music_engine_write_pitch_high
	;lsr a
	
.music_engine_write_pitch_high:
	
	ldy channelOffset
    lda FreqLookupTbl+1,x ; pitch high
    sta $4003, y
	
	lda #$7f
	sta $4000,y ; not silent sq1
	lda #$0f
    sta $4015 ; not silent triangle
	
.music_engine_new_note:
	ldy currentChannel	
	tya
	tax
	inc pulse1Note, x
	
	ldx pulse1Note, y
	lda Song, x
	
	cmp #$ff
	bne .music_engine_tick_new
	
	lda #$00 ; loops song back to note 0 if it gets to the last note, indicated by $ff
	sta pulse1Note, y
	sta pulse1Tick, y
	
.music_engine_tick_end:
	inc currentChannel
	lda currentChannel
	cmp #$03
	bne music_engine_tick
	
	inc globalTick
	jmp sq2_tick_done
	
.music_engine_tick_new:
	ldx currentChannel
	inc pulse1Tick, x

	ldx pulse1Note, y ; reading tempo data 
	lda Song-1, x
	lsr a
	lsr a
	lsr a
	lsr a
	lsr a
	tax
	lda NoteLenLookupTbl, x
	cmp pulse1Tick, y
	bne .music_engine_tick_end
	
	lda #$ff ; goes on to the next note if we reach the relative tick that corresponds to the note's length
	sta pulse1Tick, y
	jmp .music_engine_tick_end

.music_engine_note_cut:

	ldx currentChannel
	ldy channelOffset
	inc pulse1Tick, x
	
	lda #$70 ;silence sq1
	sta $4000, y
	
	cpx #$02
	beq .triangle_note_cut
	
	jmp .music_engine_new_note

.triangle_note_cut:
	lda #%00001011 ; silent triangle
	sta $4015
	jmp .music_engine_new_note
	
sq2_tick_done:
	
noise_tick:
	lda #$00
	cmp noiseTick
	bne .noise_tick_new
	
	ldx noiseNote ; reading noise period data
	lda SongNoise, x 
	inc noiseNote
	sta $400e
	
	ldx $%11111000 ; length counter for noise on note onset
	stx $400f
		
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
	
	lda #$ff ; goes on to the next note if we reach the relative tick that corresponds to the note's length
	sta noiseTick
	
.noise_tick_end:
	lda #$00
	sta currentChannel
	rts
