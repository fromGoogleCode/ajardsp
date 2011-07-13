.code
	or32 $acc0, $acc1, $acc2
.data
	.word 0x0000
       	.word 0x0000
        .word 0x4400
       	.word 0x5566
       	.word 0x1111
.code


        /* Start the VGA ctrl. */

        xor32 $acc1, $acc1, $acc1
        ldimm16 $ptr1,  0xf001
        ldimm16 $ptr0,  0x0004
        ldimm16 $acc1h, 0x0000
        ldimm16 $acc1l, 0x0000
        nop
        nop
        stext32 $ptr0, $ptr1, $acc1

        ldimm16 $ptr1,  0xf001
        ldimm16 $ptr0,  0x0000
        ldimm16 $acc1l, 0x0001
        nop
        nop
        stext32 $ptr0, $ptr1, $acc1

        xor32 $acc0, $acc0, $acc0
        ldimm16 $ptr0,  0x0000
        nop
        st32 $ptr0, $acc0

        /* Clear frame buffer */
        ldimm16 $ptr2,  0x0008
        ldimm16 $ptr1,  0x0000
      | ldimm16 $ptr0,  0xfff0
        mvts16 $ptr2, $bkrepcnt
        ldimm16 $acc0l, 0x0000
      | ldimm16 $acc0h, 0x0000
        ldimm16 $acc1l, 0xfff0
      | ldimm16 $acc1h, 0x0000

        nop
        bkrep #loop_clear_end
        extburst 0x05, $ptr0, $ptr1, $acc0
        add32 $acc0, $acc1, $acc0
loop_clear_end:
        nop
        nop

forever:
        /* Read from ADC */
        ldimm16 $acc0l, 0x0000
      | ldimm16 $acc0h, 0xe000
        ldimm16 $ptr0,  200
      | ldimm16 $ptr1,  0x0000

        extburst 0x02, $ptr0, $ptr1, $acc0

        /* Write to VGA memory */
        ldimm16 $acc0l, 0x0000
      | ldimm16 $acc0h, 0x0001
        ldimm16 $ptr0,  0x0100
      | ldimm16 $ptr1,  0x0000
        ldimm16 $ptr3,  0x0000
/*
        extburst 0x07, $ptr0, $ptr1, $acc0
*/
        /* Write the graph */
        ldimm16 $acc7l, 0xffff
        ldimm16 $acc7h, 0xffff
        ldimm16 $ptr0,  200
        ldimm16 $acc1l, 200
        ldimm16 $acc2h, 0
        mvts16 $ptr0, $bkrepcnt
        nop
        bkrep #loop_graph
        ldinc32 $ptr3, $acc0
        mv16  $ptr3, $acc2l
        mpy16 $acc1l, $acc0l, $acc0
        nop
        add32 $acc0, $acc2, $acc0
        nop
loop_graph:
        mv16 $acc0l, $ptr0
      | mv16 $acc0h, $ptr1
        stext32 $ptr0, $ptr1, $acc7

        bra #forever

        nop
        nop
        halt
        nop
        nop
