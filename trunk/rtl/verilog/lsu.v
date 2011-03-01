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

module lsu(clk,
	   rst,
           clk_en,

	   inst,

           pred_tst_idx_o,
           pred_tst_bit_i,

	   ptr_rd_en_o,
	   ptr_rd_idx_o,
	   ptr_rd_data_i,

	   ptr_2nd_rd_en_o,
	   ptr_2nd_rd_idx_o,
	   ptr_2nd_rd_data_i,

	   ptr_wr_en_o,
	   ptr_wr_idx_o,
	   ptr_wr_data_o,

	   acc_rd_en_o,
	   acc_rd_idx_o,
	   acc_rd_data_i,

	   acc_wr_en_o,
	   acc_wr_idx_o,
           acc_wr_mask_o,
	   acc_wr_data_o,

	   dmem_addr_o,
	   dmem_rd_en_o,
	   dmem_wr_en_o,
           dmem_wr_mask_o,
	   dmem_rd_data_i,
	   dmem_wr_data_o,

           spec_regs_raddr_o,
           spec_regs_waddr_o,
           spec_regs_ren_o,
           spec_regs_wen_o,
           spec_regs_data_i,
           spec_regs_data_o,

           sp_i,
           push_en_o,
           pop_en_o,
           stack_width_o,

           bitrev_i,

           mask_sel_i,
           mask_0_i,
           mask_1_i,

           mod_sel_i,
           mod_0_i,
           mod_1_i,

           m_if_addr_o,
           m_if_data_o,
           m_if_data_i,
           m_if_read_req_o,
           m_if_write_req_o
           );

