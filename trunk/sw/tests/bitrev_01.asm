/*
 *  Loads array (16-bits at a time) in bit-reversed order and stores normal (i.e. bit-reversing the order)
 *  Requires (from config.v): AJARDSP_CONFIG_ENABLE_ACCRF_BYPASS
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
        ldimm16 #input, $ptr0
      | ldimm16 #output, $ptr1

        ldimm16 0x0001, $acc0l
      | ldimm16 0x0800, $acc0h

        mvts16 $acc0l, $modsel
        mvts16 $acc0h, $mod0

        ldimm16 0x0001, $acc0l
      | ldimm16 0xf800, $acc0h

        mvts16 $acc0l, $masksel
        mvts16 $acc0h, $mask0

        ldimm16 0x0001, $acc0l
        mvts16 $acc0l, $bitrev
        nop

        /* Loop prologue */

        ldimm16 31, $ptr7
	mvts16 $ptr7, $bkrepcnt
	nop
        /* Loop kernel */
        bkrep #loop_end

        /* Loop body begins here */
        ldinc16 $ptr0, $acc1l
        stinc16 $acc1l, $ptr1
        nop
loop_end:
        nop
        nop
        /* Loop body ends here */

        nop
        halt
