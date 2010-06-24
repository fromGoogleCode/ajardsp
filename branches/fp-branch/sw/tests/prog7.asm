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
        push16 $retpc
        call #foobar2
        nop
        nop
        pop16 $retpc
        nop
	rets
        mvfs16 $acc4h, $sp
        mvfs16 $acc4h, $sp
	nop


