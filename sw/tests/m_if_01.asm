.code
	or32 $acc0, $acc1, $acc2
.data
	.word 0xcafe
       	.word 0xbabe
.code
        ldimm16 $ptr3, 0x0123
      | ldimm16 $ptr4, 0x4567
        ldimm16 $acc3l, 0x89ab
      | ldimm16 $acc3h, 0xcdef
        nop
        nop
        stext32 $ptr3, $ptr4, $acc3 
	nop
        ldext32 $ptr3, $ptr4, $acc6
        nop
        nop
	halt
