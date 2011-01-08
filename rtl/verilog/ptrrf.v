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

`include "config.v"

module ptrrf(clk,
	     rst,

	     rd_idx_0_i,
	     rd_data_0_o,

	     rd_idx_1_i,
	     rd_data_1_o,

	     wr_idx_0_i,
	     wr_en_0_i,
	     wr_data_0_i,

	     wr_idx_1_i,
	     wr_en_1_i,
	     wr_data_1_i);

   input clk;
   input rst;

   input  [2:0]  rd_idx_0_i;
   output [15:0] rd_data_0_o;

   input  [2:0]  rd_idx_1_i;
   output [15:0] rd_data_1_o;

   input [2:0] 	 wr_idx_0_i;
   input 	 wr_en_0_i;
   input [15:0]  wr_data_0_i;

   input [2:0] 	 wr_idx_1_i;
   input 	 wr_en_1_i;
   input [15:0]  wr_data_1_i;

   reg [15:0] 	 ptr_regs[0:7];

   integer       i, j;

`ifdef AJARDSP_CONFIG_ENABLE_PTRRF_BYPASS

   reg [2:0]     rd_idx_w[0:1];
   reg [15:0]    rd_data_w[0:1];

   reg [2:0]     wr_idx_w[0:1];
   reg           wr_en_w[0:1];
   reg [15:0]    wr_data_w[0:1];

   assign rd_data_0_o = rd_data_w[0];
   assign rd_data_1_o = rd_data_w[1];

   always @(rd_idx_0_i   or rd_idx_1_i   or
            wr_idx_0_i   or wr_idx_1_i   or
            wr_en_0_i    or wr_en_1_i    or
            wr_data_0_i  or wr_data_1_i  or
            ptr_regs[0]  or ptr_regs[1]  or ptr_regs[2]  or ptr_regs[3]  or
            ptr_regs[4]  or ptr_regs[5]  or ptr_regs[6]  or ptr_regs[7])
     begin

        rd_idx_w[0] = rd_idx_0_i;
        rd_idx_w[1] = rd_idx_1_i;

        wr_idx_w[0] = wr_idx_0_i;
        wr_idx_w[1] = wr_idx_1_i;

        wr_en_w[0] = wr_en_0_i;
        wr_en_w[1] = wr_en_1_i;

        wr_data_w[0] = wr_data_0_i;
        wr_data_w[1] = wr_data_1_i;


        for (i = 0; i < 2; i = i + 1)
          begin
             rd_data_w[i] = ptr_regs[rd_idx_w[i]];

             for (j = 0; j < 2; j = j + 1)
               begin
                  if (wr_en_w[j] && rd_idx_w[i] == wr_idx_w[j])
                    begin
                       rd_data_w[i] = wr_data_w[j];
                    end
               end
          end
     end

`else

   assign rd_data_0_o = ptr_regs[rd_idx_0_i];
   assign rd_data_1_o = ptr_regs[rd_idx_1_i];

`endif

   always @(posedge clk)
     begin
	if (rst)
	  begin

	     for (i = 0; i < 8; i = i + 1)
	       begin
		  ptr_regs[i] <= 0;
	       end
	  end
	else
	  begin
	     if (wr_en_0_i)
	       begin
		  ptr_regs[wr_idx_0_i] <= wr_data_0_i;
		  $display("P%d = %h", wr_idx_0_i, wr_data_0_i);
	       end

	     if (wr_en_1_i)
	       begin
		  ptr_regs[wr_idx_1_i] <= wr_data_1_i;
		  $display("P%d = %h", wr_idx_1_i, wr_data_1_i);
	       end

	  end
     end

endmodule // ptrrf
