.code
	or32 $acc0, $acc1, $acc2
.data
	.word 0xcafe
       	.word 0xbabe
.code
loop_forever_start:
        xor32 $acc0, $acc0, $acc0
        xor32 $acc3, $acc3, $acc3
      | ldimm16 $ptr3, 0x000
        ldimm16 $ptr6, 0x1ff
        /* Fill pattern in SDRAM */
        ldimm16 $ptr0, 0x0000
      | ldimm16 $ptr1, 0xf000
        ldimm16 $ptr2, 0xe000

        ldimm16 $acc3h, 768

        mvts16 $ptr6, $bkrepcnt
        nop
        bkrep #loop_init_end
        ldext32  $ptr3, $ptr2, $acc0
        nop
        nop
        nop
/*        shiftrl32 $acc0, $acc3h, $acc0 */
        sub16 $acc0l, $acc3h
        nop
        nop
        stext32  $ptr0, $ptr1, $acc0
       	addptr16 $ptr0, 1
loop_init_end:
        nop
        nop
        bra #loop_forever_start
        nop
        nop

        halt
