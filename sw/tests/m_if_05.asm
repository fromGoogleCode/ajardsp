.code
	or32 $acc0, $acc1, $acc2
.data
	.word 0xcafe
       	.word 0xbabe
.code
loop_forever_start:
        xor32 $acc0, $acc0, $acc0
        xor32 $acc3, $acc3, $acc3
      | ldimm16 0x000, $ptr3
        ldimm16 0x1ff, $ptr6
        /* Fill pattern in SDRAM */
        ldimm16 0x0000, $ptr0
      | ldimm16 0xf000, $ptr1
        ldimm16 0xe000, $ptr2

        ldimm16 768, $acc3h

        mvts16 $ptr6, $bkrepcnt
        nop
        bkrep #loop_init_end
        ldext32  $ptr3, $ptr2, $acc0
        nop
        nop
        nop
/*        shiftrl32 $acc0, $acc3h, $acc0 */
        sub16 $acc3h, $acc0l
        nop
        nop
        stext32  $acc0, $ptr0, $ptr1
       	addptr16 1, $ptr0
loop_init_end:
        nop
        nop
        bra #loop_forever_start
        nop
        nop

        halt
