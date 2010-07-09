/*
 *  Tests 32 bit BMU operations
 */

.data
input_0:
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

input_1:
        .word 16
        .word 17
        .word 18
        .word 19
        .word 20
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
      | ldimm16 $ptr5, #input_0

        ldimm16 $ptr6, #input_1
      | ldimm16 $ptr7, #input_1

        ldimm16 $ptr2, #output
      | ldimm16 $acc3h, 4

        ldinc32 $ptr4, $acc1

        nop
        nop

        shiftll32 $acc1, $acc3h, $acc2
        nop
        ldimm16 $acc5h, 0x8000
      | ldimm16 $acc5l, 0x1234


        stinc32 $ptr2, $acc2
        nop
        shiftra32 $acc5, $acc3h, $acc7
        shiftrl32 $acc5, $acc3h, $acc6
        nop
        nop
        nop

        halt
