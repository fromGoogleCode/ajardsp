.data
input:
        .word 0
        .word 1
        .word 2
        .word 3
        .word 4
        .word 5
        .word 6
        .word 7
        .word 8
        .word 9
        .word 10
        .word 11
        .word 12
        .word 13
        .word 14
        .word 15

output:
        .skip 32
.code

        ldimm16 256, $acc0l
      | ldimm16 257, $acc0h
        ldimm16 258, $acc1l
      | ldimm16 259, $acc1h
		             
        ldimm16 256, $acc4h
	nop
	nop
	mvts16 $acc4h, $sp
        nop
        nop
        ldimm16 0x4440, $acc4l
      | ldimm16 0x444f, $acc4h
        ldimm16 0x5550, $acc5l
      | ldimm16 0x555f, $acc5h
        ldimm16 0x6660, $acc6l
      | ldimm16 0x666f, $acc6h
        ldimm16 0x7770, $acc7l
      | ldimm16 0x777f, $acc7h

        call #function_0
        push16 $acc0l | push16 $acc0h
        push16 $acc1l | push16 $acc1h
        nop
        pop16 $ptr3
        push16 $ptr4
	mvfs16 $sp, $acc7l | push16 $acc7h
        push16 $acc7h
	mvfs16 $sp, $acc2l | push32 $acc2
        push32 $acc0 | push32 $acc1
	call #foobar
        mvfs16 $sp, $acc4h
	mvfs16 $sp, $acc2l
	mvfs16 $sp, $acc2l
        mvts16 $acc2h, $sp
        halt
	nop
.align 4
foobar2:
	mvfs16 $retpc, $acc1l
	rets
        mvfs16 $retpc, $acc4h
        mvfs16 $retpc, $acc4h
	nop
.align 4
foobar:
        ldimm16 0xbabe, $ptr5 | push16 $retpc
        call #foobar2
        nop
        nop
        pop16 $retpc
        nop
	rets
        mvfs16 $sp, $acc4h
        mvfs16 $sp, $acc4h
	nop


.align 4
function_0:
        /* prologue - begin */
        mvfs16 $sp, $ptr7 | push16 $ptr7
        push16 $retpc
        addptr16 -32, $ptr7 /* make room for locals */
        nop
        mvts16 $ptr7, $sp | mvfs16 $sp, $ptr7
        nop
        push16 $ptr7 /* sp before locals*/| push16 $acc0l  /* dummy align push */

        push32 $acc4| push32 $acc5
        push32 $acc6| push32 $acc7
        /* prologue - end */

        nop
        nop

        /* epilogue - begin */
        pop32 $acc7 | pop32 $acc6
        pop32 $acc5 | pop32 $acc4
        pop16 $acc0l | pop16 $sp
        nop
        pop16 $retpc | pop16 $ptr7
        rets
        nop
        nop
        /* epilogue - end */
