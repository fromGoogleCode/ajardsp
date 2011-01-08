/*
 *  Floating point multiply example
 */

.data
input_0:
        .word 0xc2e0
        .word 0x42e0
        .word 0xc2e0
        .word 0x42e0
        .word 0xcafe
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

input_1:
        .word 0xbd33
        .word 0x3d33
        .word 0x3d33
        .word 0xbd33
        .word 0xbabe
        .word 21
        .word 22
        .word 23
        .word 24
        .word 25
        .word 26
        .word 27
        .word 28
        .word 29
        .word 30
        .word 31


output:
        .skip 32
.code
        ldimm16 $ptr4, #input_0
      | ldimm16 $ptr5, #input_1
        ldimm16 $ptr6, #output

        nop
        nop

        /* Loop prologue */
        ldinc16 $ptr4, $acc1l
      | ldinc16 $ptr5, $acc0l

	ldimm16 $ptr0, 4
	mvts16 $ptr0, $bkrepcnt
	nop
        /* Loop kernel */
        bkrep #loop_end

        fpadd $acc0l, $acc1l, $acc2l
        ldinc16 $ptr4, $acc1l
      | ldinc16 $ptr5, $acc0l
        nop
        nop

loop_end:
        nop
        stinc16 $ptr6, $acc2l
        nop

        halt
