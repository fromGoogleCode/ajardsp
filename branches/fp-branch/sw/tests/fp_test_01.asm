/*
 *  Floating point multiply example
 */

.data
input_0:
        .word 0x3c33
        .word 0x3c34
        .word 0x3c35
        .word 0x3c36
        .word 0x3c37
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
        .word 0x3d33
        .word 0x3d34
        .word 0x3d35
        .word 0x3d36
        .word 0x3d37
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

        /* Loop kernel */
        bkrep #loop_end, 4

        fpmul $acc0l, $acc1l, $acc2l
        ldinc16 $ptr4, $acc1l
      | ldinc16 $ptr5, $acc0l
        nop
        nop

loop_end:
        nop
        stinc16 $ptr6, $acc2l
        nop

        halt
