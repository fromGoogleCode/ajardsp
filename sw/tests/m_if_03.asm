.code
	or32 $acc0, $acc1, $acc2
.data
	.word 0xcafe
       	.word 0xbabe
.code
        xor32 $acc0, $acc0, $acc0
        xor32 $acc1, $acc1, $acc1
      | ldimm16 0x1ff, $ptr6
        /* Fill pattern in SDRAM */
        ldimm16 0x0000, $ptr0
      | ldimm16 0xf000, $ptr1
        ldimm16 0x0000, $ptr2
        ldimm16 0x0001, $acc1l



        mvts16 $ptr6, $bkrepcnt
        nop
        bkrep #loop_init_end
        stext32  $acc0, $ptr0, $ptr2
       	addptr16 2, $ptr0
        add32    $acc0, $acc1, $acc0
loop_init_end:
        nop
        nop



loop_forever:
        mvts16 $ptr6, $bkrepcnt
        ldimm16 0x0000, $ptr0
        ldimm16 0x0000, $ptr3
        nop
        bkrep #loop_run_end
        ldext32  $ptr0, $ptr2, $acc0
        nop
        nop
        nop
        nop
        nop
        stext32  $acc0, $ptr3, $ptr1
       	addptr16 2, $ptr0
	addptr16 1, $ptr3
loop_run_end:
        nop
        nop

        bra #loop_forever
        nop
        nop
        halt
