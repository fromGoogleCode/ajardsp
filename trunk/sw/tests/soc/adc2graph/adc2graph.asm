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
        ldimm16 0xf001, $ptr1
        ldimm16 0x0004, $ptr0
        ldimm16 0x0000, $acc1h
        ldimm16 0x0000, $acc1l
        nop
        nop
        stext32 $acc1, $ptr0, $ptr1

        ldimm16 0xf001, $ptr1
        ldimm16 0x0000, $ptr0
        ldimm16 0x0001, $acc1l
        nop
        nop
        stext32 $acc1, $ptr0, $ptr1

        xor32   $acc0, $acc0, $acc0
        ldimm16 0x0000,$ptr0
        nop
        st32    $acc0, $ptr0

        /* Clear frame buffer */
        ldimm16 0x0008, $ptr2
        ldimm16 0x0000, $ptr1
      | ldimm16 0xfff0, $ptr0
        mvts16 $ptr2, $bkrepcnt
        ldimm16 0x0000, $acc0l
      | ldimm16 0x0000, $acc0h
        ldimm16 0xfff0, $acc1l
      | ldimm16 0x0000, $acc1h

        nop
        bkrep #loop_clear_end
        extburst 0x05, $ptr0, $ptr1, $acc0
        add32 $acc0, $acc1, $acc0
loop_clear_end:
        nop
        nop

forever:

        /* Read from ADC */
        ldimm16 0x0000, $acc0l
      | ldimm16 0xe000, $acc0h
        ldimm16 200,    $ptr0
      | ldimm16 0x0000, $ptr1

        extburst 0x02, $ptr0, $ptr1, $acc0

        /* Write the graph */
        ldimm16 0xffff, $acc7l
      | ldimm16 0xffff, $acc7h
        ldimm16 200,    $ptr0
      | ldimm16 200,    $acc1l  /* should be 800 (screen width) but we want to divide the samples by 4 */
        ldimm16 0,      $acc2l
      | ldimm16 0,      $acc2h
        ldimm16 0,      $ptr4

        mvts16 $ptr0, $bkrepcnt
        nop
        bkrep #loop_graph
        ldinc32 $ptr3, $acc0
        mv16  $ptr4, $acc2l
      | addptr16 4, $ptr4
        mpy16 $acc1l, $acc0l, $acc0
        nop
        add32 $acc0, $acc2, $acc0
        nop
loop_graph:
        mv16 $acc0l, $ptr0
      | mv16 $acc0h, $ptr1
        stext32 $acc7, $ptr0, $ptr1

        bra #forever

        nop
        nop
        halt
        nop
        nop
