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
        ldimm16 15,      $ptr7
	mvts16 $ptr7, $bkrepcnt
	nop
        bkrep #loop_end
        ldinc16 $ptr4, $acc1h
      | ldinc16 $ptr3, $acc0l
        nop
        mpy16 $acc1h, $acc0l, $acc6
      | cmp16eq $acc0l, $acc1h, $pred2
        nop
loop_end:
        nop
        stinc32 $acc6, $ptr2

        halt
