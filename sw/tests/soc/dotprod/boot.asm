.data
	.word 0x0000
.code
zero:
        ldimm16 0x0100, $ptr0   /* Data length */
      | ldimm16 0x0000, $ptr1
        ldimm16 0x0500, $acc0l
      | ldimm16 0xD000, $acc0h /* Data source address */

        extburst 0x03, $ptr0, $ptr1, $acc0
        nop
        nop

        ldimm16 0x0400, $ptr0  /* Code length */
      | ldimm16 0x0000, $ptr1
        ldimm16 0x0100, $acc0l
      | ldimm16 0xD000, $acc0h /* Code source address */

        extburst 0x0b, $ptr0, $ptr1, $acc0
        nop
        nop

        bra #zero
