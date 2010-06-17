.code
        ldimm16 $ptr3, 0x0123
      | ldimm16 $ptr4, 0x4567
        ldimm16 $acc3l, 0x89ab
      | ldimm16 $acc3h, 0xcdef

        nop
        nop
        mv16 $ptr3, $ptr5
        mv16 $ptr4, $acc6h
        nop
        nop
        mv16 $acc3h, $ptr1
        mv16 $acc3l, $acc3h
        nop
        nop

        halt
