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
		ld	t,0
		ld	(bc),t

		pop	hl
		j	(hl)


		SECTION	"ProcessStep",CODE
ProcessStep::
		push	hl

		ld	bc,ColorTableP
		ld	t,(bc)
		xor	t,1
		ld	(bc),t

		pop	hl
		j	(hl)
