/*
 *  Dot product of 16 elements with compare branch loop
 */

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

        ldimm16 $acc5l, 8
      | ldimm16 $acc5h, 1

        /* Loop prologue */
        ldinc32 $ptr4, $acc1
      | ldinc32 $ptr3, $acc0

        nop /* needed for two cycle latency on update of $ptr registers */
        /* Loop kernel */
loop_start:
        mpy16 $acc1l, $acc0l, $acc2
      | mpy16 $acc1h, $acc0h, $acc3
      | ldinc32 $ptr4, $acc1
      | ldinc32 $ptr3, $acc0
        sub16 $acc5l, $acc5h  /* has a latency of two so result will not be used until next iteration */
        cmp16ne $acc5l, $acc5h, $pred1
        nop
        add32 $acc6, $acc2, $acc6
      | add32 $acc7, $acc3, $acc7
        if ($pred1) bra #loop_start
        /* Loop body ends here */

        nop
        nop
        add32 $acc6, $acc7, $acc0
        nop
        nop
        st32 $ptr2, $acc0

        halt
