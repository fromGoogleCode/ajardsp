.code
	or32 $acc0, $acc1, $acc2
.data
	.word 0xcafe
       	.word 0xbabe
.code
        xor32 $acc0, $acc0, $acc0
        xor32 $acc1, $acc1, $acc1
      | ldimm16 $ptr6, 0x1ff
        /* Fill pattern in SDRAM */
        ldimm16 $ptr0, 0x0000
      | ldimm16 $ptr1, 0xf000
        ldimm16 $ptr2, 0x0000
        ldimm16 $acc1l, 0x0001



        mvts16 $ptr6, $bkrepcnt
        nop
        bkrep #loop_init_end
        stext32  $ptr0, $ptr2, $acc0
       	addptr16 $ptr0, 2
        add32    $acc0, $acc1, $acc0
loop_init_end:
        nop
        nop



loop_forever:
        mvts16 $ptr6, $bkrepcnt
        ldimm16 $ptr0, 0x0000
        ldimm16 $ptr3, 0x0000
        nop
        bkrep #loop_run_end
        ldext32  $ptr0, $ptr2, $acc0
        nop
        nop
        nop
        nop
        nop
        stext32  $ptr3, $ptr1, $acc0
       	addptr16 $ptr0, 2
	addptr16 $ptr3, 1
loop_run_end:
        nop
        nop

        bra #loop_forever
        nop
        nop
        halt
