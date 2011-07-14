.data
	.word 0x0000
.code
zero:
        ldimm16 $ptr0, 0x0100  /* Data length */
      | ldimm16 $ptr1, 0x0000
        ldimm16 $acc0l, 0x0500
      | ldimm16 $acc0h, 0xD000 /* Data source address */

        extburst 0x03, $ptr0, $ptr1, $acc0
        nop
        nop

        ldimm16 $ptr0, 0x0400  /* Code length */
      | ldimm16 $ptr1, 0x0000
        ldimm16 $acc0l, 0x0100
      | ldimm16 $acc0h, 0xD000 /* Code source address */

        extburst 0x0b, $ptr0, $ptr1, $acc0
        nop
        nop

        bra #zero
