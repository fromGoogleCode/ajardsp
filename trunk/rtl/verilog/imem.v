// This file is part of AjarDSP
//
// Copyright (c) 2010, Markus Lavin
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

module imem(clk,
	    rst,
            clk_en,
            ren_i,
	    addr_i,
	    inst_o,

            ext_imem_wr_addr_i,
            ext_imem_wr_data_i,
            ext_imem_wr_en_i
            );

   input clk;
   input rst;
   input clk_en;

   input ren_i;
   input [13:0] addr_i;
   output [63:0] inst_o;

   input [15:0]  ext_imem_wr_addr_i;
   input [63:0]  ext_imem_wr_data_i;
   input         ext_imem_wr_en_i;

`ifdef SIMULATION
   reg [63:0]    imemory [0:14'h3fff];
   reg [63:0]    inst_o;

   initial begin
`ifdef IMEM_FILE
      $readmemh(`IMEM_FILE, imemory);
`else
      $readmemh("imem.hex", imemory);
`endif
   end

   always @(posedge clk)
     begin
        if (clk_en && ren_i)
          begin
	     inst_o <= imemory[addr_i];
          end
     end

`else // !`ifdef SIMULATION

   wire [31:0]   inst_low_w;
   wire [31:0]   inst_high_w;
   wire [13:0]   addr;

   assign inst_o = {inst_high_w, inst_low_w};
   assign addr = ext_imem_wr_en_i ? ext_imem_wr_addr_i[13:0] : addr_i;

   // defparam
   //   imem_ram_low.INIT_00 = 256'h000000000000000000000000000000000000000000000000000000e2000000e2;

   RAMB16_S36 imem_ram_low(.DO(inst_low_w),
			   //.DOP(),
			   .ADDR(addr),
			   .CLK(clk),
			   .DI(ext_imem_wr_data_i[31:0]),
			   .DIP(4'h0),
			   .EN(clk_en & (ren_i | ext_imem_wr_en_i)),
			   .SSR(rst),
			   .WE(ext_imem_wr_en_i));


   // defparam
   //   imem_ram_high.INIT_00 = 256'h000000000000000000000000000000000000000000000000000000e2000000e2;

   RAMB16_S36 imem_ram_high(.DO(inst_high_w),
			    //.DOP(),
			    .ADDR(addr),
			    .CLK(clk),
			    .DI(ext_imem_wr_data_i[63:32]),
			    .DIP(4'h0),
			    .EN(clk_en & (ren_i | ext_imem_wr_en_i)),
			    .SSR(rst),
			    .WE(ext_imem_wr_en_i));



`endif // !`ifdef SIMULATION

endmodule
