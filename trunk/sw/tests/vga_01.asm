.code
	or32 $acc0, $acc1, $acc2
.data
	.word 0xcafe
       	.word 0xbabe
.code
        xor32 $acc0, $acc0, $acc0
        xor32 $acc1, $acc1, $acc1
      | ldimm16 0xffff, $ptr6
        /* Fill pattern in SDRAM */
        ldimm16 0x0000, $ptr0
      | ldimm16 0xf000, $ptr1
        ldimm16 0x0000, $ptr2
        ldimm16 0x0000, $acc1l
        ldimm16 0x0000, $acc1h

        ldimm16 0x0102, $acc1h
        ldimm16 0x0304, $acc1l

        mvts16 $ptr6, $bkrepcnt
        ldimm16 0x0000, $ptr2
        nop
        bkrep #loop_init_end
        stext32  $acc1, $ptr0, $ptr2
      	addptr16 4, $ptr0
        nop
loop_init_end:
        nop
        nop

        ldimm16 0x6466, $acc0l
        ldimm16 0x7954, $acc0h
        ldimm16 0x0000, $ptr0
        mvts16 $ptr6, $bkrepcnt
        nop

        /* Clear console */
        bkrep #loop_init_end2
        stext32  $acc0, $ptr0, $ptr1
        nop
      	addptr16 4, $ptr0
        nop
loop_init_end2:
        mv16 $ptr0, $acc0l
        nop




        ldimm16 0x0010, $ptr2
        nop
        nop

        /* Start the VGA ctrl. */
        ldimm16 0xf001, $ptr1 
        ldimm16 0x0000, $ptr0
        ldimm16 0x0001, $acc1l
        nop
        stext32 $acc1, $ptr0, $ptr1

        nop
        nop

loop_forever:
        nop
        bra #loop_forever



        halt


