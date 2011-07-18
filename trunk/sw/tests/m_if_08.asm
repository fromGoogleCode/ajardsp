.code
	or32 $acc0, $acc1, $acc2
.data
	.word 0xcafe
       	.word 0xbabe
.code
        xor32 $acc0, $acc0, $acc0
        xor32 $acc1, $acc1, $acc1
      | ldimm16 0x0400, $ptr6
        /* Fill pattern in SDRAM */
        ldimm16 0x0000, $ptr0
      | ldimm16 0xf000, $ptr1
        ldimm16 0x0000, $ptr2
        ldimm16 0x0000, $acc1l
        ldimm16 0x0000, $acc1h

        ldimm16 0x1111, $acc1l
        ldimm16 0x2222, $acc1h

        mvts16 $ptr6, $bkrepcnt
        ldimm16 0x0000, $ptr2
        nop
        bkrep #loop_init_end
        stext32  $acc1, $ptr0, $ptr2
      	addptr16 2, $ptr0
        mv16 $ptr0, $acc1l
 	addptr16 2, $ptr0
        mv16 $ptr0, $acc1h
        nop
loop_init_end:
        nop
        nop


        /* Read back for verify */


        ldimm16 0x00ff, $ptr6
        nop
        mvts16 $ptr6, $bkrepcnt
        ldimm16 0x0000, $ptr0
        ldimm16 0x0000, $ptr2
        ldimm16 0x0000, $ptr3
        nop
        bkrep #loop_init_end_6

        ldext32  $ptr0, $ptr2, $acc1
/*
        mv16 $ptr0, $acc1l
        mv16 $ptr0, $acc1h
*/
        nop
        nop
      	addptr16 4, $ptr0
        stinc32 $acc1, $ptr3
        nop
loop_init_end_6:
        nop
        nop

        halt


