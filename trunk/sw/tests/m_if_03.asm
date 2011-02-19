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
        stext32  $ptr0, $ptr2, $acc0
       	addptr16 $ptr0, 2
loop_init_end:
        nop
        nop



loop_forever:
        mvts16 $ptr6, $bkrepcnt
        ldimm16 $ptr0, 0x0000
        bkrep #loop_run_end
        ldext32  $ptr0, $ptr2, $acc0
        nop
        nop
        nop
        nop
        nop
        stext32  $ptr0, $ptr1, $acc0
       	addptr16 $ptr0, 1
loop_run_end:
        nop
        nop

        bra #loop_forever
        nop
        nop
        halt
