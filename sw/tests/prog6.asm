.data
input:
        .word 0
        .word 1
        .word 2
        .word 3
        .word 4
        .word -5
        .word -0x6
        .word 7
        .word 8
        .word 9
        .word 10
        .word 11
        .word 12
        .word 13
        .word 14
        .word 15

output:
        .skip 32
.code

        ldimm16 10, $ptr3
        nop
        nop
        ldoff16 $ptr3,-1, $acc3h
        ldoff16 $ptr3, 0, $acc3h
        ldoff16 $ptr3, 1, $acc3h
        ldoff32 $ptr3,-2, $acc7
        nop
        nop
        stoff32 $acc7, -4, $ptr3
        stoff32 $acc7,  2, $ptr3 | stoff16 $acc7h, -5,$ptr3


        ldimm16 0xffff, $acc0l
      | ldimm16 0x0000, $acc0h
        ldimm16 0xff00, $acc1l
      | ldimm16 0x0808, $acc1h
			        
        ldimm16 32,    	$acc4h
	nop
	nop
	mvts16 $acc4h, $sp
        nop
        nop

        mvts16 $acc0l, $satctrl
        mvts16 $acc0h, $satctrl
        mvts16 $acc1l, $satctrl
        mvts16 $acc1h, $satctrl
        mvts16 $acc0l, $mulsign
        push16 $satctrl
        push16 $mulsign

        ldimm16 0x1234, $acc2l
      | ldimm16 0x7fff, $acc2h

        nop
        nop
        add32 $acc2, $acc2, $acc3
        nop

        ldimm16 0xffff, $acc2l
        ldimm16 -3,     $acc2h
        nop
        nop
        mpy16 $acc2l, $acc2h, $acc5
        nop
        nop
        push32 $acc5

        halt

