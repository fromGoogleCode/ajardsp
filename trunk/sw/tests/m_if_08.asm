.code
	or32 $acc0, $acc1, $acc2
.data
	.word 0xcafe
       	.word 0xbabe
.code
        xor32 $acc0, $acc0, $acc0
        xor32 $acc1, $acc1, $acc1
      | ldimm16 $ptr6, 0x0400
        /* Fill pattern in SDRAM */
        ldimm16 $ptr0, 0x0000
      | ldimm16 $ptr1, 0xf000
        ldimm16 $ptr2, 0x0000
        ldimm16 $acc1l, 0x0000
        ldimm16 $acc1h, 0x0000

        ldimm16 $acc1l, 0x1111
        ldimm16 $acc1h, 0x2222

        mvts16 $ptr6, $bkrepcnt
        ldimm16 $ptr2, 0x0000
        nop
        bkrep #loop_init_end
        stext32  $ptr0, $ptr2, $acc1
      	addptr16 $ptr0, 2
        mv16 $ptr0, $acc1l
 	addptr16 $ptr0, 2
        mv16 $ptr0, $acc1h
        nop
loop_init_end:
        nop
        nop


        /* Read back for verify */


        ldimm16 $ptr6, 0x00ff
        nop
        mvts16 $ptr6, $bkrepcnt
        ldimm16 $ptr0, 0x0000
        ldimm16 $ptr2, 0x0000
        ldimm16 $ptr3, 0x0000
        nop
        bkrep #loop_init_end_6

        ldext32  $ptr0, $ptr2, $acc1
/*
        mv16 $ptr0, $acc1l
        mv16 $ptr0, $acc1h
*/
        nop
        nop
      	addptr16 $ptr0, 4
        stinc32 $ptr3, $acc1
        nop
loop_init_end_6:
        nop
        nop

        halt


