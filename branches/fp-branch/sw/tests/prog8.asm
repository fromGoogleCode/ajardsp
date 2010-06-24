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


        ldimm16 $ptr4, #input
      | ldimm16 $ptr3, #input
        ldimm16 $ptr2, #output
        nop

        bkrep #loop_end, 15
        ldinc16 $ptr4, $acc1h
      | ldinc16 $ptr3, $acc0l
        nop
        mpy16 $acc1h, $acc0l, $acc6
      | cmpeq16 $acc0l, $acc1h, $pred2
        nop
loop_end:
        nop
        stinc32 $ptr2, $acc6

        halt
