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

module bmu(clk,
	   rst,

	   inst,

	   op_0_idx_o,
           op_0_ren_o,
	   op_0_data_i,

	   op_1_idx_o,
           op_1_ren_o,
	   op_1_data_i,

	   res_idx_o,
	   res_wen_o,
           res_mask_o,
	   res_data_o,

           pred_tst_idx_o,
           pred_tst_bit_i

	   );

`include "insns.v"

   input clk;
   input rst;
   input [31:0] inst;

   output [2:0]	  op_0_idx_o;
   reg    [2:0]   op_0_idx_o;
   output reg     op_0_ren_o;
   input [`AJARDSP_CONFIG_ACC_GUARD_BITS+31:0] op_0_data_i;

   output [2:0]   op_1_idx_o;
   reg    [2:0]   op_1_idx_o;
   output reg     op_1_ren_o;
   input [`AJARDSP_CONFIG_ACC_GUARD_BITS+31:0] op_1_data_i;

   output [2:0]   res_idx_o;
   reg    [2:0]   res_idx_o;
   output 	  res_wen_o;
   reg 		  res_wen_o;
   output [2:0]	  res_mask_o;
   reg    [2:0]   res_mask_o;

   output [`AJARDSP_CONFIG_ACC_GUARD_BITS+31:0] res_data_o;
   reg [`AJARDSP_CONFIG_ACC_GUARD_BITS+31:0]    res_data_o;

   output [1:0]   pred_tst_idx_o;
   input          pred_tst_bit_i;

   reg [31:0] inst_pipe_0_r;
   reg [31:0] inst_pipe_1_r;
   reg [31:0] inst_pipe_2_r;

   reg [`AJARDSP_CONFIG_ACC_GUARD_BITS+31:0] op_0_r;
   reg [`AJARDSP_CONFIG_ACC_GUARD_BITS+31:0] op_1_r;

   reg [15:0] op_0_16_r;
   reg [15:0] op_1_16_r;

   reg        op_0_16_pos;
   reg        op_1_16_pos;

   reg [`AJARDSP_CONFIG_ACC_GUARD_BITS+31:0] res;
   reg [`AJARDSP_CONFIG_ACC_GUARD_BITS+31:0] res_r;

   wire signed [31:0] op_0_r_signed_w;
   wire signed [15:0] op_0_16_r_signed_w;

   assign pred_tst_idx_o = inst_pipe_2_r[31:30];

   assign op_0_r_signed_w    = op_0_r;
   assign op_0_16_r_signed_w = op_0_16_r;

   always @(posedge clk)
     begin
	if (rst)
	  begin
	     inst_pipe_0_r <= 32'h0;
	     inst_pipe_1_r <= 32'h0;
	     inst_pipe_2_r <= 32'h0;
	  end
	else
	  begin
	     inst_pipe_0_r <= inst;
	     inst_pipe_1_r <= inst_pipe_0_r;
	     inst_pipe_2_r <= inst_pipe_1_r;
	  end
     end

   always @(posedge clk)
     begin
	if (rst)
	  begin
	     res_r <= 0;
	     op_0_r <= 0;
	     op_1_r <= 0;
	  end
	else
	  begin
	     res_r <= res;

	     op_0_r <= op_0_data_i;
             op_1_r <= op_1_data_i;

             if (op_0_16_pos)
               op_0_16_r <= op_0_data_i[31:16];
             else
               op_0_16_r <= op_0_data_i[15:0];

             if (op_1_16_pos)
	       op_1_16_r <= op_1_data_i[31:16];
             else
               op_1_16_r <= op_1_data_i[15:0];

	  end
     end

   // Instruction decode pipeline stage #0
   always @(inst_pipe_0_r)
     begin

	op_0_idx_o = 0;
	op_1_idx_o = 0;

        op_0_ren_o = 0;
        op_1_ren_o = 0;

        op_0_16_pos = 0;
        op_1_16_pos = 0;

        if (inst_pipe_0_r[INSN_SIZE_BIT] & inst_pipe_0_r[INSN_ENC_BIT])
          begin  /* 32 bit instruction encoding */

             if (inst_pipe_0_r[8:4] == BMU_ITYPE_AND_16_32    ||
                 inst_pipe_0_r[8:4] == BMU_ITYPE_NOT_16_32    ||
                 inst_pipe_0_r[8:4] == BMU_ITYPE_OR_16_32     ||
                 inst_pipe_0_r[8:4] == BMU_ITYPE_XOR_16_32    ||
                 inst_pipe_0_r[8:4] == BMU_ITYPE_SHIFTA_16_32 ||
                 inst_pipe_0_r[8:4] == BMU_ITYPE_SHIFTL_16_32)
               begin
	          op_0_idx_o  = inst_pipe_0_r[12:10];
                  op_0_ren_o  = 1;
                  op_0_16_pos = inst_pipe_0_r[9];
	          op_1_idx_o  = inst_pipe_0_r[16:14];
                  op_1_ren_o  = 1;
                  op_1_16_pos = inst_pipe_0_r[13];
               end
          end
        else  /* 16 bit instruction encoding */
          begin
          end
     end

   // Instruction execute pipeline stage #1
   always @(inst_pipe_1_r or op_0_r or op_1_r or op_0_16_r or op_1_16_r or op_0_r_signed_w or op_0_16_r_signed_w)
     begin

	res = 0;

        if (inst_pipe_1_r[INSN_SIZE_BIT] & inst_pipe_1_r[INSN_ENC_BIT])
          begin  /* 32 bit instruction encoding */
             case (inst_pipe_1_r[8:4])
               BMU_ITYPE_AND_16_32: begin
                  if (inst_pipe_1_r[BMU_OP_SIZE16_BIT])
                    res = {16'h0, op_0_16_r & op_1_16_r};
                  else
 	            res = op_0_r & op_1_r;
 	       end
               BMU_ITYPE_NOT_16_32: begin
                  if (inst_pipe_1_r[BMU_OP_SIZE16_BIT])
                    res = {16'h0, ~op_0_16_r};
                  else
 	            res = ~op_0_r;
 	       end
               BMU_ITYPE_OR_16_32: begin
                  if (inst_pipe_1_r[BMU_OP_SIZE16_BIT])
                    res = {16'h0, op_0_16_r | op_1_16_r};
                  else
 	            res = op_0_r | op_1_r;
 	       end
               BMU_ITYPE_XOR_16_32: begin
                  if (inst_pipe_1_r[BMU_OP_SIZE16_BIT])
                    res = {16'h0, op_0_16_r ^ op_1_16_r};
                  else
 	            res = op_0_r ^ op_1_r;
 	       end
               BMU_ITYPE_SHIFTL_16_32: begin
                  if (inst_pipe_1_r[BMU_OP_SIZE16_BIT])
                    begin
                       if (inst_pipe_1_r[23])
                         res = {16'h0, op_0_16_r << op_1_16_r[4:0]};
                       else
                         res = {16'h0, op_0_16_r >> op_1_16_r[4:0]};
                    end
                  else
                    begin
                       if (inst_pipe_1_r[23])
 	                 res = op_0_r << op_1_16_r[5:0];
                       else
                         res = op_0_r >> op_1_16_r[5:0];
                    end
 	       end
               BMU_ITYPE_SHIFTA_16_32: begin
                  if (inst_pipe_1_r[BMU_OP_SIZE16_BIT])
                    begin
                       res = {16'h0, op_0_16_r_signed_w >>> op_1_16_r[4:0]};
                    end
                  else
                    begin
                       res = op_0_r_signed_w >>> op_1_16_r[5:0];
                    end
 	       end

             endcase
          end
        else  /* 16 bit instruction encoding */
          begin
          end
     end

   // Instruction writeback pipeline stage #2
   always @(inst_pipe_2_r or res_r or pred_tst_bit_i)
     begin
	res_idx_o  = 0;
	res_wen_o  = (inst_pipe_2_r[1] == 0 || pred_tst_bit_i) && inst_pipe_2_r[15:0] != 0;
        res_mask_o = 3'b111;
	res_data_o = res_r;

        if (inst_pipe_2_r[INSN_SIZE_BIT] & inst_pipe_2_r[INSN_ENC_BIT])
          begin  /* 32 bit instruction encoding */
             if (inst_pipe_2_r[8:4] == BMU_ITYPE_AND_16_32    ||
                 inst_pipe_2_r[8:4] == BMU_ITYPE_NOT_16_32    ||
                 inst_pipe_2_r[8:4] == BMU_ITYPE_OR_16_32     ||
                 inst_pipe_2_r[8:4] == BMU_ITYPE_XOR_16_32    ||
                 inst_pipe_2_r[8:4] == BMU_ITYPE_SHIFTA_16_32 ||
                 inst_pipe_2_r[8:4] == BMU_ITYPE_SHIFTL_16_32)
               begin
	          res_idx_o = inst_pipe_2_r[20:18];
                  if (inst_pipe_2_r[BMU_OP_SIZE16_BIT])
                    begin
                       if (inst_pipe_2_r[17])
                         begin
                            res_mask_o = 2'b10;
	                    res_data_o = {res_r[15:0], 16'h0};
                         end
                       else
                         begin
                            res_mask_o = 2'b01;
	                    res_data_o = {16'h0, res_r[15:0]};
                         end
                    end
                  else
                    begin
                       res_mask_o = 3'b111;
	               res_data_o = res_r;
                    end
               end
          end
        else
          begin  /* 16 bit instruction encoding */
          end
     end

endmodule
