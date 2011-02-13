// Copyright (c) 2010, Denis Markovic
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

// done and (c) by Denis Markovic (outside work at STEricsson or Teleca, i.e. Teleca
// or STEricsson hold no rights on this code)

//`timescale 10ns/1ns

module fp_mul(clk, rst, op_a_i, op_b_i, res_o, mo1,mo2);
   input clk;
   input rst;

   input  [15:0] op_a_i;
   input  [15:0] op_b_i;
   output reg [15:0] res_o;
   output reg [15:0] mo1,mo2;


   parameter mant_width = 8,
             exp_width = 7,
             exp_offs  = 63;
   parameter sign_bit_pos = 15;

   reg [17:0] 	 imul, imul1, imul2;
   reg [(mant_width+1):0] 	 iadd,iadd2;
   reg [0:0] 			 isign,isign2, rst_is_zero,rst_is_zero2;

   //initial
   //  mstate <= INIT;

   always
     @(posedge clk) begin: process

       //inp op_a_i,op_b_i

       //out imul
       //    iadd
       //    rst_is_zero
	       // generate mant and exp
	       imul <= {9'b000000001,op_a_i[(mant_width-1):0]} * {9'b000000001,op_b_i[(mant_width-1):0]};
	       iadd <= {3'b000,op_a_i[(sign_bit_pos-1):mant_width]} + {3'b000,op_b_i[(sign_bit_pos-1):mant_width]};
	       //res_o[sign_bit_pos]<=op_a_i[sign_bit_pos]^op_b_i[sign_bit_pos];
	       isign <= op_a_i[sign_bit_pos]^op_b_i[sign_bit_pos];
	if({op_a_i,op_b_i} == 0)
	  rst_is_zero <= 1;
	else
	  rst_is_zero <= 0;

	//inp imul
	//    iadd
	//    isign
	//    rst_is_zero

	//out imul2
	//    iadd2
	//    isign2
	//    rst_is_zero2
	//NORM:
	isign2 <= isign;
	rst_is_zero2 <= rst_is_zero;

	if(imul[mant_width*2+1])
	  begin
	     iadd2 <= (iadd+1-exp_offs);
	     imul2 <= imul >> 9;
	  end
	else
	  begin
	     iadd2 <= (iadd - exp_offs);
	     imul2 <= imul >> 8;
	  end

	res_o[sign_bit_pos:sign_bit_pos] <= isign2[0:0];
	res_o[(sign_bit_pos-1):mant_width] <= iadd2[(exp_width-1):0];
	res_o[(mant_width-1):0] <= imul2[(mant_width-1):0];


     end // process

endmodule // fp_mul_pipe

