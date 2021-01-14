		INCLUDE	"lowlevel/memory.i"

		IMPORT	ColorTable1
		IMPORT	ColorTable2
		IMPORT	ColorTableP

		SECTION	"Init",CODE
Init::		
		push	hl

		ld	bc,ColorTable1
		ld	de,256
		ld	ft,$0000
		jal	SetMemoryWords

		ld	bc,ColorTable2
		ld	de,256
		ld	ft,$001F
		jal	SetMemoryWords

		ld	bc,ColorTableP
		ld	t,ColorTable1>>9
		ld	(bc),t

		pop	hl
		j	(hl)


		SECTION	"ProcessStep",CODE
ProcessStep::
		push	hl

		ld	bc,ColorTableP
		ld	t,(bc)
		push	ft
		xor	t,1
		ld	(bc),t
		pop	ft

		; bc = color table
		add	t,t
		ld	b,t
		ld	c,0

		; clear color table
		ld	de,256
		ld	ft,$0000
		jal	SetMemoryWords

		; increment frame counter
		ld	de,barIndex
		ld	t,(de)
		add	t,1
		ld	(de),t

		; get bar position
		ld	f,7
		ld	de,bar1
.next_bar	and	t,127
		push	ft
		ld	f,0
		add	ft,barMovementTable
		ld	t,(ft)

		; plot bar
		sub	t,BAR_HEIGHT/2
		jal	plotBar

		pop	ft
		add	de,bar2-bar1
		add	t,6
		dj	f,.next_bar

		pop	hl
		j	(hl)

BAR_HEIGHT:	EQU	9

; -- Inputs:
; --    t - y pos
; --   bc - color list
; --   de - bar
plotBar:
		pusha

		ld	f,0
		add	ft,ft
		add	ft,bc
		ld	bc,ft

		ld	f,BAR_HEIGHT*2
.loop		ld	t,(de)
		ld	(bc),t
		add	de,1
		add	bc,1
		dj	f,.loop

		popa
		j	(hl)


DC_RGB:		MACRO	; r, g, b (0.0 - 1.0)
		DW	(((\1)**31)<<10)|(((\2)**31)<<5)|((\3)**31)
		ENDM

DC_COLOR:	MACRO	; r, g, b, brightness
		DC_RGB	(\1)**(\4),(\2)**(\4),(\3)**(\4)
		ENDM

MAKEBAR:	MACRO	; r, g, b
line__		SET	0
		REPT	BAR_HEIGHT
		DC_COLOR (\1),(\2),(\3),(sin(0.5*line__/(BAR_HEIGHT-1)))
line__		SET	line__+1
		ENDR
		ENDM

MAKESINE:	MACRO	; length, amplitude, bias
angle__		SET	0
		REPT	(\1)
		DB	(sin(1.0*angle__/(\1))**(\2.5))>>16+(\3)
angle__		SET	angle__+1
		ENDR
		PURGE	angle__
		ENDM

		SECTION	"SineTables",DATA
barMovementTable:
		MAKESINE 128,30,120

bar1:		MAKEBAR	0.5, 0.5, 1.0
bar2:		MAKEBAR	0.5, 1.0, 0.5
bar3:		MAKEBAR	0.5, 1.0, 1.0
bar4:		MAKEBAR	1.0, 0.5, 0.5
bar5:		MAKEBAR	1.0, 0.5, 1.0
bar6:		MAKEBAR	1.0, 1.0, 0.5
bar7:		MAKEBAR	1.0, 1.0, 1.0



		SECTION	"DemoVars",BSS
barIndex:	DS	1