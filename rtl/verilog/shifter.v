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

module shifter(data_i,
               steps_i,
               data_o,
               dir_left_i,
               rotate_en_i,
               arith_en_i
	       );

   input [31:0] data_i;
   input [5:0]  steps_i;
   output reg [31:0] data_o;
   input         dir_left_i;
   input         rotate_en_i;
   input         arith_en_i;

   wire [7:0]    step_mul_op_w;
   wire [31:0]   mul_res_w;
   wire [31:0]   mul_input_w;
   reg [31:0]   mux_res_w;


   //assign mul_input_w    = dir_left_i ? data_i[31:0] : data_i[0:31];
   assign mul_input_w    = dir_left_i ? data_i[31:0] : {<<{data_i}}; // NAK 2012-10-26 Changed to compile in Modelsim
   //assign data_o         = dir_left_i ? mux_res_w[31:0] : mux_res_w[0:31];
   assign data_o         = dir_left_i ? mux_res_w[31:0] : {<<{mux_res_w[31:0]}}; // NAK Changed this line so it would compile in Modelsim.

   assign steps_mul_op_w = 1 << steps_i[2:0];

   always @(mul_res_w or steps_i)
     begin
        case (steps_i[4:3])
          2'h0: begin
             mux_res_w = {mul_res_w[31:24], mul_res_w[23:16], mul_res_w[15:8], mul_res_w[7:0]};
          end
          2'h1: begin
             mux_res_w = {mul_res_w[23:16], mul_res_w[15:8], mul_res_w[7:0], mul_res_w[31:24]};
          end
          2'h2: begin
             mux_res_w = {mul_res_w[15:8], mul_res_w[7:0], mul_res_w[31:24], mul_res_w[23:16]};
          end
          2'h3: begin
             mux_res_w = {mul_res_w[7:0], mul_res_w[31:24], mul_res_w[23:16], mul_res_w[15:8]};
          end
        endcase
     end

   MULT18X18SIO #(
                  .AREG(0), // Enable the input registers on the A port (1=on, 0=off)
                  .BREG(0), // Enable the input registers on the B port (1=on, 0=off)
                  .B_INPUT("DIRECT"), // B cascade input "DIRECT" or "CASCADE"
                  .PREG(0) // Enable the input registers on the P port (1=on, 0=off)
                  ) MULT18X18SIO_inst_0 (
                                         .BCOUT(), // 18-bit cascade output
                                         .P(mul_res_w[7:0]),    // 36-bit multiplier output
                                         .A({mul_input_w[7:0], mul_input_w[31:24]}),   // 18-bit multiplier input
                                         .B(steps_mul_op_w),   // 18-bit multiplier input
                                         .BCIN(18'h0), // 18-bit cascade input
                                         .CEA(1'b0), // Clock enable input for the A port
                                         .CEB(1'b0), // Clock enable input for the B port
                                         .CEP(1'b0), // Clock enable input for the P port
                                         .CLK(1'b0), // Clock input
                                         .RSTA(1'b0), // Synchronous reset input for the A port
                                         .RSTB(1'b0), // Synchronous reset input for the B port
                                         .RSTP(1'b0)  // Synchronous reset input for the P port
                                         );

   MULT18X18SIO #(
                  .AREG(0), // Enable the input registers on the A port (1=on, 0=off)
                  .BREG(0), // Enable the input registers on the B port (1=on, 0=off)
                  .B_INPUT("DIRECT"), // B cascade input "DIRECT" or "CASCADE"
                  .PREG(0) // Enable the input registers on the P port (1=on, 0=off)
                  ) MULT18X18SIO_inst_1 (
                                         .BCOUT(), // 18-bit cascade output
                                         .P(mul_res_w[15:8]),    // 36-bit multiplier output
                                         .A({mul_input_w[15:8], mul_input_w[7:0]}),   // 18-bit multiplier input
                                         .B(steps_mul_op_w),   // 18-bit multiplier input
                                         .BCIN(18'h0), // 18-bit cascade input
                                         .CEA(1'b0), // Clock enable input for the A port
                                         .CEB(1'b0), // Clock enable input for the B port
                                         .CEP(1'b0), // Clock enable input for the P port
                                         .CLK(1'b0), // Clock input
                                         .RSTA(1'b0), // Synchronous reset input for the A port
                                         .RSTB(1'b0), // Synchronous reset input for the B port
                                         .RSTP(1'b0)  // Synchronous reset input for the P port
                                         );

   MULT18X18SIO #(
                  .AREG(0), // Enable the input registers on the A port (1=on, 0=off)
                  .BREG(0), // Enable the input registers on the B port (1=on, 0=off)
                  .B_INPUT("DIRECT"), // B cascade input "DIRECT" or "CASCADE"
                  .PREG(0) // Enable the input registers on the P port (1=on, 0=off)
                  ) MULT18X18SIO_inst_2 (
                                         .BCOUT(), // 18-bit cascade output
                                         .P(mul_res_w[23:16]),    // 36-bit multiplier output
                                         .A({mul_input_w[23:16], mul_input_w[15:8]}),   // 18-bit multiplier input
                                         .B(steps_mul_op_w),   // 18-bit multiplier input
                                         .BCIN(18'h0), // 18-bit cascade input
                                         .CEA(1'b0), // Clock enable input for the A port
                                         .CEB(1'b0), // Clock enable input for the B port
                                         .CEP(1'b0), // Clock enable input for the P port
                                         .CLK(1'b0), // Clock input
                                         .RSTA(1'b0), // Synchronous reset input for the A port
                                         .RSTB(1'b0), // Synchronous reset input for the B port
                                         .RSTP(1'b0)  // Synchronous reset input for the P port
                                         );

   MULT18X18SIO #(
                  .AREG(0), // Enable the input registers on the A port (1=on, 0=off)
                  .BREG(0), // Enable the input registers on the B port (1=on, 0=off)
                  .B_INPUT("DIRECT"), // B cascade input "DIRECT" or "CASCADE"
                  .PREG(0) // Enable the input registers on the P port (1=on, 0=off)
                  ) MULT18X18SIO_inst_3 (
                                         .BCOUT(), // 18-bit cascade output
                                         .P(mul_res_w[31:24]),    // 36-bit multiplier output
                                         .A({mul_input_w[31:24], mul_input_w[23:16]}),   // 18-bit multiplier input
                                         .B(steps_mul_op_w),   // 18-bit multiplier input
                                         .BCIN(18'h0), // 18-bit cascade input
                                         .CEA(1'b0), // Clock enable input for the A port
                                         .CEB(1'b0), // Clock enable input for the B port
                                         .CEP(1'b0), // Clock enable input for the P port
                                         .CLK(1'b0), // Clock input
                                         .RSTA(1'b0), // Synchronous reset input for the A port
                                         .RSTB(1'b0), // Synchronous reset input for the B port
                                         .RSTP(1'b0)  // Synchronous reset input for the P port
                                         );


endmodule
