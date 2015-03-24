# Getting started guide for the AjarDSP project #

This page describes, in reasonable detail, how to setup the AjarDSP simulation environment environment and run the test suite.

## Prerequisites ##

To be able to run RTL simulation and build the required software please make sure that the following software packages are properly installed

  * **cver** - Currenty the only supported RTL simulator. Can be downloaded from http://sourceforge.net/projects/gplcver/ . (Note that GPL cver does not seem to work when compiled as a 64bit binary. If compiling from source on a 64bit machine use gcc flag -m32 to get a 32bit binary)
  * **flex** - Lexer generator needed by the assembler
  * **bison** - Parser generator needed by the assembler
  * **GTK+ development libraries** - GUI libraries needed by the _simdebug_ interactive debug tool.
  * **gtkwave** - waveform viewer useful for viewing waveforms produced by simulation.

## Building the tools ##

  1. Build the assembler _ajardsp-asm_ and add to path
    1. `> cd ajardsp/sw/tools/asm`
    1. `> source ./build.sourceme`
    1. ``> export PATH=$PATH:`pwd```
  1. Build the debug GUI
    1. `> cd ajardsp/sw/tools/simdebug`
    1. Update `build.source` so that `$CVER_INC` points to the cver include directory
    1. `> source ./build.sourceme`
  1. Build the target monitor
    1. `cd ajardsp/sw/tools/target`
    1. `> source ./build.sourceme`

## Running simulation ##
  1. `> cd ajardsp/sw/tests`
  1. `> ../tools/do-tests.pl`
  1. Verify that you get output similar to:

```
Assembling 'prog10.asm'                                          [PASSED]
RTL simulation of DSP with input 'prog10.asm'       cycles=57    [PASSED]
Verifying DMEM contents after 'prog10.asm'                       [PASSED]

Assembling 'prog11.asm'                                          [PASSED]
RTL simulation of DSP with input 'prog11.asm'       cycles=79    [PASSED]
Verifying DMEM contents after 'prog11.asm'                       [PASSED]

Assembling 'prog12.asm'                                          [PASSED]
RTL simulation of DSP with input 'prog12.asm'       cycles=52    [PASSED]
Verifying DMEM contents after 'prog12.asm'                       [PASSED]

Assembling 'prog13.asm'                                          [PASSED]
RTL simulation of DSP with input 'prog13.asm'       cycles=38    [PASSED]
Verifying DMEM contents after 'prog13.asm'                       [PASSED]

Assembling 'prog5.asm'                                           [PASSED]
RTL simulation of DSP with input 'prog5.asm'        cycles=19    [PASSED]

Assembling 'prog6.asm'                                           [PASSED]
RTL simulation of DSP with input 'prog6.asm'        cycles=46    [PASSED]

Assembling 'prog7.asm'                                           [PASSED]
RTL simulation of DSP with input 'prog7.asm'        cycles=44    [PASSED]

Assembling 'prog8.asm'                                           [PASSED]
RTL simulation of DSP with input 'prog8.asm'        cycles=122   [PASSED]
Verifying DMEM contents after 'prog8.asm'                        [PASSED]

Assembling 'prog9.asm'                                           [PASSED]
RTL simulation of DSP with input 'prog9.asm'        cycles=82    [PASSED]
Verifying DMEM contents after 'prog9.asm'                        [PASSED]

Statistics:
Assembler      9 passed,   0 failed
Simulation     9 passed,   0 failed
Verification   6 passed,   0 failed
```

That is it. RTL simulation of AjarDSP has now run on the `.asm` files in `ajardsp/sw/tests` and for those `.asm` files that had a corresponding `.ref` file the result (contents of DMEM after simulation) has been verified.

When simulation runs the directory `ajardsp/sw/tests/workdir` will be created. This directory contains very useful information such as _gtkwave_ viewable `verilog.dump` files that resulted from the test cases in the test suite.

By default `do-tests.pl` will "glob" all `.asm` files in the current directory. If this is not the desired behavior then specific `.asm` files can be specified on the command line. The **-debug** switch will launch the graphical debug front end. The **-target** switch will, instead of RTL simulation, run the test suite on UART connected HW.

## Running FPGA synthesis ##
The synthesis script is currently setup for the Xilinx Spartan3E FPGA (as mounted on the Spartan 3E starter kit).

Given that the Xilinx ISE WebPack tools (or similar) are already installed then just do:

  1. `> cd ajardsp/syn/xilinx-ise`
  1. `> make` - will run full flow and produce the FPGA configuration bitstream
  1. `> make download` - launches _impact_ to automatically configure the USB connected FPGA.