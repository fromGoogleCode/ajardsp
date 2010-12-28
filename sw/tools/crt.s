.code
        bra #start
        nop
        nop
int_vec:
        nop
        reti
        nop
        nop
start:
        ldimm16 $ptr7, 0x1000
        nop
        mvts16 $ptr7, $sp
        call #main
        nop
        nop
        halt
        nop
        nop
        nop

