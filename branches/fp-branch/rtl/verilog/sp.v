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

module sp(clk, rst,
          sp_0_o,
          push_0_en_i,
          pop_0_en_i,
          width_0_i,
          sp_1_o,
          push_1_en_i,
          pop_1_en_i,
          width_1_i,

          spec_regs_raddr_i,
          spec_regs_waddr_i,
          spec_regs_ren_i,
          spec_regs_wen_i,
          spec_regs_data_i,
          spec_regs_data_o
          );

`include "specregs.v"

   input clk;
   input rst;

   output [15:0] sp_0_o;
   reg [15:0]    sp_0_o;
   input         push_0_en_i;
   input         pop_0_en_i;
   input [1:0]   width_0_i;

   output [15:0] sp_1_o;
   reg [15:0]    sp_1_o;
   input         push_1_en_i;
   input         pop_1_en_i;
   input [1:0]   width_1_i;

   input [5:0]   spec_regs_raddr_i;
   input [5:0]   spec_regs_waddr_i;
   input         spec_regs_ren_i;
   input         spec_regs_wen_i;
   input  [15:0] spec_regs_data_i;
   output [15:0] spec_regs_data_o;

   reg [15:0]    sp_r;

   /* push - pre dec,
      pop  - post inc */

   always @(push_0_en_i or pop_0_en_i or width_0_i or
            push_1_en_i or pop_1_en_i or width_1_i or sp_r)
     begin
        sp_0_o = sp_r;
        sp_1_o = sp_r;


        if ((push_0_en_i && pop_1_en_i) ||
            (push_1_en_i && pop_0_en_i))
          begin
`ifdef SIMULATION
             $display("Parallel push and pop is illegal combination!!!");
             $finish;
`endif
          end
        else
          begin
             if (push_0_en_i && push_1_en_i)
               begin
                  sp_0_o = sp_r - width_0_i;
                  sp_1_o = sp_r - (width_0_i + width_1_i);
               end
             else if (push_0_en_i)
               begin
                  sp_0_o = sp_r - width_0_i;
               end
             else if (push_1_en_i)
               begin
                  sp_1_o = sp_r - width_1_i;
               end
             else if (pop_0_en_i)
               begin
                  sp_1_o = sp_r + width_0_i;
               end
          end
     end

   assign spec_regs_data_o = (spec_regs_ren_i && spec_regs_raddr_i == SPEC_REGS_ADDR_SP)
     ? sp_r : 16'hzzzz;

   always @(posedge clk)
     begin
        if (rst)
          begin
             sp_r <= 0;
          end
        else
          begin
             if (spec_regs_wen_i && spec_regs_waddr_i == SPEC_REGS_ADDR_SP)
               begin
                  sp_r <= spec_regs_data_i;
               end
             else if (pop_1_en_i)
               begin
                  sp_r <= sp_1_o + width_1_i;
               end
             else if (push_1_en_i || pop_0_en_i)
               begin
                  sp_r <= sp_1_o;
               end
             else if (push_0_en_i)
               begin
                  sp_r <= sp_0_o;
               end
          end
     end // always @ (posedge clk)

endmodule // sp
