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

   input [15:0] op_a_i;
   input [15:0] op_b_i;
   output reg [15:0] res_o;
   output reg [15:0] mo1,mo2;


   parameter mant_width = 8,
               exp_width = 7;
   parameter sign_bit_pos = 15;

   parameter INIT = 0,NORM = 1,OVRFLWHNDL = 2,RESRDY = 3;

   reg [1:0]         mstate;

   reg [17:0]        imul, imul1, imul2;
   reg [(mant_width+1):0] iadd, iadd1, iadd2;

   initial
     mstate <= INIT;

   always
     @(posedge clk) begin: process
        if(rst)
          begin

             mstate <= INIT;
             imul <= 0;
             iadd <= 0;
             res_o <= 0;
          end
        else
          begin
        case (mstate)
          INIT:
            begin
               // generate mant and exp
               imul1 = {9'b000000001,op_a_i[(mant_width-1):0]};
               imul2 = {9'b000000001,op_b_i[(mant_width-1):0]};
               imul <= imul1 * imul2;
               iadd1 = {3'b000,op_a_i[(sign_bit_pos-1):mant_width]};
               iadd2 = {3'b000,op_b_i[(sign_bit_pos-1):mant_width]};
               iadd <= (iadd1 + iadd2)-(63);
               res_o[sign_bit_pos]<=op_a_i[sign_bit_pos]^op_b_i[sign_bit_pos];

               //res_o <= 2;
               mstate <= NORM;
            end

          NORM:
            begin
               mo1 = imul;
               mo2 = iadd;

               if(imul[mant_width*2+1])
                 begin
                    iadd <= (iadd+1);
                    imul <= imul >> 9;
                 end
               else
                 begin
                    //iadd <= (iadd + 0);
                    imul <= imul >> 8;
                 end
               //imul <= imul >> 2;

               mstate <= OVRFLWHNDL;
               // normalize mantissa and correct exp.
            end

          OVRFLWHNDL:
            begin
               // currently not used, no rounding yet ...
               res_o[(sign_bit_pos-1):mant_width] <= iadd[(exp_width-1):0];
               res_o[(mant_width-1):0] <= imul[(mant_width-1):0];
               mstate <= RESRDY;
            end

          RESRDY:
            begin
               // do nothing, result is ready and at output (or maybe cp to output??)
            end

        endcase // case (mstate)

          end

     end // process

endmodule // fp_mul


`ifdef NODEFINED_SIM

module test_fp_mul;

   reg [15:0] op1;
   reg [15:0] op2;
   reg        mrst_n,mclk_n;
   wire [15:0] res;
   wire [15:0] mmo,amo;


   fp_mul mymulblk(.clk(mclk_n),.rst(mrst_n),.op_a_i(op1),.op_b_i(op2),.res_o(res),.mo1(mmo),.mo2(amo));

   initial
     begin
        mrst_n = 1;
        mclk_n = 1;
        op1  = 16'b0011110000110011; // should be 1.0
        op2  = 16'b0011110100110011;
        #5 mclk_n = 0;
        #10 mclk_n = 1;
        mrst_n = 0;
        #15 mclk_n = 0;
        #20 mclk_n = 1;
        #25 mclk_n = 0;
        #30 mclk_n = 1;
        #35 mclk_n = 0;
        #40 mclk_n = 1;
        #45 mclk_n = 0;
        #50 mclk_n = 1;
        #55 mclk_n = 0;
        #60 mclk_n = 1;
     end

   initial
     begin
        $monitor("Signals at time %t:",$time,"clk = %b,rst = %b,mul %b mmo %b amo %b",mclk_n,mrst_n,res,mmo,amo);
     end

endmodule // test_fp_mul

`endif
