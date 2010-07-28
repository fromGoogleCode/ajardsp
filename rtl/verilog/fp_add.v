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

// done and (c) by Denis Markovic, June 2010

module fp_add(clk, rst, op_a_i, op_b_i, res_o, dbg1,dbg2);
   input clk;
   input rst;

   input  [15:0] op_a_i;
   input  [15:0] op_b_i;
   output reg [15:0] res_o;
   output reg [15:0] dbg1,dbg2;


   parameter mant_width = 8,
             exp_width = 7;
   parameter sign_bit_pos = 15;

   //reg [1:0] 	 mstate;

   reg [17:0] 	 imul, imul1, imul2;
   reg [(mant_width+1):0] 	 iadd,iadd2;

   reg [7:0] 			 delta_exp0, delta_exp1, common_exp, common_exp_norm;
   reg [8:0] 			 mant1, mant0, shiftedmant0, shiftedmant1;
   reg [9:0] 			 sum;
   reg [0:0] 			 absagtabsb_2,absagtabsb_1,absagtabsb, subnumbers, subnumbers_1;
   reg [0:3] 			 resshft;

   reg [15:0] 			 op_a_i_1,op_a_i_2,op_a_i_3;
   reg [15:0] 			 op_b_i_1,op_b_i_2,op_b_i_3;

   //initial
     //mstate <= INIT;

   always
     @(posedge clk) begin: process
        if (rst)
          begin
             imul  <= 0;
             imul1 <= 0;
             imul2 <= 0;
             iadd  <= 0;
             iadd2 <= 0;

             delta_exp0 <= 0;
             delta_exp1 <= 0;
             common_exp <= 0;
             common_exp_norm <= 0;
             mant1 <= 0;
             mant0 <= 0;
             shiftedmant0 <= 0;
             shiftedmant1 <= 0;
	     sum <= 0;
             absagtabsb_2 <= 0;
             absagtabsb_1 <= 0;
             absagtabsb <= 0;
             subnumbers <= 0;
             subnumbers_1 <= 0;
             resshft <= 0;

 	     op_a_i_1 <= 0;
             op_a_i_2 <= 0;
             op_a_i_3 <= 0;
   	     op_b_i_1 <= 0;
             op_b_i_2 <= 0;
             op_b_i_3 <= 0;

          end
        else
          begin

	       //inp op_a, op_b

	       //out delta_exp0
	       //    delta_exp1
	       //    absagtabsb
	       //    subnumbers
	       //    mant0
	       //    mant1
	       //    op_a_i_1
	       //    op_b_i_1
	       delta_exp0 <= op_a_i[14:8] - op_b_i[14:8];
	       delta_exp1 <= op_b_i[14:8] - op_a_i[14:8];

	       op_a_i_1[15:0] <= op_a_i[15:0];
	       op_b_i_1[15:0] <= op_b_i[15:0];

	       if(op_a_i[14:0] > op_b_i[14:0])
		 absagtabsb <= 1;
	       else
		 absagtabsb <= 0;

	       subnumbers <= op_a_i[15] ^ op_b_i[15];

	       mant0 <= {9'b000000001,op_a_i[(mant_width-1):0]};
	       mant1 <= {9'b000000001,op_b_i[(mant_width-1):0]};

	       // inp absagtabsb
	       //     delta_exp0
	       //     delta_exp1
	       //     mant0
	       //     mant1
	       //     op_a_i_1
	       //     op_b_i_1
	       //     subnumbers

	       // out shiftedmant0
	       //     shiftedmant1
	       //     common_exp
	       //     subnumbers_1
	       //     absagtabsb_1
	       //     op_a_i_2
	       //     op_b_i_2
	       subnumbers_1 <= subnumbers;
	       absagtabsb_1 <= absagtabsb;
	       op_a_i_2 <= op_a_i_1;
	       op_b_i_2 <= op_b_i_1;

	       if(absagtabsb)
		 begin
		    if(delta_exp0 > 8)
		      begin
			 shiftedmant0 <= mant0;
			 shiftedmant1 <= 0;
		      end
		    else
		      begin
			 shiftedmant0 <= mant0;
			 shiftedmant1 <= mant1 >> delta_exp0;
		      end
		    common_exp <= op_a_i_1[14:8];
		 end
	       else
		 begin
		    if(delta_exp1 > 8)
		      begin
			 shiftedmant1 <= 0;
			 shiftedmant0 <= mant1;
		      end
		    else
		      begin
			 shiftedmant1 <= mant0 >> delta_exp1;
			 shiftedmant0 <= mant1;
		      end
		    common_exp <= op_b_i_1[14:8];
		 end

	       // inp shiftedmant0
	       //     shiftedmant1
	       //     common_exp
	       //     subnumbers_1
	       //     op_a_i_2
	       //     op_b_i_2
	       //     absagtabsb_1
	       // out sum
	       //     common_exp_norm
	       //     op_a_i_3
	       //     op_b_i_3
	       //     absagtabsb_2
	       // now always: shiftedmant0 >= shiftedmant1
	       op_a_i_3 <= op_a_i_2;
	       op_b_i_3 <= op_b_i_2;
	       absagtabsb_2 <= absagtabsb_1;

	       if(subnumbers_1)
		 sum <= shiftedmant0 - shiftedmant1;
	       else
		 sum <= shiftedmant0 + shiftedmant1;

	       common_exp_norm <= common_exp;


          end

     end // process

   always @(op_a_i_3 or op_b_i_3 or common_exp_norm or sum)
     begin
        	       // inp common_exp_norm
	       //     absagtabsb_2
	       //     sum
	       //     op_a_i_3
	       //     op_b_i_3
	       // out res_o

	       if(absagtabsb_2)
		 res_o[sign_bit_pos] = op_a_i_3[sign_bit_pos];
	       else
		 res_o[sign_bit_pos] = op_b_i_3[sign_bit_pos];

	       // only needed if we did a subtraction
	       //res_o[(sign_bit_pos-1):mant_width] = common_exp_norm - resshft;
	       //res_o[(mant_width-1):0] = sum;//(sum << resshft);
	       casez(sum[9:0])
		 10'b01????????:
		   begin
		      res_o[(sign_bit_pos-1):mant_width] = common_exp_norm;
		      res_o[(mant_width-1):0] = sum[(mant_width-1):0];
		   end
		 10'b001???????:
		   begin
		      res_o[(sign_bit_pos-1):mant_width] = common_exp_norm-1;
		      res_o[(mant_width-1):0] = sum[(mant_width-1):0] << 1;
		   end
		 10'b0001??????:
		   begin
		      res_o[(sign_bit_pos-1):mant_width] = common_exp_norm-2;
		      res_o[(mant_width-1):0] = sum[(mant_width-1):0] << 2;
		   end
		 10'b00001?????:
		   begin
		      res_o[(sign_bit_pos-1):mant_width] = common_exp_norm-3;
		      res_o[(mant_width-1):0] = sum[(mant_width-1):0] << 3;
		   end
		 10'b000001????:
		   begin
		      res_o[(sign_bit_pos-1):mant_width] = common_exp_norm-4;
		      res_o[(mant_width-1):0] = sum[(mant_width-1):0] << 4;
		   end
		 10'b0000001???:
		   begin
		      res_o[(sign_bit_pos-1):mant_width] = common_exp_norm-5;
		      res_o[(mant_width-1):0] = sum[(mant_width-1):0] << 5;
		   end
		 10'b00000001??:
		   begin
		      res_o[(sign_bit_pos-1):mant_width] = common_exp_norm-6;
		      res_o[(mant_width-1):0] = sum[(mant_width-1):0] << 6;
		   end
		 10'b000000001?:
		   begin
		      res_o[(sign_bit_pos-1):mant_width] = common_exp_norm-7;
		      res_o[(mant_width-1):0] = sum[(mant_width-1):0] << 7;
		   end
		 default:
		   begin
		      res_o[(sign_bit_pos):mant_width] = 0;
		      res_o[(mant_width-1):0] = 0;
		   end
	       endcase
     end

endmodule // fp_add
