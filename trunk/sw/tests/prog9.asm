.data
input:
        .word 0
        .word 1
        .word 2
        .word 3
        .word 4
        .word 5
        .word 6
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


        ldimm16 #input,  $ptr4
      | ldimm16 #input,  $ptr3
        ldimm16 #output, $ptr2
        nop		        
        ldimm16 7,       $ptr7
	mvts16 $ptr7, $bkrepcnt
	nop
        bkrep #loop_end
        ldinc32 $ptr4, $acc1
      | ldinc32 $ptr3, $acc0
        nop
        mpy16 $acc1l, $acc0l, $acc6
      | mpy16 $acc1h, $acc0h, $acc7
        nop
        nop
        stinc32 $acc6, $ptr2
loop_end:
        nop
        stinc32 $acc7, $ptr2

        halt
