// This file is part of AjarDSP
//
// Copyright (c) 2010, 2011 Markus Lavin
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// 3. Neither the name of the <ORGANIZATION> nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

`timescale   1 ns / 1 ps

module tb;

   reg clk, rst;

   wire ddr_clk, ddr_clk_n;
   wire ddr_cke;
   wire [2:0] ddr_cmd;
   wire [15:0] ddr_data;
   wire [1:0]  ddr_dqs;
   wire [12:0] ddr_addr;
   wire [1:0]  ddr_ba;

   wire        ras, cas, we;
   wire        cs;

   wire        ldm, udm;
   wire        ldqs, udqs;

   reg [15:0]  cnt_r;


   soc_top soc_top_0(
                     .CLK_50_MHZ(clk),
                     .RST(rst),

                     .SD_A(ddr_addr),
                     .SD_DQ(ddr_data),
                     .SD_BA(ddr_ba),
                     .SD_CAS(cas),
                     .SD_CK_N(ddr_clk_n),
                     .SD_CK_P(ddr_clk),
                     .SD_CKE(ddr_cke),
                     .SD_CS(cs),
                     .SD_LDM(ldm),
                     .SD_LDQS(ldqs),
                     .SD_RAS(ras),
                     .SD_UDM(udm),
                     .SD_UDQS(udqs),
                     .SD_WE(we),
                     .SD_CK_FB(ddr_clk),

                     .SW(0),
                     .BTN_NORTH(0),
                     .BTN_EAST(0),
                     .BTN_SOUTH(0),
                     .LED(),

                     .ADC_MISO(cnt_r[5])
                     );


   ddr ddr_0(.Clk(ddr_clk),
             .Clk_n(ddr_clk_n),
             .Cke(ddr_cke),
             .Cs_n(cs),
             .Ras_n(ras),
             .Cas_n(cas),
             .We_n(we),
             .Ba(ddr_ba),
             .Addr(ddr_addr),
             .Dm({udm, ldm}),
             .Dq(ddr_data),
             .Dqs({udqs, ldqs}));


   initial begin
      $dumpvars;
      rst = 1;
      clk = 0;
      #200;
      rst = 0;

      #1500000;

      $finish;
   end

   always @(posedge clk)
     begin
        if (rst)
          cnt_r <= 0;
        else
          cnt_r <= cnt_r + 1;
     end

   always clk = #10 ~clk;

endmodule

