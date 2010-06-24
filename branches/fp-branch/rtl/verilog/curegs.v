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

module curegs(clk, rst,

              satctrl_o,
              mulsign_o,

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


   input [5:0]   spec_regs_raddr_i;
   input [5:0]   spec_regs_waddr_i;
   input         spec_regs_ren_i;
   input         spec_regs_wen_i;
   input  [15:0] spec_regs_data_i;
   output [15:0] spec_regs_data_o;

   output [7:0]  satctrl_o;
   output [7:0]  mulsign_o;

   reg [7:0]    satctrl_r;
   reg [7:0]    mulsign_r;

   assign satctrl_o = satctrl_r;
   assign mulsign_o = mulsign_r;

   assign spec_regs_data_o = (spec_regs_ren_i &&
                              spec_regs_raddr_i == SPEC_REGS_ADDR_CUSATCTRL)
     ? {8'hff, satctrl_r} : 16'hzzzz;

   assign spec_regs_data_o = (spec_regs_ren_i &&
                              spec_regs_raddr_i == SPEC_REGS_ADDR_CUMULSIGN)
     ? {8'hff, mulsign_r} : 16'hzzzz;


   always @(posedge clk)
     begin
        if (rst)
          begin
             satctrl_r <= 0;
             mulsign_r <= 0;
          end
        else
          begin
             if (spec_regs_wen_i && spec_regs_waddr_i == SPEC_REGS_ADDR_CUSATCTRL)
               begin
                  satctrl_r <= {spec_regs_data_i[15] ? spec_regs_data_i[7] : satctrl_r[7],
                                spec_regs_data_i[14] ? spec_regs_data_i[6] : satctrl_r[6],
                                spec_regs_data_i[13] ? spec_regs_data_i[5] : satctrl_r[5],
                                spec_regs_data_i[12] ? spec_regs_data_i[4] : satctrl_r[4],

                                spec_regs_data_i[11] ? spec_regs_data_i[3] : satctrl_r[3],
                                spec_regs_data_i[10] ? spec_regs_data_i[2] : satctrl_r[2],
                                spec_regs_data_i[9]  ? spec_regs_data_i[1] : satctrl_r[1],
                                spec_regs_data_i[8]  ? spec_regs_data_i[0] : satctrl_r[0]};
               end

             if (spec_regs_wen_i && spec_regs_waddr_i == SPEC_REGS_ADDR_CUMULSIGN)
               begin
                  mulsign_r <= {spec_regs_data_i[15] ? spec_regs_data_i[7] : mulsign_r[7],
                                spec_regs_data_i[14] ? spec_regs_data_i[6] : mulsign_r[6],
                                spec_regs_data_i[13] ? spec_regs_data_i[5] : mulsign_r[5],
                                spec_regs_data_i[12] ? spec_regs_data_i[4] : mulsign_r[4],

                                spec_regs_data_i[11] ? spec_regs_data_i[3] : mulsign_r[3],
                                spec_regs_data_i[10] ? spec_regs_data_i[2] : mulsign_r[2],
                                spec_regs_data_i[9]  ? spec_regs_data_i[1] : mulsign_r[1],
                                spec_regs_data_i[8]  ? spec_regs_data_i[0] : mulsign_r[0]};
               end

          end
     end


endmodule

