/*
 *  Dot product of 32 elements. Fast version.
 *  Requires (from config.v): AJARDSP_CONFIG_ENABLE_ACCRF_BYPASS and AJARDSP_CONFIG_ENABLE_PTRRF_BYPASS
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
        ldimm16 #input_0, $ptr4
      | ldimm16 #input_0, $ptr5
			         
        ldimm16 #output,  $ptr2

        /* Loop prologue */
        ldinc32 $ptr4, $acc1
      | ldinc32 $ptr5, $acc0
        nop
        nop

        ldimm16 3, $ptr3
	mvts16 $ptr3, $bkrepcnt
	nop
        /* Loop kernel */
        bkrep #loop_end

        /* Loop body begins here */

        mac16 $acc1l, $acc0l, $acc4
      | mac16 $acc1h, $acc0h, $acc5
      | ldinc32 $ptr4, $acc1
      | ldinc32 $ptr5, $acc0

        mac16 $acc1l, $acc0l, $acc6
      | mac16 $acc1h, $acc0h, $acc7
      | ldinc32 $ptr4, $acc1
      | ldinc32 $ptr5, $acc0

loop_end:
        mac16 $acc1l, $acc0l, $acc4
      | mac16 $acc1h, $acc0h, $acc5
      | ldinc32 $ptr4, $acc1
      | ldinc32 $ptr5, $acc0

        mac16 $acc1l, $acc0l, $acc6
      | mac16 $acc1h, $acc0h, $acc7
      | ldinc32 $ptr4, $acc1
      | ldinc32 $ptr5, $acc0

        /* Loop body ends here */

        nop

        add32 $acc4, $acc5, $acc0
        add32 $acc6, $acc7, $acc1
        nop
        nop
        add32 $acc0, $acc1, $acc0
        nop
        nop
        st32 $acc0, $ptr2

        halt
