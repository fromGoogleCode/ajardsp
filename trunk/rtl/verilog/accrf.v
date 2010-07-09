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

module accrf(clk,
             rst,

             rd_idx_0_i,
             rd_data_0_o,

             rd_idx_1_i,
             rd_data_1_o,

             rd_idx_2_i,
             rd_data_2_o,

             rd_idx_3_i,
             rd_data_3_o,

             rd_idx_4_i,
             rd_data_4_o,

             rd_idx_5_i,
             rd_data_5_o,

             rd_idx_6_i,
             rd_data_6_o,

             rd_idx_7_i,
             rd_data_7_o,

             rd_idx_8_i,
             rd_data_8_o,

             rd_idx_9_i,
             rd_data_9_o,

             wr_idx_0_i,
             wr_en_0_i,
             wr_mask_0_i,
             wr_data_0_i,

             wr_idx_1_i,
             wr_en_1_i,
             wr_mask_1_i,
             wr_data_1_i,

             wr_idx_2_i,
             wr_en_2_i,
             wr_mask_2_i,
             wr_data_2_i,

             wr_idx_3_i,
             wr_en_3_i,
             wr_mask_3_i,
             wr_data_3_i,

             wr_idx_4_i,
             wr_en_4_i,
             wr_mask_4_i,
             wr_data_4_i

             );

   input clk;
   input rst;

   input  [2:0]  rd_idx_0_i;
   output [31:0] rd_data_0_o;

   input  [2:0]  rd_idx_1_i;
   output [31:0] rd_data_1_o;

   input  [2:0]  rd_idx_2_i;
   output [31:0] rd_data_2_o;

   input  [2:0]  rd_idx_3_i;
   output [31:0] rd_data_3_o;

   input [2:0]   rd_idx_4_i;
   output [31:0] rd_data_4_o;

   input [2:0]   rd_idx_5_i;
   output [31:0] rd_data_5_o;

   input [2:0]   rd_idx_6_i;
   output [31:0] rd_data_6_o;

   input [2:0]   rd_idx_7_i;
   output [31:0] rd_data_7_o;

   input [2:0]   rd_idx_8_i;
   output [31:0] rd_data_8_o;

   input [2:0]   rd_idx_9_i;
   output [31:0] rd_data_9_o;

   input [2:0]   wr_idx_0_i;
   input         wr_en_0_i;
   input [1:0]   wr_mask_0_i;
   input [31:0]  wr_data_0_i;

   input [2:0]   wr_idx_1_i;
   input         wr_en_1_i;
   input [1:0]   wr_mask_1_i;
   input [31:0]  wr_data_1_i;

   input [2:0]   wr_idx_2_i;
   input         wr_en_2_i;
   input [1:0]   wr_mask_2_i;
   input [31:0]  wr_data_2_i;

   input [2:0]   wr_idx_3_i;
   input         wr_en_3_i;
   input [1:0]   wr_mask_3_i;
   input [31:0]  wr_data_3_i;

   input [2:0]   wr_idx_4_i;
   input         wr_en_4_i;
   input [1:0]   wr_mask_4_i;
   input [31:0]  wr_data_4_i;

   reg [15:0]    acc_regs_low[0:7];
   reg [15:0]    acc_regs_high[0:7];

   reg [4:0]     i;

   assign rd_data_0_o = {acc_regs_high[rd_idx_0_i], acc_regs_low[rd_idx_0_i]};
   assign rd_data_1_o = {acc_regs_high[rd_idx_1_i], acc_regs_low[rd_idx_1_i]};
   assign rd_data_2_o = {acc_regs_high[rd_idx_2_i], acc_regs_low[rd_idx_2_i]};

   assign rd_data_3_o = {acc_regs_high[rd_idx_3_i], acc_regs_low[rd_idx_3_i]};
   assign rd_data_4_o = {acc_regs_high[rd_idx_4_i], acc_regs_low[rd_idx_4_i]};
   assign rd_data_5_o = {acc_regs_high[rd_idx_5_i], acc_regs_low[rd_idx_5_i]};

   assign rd_data_6_o = {acc_regs_high[rd_idx_6_i], acc_regs_low[rd_idx_6_i]};
   assign rd_data_7_o = {acc_regs_high[rd_idx_7_i], acc_regs_low[rd_idx_7_i]};

   assign rd_data_8_o = {acc_regs_high[rd_idx_8_i], acc_regs_low[rd_idx_8_i]};
   assign rd_data_9_o = {acc_regs_high[rd_idx_9_i], acc_regs_low[rd_idx_9_i]};

   always @(posedge clk)
     begin
        if (rst)
          begin

             for (i = 0; i < 8; i = i + 1)
               begin
                  acc_regs_low[i]  <= 0;
                  acc_regs_high[i] <= 0;
               end
          end
        else
          begin
             if (wr_en_0_i)
               begin
                  if (wr_mask_0_i[0])
                    acc_regs_low[wr_idx_0_i] <= wr_data_0_i[15:0];
                  if (wr_mask_0_i[1])
                    acc_regs_high[wr_idx_0_i] <= wr_data_0_i[31:16];

                  $display("A%d = %h", wr_idx_0_i, wr_data_0_i);
               end

             if (wr_en_1_i)
               begin
                  if (wr_mask_1_i[0])
                    acc_regs_low[wr_idx_1_i] <= wr_data_1_i[15:0];
                  if (wr_mask_1_i[1])
                    acc_regs_high[wr_idx_1_i] <= wr_data_1_i[31:16];

                  $display("A%d = %h", wr_idx_1_i, wr_data_1_i);
               end

             if (wr_en_2_i)
               begin
                  if (wr_mask_2_i[0])
                    acc_regs_low[wr_idx_2_i] <= wr_data_2_i[15:0];
                  if (wr_mask_2_i[1])
                    acc_regs_high[wr_idx_2_i] <= wr_data_2_i[31:16];

                  $display("A%d = %h", wr_idx_2_i, wr_data_2_i);
               end

             if (wr_en_3_i)
               begin
                  if (wr_mask_3_i[0])
                    acc_regs_low[wr_idx_3_i] <= wr_data_3_i[15:0];
                  if (wr_mask_3_i[1])
                    acc_regs_high[wr_idx_3_i] <= wr_data_3_i[31:16];

                  $display("A%d = %h", wr_idx_3_i, wr_data_3_i);
               end

             if (wr_en_4_i)
               begin
                  if (wr_mask_4_i[0])
                    acc_regs_low[wr_idx_4_i] <= wr_data_4_i[15:0];
                  if (wr_mask_4_i[1])
                    acc_regs_high[wr_idx_4_i] <= wr_data_4_i[31:16];

                  $display("A%d = %h", wr_idx_4_i, wr_data_4_i);
               end


          end
     end

endmodule // accrf
