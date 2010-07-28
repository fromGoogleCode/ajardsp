// done and (c) by Denis Markovic, June 2010

`timescale 10ns/1ns

module fp_add_pipe(clk, rst, op_a_i, op_b_i, res_o, dbg1,dbg2);
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
	       
	       // inp common_exp_norm
	       //     absagtabsb_2
	       //     sum
	       //     op_a_i_3
	       //     op_b_i_3
	       // out res_o

	       if(absagtabsb_2)
		 res_o[sign_bit_pos] <= op_a_i_3[sign_bit_pos];
	       else
		 res_o[sign_bit_pos] <= op_b_i_3[sign_bit_pos];

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

	
     end // process
   
endmodule // fp_add

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

   parameter INIT = 0,NORM = 1,OVRFLWHNDL = 2,NORMRES = 3, RESRDY = 4;

   reg [1:0] 	 mstate;

   reg [17:0] 	 imul, imul1, imul2;
   reg [(mant_width+1):0] 	 iadd,iadd2;

   reg [7:0] 			 delta_exp0, delta_exp1, common_exp, common_exp_norm;
   reg [8:0] 			 mant1, mant0, shiftedmant0, shiftedmant1;
   reg [9:0] 			 sum;
   reg [0:0] 			 absagtabsb_2,absagtabsb_1,absagtabsb, subnumbers, subnumbers_1;
   reg [0:3] 			 resshft;

   reg [15:0] 			 op_a_i_1,op_a_i_2,op_a_i_3;
   reg [15:0] 			 op_b_i_1,op_b_i_2,op_b_i_3;

   initial
     mstate <= INIT;

   always
     @(posedge clk) begin: process
	if(rst)
	   mstate <= INIT;

	case (mstate)
	  INIT:
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

	       op_a_i_1[15:0] = op_a_i[15:0];
	       op_b_i_1[15:0] = op_b_i[15:0];
	       
	       if(op_a_i[14:0] > op_b_i[14:0])
		 absagtabsb <= 1;
	       else
		 absagtabsb <= 0;

	       subnumbers <= op_a_i[15] ^ op_b_i[15];

	       mant0 <= {9'b000000001,op_a_i[(mant_width-1):0]};
	       mant1 <= {9'b000000001,op_b_i[(mant_width-1):0]};
	       
	       mstate = NORM;
	    end

	  NORM:
	    begin
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
	       
	       mstate = OVRFLWHNDL;
	       // normalize mantissa and correct exp.
	    end

	  OVRFLWHNDL:
	    begin
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
	       
	       mstate = NORMRES;
	    end
	  NORMRES:
	    begin
	       // inp common_exp_norm
	       //     absagtabsb_2
	       //     sum
	       //     op_a_i_3
	       //     op_b_i_3
	       // out res_o

	       if(absagtabsb_2)
		 res_o[sign_bit_pos] <= op_a_i_3[sign_bit_pos];
	       else
		 res_o[sign_bit_pos] <= op_b_i_3[sign_bit_pos];

	       // only needed if we did a subtraction
	       //res_o[(sign_bit_pos-1):mant_width] <= common_exp_norm - resshft;
	       //res_o[(mant_width-1):0] <= sum;//(sum << resshft);
	       casez(sum[9:0])
		 10'b01????????:
		   begin
		      res_o[(sign_bit_pos-1):mant_width] <= common_exp_norm;
		      res_o[(mant_width-1):0] <= sum[(mant_width-1):0];
		   end
		 10'b001???????:
		   begin
		      res_o[(sign_bit_pos-1):mant_width] <= common_exp_norm-1;
		      res_o[(mant_width-1):0] <= sum[(mant_width-1):0] << 1;
		   end
		 10'b0001??????:
		   begin
		      res_o[(sign_bit_pos-1):mant_width] <= common_exp_norm-2;
		      res_o[(mant_width-1):0] <= sum[(mant_width-1):0] << 2;
		   end
		 10'b00001?????:
		   begin
		      res_o[(sign_bit_pos-1):mant_width] <= common_exp_norm-3;
		      res_o[(mant_width-1):0] <= sum[(mant_width-1):0] << 3;
		   end
		 10'b000001????:
		   begin
		      res_o[(sign_bit_pos-1):mant_width] <= common_exp_norm-4;
		      res_o[(mant_width-1):0] <= sum[(mant_width-1):0] << 4;
		   end
		 10'b0000001???:
		   begin
		      res_o[(sign_bit_pos-1):mant_width] <= common_exp_norm-5;
		      res_o[(mant_width-1):0] <= sum[(mant_width-1):0] << 5;
		   end
		 10'b00000001??:
		   begin
		      res_o[(sign_bit_pos-1):mant_width] <= common_exp_norm-6;
		      res_o[(mant_width-1):0] <= sum[(mant_width-1):0] << 6;
		   end
		 10'b000000001?:
		   begin
		      res_o[(sign_bit_pos-1):mant_width] <= common_exp_norm-7;
		      res_o[(mant_width-1):0] <= sum[(mant_width-1):0] << 7;
		   end
		 default:
		   begin
		      res_o[(sign_bit_pos):mant_width] <= 0;
		      res_o[(mant_width-1):0] <= 0;
		   end
	       endcase

	       mstate = RESRDY;
	    end
	  
	  RESRDY:
	    begin
	    end	  
  
	endcase // case (mstate)
	
     end // process
   
endmodule // fp_add



module test_fp_add;

   reg [15:0] op1;
   reg [15:0] op2;
   reg mrst_n,mclk_n;
   wire [15:0] res;
   wire [15:0] mmo,amo;
   

   fp_add_pipe mymulblk(.clk(mclk_n),.rst(mrst_n),.op_a_i(op1),.op_b_i(op2),.res_o(res),.dbg1(mmo),.dbg2(amo));
   
   initial
     begin
	mrst_n = 0;
	mclk_n = 0;

//TstFlt: -15.000000 + -0.300000 = -15.281250   (c2e0 + bd33 = c2e9)
op1 = 16'hc2e0;
op2 = 16'hbd33;
#5 mclk_n = 1;
//TstFlt: 15.000000 + 0.300000 = 15.281250   (42e0 + 3d33 = 42e9)
#5 mclk_n = 0;
op1 = 16'h42e0;
op2 = 16'h3d33;
#5 mclk_n = 1;
//TstFlt: -15.000000 + 0.300000 = -14.718750   (c2e0 + 3d33 = c2d7)
#5 mclk_n = 0;
op1 = 16'hc2e0;
op2 = 16'h3d33;
#5 mclk_n = 1;
//TstFlt: 15.000000 + -0.300000 = 14.718750   (42e0 + bd33 = 42d7)
#5 mclk_n = 0;
op1 = 16'h42e0;
op2 = 16'hbd33;
#5 mclk_n = 1;
#5 mclk_n = 0;
#5 mclk_n = 1;


#5 mclk_n = 0;
#5 mclk_n = 1;
#5 mclk_n = 0;
#5 mclk_n = 1;


     end

   initial
     begin
	$monitor("Signals at time %t:",$time,"clk = %b,rst = %b,mul %h mmo %b amo %b",mclk_n,mrst_n,res,mmo,amo);
     end
   
	endmodule // test_fp_add

	