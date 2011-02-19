.code
	or32 $acc0, $acc1, $acc2
.data
	.word 0xcafe
       	.word 0xbabe
.code
        ldimm16 $ptr5, 0x0000
        ldimm16 $ptr3, 0xf000
      | ldimm16 $ptr4, 0x7f
        ldimm16 $acc3l, 0x7f
      | ldimm16 $acc3h, 0x0
        xor32 $acc4, $acc4, $acc4
        nop
        ldimm16 $acc4l, 0x3f
        nop
        nop
loop:
        nop
        nop
        nop
        mv16 $ptr4, $acc3l
        and32 $acc3, $acc4, $acc3
        nop
        nop
      stext32 $ptr4, $ptr5, $acc3
      nop
      nop
      nop
      nop
      ldext32 $ptr4, $ptr5, $acc7
      nop
      nop
      nop

        stext32 $ptr4, $ptr3, $acc7
	addptr16 $ptr4, 1
	bra #loop
	nop
        nop
        nop
	halt
