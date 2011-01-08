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

        ldimm16 $acc0l, 256
      | ldimm16 $acc0h, 257
        ldimm16 $acc1l, 258
      | ldimm16 $acc1h, 259

        ldimm16 $acc4h, 256
	nop
	nop
	mvts16 $acc4h, $sp
        nop
        nop
        ldimm16 $acc4l, 0x4440
      | ldimm16 $acc4h, 0x444f
        ldimm16 $acc5l, 0x5550
      | ldimm16 $acc5h, 0x555f
        ldimm16 $acc6l, 0x6660
      | ldimm16 $acc6h, 0x666f
        ldimm16 $acc7l, 0x7770
      | ldimm16 $acc7h, 0x777f

        call #function_0
        push16 $acc0l | push16 $acc0h
        push16 $acc1l | push16 $acc1h
        nop
        pop16 $ptr3
        push16 $ptr4
	mvfs16 $acc7l, $sp | push16 $acc7h
        push16 $acc7h
	mvfs16 $acc2l, $sp | push32 $acc2
        push32 $acc0 | push32 $acc1
	call #foobar
        mvfs16 $acc4h, $sp
	mvfs16 $acc2l, $sp
	mvfs16 $acc2l, $sp
        mvts16 $acc2h, $sp
        halt
	nop
.align 4
foobar2:
	mvfs16 $acc1l, $retpc
	rets
        mvfs16 $acc4h, $retpc
        mvfs16 $acc4h, $retpc
	nop
.align 4
foobar:
        ldimm16 $ptr5, 0xbabe | push16 $retpc
        call #foobar2
        nop
        nop
        pop16 $retpc
        nop
	rets
        mvfs16 $acc4h, $sp
        mvfs16 $acc4h, $sp
	nop


.align 4
function_0:
        /* prologue - begin */
        mvfs16 $ptr7, $sp | push16 $ptr7
        push16 $retpc
        addptr16 $ptr7, -32 /* make room for locals */
        nop
        mvts16 $ptr7, $sp | mvfs16 $ptr7, $sp
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
