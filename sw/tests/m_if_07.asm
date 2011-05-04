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

        ldimm16 $acc1h, 0x0100
        ldimm16 $acc1l, 0x0001

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

        ldimm16 $acc1h, 0x0002
        ldimm16 $acc1l, 0x0100
        ldimm16 $ptr2, 0x0001
        nop
        mvts16 $ptr6, $bkrepcnt
        nop
        bkrep #loop_init_end2
        stext32  $ptr0, $ptr2, $acc1
      	addptr16 $ptr0, 4
        nop
loop_init_end2:
        nop
        nop

        nop

        ldimm16 $acc1h, 0x0102
        ldimm16 $acc1l, 0x0404
        ldimm16 $ptr2, 0x0002
        nop
        mvts16 $ptr6, $bkrepcnt
        nop
        bkrep #loop_init_end3
        stext32  $ptr0, $ptr2, $acc1
      	addptr16 $ptr0, 4
        nop
loop_init_end3:
        nop
        nop

        nop
        ldimm16 $acc1h, 0x0000
        ldimm16 $acc1l, 0x0606
        ldimm16 $ptr2, 0x0003
        nop
        mvts16 $ptr6, $bkrepcnt
        nop
        bkrep #loop_init_end4
        stext32  $ptr0, $ptr2, $acc1
      	addptr16 $ptr0, 4
        nop
loop_init_end4:
        nop
        nop

        ldimm16 $acc1h, 0x0102
        ldimm16 $acc1l, 0x0707
        ldimm16 $ptr2, 0x0004
        nop
        mvts16 $ptr6, $bkrepcnt
        nop
        bkrep #loop_init_end5
        stext32  $ptr0, $ptr2, $acc1
      	addptr16 $ptr0, 4
        nop
loop_init_end5:
        nop
        nop



        /* Start the VGA ctrl. */
        stext32 $ptr2, $ptr1, $acc1

        /* Start the VGA ctrl. */
        ldimm16 $ptr1,  0xf001
        ldimm16 $ptr0,  0x0000
        ldimm16 $acc1l, 0x0001
        nop
        stext32 $ptr0, $ptr1, $acc1




        ldimm16 $ptr6, 0x0200
        nop
        mvts16 $ptr6, $bkrepcnt
        ldimm16 $ptr0, 0x0000
        ldimm16 $ptr2, 0x0000
        ldimm16 $ptr3, 0x0000
        nop
        bkrep #loop_init_end_6
        ldext32  $ptr0, $ptr2, $acc1
      	addptr16 $ptr0, 4
        stinc32 $ptr3, $acc1
        nop
loop_init_end_6:
        nop
        nop




foreverever:

        ldimm16 $ptr0,  0x0004
        ldimm16 $acc1h, 0x0000
       | ldimm16 $acc1l, 0xe000
        nop
        stext32 $ptr0, $ptr1, $acc1
        ldimm16 $acc1l, 0x0000
        nop
        stext32 $ptr0, $ptr1, $acc1

/*        bra #foreverever */
        nop
        nop


        halt


