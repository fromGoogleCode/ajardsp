# AjarDSP #

AjarDSP (_ajar_ as in slightly open) is an open source implementation of a synthesizable 16-bit dual-mac VLIW DSP with accompanying tools.

## Background ##
The goal of the the AjarDSP project is to create a free open source
digital signal processor accompanied with a open source tool chain.
The DSP itself is intended to be simple, pure and reasonably small.
The design is cache-less and the DSP operates entirely on its internal
memories. Its primary purpose is SoC integration but it can also
operate stand alone. The DSP is designed to be of
the '16-bit dual-mac' class, meaning that the execution units and data
paths are dimensioned so that it can multiply and accumulate two
16-bit integer pairs every clock cycles as well as fetching four
16-bit operands from memory.

The AjarDSP core is implemented in synthesizeable Verilog HDL.

## Why? ##
There are many open source CPU implementations floating around on the
net but most of these are generic CPUs (many very similar to MIPS/DLX)
and while perfectly suitable for generic tasks they are for the same
reasons less suitable for the specific task of high performance digital signal
processing. Few open source DSPs can be found and those that can be
found are often re-implementations of existing commercial machines that are
either out-dated or subject legal issues for its users. Anyway, these
are the authors observations. They may or may not be accurate...

## Architecture ##

The major blocks of AjarDSP are depicted in the diagram below (with
some reservations when it comes to the interconnect shown)

![http://ajardsp.googlecode.com/svn/trunk/doc/ajardsp-blocks.png](http://ajardsp.googlecode.com/svn/trunk/doc/ajardsp-blocks.png)

## Status ##
  * Basic test suite working


## Future/Roadmap ##
http://code.google.com/p/ajardsp/wiki/roadmap

## Synthesis ##
http://code.google.com/p/ajardsp/wiki/synthesis

# AjarDSP tools #

### ajardsp-asm ###
Fulfills its purpose..

### simdebug ###
A graphical front end to the RTL simulation (using Verilog PLI / VPI). Shows the contents of the different pipelines and allows for single stepping and modifying of architectural DSP registers and DMEM contents. Changes are highlighted in red.

![http://ajardsp.googlecode.com/svn/wiki/images/simdebug-001.png](http://ajardsp.googlecode.com/svn/wiki/images/simdebug-001.png)

### ajardsp-gcc ###
Based on gcc 4.4.5. Work has started but lots of work remains before it is useful. See http://code.google.com/p/ajardsp/wiki/gcc.

## Getting started ##
See the sources-tab for information on how to obtain the source code and then follow the instructions in the Getting started guide http://code.google.com/p/ajardsp/wiki/started. Join the AjarDSP discussion group http://groups.google.com/group/ajardsp.