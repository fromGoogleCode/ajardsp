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
        ldimm16 0xf001, $ptr1
        ldimm16 0x0004, $ptr0
        ldimm16 0x0000, $acc1h
        ldimm16 0x0000, $acc1l
        stext32 $acc1, $ptr0, $ptr1

        ldimm16 0xf001, $ptr1
        ldimm16 0x0000, $ptr0
        ldimm16 0x0001, $acc1l
        stext32 $acc1, $ptr0, $ptr1

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
        addptr16 0x2, $ptr1
loop_clear_end:
        nop
        nop

loop_wait:
        bra #loop_wait
