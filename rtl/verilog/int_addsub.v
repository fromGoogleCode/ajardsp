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

module int_addsub(op_a_i, op_b_i, res_o, sat_en_i, sub_en_i);

   parameter WIDTH = `AJARDSP_CONFIG_ACC_GUARD_BITS + 32;

   input [WIDTH-1:0] op_a_i;
   input [WIDTH-1:0]  op_b_i;
   output [WIDTH-1:0] res_o;
   input         sat_en_i;
   input         sub_en_i;

   reg [WIDTH-1:0] res_o;
   reg [WIDTH:0]   ires;

   wire [WIDTH-1:0]   max_pos_w;
   wire [WIDTH-1:0]   max_neg_w;

   assign max_pos_w = {1'b0, {WIDTH-1{1'b1}}};
   assign max_neg_w = {1'b1, {WIDTH-1{1'b0}}};

   /* Perform the add/sub operation */
   always @(op_a_i or op_b_i or sub_en_i)
     begin
        if (sub_en_i)
          begin
             ires = {op_a_i[WIDTH-1], op_a_i} - {op_b_i[WIDTH-1], op_b_i};
          end
        else
          begin
             ires = {op_a_i[WIDTH-1], op_a_i} + {op_b_i[WIDTH-1], op_b_i};
          end
     end

   /* Perform signed saturation on the result */
   always @(ires or sat_en_i)
     begin
        if (sat_en_i == 0 || ires[WIDTH:WIDTH-1] == 2'b00 || ires[WIDTH:WIDTH-1] == 2'b11)
          begin
             res_o = ires[WIDTH-1:0];
          end
        else if (ires[WIDTH] == 1'b1)
          begin
             res_o = max_neg_w;
          end
        else
          begin
             res_o = max_pos_w;
          end
     end

endmodule
