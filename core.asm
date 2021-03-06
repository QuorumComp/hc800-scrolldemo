		IMPORT	Init
		IMPORT	ProcessStep
		IMPORT	Cleanup

		INCLUDE	"lowlevel/hc800.i"

		INCLUDE	"stdlib/stream.i"
		INCLUDE	"stdlib/syscall.i"


		SECTION	"EntryVector",CODE[0],ROOT
		ld	ft,Entry
		j	(ft)

; Vector $28, external interrupt handler
		SECTION	"ExternalVector",CODE[$28],ROOT
		pusha
		ld	ft,HBlankHandler
		j	(ft)


		SECTION	"Entry",CODE
Entry::
		di

		jal	MmuInit

		; Disable interrupt sources
		ld	b,IO_ICTRL_BASE
		ld	c,IO_ICTRL_ENABLE
		ld	t,$7F
		lio	(bc),t

		; Enable horizontal blank interrupt source
		ld	t,IO_INT_HBLANK|IO_INT_SET
		lio	(bc),t

		jal	Init

		ei

.wait		ld	de,vBlank
		ld	t,(de)

		cmp	t,0
		j/eq	.not_vblank
		ld	t,0
		ld	(de),t

		jal	ProcessStep

.not_vblank
		; check Escape key

		ld	b,IO_KEYBOARD_BASE
		ld	c,IO_KEYBOARD_STATUS

		lio	t,(bc)
		and	t,IO_KBD_STAT_READY
		cmp	t,0
		j/eq	.wait

		ld	c,IO_KEYBOARD_DATA
		lio	t,(bc)
		cmp	t,27
		j/ne	.wait

		; Exit

		di
		jal	Cleanup

		jal	MmuExit

		ld	b,IO_ICTRL_BASE
		ld	c,IO_ICTRL_REQUEST
		ld	t,$7F
		lio	(bc),t

		ei

		sys	KExit


; -- Restore kernal MMU config
		SECTION	"MmuExit",CODE
MmuExit:
		ld	b,IO_MMU_BASE

		ld	c,IO_MMU_CONFIGURATION
		ld	t,MMU_CFG_SYS_HARVARD
		lio	(bc),t

		ld	c,IO_MMU_SYSTEM_CODE
		ld	t,$01
		lio	(bc),t

		j	(hl)


; -- Set current MMU config 
		SECTION	"MmuInit",CODE
MmuInit:
		ld	b,IO_MMU_BASE

		ld	c,IO_MMU_UPDATE_INDEX
		ld	t,2
		lio	(bc),t

		ld	c,IO_MMU_CONFIGURATION
		ld	t,0
		lio	(bc),t

		ld	c,IO_MMU_CODE_BANK2
		ld	t,BANK_PALETTE
		lio	(bc),t

		ld	c,IO_MMU_CODE_BANK3
		ld	t,BANK_ATTRIBUTE
		lio	(bc),t

		ld	c,IO_MMU_SYSTEM_CODE
		ld	t,BANK_CLIENT_CODE+0
		lio	(bc),t

		ld	c,IO_MMU_ACTIVE_INDEX
		ld	t,2
		lio	(bc),t

		j	(hl)


		SECTION	"VBlankHandler",CODE
VBlankHandler:
		ld	bc,vBlank
		ld	t,1
		ld	(bc),t
		j	(hl)


		SECTION	"HBlankHandler",CODE
HBlankHandler:
		; show next color

		ld	de,$8000
.color_lo	ld	t,$ff
		ld	(de),t
		add	de,1
.color_hi	ld	t,$ff
		ld	(de),t

		ld	b,IO_VIDEO_BASE
		ld	c,IO_VIDEO_VPOSR
		lio	t,(bc)
		add	t,2

		cmp	t,240
		j/ltu	.get_next_color
		j/ne	.exit

		; vblank
		jal	VBlankHandler
		j	.exit

.get_next_color
		exg	f,t
		ld	bc,ColorTableP
		ld	t,(bc)
		exg	f,t
		add	ft,ft

		ld	bc,ft
		ld	de,.color_lo+1

		ld	t,(bc)
		ld	(de),t
		add	bc,1
		add	de,.color_hi-.color_lo
		ld	t,(bc)
		ld	(de),t

.exit
		ld	b,IO_ICTRL_BASE
		ld	c,IO_ICTRL_REQUEST
		ld	t,IO_INT_HBLANK
		lio	(bc),t

		popa
		reti		


		SECTION	"ColorTables",BSS,ALIGN[$400]
ColorTable1::	DS	256*2
ColorTable2::	DS	256*2


		SECTION	"Variables",BSS
ColorTableP::	DS	1	; high byte of color table address to show
vBlank:		DS	1
