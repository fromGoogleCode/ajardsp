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
        ldimm16 0x0800, $ptr7
        nop
        mvts16 $ptr7, $sp
        call #main
        nop
        nop
        halt
        nop
        nop
stop:
        bra #stop
        nop
        nop

