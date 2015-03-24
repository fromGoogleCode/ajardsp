# AjarDSP-SoC introduction #

The system currently ([r60](https://code.google.com/p/ajardsp/source/detail?r=60)) contains the following blocks with interconnect as shown.

![http://ajardsp.googlecode.com/svn/trunk/doc/soc-blocks.png](http://ajardsp.googlecode.com/svn/trunk/doc/soc-blocks.png)

The DSPs are booted from external memories. When reset is released a boot vector is automatically loaded from a predefined address (defparam of wb\_ajardsp.v). The boot vector looks something like this (taken from ajardsp/sw/tests/soc/adc2graph)

```
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
```

It loads both data and code and then branches to address zero. When the last burst begins the branch instruction will already be in the fetch queue so all of the instruction memory can be overwritten.

The external memory currently used for this purpose is the on-chip RAM at address 0xD0000000.

The boot vector and the actual application code is assembled like this

```
$ ajardsp-asm -o=build/boot boot.asm
$ ajardsp-asm -o=build/adc2graph adc2graph.asm
```

and finally placed in the on-chip RAM with the wb\_debug tool

```
$ wb_debug --load-imem:build/boot.imem:0xd0000000:0x100 --load-imem:build/adc2graph.imem:0xd0000100:0x400 --load-dmem:build/adc2graph.dmem:0xd0000500:0x100 --w32:0xc0000004:0x1
```

Note the write to address 0xC0000004 (misc. block) that releases reset signal for DSP 0.

A simple sanity check can be to operate the LED register of the misc. block like this

```
$ wb_debug --w32:0xC0000000:0xA5
```

The wb\_debug tool can also be used to dump memory contents as below
```
$ wb_debug --dump:0xD0000000:0x30
0xD0000000: 0x20100097
0xD0000004: 0x20000196
0xD0000008: 0x205000A7
0xD000000C: 0x2D0001A6
0xD0000010: 0x200608D6
0xD0000014: 0x00000000
0xD0000018: 0x20400097
0xD000001C: 0x20000196
0xD0000020: 0x201000A7
0xD0000024: 0x2D0001A6
0xD0000028: 0x201608D6
0xD000002C: 0x00000000
```

The memory map can be found here http://code.google.com/p/ajardsp/source/browse/trunk/doc/soc-memmap.txt