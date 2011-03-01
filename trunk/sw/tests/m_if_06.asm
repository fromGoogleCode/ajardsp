.code
	or32 $acc0, $acc1, $acc2
.data
	.word 0xcafe
       	.word 0xbabe
.code
loop_forever_start:
        xor32 $acc0, $acc0, $acc0
        /* Fill pattern in SDRAM */
        ldimm16 $ptr0, 0x0000
      | ldimm16 $ptr1, 0x0000

        mvts16 $ptr6, $bkrepcnt
        nop
        bkrep #loop_init_end
        nop
        nop
        nop
        nop
        stext32  $ptr0, $ptr1, $acc0
         nop
nop
nop
nop
nop
       	addptr16 $ptr0, 1
loop_init_end:
        nop
        nop

        halt
