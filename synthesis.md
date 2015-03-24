#Summary of synthesis results.

# Synthesis #

This page contains some information gathered from the synthesis reports.

## AjarDSP (trunk -[r35](https://code.google.com/p/ajardsp/source/detail?r=35)) for Spartan3E (device xc3s500e, package fg320, speed -4) ##

```
Design Summary Report:

 Number of External IOBs                          19 out of 232     8%

   Number of External Input IOBs                  3

      Number of External Input IBUFs              3
        Number of LOCed External Input IBUFs      3 out of 3     100%


   Number of External Output IOBs                16

      Number of External Output IOBs             16
        Number of LOCed External Output IOBs     16 out of 16    100%


   Number of External Bidir IOBs                  0


   Number of BUFGMUXs                        1 out of 24      4%
   Number of MULT18X18SIOs                   2 out of 20     10%
   Number of RAMB16s                         4 out of 20     20%
   Number of Slices                       4647 out of 4656   99%
      Number of SLICEMs                      1 out of 2328    1%


Design statistics:
   Minimum period:  19.947ns (Maximum frequency:  50.133MHz)
```

```
markus@markus-desktop:~/ajardsp/syn/xilinx-ise$ ../../xdlanalyze.pl build/project_r.ncd 2
XDLAnalyze V1.1 by Andreas Ehliar <ehliar@isy.liu.se>
Calling xdl -ncd2xdl to convert .ncd file to .xdl file before running analyzer
Release 12.1 - xdl M.53d (lin64)
Copyright (c) 1995-2010 Xilinx, Inc.  All rights reserved.

Loading device for application Rf_Device from file '3s500e.nph' in environment /opt/Xilinx/12.1/ISE_DS/ISE.
   "top_top" is an NCD, version 3.2, device xc3s500e, package fg320, speed -4
Successfully converted design 'build/project_r.ncd' to '/tmp/fileVeFYsV.xdl'.
Analyzing the file /tmp/fileVeFYsV.xdl...........................
+---------------------------------+--------+--------+--------+--------+
| Module                          |   LUTS |     FF | RAMB16 |    IOB |
+---------------------------------+--------+--------+--------+--------+
| /                               |     36 |    170 |        |     16 |
| ajardsp_0                       |    631 |        |        |        |
| ajardsp_0/accrf_share_0         |    111 |        |        |        |
| ajardsp_0/accrf_share_0/accrf_0 |   2901 |    320 |        |        |
| ajardsp_0/bmu_0                 |   1059 |    141 |        |        |
| ajardsp_0/cu_0                  |    414 |    262 |        |        |
| ajardsp_0/cu_0/addsub           |     46 |        |        |        |
| ajardsp_0/cu_0/mul              |      2 |        |        |        |
| ajardsp_0/cu_1                  |    408 |    262 |        |        |
| ajardsp_0/cu_1/addsub           |     46 |        |        |        |
| ajardsp_0/cu_1/mul              |      2 |        |        |        |
| ajardsp_0/curegs_0              |     22 |     16 |        |        |
| ajardsp_0/dmem_0                |     74 |        |      2 |        |
| ajardsp_0/imem_0                |     10 |        |      2 |        |
| ajardsp_0/lsu_0                 |    746 |    155 |        |        |
| ajardsp_0/lsu_0/adder_0         |     48 |        |        |        |
| ajardsp_0/lsu_1                 |    699 |    135 |        |        |
| ajardsp_0/lsu_1/adder_0         |     48 |        |        |        |
| ajardsp_0/lsuregs_0             |      8 |    112 |        |        |
| ajardsp_0/pcu_0                 |     91 |     96 |        |        |
| ajardsp_0/pred_0                |     15 |      3 |        |        |
| ajardsp_0/ptrrf_0               |    351 |    128 |        |        |
| ajardsp_0/sp_0                  |    131 |     16 |        |        |
| ajardsp_0/vliwfetch_0           |    278 |    108 |        |        |
| ajardsp_0/vliwfetch_0/vliwdec_0 |     92 |        |        |        |
| rx_0                            |     49 |     34 |        |        |
| rx_0/Mshreg_rx_bit_l2           |      1 |        |        |        |
| tx_0                            |     58 |     32 |        |        |
+---------------------------------+--------+--------+--------+--------+
| Total                           |   8377 |   1990 |      4 |     16 |
+---------------------------------+--------+--------+--------+--------+
```