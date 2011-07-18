.code
	or32 $acc0, $acc1, $acc2
.data
	.word 0xcafe
       	.word 0xbabe
.code
loop_forever_start:
        xor32 $acc0, $acc0, $acc0
        /* Fill pattern in SDRAM */
        ldimm16 0x0000, $ptr0
      | ldimm16 0x0000, $ptr1

        mvts16 $ptr6, $bkrepcnt
        nop
        bkrep #loop_init_end
        nop
        nop
        nop
        nop
        stext32  $acc0, $ptr0, $ptr1
         nop
nop
nop
nop
nop
       	addptr16 1, $ptr0
loop_init_end:
        nop
        nop

        halt
