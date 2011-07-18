/*
 *  Dot product of 16 elements
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
        ldimm16 #input, $ptr4
      | ldimm16 #input, $ptr3
        ldimm16 #output, $ptr2 

        nop
        /* Loop prologue */
        ldinc32 $ptr4, $acc1
      | ldinc32 $ptr3, $acc0

        ldimm16 7, $ptr7
	mvts16 $ptr7, $bkrepcnt
	nop
        /* Loop kernel */
        bkrep #loop_end

        mpy16 $acc1l, $acc0l, $acc2
      | mpy16 $acc1h, $acc0h, $acc3
      | ldinc32 $ptr4, $acc1
      | ldinc32 $ptr3, $acc0
        nop
loop_end:
        nop
        add32 $acc6, $acc2, $acc6
      | add32 $acc7, $acc3, $acc7
        /* Loop body ends here */

        nop
        nop
        add32 $acc6, $acc7, $acc0
        nop
        nop
        st32 $acc0, $ptr2

        halt