`include "insns.v"

   input clk;
   input rst;
   input clk_en;

   input [31:0] inst;

   output [1:0] pred_tst_idx_o;
   input        pred_tst_bit_i;

   output 	ptr_rd_en_o;
   reg 		ptr_rd_en_o;
   output [2:0] ptr_rd_idx_o;
   reg    [2:0] ptr_rd_idx_o;
   input [15:0] ptr_rd_data_i;

   output 	ptr_2nd_rd_en_o;
   reg 		ptr_2nd_rd_en_o;
   output [2:0] ptr_2nd_rd_idx_o;
   reg    [2:0] ptr_2nd_rd_idx_o;
   input [15:0] ptr_2nd_rd_data_i;

   output 	 ptr_wr_en_o;
   reg 		 ptr_wr_en_o;
   output [2:0]  ptr_wr_idx_o;
   reg    [2:0]  ptr_wr_idx_o;
   output [15:0] ptr_wr_data_o;
   reg    [15:0] ptr_wr_data_o;

   output 	acc_rd_en_o;
   reg 		acc_rd_en_o;
   output [2:0] acc_rd_idx_o;
   reg    [2:0] acc_rd_idx_o;
   input [31:0] acc_rd_data_i;

   output 	 acc_wr_en_o;
   reg 		 acc_wr_en_o;
   output [1:0]	 acc_wr_mask_o;
   reg 	  [1:0]	 acc_wr_mask_o;
   output [2:0]  acc_wr_idx_o;
   reg    [2:0]  acc_wr_idx_o;
   output [31:0] acc_wr_data_o;
   reg    [31:0] acc_wr_data_o;


   output [15:0] dmem_addr_o;
   output 	 dmem_rd_en_o;
   output 	 dmem_wr_en_o;
   output [1:0]  dmem_wr_mask_o;
   reg [1:0]     dmem_wr_mask_o;

   input [31:0]  dmem_rd_data_i;
   output [31:0] dmem_wr_data_o;
   reg [31:0]    dmem_wr_data_o;

   output [5:0]  spec_regs_raddr_o;
   reg    [5:0]  spec_regs_raddr_o;
   output [5:0]  spec_regs_waddr_o;
   reg    [5:0]  spec_regs_waddr_o;
   output        spec_regs_ren_o;
   reg           spec_regs_ren_o;
   output        spec_regs_wen_o;
   reg           spec_regs_wen_o;
   input  [15:0] spec_regs_data_i;
   output [15:0] spec_regs_data_o;
   reg    [15:0] spec_regs_data_o;
   reg  [15:0]   spec_regs_data_o_r;
   reg  [15:0]   spec_regs_data_o_w;

   input [15:0]  sp_i;
   output        push_en_o;
   reg           push_en_o;
   output        pop_en_o;
   reg           pop_en_o;
   output [1:0]  stack_width_o;
   reg [1:0]     stack_width_o;

   input [15:0]  bitrev_i;
   input [15:0]  mask_sel_i;
   input [15:0]  mask_0_i;
   input [15:0]  mask_1_i;
   input [15:0]  mod_sel_i;
   input [15:0]  mod_0_i;
   input [15:0]  mod_1_i;

   input      [31:0] m_if_data_i;
   output     [31:0] m_if_addr_o;
   output     [31:0] m_if_data_o;
   output reg        m_if_read_req_o;
   output reg        m_if_write_req_o;

   reg [15:0]    spec_regs_data_i_r;

   reg [31:0] inst_pipe_0_r;
   reg [31:0] inst_pipe_1_r;

   reg [15:0] addr_pipe_1_r;

   reg [15:0]  dmem_log_addr;
   reg [15:0]  dmem_log_addr_r;
   reg         dmem_log_size_16;
   reg [15:0]  dmem_log_write_data_16;
   reg [31:0]  dmem_log_write_data_32;
   reg [15:0]  dmem_log_read_data_16;
   reg [31:0]  dmem_log_read_data_32;
   reg         dmem_log_write_en;
   reg         dmem_log_read_en;

   reg [15:0]  mv_16_w;
   reg [15:0]  mv_16_r;

   reg [15:0]  addptr_sum;
   reg [15:0]  addptr_sum_pipe_r;

   reg [15:0]  ptr_post_inc_w, ptr_post_inc_r;

   reg [15:0]  adder_mod_val;
   wire [15:0] adder_res;

   reg [15:0]  curr_mask;
   reg [1:0]   mask_sel_array[0:7];

   wire        commit_pipe_0_w;
   reg         commit_pipe_1_r;

   assign pred_tst_idx_o = inst_pipe_0_r[31:30];
   assign commit_pipe_0_w = inst_pipe_0_r[INSN_SIZE_BIT] ? pred_tst_bit_i ^ inst_pipe_0_r[INSN_PRED_NEG_BIT] : 1;

   always @(ptr_rd_idx_o or mask_sel_i or mask_0_i or mask_1_i)
     begin

        mask_sel_array[0] = mask_sel_i[1:0];
        mask_sel_array[1] = mask_sel_i[3:2];
        mask_sel_array[2] = mask_sel_i[5:4];
        mask_sel_array[3] = mask_sel_i[7:6];

        mask_sel_array[4] = mask_sel_i[9:8];
        mask_sel_array[5] = mask_sel_i[11:10];
        mask_sel_array[6] = mask_sel_i[13:12];
        mask_sel_array[7] = mask_sel_i[15:14];

        case (mask_sel_array[ptr_rd_idx_o])
          2'b00: begin /* No mask */
             curr_mask = 16'hffff;
          end
          2'b01: begin /* Mask 0 */
             curr_mask = mask_0_i;
          end
          2'b01: begin /* Mask 1 */
             curr_mask = mask_1_i;
          end
          default: begin /* Reserved (no mask) */
             curr_mask = 16'hffff;
          end
         endcase

     end

   reg [15:0]  curr_mod;
   reg [1:0]   mod_sel_array[0:7];


   always @(ptr_rd_idx_o or adder_mod_val or mod_sel_i or mod_0_i or mod_1_i)
     begin

        mod_sel_array[0] = mod_sel_i[1:0];
        mod_sel_array[1] = mod_sel_i[3:2];
        mod_sel_array[2] = mod_sel_i[5:4];
        mod_sel_array[3] = mod_sel_i[7:6];

        mod_sel_array[4] = mod_sel_i[9:8];
        mod_sel_array[5] = mod_sel_i[11:10];
        mod_sel_array[6] = mod_sel_i[13:12];
        mod_sel_array[7] = mod_sel_i[15:14];

        case (mod_sel_array[ptr_rd_idx_o])
          2'b00: begin /* No mod */
             curr_mod = adder_mod_val;
          end
          2'b01: begin /* Mod 0 */
             curr_mod = mod_0_i;
          end
          2'b01: begin /* Mod 1 */
             curr_mod = mod_1_i;
          end
          default: begin /* Reserved (no mod) */
             curr_mod = adder_mod_val;
          end
         endcase

     end

   ptr_adder adder_0(.ptr_i(ptr_rd_data_i),
                     .mod_i(curr_mod),
                     .mask_i(curr_mask),
                     .bitrev_i(bitrev_i[ptr_rd_idx_o]),
                     .ptr_o(adder_res));

   assign dmem_addr_o = {dmem_log_addr[15:1], 1'b0};
   assign dmem_rd_en_o = dmem_log_read_en;
   assign dmem_wr_en_o = dmem_log_write_en;

   assign m_if_addr_o = {ptr_2nd_rd_data_i, ptr_rd_data_i};
   assign m_if_data_o = acc_rd_data_i;

   /* DMEM read logic */
   always @(posedge clk)
     begin
        if (rst)
          begin
             dmem_log_addr_r <= 0;
          end
        else if (clk_en)
          begin
             dmem_log_addr_r <= dmem_log_addr;
          end
     end

   always @(dmem_log_addr_r or dmem_rd_data_i)
     begin
        dmem_log_read_data_32 = dmem_rd_data_i;
        if (dmem_log_addr_r[0])
          begin
             dmem_log_read_data_16 = dmem_rd_data_i[31:16];
          end
        else
          begin
             dmem_log_read_data_16 = dmem_rd_data_i[15:0];
          end
     end

   /* DMEM write logic */
   always @(dmem_log_addr or dmem_log_size_16 or dmem_log_write_data_16 or
            dmem_log_write_data_32)
     begin
        if (dmem_log_size_16)
          begin
             if (dmem_log_addr[0])
               begin
                  dmem_wr_data_o = {dmem_log_write_data_16, 16'h0};
                  dmem_wr_mask_o = 2'b10;
               end
             else
               begin
                  dmem_wr_data_o = {16'h0, dmem_log_write_data_16};
                  dmem_wr_mask_o = 2'b01;
               end
          end
        else
          begin
             dmem_wr_data_o = dmem_log_write_data_32;
             dmem_wr_mask_o = 2'b11;
          end
     end

   always @(posedge clk)
     begin
	if (rst)
	  begin
	     inst_pipe_0_r <= 32'h0;
	     inst_pipe_1_r <= 32'h0;
	     addr_pipe_1_r <= 16'h0;
             spec_regs_data_i_r <= 16'h0;
             spec_regs_data_o_r <= 16'h0;
             mv_16_r <= 16'h0;
             addptr_sum_pipe_r <= 0;
             ptr_post_inc_r <= 0;
             commit_pipe_1_r <= 0;
	  end
	else if (clk_en)
	  begin
	     inst_pipe_0_r <= inst;
	     inst_pipe_1_r <= inst_pipe_0_r;
	     addr_pipe_1_r <= ptr_rd_data_i;
             spec_regs_data_i_r <= spec_regs_data_i;
             spec_regs_data_o_r <= spec_regs_data_o_w;
             mv_16_r <= mv_16_w;
             addptr_sum_pipe_r <= addptr_sum;
             ptr_post_inc_r <= ptr_post_inc_w;
             commit_pipe_1_r <= commit_pipe_0_w;
	  end
     end

   /*
    * Pipeline stage #0
    */
   always @(inst_pipe_0_r or ptr_rd_data_i or ptr_2nd_rd_data_i or acc_rd_data_i or sp_i or
            spec_regs_data_i or adder_res or commit_pipe_0_w)
     begin
	ptr_rd_en_o  = 0;
        ptr_rd_idx_o = 0;

        acc_rd_en_o  = 0;
        acc_rd_idx_o = 0;

	dmem_log_read_en  = 0;
	dmem_log_write_en = 0;
        dmem_log_addr     = 0;
        dmem_log_size_16  = 0;
        dmem_log_write_data_16 = 0;
        dmem_log_write_data_32 = 0;

        spec_regs_ren_o  = 0;
        spec_regs_raddr_o = 0;
        spec_regs_data_o_w = 0;

        push_en_o = 0;
        pop_en_o  = 0;
        stack_width_o = 0;

        mv_16_w = 0;

        addptr_sum = 0;
        ptr_post_inc_w = 0;

        adder_mod_val = 0;

        ptr_2nd_rd_en_o = 0;
        ptr_2nd_rd_idx_o = 0;

        m_if_read_req_o  = 0;
        m_if_write_req_o = 0;

        if (inst_pipe_0_r[INSN_SIZE_BIT] & inst_pipe_0_r[INSN_ENC_BIT])
          begin  /* 32 bit instruction encoding */
             if (inst_pipe_0_r[7:4] == LSU_ITYPE_ADDPTR_16)
	       begin
	          ptr_rd_en_o = 1;
	          ptr_rd_idx_o = inst_pipe_0_r[27:25];
/*	          addptr_sum = ptr_rd_data_i +
                               {{3{inst_pipe_0_r[24]}}, inst_pipe_0_r[24:13]}; */
                  adder_mod_val = {{4{inst_pipe_0_r[24]}}, inst_pipe_0_r[24:13]};
                  addptr_sum    = adder_res;
	       end

             if (inst_pipe_0_r[7:4] == LSU_ITYPE_LD_OFF_16 ||
                 inst_pipe_0_r[7:4] == LSU_ITYPE_LD_OFF_32)
	       begin
	          ptr_rd_en_o = 1;
	          ptr_rd_idx_o = inst_pipe_0_r[27:25];
	          dmem_log_read_en = 1;
                  dmem_log_size_16  = 1;
	          dmem_log_addr = ptr_rd_data_i +
                                  {{4{inst_pipe_0_r[24]}}, inst_pipe_0_r[24:13]};
/*                  adder_mod_val = {{3{inst_pipe_0_r[24]}}, inst_pipe_0_r[24:13]};
                  dmem_log_addr = adder_res; */
	       end

             if (inst_pipe_0_r[7:4] == LSU_ITYPE_ST_OFF_32)
	       begin
	          ptr_rd_en_o = 1;
	          ptr_rd_idx_o = inst_pipe_0_r[27:25];

                  dmem_log_write_en = 1 & commit_pipe_0_w;
                  dmem_log_size_16  = 0;
	          dmem_log_addr = ptr_rd_data_i +
                                  {{4{inst_pipe_0_r[24]}}, inst_pipe_0_r[24:13]};
/*                  adder_mod_val = {{3{inst_pipe_0_r[24]}}, inst_pipe_0_r[24:13]};
                  dmem_log_addr = adder_res; */

		  acc_rd_en_o = 1;
		  acc_rd_idx_o = inst_pipe_0_r[11:9];
                  dmem_log_write_data_32 = acc_rd_data_i;
	       end

             if (inst_pipe_0_r[7:4] == LSU_ITYPE_ST_OFF_16)
	       begin
	          ptr_rd_en_o = 1;
	          ptr_rd_idx_o = inst_pipe_0_r[27:25];

                  dmem_log_write_en = 1 & commit_pipe_0_w;
                  dmem_log_size_16  = 1;
                  dmem_log_addr = ptr_rd_data_i +
                                  {{4{inst_pipe_0_r[24]}}, inst_pipe_0_r[24:13]};
/*                  adder_mod_val = {{4{inst_pipe_0_r[24]}}, inst_pipe_0_r[24:13]};
                  dmem_log_addr = adder_res; */

                  if (inst_pipe_0_r[12])  /* $acc */
	            begin
		       acc_rd_en_o = 1;
		       acc_rd_idx_o = inst_pipe_0_r[11:9];
                       if (inst_pipe_0_r[8])
                         begin
                            dmem_log_write_data_16 = acc_rd_data_i[31:16];
                         end
                       else
                         begin
                            dmem_log_write_data_16 = acc_rd_data_i[15:0];
                         end
	            end
	          else  /* $ptr */
	            begin
                       ptr_2nd_rd_en_o = 1;
                       ptr_2nd_rd_idx_o = inst_pipe_0_r[10:8];
                       dmem_log_write_data_16 = ptr_2nd_rd_data_i;
	            end
	       end

             if (inst_pipe_0_r[7:4] == LSU_ITYPE_MVTS_16)
               begin

                  if (inst_pipe_0_r[12])  /* $acc */
	            begin
		       acc_rd_en_o = 1;
		       acc_rd_idx_o = inst_pipe_0_r[11:9];

                       if (inst_pipe_0_r[8])
                         begin
                            spec_regs_data_o_w = acc_rd_data_i[31:16];
                         end
                       else
                         begin
                            spec_regs_data_o_w = acc_rd_data_i[15:0];
                         end
	            end
                  else  /* $ptr */
                    begin
                       ptr_rd_en_o      = 1;
                       ptr_rd_idx_o     = inst_pipe_0_r[10:8];
                       spec_regs_data_o_w = ptr_rd_data_i;
                    end
               end

             if (inst_pipe_0_r[7:4] == LSU_ITYPE_MVFS_16)
               begin

                  spec_regs_raddr_o = inst_pipe_0_r[18:13];
                  spec_regs_ren_o = 1;

               end

             if (inst_pipe_0_r[7:4] == LSU_ITYPE_LD_EXT_32)
               begin
                  ptr_rd_en_o      = 1;
                  ptr_rd_idx_o     = inst_pipe_0_r[10:8];
                  ptr_2nd_rd_en_o  = 1;
                  ptr_2nd_rd_idx_o = inst_pipe_0_r[13:11];

                  m_if_read_req_o = commit_pipe_0_w;
               end

             if (inst_pipe_0_r[7:4] == LSU_ITYPE_ST_EXT_32)
               begin
                  ptr_rd_en_o      = 1;
                  ptr_rd_idx_o     = inst_pipe_0_r[10:8];
                  ptr_2nd_rd_en_o  = 1;
                  ptr_2nd_rd_idx_o = inst_pipe_0_r[13:11];

                  acc_rd_en_o  = 1;
		  acc_rd_idx_o = inst_pipe_0_r[16:14];

                  m_if_write_req_o = commit_pipe_0_w;
               end
          end  /* 32 bit instruction encoding */
        else
          begin  /* 16 bit instruction encoding */

	     if (inst_pipe_0_r[7:4] == LSU_ITYPE_LD_16 ||
                 inst_pipe_0_r[7:4] == LSU_ITYPE_LD_INC_16)
	       begin
	          ptr_rd_en_o = 1;
	          ptr_rd_idx_o = inst_pipe_0_r[10:8];
	          dmem_log_read_en = 1;
                  dmem_log_size_16  = 1;
	          dmem_log_addr = ptr_rd_data_i;
/*                  ptr_post_inc_w = ptr_rd_data_i + 1; */
                  adder_mod_val  = 1;
                  ptr_post_inc_w = adder_res;
	       end

	     if (inst_pipe_0_r[7:4] == LSU_ITYPE_LD_32 ||
                 inst_pipe_0_r[7:4] == LSU_ITYPE_LD_INC_32)
	       begin
	          ptr_rd_en_o = 1;
	          ptr_rd_idx_o = inst_pipe_0_r[10:8];
	          dmem_log_read_en = 1;
                  dmem_log_size_16  = 0;
	          dmem_log_addr = ptr_rd_data_i;
/*                  ptr_post_inc_w = ptr_rd_data_i + 2; */
                  adder_mod_val  = 2;
                  ptr_post_inc_w = adder_res;
	       end

	     if (inst_pipe_0_r[7:4] == LSU_ITYPE_ST_16 ||
                 inst_pipe_0_r[7:4] == LSU_ITYPE_ST_INC_16)
	       begin
	          ptr_rd_en_o = 1;
	          ptr_rd_idx_o = inst_pipe_0_r[10:8];

                  dmem_log_write_en = 1 & commit_pipe_0_w;
                  dmem_log_size_16  = 1;
	          dmem_log_addr = ptr_rd_data_i;
/*                  ptr_post_inc_w = ptr_rd_data_i + 1; */
                  adder_mod_val  = 1;
                  ptr_post_inc_w = adder_res;

                  if (inst_pipe_0_r[15])  /* $acc */
	            begin
		       acc_rd_en_o = 1;
		       acc_rd_idx_o = inst_pipe_0_r[14:12];
                       if (inst_pipe_0_r[11])
                         begin
                            dmem_log_write_data_16 = acc_rd_data_i[31:16];
                         end
                       else
                         begin
                            dmem_log_write_data_16 = acc_rd_data_i[15:0];
                         end
	            end
	          else  /* $ptr */
	            begin
                       ptr_2nd_rd_en_o = 1;
                       ptr_2nd_rd_idx_o = inst_pipe_0_r[13:11];
                       dmem_log_write_data_16 = ptr_2nd_rd_data_i;
	            end

	       end

	     if (inst_pipe_0_r[7:4] == LSU_ITYPE_ST_32 ||
                 inst_pipe_0_r[7:4] == LSU_ITYPE_ST_INC_32)
	       begin
	          ptr_rd_en_o = 1;
	          ptr_rd_idx_o = inst_pipe_0_r[10:8];

                  dmem_log_write_en = 1 & commit_pipe_0_w;
                  dmem_log_size_16  = 0;
	          dmem_log_addr = ptr_rd_data_i;

		  acc_rd_en_o = 1;
		  acc_rd_idx_o = inst_pipe_0_r[13:11];
                  dmem_log_write_data_32 = acc_rd_data_i;
/*                  ptr_post_inc_w = ptr_rd_data_i + 2; */
                  adder_mod_val  = 2;
                  ptr_post_inc_w = adder_res;

	       end

	     if (inst_pipe_0_r[7:4] == LSU_ITYPE_MV_ACC_PTR_16)
	       begin
                  if (inst_pipe_0_r[8])  /* mv $acc -> $ptr */
                    begin
                       acc_rd_en_o = 1;
		       acc_rd_idx_o = inst_pipe_0_r[15:13];

                       if (inst_pipe_0_r[12])
                         begin
                            mv_16_w = acc_rd_data_i[31:16];
                         end
                       else
                         begin
                            mv_16_w = acc_rd_data_i[15:0];
                         end
                    end
                  else  /* mv $ptr -> $acc */
                    begin
                       ptr_rd_en_o = 1;
	               ptr_rd_idx_o = inst_pipe_0_r[11:9];
                       mv_16_w = ptr_rd_data_i;
                    end
               end

	     if (inst_pipe_0_r[7:4] == LSU_ITYPE_MV_ACC_ACC_16)
	       begin
                  acc_rd_en_o = 1;
		  acc_rd_idx_o = inst_pipe_0_r[15:13];

                  if (inst_pipe_0_r[12])
                    begin
                       mv_16_w = acc_rd_data_i[31:16];
                    end
                  else
                    begin
                       mv_16_w = acc_rd_data_i[15:0];
                    end
               end

             if (inst_pipe_0_r[7:4] == LSU_ITYPE_MV_PTR_PTR_16)
	       begin
                  ptr_rd_en_o = 1;
	          ptr_rd_idx_o = inst_pipe_0_r[11:9];
                  mv_16_w = ptr_rd_data_i;
               end

             if (inst_pipe_0_r[7:4] == LSU_ITYPE_PUSH_POP_16_32)
               begin

                  dmem_log_size_16  = ~inst_pipe_0_r[9];
	          dmem_log_addr = sp_i;
                  stack_width_o = inst_pipe_0_r[9] ? 2'b10 : 2'b01;

                  spec_regs_raddr_o = inst_pipe_0_r[15:11];

                  if (inst_pipe_0_r[8])  /* Push */
                    begin
                       push_en_o = 1;
                       dmem_log_write_en = 1 & commit_pipe_0_w;
                       dmem_log_write_data_32 = acc_rd_data_i;

                       if (inst_pipe_0_r[10])
                         begin
                            dmem_log_write_data_16 = spec_regs_data_i;
                            spec_regs_ren_o = 1;
                         end
                       else
                         begin
                            if (inst_pipe_0_r[15])  /* $acc */
	                      begin
		                 acc_rd_en_o = 1;
		                 acc_rd_idx_o = inst_pipe_0_r[14:12];
                                 if (inst_pipe_0_r[11])
                                   begin
                                      dmem_log_write_data_16 = acc_rd_data_i[31:16];
                                   end
                                 else
                                   begin
                                      dmem_log_write_data_16 = acc_rd_data_i[15:0];
                                   end
	                      end
	                    else  /* $ptr */
	                      begin
                                 ptr_rd_idx_o = inst_pipe_0_r[13:11];
                                 dmem_log_write_data_16 = ptr_rd_data_i;
	                      end
                         end
                    end
                  else  /* Pop */
                    begin
                       dmem_log_read_en = 1;
                       pop_en_o = 1;
                    end
               end

	     if (inst_pipe_0_r[7:4] == LSU_ITYPE_MV_ACC_PTR_16)
               begin
               end

          end  /* 16 bit instruction encoding */

     end

   /*
    * Pipeline stage #1
    */
   always @(inst_pipe_1_r or addr_pipe_1_r or dmem_rd_data_i or
            dmem_log_read_data_16 or dmem_log_read_data_32 or
            spec_regs_data_i_r or spec_regs_data_o_r or mv_16_r or
            addptr_sum_pipe_r or ptr_post_inc_r or commit_pipe_1_r or
            m_if_data_i)
     begin
	ptr_wr_en_o = 0;
	ptr_wr_idx_o = 0;
	ptr_wr_data_o = 0;

	acc_wr_en_o = 0;
	acc_wr_idx_o = 0;
        acc_wr_mask_o = 0;
	acc_wr_data_o = 0;

        spec_regs_data_o = 0;
        spec_regs_waddr_o = 0;
        spec_regs_wen_o  = 0;

        if (inst_pipe_1_r[INSN_SIZE_BIT] & inst_pipe_1_r[INSN_ENC_BIT])
          begin  /* 32 bit instruction encoding */

             if (inst_pipe_1_r[7:4] == LSU_ITYPE_ADDPTR_16)
               begin
                  ptr_wr_en_o   = 1 & commit_pipe_1_r;
	          ptr_wr_idx_o  = inst_pipe_1_r[27:25];
	          ptr_wr_data_o = addptr_sum_pipe_r;
               end

	     if (inst_pipe_1_r[7:4] == LSU_ITYPE_LD_IMM_ACC_16)
	       begin
		  acc_wr_en_o = 1 & commit_pipe_1_r;
		  acc_wr_idx_o = inst_pipe_1_r[11:9];
                  if (inst_pipe_1_r[8])
                    begin
		       acc_wr_data_o[31:16] = inst_pipe_1_r[27:12];
                       acc_wr_mask_o = 2'b10;
                    end
                  else
                    begin
                       acc_wr_data_o[15:0] = inst_pipe_1_r[27:12];
                       acc_wr_mask_o = 2'b01;
                    end
	       end

             if (inst_pipe_1_r[7:4] == LSU_ITYPE_LD_IMM_PTR_16)
	       begin
		  ptr_wr_en_o = 1 & commit_pipe_1_r;
		  ptr_wr_idx_o = inst_pipe_1_r[10:8];
		  ptr_wr_data_o = inst_pipe_1_r[27:12];
	       end

             if (inst_pipe_1_r[7:4] == LSU_ITYPE_LD_OFF_16)
	       begin
	          if (inst_pipe_1_r[12])
	            begin
		       acc_wr_en_o = 1 & commit_pipe_1_r;
                       acc_wr_idx_o = inst_pipe_1_r[11:9];
                       if (inst_pipe_1_r[8])
                         begin
		            acc_wr_data_o = {dmem_log_read_data_16, 16'h0};
                            acc_wr_mask_o = 2'b10;
                         end
                       else
                         begin
                            acc_wr_data_o = {16'h0, dmem_log_read_data_16};
                            acc_wr_mask_o = 2'b01;
                         end
	            end
	          else
	            begin
		       ptr_wr_en_o = 1 & commit_pipe_1_r;
		       ptr_wr_idx_o = inst_pipe_1_r[10:8];
		       ptr_wr_data_o = dmem_log_read_data_16;
	            end
	       end

             if (inst_pipe_1_r[7:4] == LSU_ITYPE_LD_OFF_32)
	       begin
		  acc_wr_en_o   = 1 & commit_pipe_1_r;
                  acc_wr_idx_o  = inst_pipe_1_r[11:9];
		  acc_wr_data_o = dmem_log_read_data_32;
                  acc_wr_mask_o = 2'b11;
	       end

             if (inst_pipe_1_r[7:4] == LSU_ITYPE_MVTS_16)
               begin
                  spec_regs_waddr_o = inst_pipe_1_r[18:13];
                  spec_regs_wen_o  = 1 & commit_pipe_1_r;
                  spec_regs_data_o = spec_regs_data_o_r;
               end

             if (inst_pipe_1_r[7:4] == LSU_ITYPE_MVFS_16)
               begin
	          if (inst_pipe_1_r[12])  /* $acc */
	            begin
		       acc_wr_en_o = 1 & commit_pipe_1_r;
		       acc_wr_idx_o = inst_pipe_1_r[11:9];

                       if (inst_pipe_1_r[8])
                         begin
		            acc_wr_data_o[31:16] = spec_regs_data_i_r;
                            acc_wr_mask_o = 2'b10;
                         end
                       else
                         begin
                            acc_wr_data_o[15:0] = spec_regs_data_i_r;
                            acc_wr_mask_o = 2'b01;
                         end
	            end
                  else  /* $ptr */
                    begin
                       ptr_wr_en_o   = 1 & commit_pipe_1_r;
                       ptr_wr_idx_o  = inst_pipe_1_r[10:8];
                       ptr_wr_data_o = spec_regs_data_i_r;
                    end

               end

             if (inst_pipe_1_r[7:4] == LSU_ITYPE_LD_EXT_32)
               begin
                  acc_wr_en_o = 1 & commit_pipe_1_r;
		  acc_wr_idx_o = inst_pipe_1_r[16:14];

		  acc_wr_data_o[31:0] = m_if_data_i;
                  acc_wr_mask_o = 2'b11;
               end

          end  /* 32 bit instruction encoding */
        else
          begin  /* 16 bit instruction encoding */

             if (inst_pipe_1_r[7:4] == LSU_ITYPE_MV_ACC_PTR_16)
	       begin
	          if (inst_pipe_1_r[8])  /* mv $acc -> $ptr */
                    begin
		       ptr_wr_en_o = 1 & commit_pipe_1_r;
		       ptr_wr_idx_o = inst_pipe_1_r[11:9];
		       ptr_wr_data_o = mv_16_r;
	            end
	          else  /* mv $ptr -> $acc */
                    begin
		       acc_wr_en_o = 1 & commit_pipe_1_r;
                       acc_wr_idx_o = inst_pipe_1_r[15:13];
                       if (inst_pipe_1_r[12])
                         begin
		            acc_wr_data_o = {mv_16_r, 16'h0};
                            acc_wr_mask_o = 2'b10;
                         end
                       else
                         begin
                            acc_wr_data_o = {16'h0, mv_16_r};
                            acc_wr_mask_o = 2'b01;
                         end
	            end
	       end

             if (inst_pipe_1_r[7:4] == LSU_ITYPE_MV_PTR_PTR_16)
	       begin
                  begin
		     ptr_wr_en_o = 1 & commit_pipe_1_r;
		     ptr_wr_idx_o = inst_pipe_1_r[14:12];
		     ptr_wr_data_o = mv_16_r;
	          end
	       end

             if (inst_pipe_1_r[7:4] == LSU_ITYPE_MV_ACC_ACC_16)
	       begin
		  acc_wr_en_o = 1 & commit_pipe_1_r;
                  acc_wr_idx_o = inst_pipe_1_r[11:9];
                  if (inst_pipe_1_r[8])
                    begin
		       acc_wr_data_o = {mv_16_r, 16'h0};
                       acc_wr_mask_o = 2'b10;
                    end
                  else
                    begin
                       acc_wr_data_o = {16'h0, mv_16_r};
                       acc_wr_mask_o = 2'b01;
                    end
	       end

	     if (inst_pipe_1_r[7:4] == LSU_ITYPE_LD_16 ||
                 inst_pipe_1_r[7:4] == LSU_ITYPE_LD_INC_16)
	       begin
	          if (inst_pipe_1_r[15])
	            begin
		       acc_wr_en_o = 1 & commit_pipe_1_r;
                       acc_wr_idx_o = inst_pipe_1_r[14:12];
                       if (inst_pipe_1_r[11])
                         begin
		            acc_wr_data_o = {dmem_log_read_data_16, 16'h0};
                            acc_wr_mask_o = 2'b10;
                         end
                       else
                         begin
                            acc_wr_data_o = {16'h0, dmem_log_read_data_16};
                            acc_wr_mask_o = 2'b01;
                         end
	            end
	          else
	            begin
		       ptr_wr_en_o = 1 & commit_pipe_1_r;
		       ptr_wr_idx_o = inst_pipe_1_r[13:11];
		       ptr_wr_data_o = dmem_log_read_data_16;
	            end

                  if (inst_pipe_1_r[7:4] == LSU_ITYPE_LD_INC_16 && inst_pipe_1_r[15])
                    begin
	               ptr_wr_en_o   = 1 & commit_pipe_1_r;
	               ptr_wr_idx_o  = inst_pipe_1_r[10:8];
	               ptr_wr_data_o = ptr_post_inc_r;
                    end
	       end

	     if (inst_pipe_1_r[7:4] == LSU_ITYPE_LD_32 ||
                 inst_pipe_1_r[7:4] == LSU_ITYPE_LD_INC_32)
	       begin
		  acc_wr_en_o   = 1 & commit_pipe_1_r;
                  acc_wr_idx_o  = inst_pipe_1_r[13:11];
		  acc_wr_data_o = dmem_log_read_data_32;
                  acc_wr_mask_o = 2'b11;

                  if (inst_pipe_1_r[7:4] == LSU_ITYPE_LD_INC_32)
                    begin
                       ptr_wr_en_o   = 1 & commit_pipe_1_r;
	               ptr_wr_idx_o  = inst_pipe_1_r[10:8];
	               ptr_wr_data_o = ptr_post_inc_r;
                    end

	       end

             if (inst_pipe_1_r[7:4] == LSU_ITYPE_PUSH_POP_16_32)
               begin
                  if (inst_pipe_1_r[8])  /* Push */
                    begin
                       /* Do nothing in this pipeline stage */
                    end
                  else  /* Pop */
                    begin
                       if (inst_pipe_1_r[10])  /* $spec */
                         begin
                            spec_regs_waddr_o = inst_pipe_1_r[15:11];
                            spec_regs_wen_o   = 1 & commit_pipe_1_r;
                            spec_regs_data_o  = dmem_log_read_data_16;
                         end
                       else
                         begin
                            if (inst_pipe_1_r[15])  /* $acc */
	                      begin
		                 acc_wr_en_o = 1 & commit_pipe_1_r;
		                 acc_wr_idx_o = inst_pipe_1_r[14:12];
                                 if (inst_pipe_1_r[9])  /* pop32 */
                                   begin
                                      acc_wr_data_o = dmem_log_read_data_32;
                                      acc_wr_mask_o = 2'b11;
                                   end
                                 else /* pop16 */
                                   begin
                                      if (inst_pipe_1_r[11])
                                        begin
                                           acc_wr_data_o = {dmem_log_read_data_16, 16'h0};
                                           acc_wr_mask_o = 2'b10;
                                        end
                                      else
                                        begin
                                           acc_wr_data_o = {16'h0, dmem_log_read_data_16};
                                           acc_wr_mask_o = 2'b01;
                                        end
                                   end
	                      end
	                    else  /* $ptr */
	                      begin
                                 ptr_wr_en_o   = 1 & commit_pipe_1_r;
                                 ptr_wr_idx_o  = inst_pipe_1_r[13:11];
                                 ptr_wr_data_o = dmem_log_read_data_16;
	                      end
                         end
                    end
               end

             if (inst_pipe_1_r[7:4] == LSU_ITYPE_ST_INC_16 && inst_pipe_1_r[15])
               begin
	          ptr_wr_en_o   = 1 & commit_pipe_1_r;
	          ptr_wr_idx_o  = inst_pipe_1_r[10:8];
	          ptr_wr_data_o = ptr_post_inc_r;
               end

             if (inst_pipe_1_r[7:4] == LSU_ITYPE_ST_INC_32)
               begin
                  ptr_wr_en_o   = 1 & commit_pipe_1_r;
	          ptr_wr_idx_o  = inst_pipe_1_r[10:8];
	          ptr_wr_data_o = ptr_post_inc_r;
               end
          end  /* 16 bit instruction encoding */
     end

endmodule // lsu

module ptr_adder(ptr_i, mod_i, mask_i, bitrev_i, ptr_o);

   input  [15:0] ptr_i, mod_i, mask_i;
   input         bitrev_i;
   output reg [15:0] ptr_o;

   reg [15:0]    ptr_rev, sum;
   integer       i;

   always @(ptr_i or mod_i or mask_i or bitrev_i)
     begin

        /* Bit-reverse */
        for (i = 0; i < 16; i = i + 1)
          begin
             ptr_rev[i] = ptr_i[15-i];
          end

        /* Compute the sum */
        if (bitrev_i)
          sum = ptr_rev + mod_i;
        else
          sum = ptr_i + mod_i;

        /* Possibly bit-reverse output and apply mask */
        for (i = 0; i < 16; i = i + 1)
          begin
             if (bitrev_i)
               ptr_o[i] = mask_i[15-i] ? sum[15-i] : ptr_i[i];
             else
               ptr_o[i] = mask_i[i] ? sum[i] : ptr_i[i];
          end
     end

endmodule

`ifdef PTRADD_TB
module ptradd_tb;

   reg [15:0] ptr_in, mod, mask;
   wire [15:0] ptr_out;
   integer    i;


   ptr_adder ptradd_0(.ptr_i(ptr_in), .mod_i(mod), .mask_i(mask), .bitrev_i(1'b0), .ptr_o(ptr_out));

   initial begin
      $dumpvars;

      ptr_in = 16'h1230;
      mod    = 16'h1001;
      mask   = 16'h000f;

      for (i = 0; i < 512; i = i + 1)
        begin
           #1 ptr_in = ptr_out;
        end

      $finish;
   end

endmodule

`endif

module lsuregs(clk, rst,

               bitrev_o,

               mask_sel_o,
               mask_0_o,
               mask_1_o,

               mod_sel_o,
               mod_0_o,
               mod_1_o,

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

   output reg [15:0] bitrev_o;
   output reg [15:0] mask_sel_o, mask_0_o, mask_1_o;
   output reg [15:0] mod_sel_o, mod_0_o, mod_1_o;

   assign spec_regs_data_o = (spec_regs_ren_i &&
                              spec_regs_raddr_i == SPEC_REGS_ADDR_BITREV)
     ? bitrev_o : 16'hzzzz;

   assign spec_regs_data_o = (spec_regs_ren_i &&
                              spec_regs_raddr_i == SPEC_REGS_ADDR_MASK_SEL)
     ? mask_sel_o : 16'hzzzz;
   assign spec_regs_data_o = (spec_regs_ren_i &&
                              spec_regs_raddr_i == SPEC_REGS_ADDR_MASK_0)
     ? mask_0_o : 16'hzzzz;
   assign spec_regs_data_o = (spec_regs_ren_i &&
                              spec_regs_raddr_i == SPEC_REGS_ADDR_MASK_1)
     ? mask_1_o : 16'hzzzz;

   assign spec_regs_data_o = (spec_regs_ren_i &&
                              spec_regs_raddr_i == SPEC_REGS_ADDR_MOD_SEL)
     ? mod_sel_o : 16'hzzzz;
   assign spec_regs_data_o = (spec_regs_ren_i &&
                              spec_regs_raddr_i == SPEC_REGS_ADDR_MOD_0)
     ? mod_0_o : 16'hzzzz;
   assign spec_regs_data_o = (spec_regs_ren_i &&
                              spec_regs_raddr_i == SPEC_REGS_ADDR_MOD_1)
     ? mod_1_o : 16'hzzzz;

   always @(posedge clk)
     begin
        if (rst)
          begin
             bitrev_o <= 0;

             mask_sel_o <= 0;
             mask_0_o <= 0;
             mask_1_o <= 0;

             mod_sel_o <= 0;
             mod_0_o <= 0;
             mod_1_o <= 0;
          end
        else
          begin
             if (spec_regs_wen_i)
               begin
                  case (spec_regs_waddr_i)
                    SPEC_REGS_ADDR_BITREV: begin
                       bitrev_o <= spec_regs_data_i;
                    end

                    SPEC_REGS_ADDR_MASK_SEL: begin
                       mask_sel_o <= spec_regs_data_i;
                    end
                    SPEC_REGS_ADDR_MASK_0: begin
                       mask_0_o <= spec_regs_data_i;
                    end
                    SPEC_REGS_ADDR_MASK_1: begin
                       mask_1_o <= spec_regs_data_i;
                    end

                    SPEC_REGS_ADDR_MOD_SEL: begin
                       mod_sel_o <= spec_regs_data_i;
                    end
                    SPEC_REGS_ADDR_MOD_0: begin
                       mod_0_o <= spec_regs_data_i;
                    end
                    SPEC_REGS_ADDR_MOD_1: begin
                       mod_1_o <= spec_regs_data_i;
                    end
                  endcase
               end
          end
     end

endmodule
