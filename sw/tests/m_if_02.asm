.code
	or32 $acc0, $acc1, $acc2
.data
	.word 0xcafe
       	.word 0xbabe
.code
        ldimm16 0x0000, $ptr5
        ldimm16 0xf000, $ptr3
      | ldimm16 0x7f,   $ptr4
        ldimm16  0x7f,  $acc3l
      | ldimm16  0x0,   $acc3h
        xor32 $acc4, $acc4, $acc4
        nop
        ldimm16 0x3f, $acc4l
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
      stext32 $acc3, $ptr4, $ptr5
      nop
      nop
      nop
      nop
      ldext32 $ptr4, $ptr5, $acc7
      nop
      nop
      nop

        stext32 $acc7, $ptr4, $ptr3
	addptr16 1, $ptr4
	bra #loop
	nop
        nop
        nop
	halt
