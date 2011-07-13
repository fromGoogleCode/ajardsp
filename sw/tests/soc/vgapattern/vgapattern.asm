.code
	or32 $acc0, $acc1, $acc2
.data
	.word 0x0001
       	.word 0x0001
        .word 0x0002
       	.word 0x0002
        .word 0x0004
       	.word 0x0004
      	.word 0x0003
       	.word 0x0003
        .word 0x0007
       	.word 0x0007
        .word 0x0005
       	.word 0x0005
        .word 0x0006
       	.word 0x0006
        .word 0x0007
       	.word 0x0007

.code


        /* Start the VGA ctrl. */
        ldimm16 $ptr1,  0xf001
        ldimm16 $ptr0,  0x0004
        ldimm16 $acc1h, 0x0000
        ldimm16 $acc1l, 0x0000
        stext32 $ptr0, $ptr1, $acc1

        ldimm16 $ptr1,  0xf001
        ldimm16 $ptr0,  0x0000
        ldimm16 $acc1l, 0x0001
        stext32 $ptr0, $ptr1, $acc1

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
        addptr16 $ptr1, 0x2
loop_clear_end:
        nop
        nop

loop_wait:
        bra #loop_wait
