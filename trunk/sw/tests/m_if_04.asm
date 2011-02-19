.code
	or32 $acc0, $acc1, $acc2
.data
	.word 0xcafe
       	.word 0xbabe
.code
        xor32 $acc0, $acc0, $acc0
      | ldimm16 $ptr6, 0x1ff
        /* Fill pattern in SDRAM */
        ldimm16 $ptr0, 0x0000
      | ldimm16 $ptr1, 0xf000
        ldimm16 $ptr2, 0x0000



        mvts16 $ptr6, $bkrepcnt
        nop
        bkrep #loop_init_end
        mv16     $ptr0, $acc0l
        stext32  $ptr0, $ptr1, $acc0
       	addptr16 $ptr0, 1
loop_init_end:
        nop
        nop

        halt
