PATTERN_LENGTH	= 32
TEMPO		= 34

	;*****************************************************************
	; pause music
	;*****************************************************************

set_color_and_pause_music:
	sta $900f
pause_music:
	sei
	lda #1
	bne vicregs	; always branches

	;*****************************************************************
	; resume music
	;*****************************************************************

resume_music:
	lda #0
vicregs:sta vic_bass
	sta vic_alto
	sta vic_soprano
	sta vic_noise
	sta mute_music
	cli
	rts

	;*****************************************************************
	; music interrupt handler
	;*****************************************************************

irq:	lda tempo_counter	; increment music pos
	clc
	adc #TEMPO 
	sta tempo_counter
	bcc @skip
	; tempo counter overflow -> increment pattern row
	inc pattern_row
	lda pattern_row
	cmp #PATTERN_LENGTH	; sets carry
	bne @skip
	lda #0
	sta pattern_row
	; pattern row overflow -> increment song pos
	lda song_pos
	;clc			; carry is always set here
	adc #1
	cmp #songend-song
	bne @skips
	; song pos overflow -> loop back
	lda #0
@skips:	sta song_pos
@skip:

	lda mute_music
	bne @done

	; pattern position
	lda pattern_row
	lsr			; A = pattern position/2
	sta pattern_row2
	lda #0			; store carry in note mask 
	adc #0
	sta note_mask

	ldx song_pos		; x = song position

	; play bass
	lda song,x		; A = bass pattern
	lsr
	lsr
	lsr
	lsr
	jsr dochan
	sta vic_bass

	; play alto
	lda song,x		; A = alto pattern
	and #$f
	jsr dochan
	sta vic_alto

	; play soprano
	lda song+1,x		; A = soprano pattern
	lsr
	lsr
	lsr
	lsr
	jsr dochan
	sta vic_soprano

	; play noise
	lda song+1,x		; A = noise pattern
	and #$f
	jsr dochan
	sta vic_noise

	;inc $900f
@done:	jmp $eabf

dochan:	; in: A = pattern
	asl
	asl
	asl
	asl
	ora pattern_row2	; A = pattern * 5 | pattern_pos
	tay
	lda paterns,y		; A = packed note
	; unpack note
	ldy note_mask
	bne @low
	lsr
	lsr
	lsr
	lsr
	.byte $2c		; skip next 2 bytes
@low:	and #$0f
	tay
	lda notelut,y
	rts

	; pattern data, 240 bytes (15 patterns * 16 bytes/pattern)
paterns:
	.if MUSIC
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $30,$00,$00,$00,$30,$00,$00,$00,$30,$00,$00,$30,$00,$00,$30,$00
	.byte $30,$00,$00,$00,$30,$00,$00,$00,$30,$00,$00,$30,$00,$30,$00,$30
	.byte $00,$00,$00,$34,$50,$40,$30,$00,$22,$22,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$34,$50,$60,$50,$40,$33,$33,$00,$00,$00,$00,$00,$00
	.byte $30,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$10,$00
	.byte $30,$30,$40,$30,$00,$20,$00,$00,$00,$00,$20,$00,$50,$30,$44,$40
	.byte $30,$30,$55,$30,$00,$10,$40,$50,$00,$00,$50,$70,$88,$70,$55,$40
	.byte $00,$00,$00,$34,$50,$60,$50,$40,$33,$33,$00,$00,$33,$00,$22,$00
	.byte $00,$00,$00,$34,$50,$60,$70,$a0,$99,$99,$00,$00,$aa,$00,$99,$00
	.byte $aa,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $33,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $33,$00,$00,$00,$30,$00,$00,$00,$30,$00,$00,$30,$00,$30,$00,$30
	.byte $20,$00,$00,$00,$00,$00,$00,$20,$20,$00,$00,$00,$00,$00,$00,$00
	.byte $bb,$bb,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.endif

	; song data, 56 bytes (28 rows * 2 bytes/row)
song:	.if MUSIC
	.byte $10,$0d
	.byte $20,$0d
	.byte $10,$3d
	.byte $20,$4d
	.byte $10,$3d
	.byte $50,$4e
	.byte $16,$3d
	.byte $27,$8d
	.byte $16,$3d
	.byte $27,$9d
	.byte $16,$3d
	.byte $27,$8d
	.byte $16,$3d
	.byte $27,$9d
	.byte $ca,$ae
	.byte $16,$0d
	.byte $27,$0d
	.byte $16,$0d
	.byte $27,$0d
	.byte $16,$3d
	.byte $27,$8d
	.byte $16,$3d
	.byte $27,$9d
	.byte $16,$3d
	.byte $27,$8d
	.byte $16,$3d
	.byte $27,$9d
	.byte $ba,$ae
	.endif
songend:

	; note lookup table, 12 bytes
notelut:.byte $00,$82,$9c,$a1,$ac,$b0,$b9,$c1,$c4,$cd,$d0,$e0
