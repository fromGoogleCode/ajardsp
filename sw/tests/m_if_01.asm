.code
	or32 $acc0, $acc1, $acc2
.data
	.word 0xcafe
       	.word 0xbabe
.code
        ldimm16 0x0123, $ptr3
      | ldimm16 0x4567, $ptr4
        ldimm16 0x89ab, $acc3l
      | ldimm16 0xcdef, $acc3h
        nop
        nop
        stext32 $acc3, $ptr3, $ptr4 
	nop
        ldext32 $ptr3, $ptr4, $acc6
        nop
        nop
	halt
