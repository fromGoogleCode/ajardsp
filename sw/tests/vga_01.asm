.code
	or32 $acc0, $acc1, $acc2
.data
	.word 0xcafe
       	.word 0xbabe
.code
        xor32 $acc0, $acc0, $acc0
        xor32 $acc1, $acc1, $acc1
      | ldimm16 $ptr6, 0xffff
        /* Fill pattern in SDRAM */
        ldimm16 $ptr0, 0x0000
      | ldimm16 $ptr1, 0xf000
        ldimm16 $ptr2, 0x0000
        ldimm16 $acc1l, 0x0000
        ldimm16 $acc1h, 0x0000

        ldimm16 $acc1h, 0x0102
        ldimm16 $acc1l, 0x0304

        mvts16 $ptr6, $bkrepcnt
        ldimm16 $ptr2, 0x0000
        nop
        bkrep #loop_init_end
        stext32  $ptr0, $ptr2, $acc1
      	addptr16 $ptr0, 4
        nop
loop_init_end:
        nop
        nop

        ldimm16 $acc0l, 0x6466
        ldimm16 $acc0h, 0x7954
        ldimm16 $ptr0,  0x0000
        mvts16 $ptr6, $bkrepcnt
        nop

        /* Clear console */
        bkrep #loop_init_end2
        stext32  $ptr0, $ptr1, $acc0
        nop
      	addptr16 $ptr0, 4
        nop
loop_init_end2:
        mv16 $ptr0, $acc0l
        nop




        ldimm16 $ptr2, 0x0010
        nop
        nop

        /* Start the VGA ctrl. */
        ldimm16 $ptr1,  0xf001
        ldimm16 $ptr0,  0x0000
        ldimm16 $acc1l, 0x0001
        nop
        stext32 $ptr0, $ptr1, $acc1

        nop
        nop

loop_forever:
        nop
        bra #loop_forever



        halt


