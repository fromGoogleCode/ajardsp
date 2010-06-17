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

module int_mul(op_a_i, op_b_i, res_o, op_a_signed_i, op_b_signed_i);

   parameter WIDTH = 16;

   input [WIDTH-1:0] op_a_i;
   input [WIDTH-1:0]  op_b_i;
   output [2*WIDTH-1:0] res_o;

   input                op_a_signed_i;
   input                op_b_signed_i;

`ifdef SIMULATION

   wire [2*WIDTH-1:0]   op_a_w;
   wire [2*WIDTH-1:0]   op_b_w;

   assign op_a_w = op_a_signed_i ? {{WIDTH{op_a_i[WIDTH-1]}}, op_a_i} : {{WIDTH{1'b0}}, op_a_i};
   assign op_b_w = op_b_signed_i ? {{WIDTH{op_b_i[WIDTH-1]}}, op_b_i} : {{WIDTH{1'b0}}, op_b_i};

   assign res_o = op_a_w * op_b_w;

`else

   wire [17:0]   op_a_w;
   wire [17:0]   op_b_w;
   wire [35:0]   res_w;

   assign op_a_w = op_a_signed_i ? {{2{op_a_i[WIDTH-1]}}, op_a_i} : {{2{1'b0}}, op_a_i};
   assign op_b_w = op_b_signed_i ? {{2{op_b_i[WIDTH-1]}}, op_b_i} : {{2{1'b0}}, op_b_i};

   assign res_o = res_w[2*WIDTH-1:0];

   MULT18X18SIO #(
                  .AREG(0), // Enable the input registers on the A port (1=on, 0=off)
                  .BREG(0), // Enable the input registers on the B port (1=on, 0=off)
                  .B_INPUT("DIRECT"), // B cascade input "DIRECT" or "CASCADE"
                  .PREG(0) // Enable the input registers on the P port (1=on, 0=off)
                  ) MULT18X18SIO_inst (
                                       .BCOUT(), // 18-bit cascade output
                                       .P(res_w),    // 36-bit multiplier output
                                       .A(op_a_w),   // 18-bit multiplier input
                                       .B(op_b_w),   // 18-bit multiplier input
                                       .BCIN(18'h0), // 18-bit cascade input
                                       .CEA(1'b0), // Clock enable input for the A port
                                       .CEB(1'b0), // Clock enable input for the B port
                                       .CEP(1'b0), // Clock enable input for the P port
                                       .CLK(1'b0), // Clock input
                                       .RSTA(1'b0), // Synchronous reset input for the A port
                                       .RSTB(1'b0), // Synchronous reset input for the B port
                                       .RSTP(1'b0)  // Synchronous reset input for the P port
                                       );

`endif

endmodule
