.code
	or32 $acc0, $acc1, $acc2
.data
	.word 0xcafe
.code
        ldimm16 0x0123, $ptr3 
      | ldimm16 0x4567, $ptr4 
        ldimm16 0x89ab, $acc3l
      | ldimm16 0xcdef, $acc3h
	add16 $acc3h, $acc3l
        nop
	add16 $acc3h, $acc3l
        nop
        mv16 $ptr3, $ptr5
        mv16 $ptr4, $acc6h
        nop
        nop
        mv16 $acc3h, $ptr1
        mv16 $acc3l, $acc3h
        nop
        nop

.data
	.word 0xbabe

.code
	halt

