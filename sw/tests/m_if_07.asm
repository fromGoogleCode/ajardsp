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
			       
        ldimm16 0x0100, $acc1h
        ldimm16 0x0001, $acc1l

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

        ldimm16 0x0002, $acc1h
        ldimm16 0x0100, $acc1l
        ldimm16 0x0001, $ptr2
        nop
        mvts16 $ptr6, $bkrepcnt
        nop
        bkrep #loop_init_end2
        stext32  $acc1, $ptr0, $ptr2
      	addptr16 4, $ptr0
        nop
loop_init_end2:
        nop
        nop

        nop

        ldimm16 0x0102, $acc1h
        ldimm16 0x0404, $acc1l
        ldimm16 0x0002, $ptr2
        nop
        mvts16 $ptr6, $bkrepcnt
        nop
        bkrep #loop_init_end3
        stext32  $acc1, $ptr0, $ptr2
      	addptr16 4, $ptr0
        nop
loop_init_end3:
        nop
        nop

        nop
        ldimm16 0x0000, $acc1h
        ldimm16 0x0606, $acc1l
        ldimm16 0x0003, $ptr2
        nop
        mvts16 $ptr6, $bkrepcnt
        nop
        bkrep #loop_init_end4
        stext32  $acc1, $ptr0, $ptr2
      	addptr16 4, $ptr0
        nop
loop_init_end4:
        nop
        nop

        ldimm16 0x0102, $acc1h
        ldimm16 0x0707, $acc1l
        ldimm16 0x0004, $ptr2
        nop
        mvts16 $ptr6, $bkrepcnt
        nop
        bkrep #loop_init_end5
        stext32  $acc1, $ptr0, $ptr2
      	addptr16 4, $ptr0
        nop
loop_init_end5:
        nop
        nop



        /* Start the VGA ctrl. */
        stext32 $acc1, $ptr2, $ptr1

        /* Start the VGA ctrl. */
        ldimm16 0xf001, $ptr1 
        ldimm16 0x0000, $ptr0 
        ldimm16 0x0001, $acc1l
        nop
        stext32 $acc1, $ptr0, $ptr1




        ldimm16 0x0200, $ptr6
        nop
        mvts16 $ptr6, $bkrepcnt
        ldimm16 0x0000, $ptr0
        ldimm16 0x0000, $ptr2
        ldimm16 0x0000, $ptr3
        nop
        bkrep #loop_init_end_6
        ldext32  $ptr0, $ptr2, $acc1
      	addptr16 4, $ptr0
        stinc32 $acc1, $ptr3
        nop
loop_init_end_6:
        nop
        nop




foreverever:

        ldimm16 0x0004, $ptr0
        ldimm16 0x0000, $acc1h
       | ldimm16 0xe000, $acc1l
        nop
        stext32 $acc1, $ptr0, $ptr1
        ldimm16 0x0000, $acc1l
        nop
        stext32 $acc1, $ptr0, $ptr1

/*        bra #foreverever */
        nop
        nop


        halt


