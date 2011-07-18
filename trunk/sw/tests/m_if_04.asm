.code
	or32 $acc0, $acc1, $acc2
.data
	.word 0xcafe
       	.word 0xbabe
.code
loop_forever_start:
        xor32 $acc0, $acc0, $acc0
      | ldimm16 0x1ff, $ptr6
        /* Fill pattern in SDRAM */
        ldimm16 0x0000, $ptr0
      | ldimm16 0xf000, $ptr1
        ldimm16 0x0000, $ptr2



        mvts16 $ptr6, $bkrepcnt
        nop
        bkrep #loop_init_end
        mv16     $ptr0, $acc0l
        stext32  $acc0, $ptr0, $ptr1
       	addptr16 1, $ptr0
loop_init_end:
        nop
        nop
        bra #loop_forever_start
        nop
        nop

        halt
