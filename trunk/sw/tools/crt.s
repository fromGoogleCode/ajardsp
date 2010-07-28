.code
        ldimm16 $ptr7, 0x1000
        nop
        nop
        mvts16 $ptr7, $sp
        call #main
        nop
        nop
        halt
