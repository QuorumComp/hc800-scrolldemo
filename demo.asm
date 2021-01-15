		INCLUDE	"lowlevel/hc800.i"
		INCLUDE	"lowlevel/memory.i"

		IMPORT	ColorTable1
		IMPORT	ColorTable2
		IMPORT	ColorTableP

		SECTION	"Init",CODE
Init::		
		push	hl

		; turn off video

		ld	b,IO_VIDEO_BASE
		ld	c,IO_VIDEO_CONTROL
		ld	t,0
		lio	(bc),t

		; initialize memory ranges

		ld	bc,$8000
		ld	t,$FF
		ld	(bc),t
		add	bc,1
		ld	t,$7F
		ld	(bc),t

		ld	bc,$C000
		ld	de,ATTRIBUTES_SIZEOF/2
		ld	ft,$0000
		jal	SetMemoryWords

		ld	bc,ColorTable1
		ld	de,256
		ld	ft,$0000
		jal	SetMemoryWords

		ld	bc,ColorTable2
		ld	de,256
		ld	ft,$0000
		jal	SetMemoryWords

		; initialize variables

		ld	bc,ColorTableP
		ld	t,ColorTable1>>9
		ld	(bc),t

		ld	bc,scrollerP
		ld	ft,scrollText
		ld	(bc),t
		add	bc,1
		exg	f,t
		ld	(bc),t

		ld	bc,scrollerHPos
		ld	t,0
		ld	(bc),t
		add	bc,1
		ld	(bc),t

		; initialize video

		ld	b,IO_VIDEO_BASE
		ld	c,IO_VID_PLANE0_CONTROL
		ld	t,0
		lio	(bc),t

		ld	ft,-116
		ld	c,IO_VID_PLANE0_VSCROLLL
		lio	(bc),t

		exg	f,t
		ld	c,IO_VID_PLANE0_VSCROLLH
		lio	(bc),t

		ld	c,IO_VIDEO_CONTROL
		ld	t,IO_VID_CTRL_P0EN
		lio	(bc),t

		pop	hl
		j	(hl)


		SECTION	"ProcessStep",CODE
ProcessStep::
		push	hl

		jal	rasterBars
		jal	scroller

		; raster flash
	if 0
		ld	t,$ff
		ld	f,255
		ld	bc,$8000
.flash		ld	(bc),t
		dj	f,.flash

	endc

		pop	hl
		j	(hl)


		SECTION	"ProcessStep",CODE
Cleanup::
		push	hl

		ld	bc,$C000
		ld	de,ATTRIBUTES_SIZEOF/2
		ld	ft,$0000
		jal	SetMemoryWords

		pop	hl
		j	(hl)


		SECTION	"RasterBars",CODE
rasterBars:
		push	hl

		; swap color table

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
		ld	f,6
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


		SECTION	"PlotBar",CODE

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


		SECTION	"Scroller",CODE
scroller:
		push	hl

		; increase horizontal scroll

		ld	bc,scrollerHPos
		ld	t,(bc)
		add	bc,1
		exg	f,t
		ld	t,(bc)

		add	ft,2
		ld	hl,ft		; hl = saved scroll pos for later
		exg	ft,bc
		ld	(ft),c
		sub	ft,1
		ld	(ft),b
		exg	ft,bc

		ld	b,IO_VIDEO_BASE
		ld	c,IO_VID_PLANE0_HSCROLLL
		lio	(bc),t
		exg	f,t
		ld	c,IO_VID_PLANE0_HSCROLLH
		lio	(bc),t

		; should we plot a new character?

		ld	t,f
		and	t,$F
		cmp	t,0
		j/ne	.no_plot

		; get character to plot, update scroll pointer

		ld	ft,scrollerP
		push	ft
		ld	c,(ft)
		add	ft,1
		ld	b,(ft)

		ld	ft,bc
		ld	e,(ft)	; e = character
		add	bc,1
		cmp	e,0
		ld/eq	bc,scrollText

		pop	ft
		ld	(ft),c
		add	ft,1
		ld	(ft),b

		; plot

		ld	ft,hl
		rs	ft,4
		add	t,46
		and	t,$3F
		add	ft,ft

		ld	f,$C0
		ld	(ft),e

.no_plot	pop	hl
		j	(hl)



		SECTION	"ScrollText",DATA
scrollText:	DB	"    This is the HC800 Home Computer using the RC811 processor     -",0


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

bar1:		MAKEBAR	0.58, 0.00, 0.83
bar2:		MAKEBAR	0.25, 0.25, 1.00
bar3:		MAKEBAR	0.10, 0.90, 0.10
bar4:		MAKEBAR	1.00, 1.00, 0.00
bar5:		MAKEBAR	1.00, 0.50, 0.00
bar6:		MAKEBAR	1.00, 0.00, 0.00



		SECTION	"DemoVars",BSS
barIndex:	DS	1
scrollerHPos:	DS	2
scrollerP:	DS	2
