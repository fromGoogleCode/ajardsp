// This file is part of AjarDSP
//
// Copyright (c) 2010, 2011 Markus Lavin
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

module pcu(clk,
	   rst,
           clk_en,

	   inst,
           pc_i,
           next_pc_i,
	   jump_en,
	   jump_pc,
           halt_o,
           pred_tst_idx_o,
           pred_tst_bit_i,

           spec_regs_raddr_i,
           spec_regs_waddr_i,
           spec_regs_ren_i,
           spec_regs_wen_i,
           spec_regs_data_i,
           spec_regs_data_o,

           interrupt_req_i,
           interrupt_ack_o,
           invalidate_insns_o,

	   ptr_rd_en_o,
	   ptr_rd_idx_o,
	   ptr_rd_data_i
           );

`include "specregs.v"
`include "insns.v"

   input clk;
   input rst;
   input clk_en;

   input [31:0] inst;
   input [15:0] pc_i;
   input [15:0] next_pc_i;

   output [15:0] jump_pc;
   output 	 jump_en;

   output        halt_o;
   reg           halt_o;

   output [1:0]  pred_tst_idx_o;
   input         pred_tst_bit_i;

   input [5:0]   spec_regs_raddr_i;
   input [5:0]   spec_regs_waddr_i;
   input         spec_regs_ren_i;
   input         spec_regs_wen_i;
   input  [15:0] spec_regs_data_i;
   output [15:0] spec_regs_data_o;

   input         interrupt_req_i;
   output reg    interrupt_ack_o;
   output        invalidate_insns_o;

   output        ptr_rd_en_o;
   reg           ptr_rd_en_o;
   output [2:0]  ptr_rd_idx_o;
   reg [2:0]     ptr_rd_idx_o;
   input [15:0]  ptr_rd_data_i;

   reg [15:0] jump_pc;
   reg 	      jump_en;

   reg [31:0] inst_pipe_0_r;
   reg [31:0] inst_pipe_1_r;
   reg        pred_tst_bit_pipe_1_r;

   reg [15:0] retpc_r;
   reg [15:0] retipc_r;

   reg [15:0] bkrep_begin_pc_r;
   reg [15:0] bkrep_end_pc_r;
   reg [15:0] bkrep_cnt_r;
   wire       bkrep_en_w;
   wire       bkrep_pc_at_end_w;

   reg [1:0]  dslot_r;
   reg [1:0]  interrupt_dslot_r;
   reg        interrupt_enable_r;

   wire       pred_tst_bit_w;

   reg        invalidate_dslot_r;
   reg [1:0]  req_dslots, req_dslots_pipe_r;
   reg [15:0] prev_pc_r;

   assign bkrep_en_w        = (bkrep_cnt_r != 0);
   assign bkrep_pc_at_end_w = (bkrep_end_pc_r == pc_i);

   assign invalidate_insns_o = interrupt_dslot_r[0] | interrupt_ack_o |
                               (req_dslots == 0 ? 1'b1 : 1'b0) | invalidate_dslot_r;

   always @(posedge clk)
     begin
        if (rst)
          begin
             dslot_r <= 0;
          end
        else if (clk_en)
          begin
             if (jump_en)
               begin
                  dslot_r <= 2'b11;
               end
             else
               begin
                  dslot_r <= {1'b0, dslot_r[1]};
               end
          end
     end

   always @(posedge clk)
     begin
        if (rst)
          begin
             invalidate_dslot_r <= 0;
          end
        else if (clk_en)
          begin
             if (req_dslots == 0 || req_dslots == 1)
               begin
                  invalidate_dslot_r <= 1;
               end
             else
               begin
                  invalidate_dslot_r <= 0;
               end
          end
     end

   always @(posedge clk)
     begin
        if (rst)
          begin
             interrupt_dslot_r <= 0;
          end
        else if (clk_en)
          begin
             if (interrupt_ack_o)
               begin
                  interrupt_dslot_r <= 2'b01;
               end
             else
               begin
                  interrupt_dslot_r <= {1'b0, interrupt_dslot_r[1]};
               end
          end
     end

   always @(posedge clk)
     begin
        if (rst)
          begin
             interrupt_enable_r <= 0;
          end
        else if (clk_en)
          begin
             if (interrupt_ack_o)
               begin
                  interrupt_enable_r <= 0;
               end
             else
               begin
                  case (inst_pipe_0_r[7:4])
                    PCU_ITYPE_RETI: begin
                       interrupt_enable_r <= 1;
                    end
                    PCU_ITYPE_EINT: begin
                       interrupt_enable_r <= 1;
                    end
                    PCU_ITYPE_DINT: begin
                       interrupt_enable_r <= 0;
                    end
                  endcase
               end
          end
     end

   always @(posedge clk)
     begin
        if (rst)
          begin
             bkrep_begin_pc_r <= 0;
             bkrep_end_pc_r   <= 0;
             bkrep_cnt_r      <= 0;
          end
        else if (clk_en)
          begin
             if (inst_pipe_0_r[INSN_SIZE_BIT] && inst_pipe_0_r[INSN_ENC_BIT] &&
                 PCU_ITYPE_BKREP == inst_pipe_0_r[7:4])
               begin
                  bkrep_begin_pc_r <= pc_i;
                  bkrep_end_pc_r   <= inst_pipe_0_r[23:8];
               end
             else if (bkrep_en_w && bkrep_pc_at_end_w && !invalidate_insns_o)
               begin
                  bkrep_cnt_r <= bkrep_cnt_r - 1;
               end
             else if (spec_regs_wen_i && spec_regs_waddr_i == SPEC_REGS_ADDR_BKREP_CNT)
               begin
                  bkrep_cnt_r <= spec_regs_data_i;
               end
          end
     end

   assign pred_tst_idx_o = inst_pipe_0_r[31:30];
   assign pred_tst_bit_w = inst_pipe_0_r[INSN_SIZE_BIT] ? pred_tst_bit_i ^ inst_pipe_0_r[INSN_PRED_NEG_BIT] : 1;

   always @(posedge clk)
     begin
	if (rst)
	  begin
	     inst_pipe_0_r <= 0;
	     inst_pipe_1_r <= 0;
             pred_tst_bit_pipe_1_r <= 1;
             prev_pc_r <= 0;
             req_dslots_pipe_r <= 0;
	  end
	else if (clk_en)
	  begin
	     inst_pipe_0_r <= inst;
             inst_pipe_1_r <= inst_pipe_0_r;
             req_dslots_pipe_r <= req_dslots;
             pred_tst_bit_pipe_1_r <= pred_tst_bit_w;
             prev_pc_r <= pc_i;
	  end
     end // always @ (posedge clk)

   assign spec_regs_data_o = (spec_regs_ren_i && spec_regs_raddr_i == SPEC_REGS_ADDR_RETPC)
     ? retpc_r : 16'hzzzz;

   assign spec_regs_data_o = (spec_regs_ren_i && spec_regs_raddr_i == SPEC_REGS_ADDR_RETIPC)
     ? retipc_r : 16'hzzzz;

   assign spec_regs_data_o = (spec_regs_ren_i && spec_regs_raddr_i == SPEC_REGS_ADDR_BKREP_CNT)
     ? bkrep_cnt_r : 16'hzzzz;

   always @(posedge clk)
     begin
        if (rst)
          begin
             retpc_r <= 0;
          end
        else if (clk_en)
          begin
             if (spec_regs_wen_i && spec_regs_waddr_i == SPEC_REGS_ADDR_RETPC)
               begin
                  retpc_r <= spec_regs_data_i;
               end
             else if (PCU_ITYPE_CALL_ABS == inst_pipe_1_r[7:4] && pred_tst_bit_pipe_1_r)
               begin
                  case (req_dslots_pipe_r)
                    0: retpc_r <= prev_pc_r;
                    1: retpc_r <= pc_i;
                    default: retpc_r <= next_pc_i;
                  endcase
               end
          end
     end

   always @(posedge clk)
     begin
        if (rst)
          begin
             retipc_r <= 0;
          end
        else if (clk_en)
          begin
             if (spec_regs_wen_i && spec_regs_waddr_i == SPEC_REGS_ADDR_RETIPC)
               begin
                  retipc_r <= spec_regs_data_i;
               end
             else if (interrupt_ack_o)
               begin
                  retipc_r <= pc_i;
               end
          end
     end


   // Combinatorial logic for jump_en and jump_pc
   always @(inst_pipe_0_r or pred_tst_bit_w or bkrep_en_w or bkrep_pc_at_end_w or
            bkrep_begin_pc_r or retpc_r or retipc_r or interrupt_req_i or dslot_r or interrupt_enable_r)
     begin

	jump_en = 0;
	jump_pc = 16'h0;
        halt_o = 0;
        interrupt_ack_o = 0;
        req_dslots = 2;  /* 2 = no dslot suppression */
        ptr_rd_en_o = 0;
        ptr_rd_idx_o = 0;

        if (bkrep_en_w && bkrep_pc_at_end_w)
          begin
             jump_pc = bkrep_begin_pc_r;
             jump_en = 1;
          end
        else if (pred_tst_bit_w && inst_pipe_0_r[7:4] != 4'h0)
          begin
             if (inst_pipe_0_r[INSN_SIZE_BIT] && inst_pipe_0_r[INSN_ENC_BIT])
               begin  /* 32 bit instruction encoding */
                  case (inst_pipe_0_r[7:4])

                    PCU_ITYPE_CALL_ABS: begin
	               jump_pc = inst_pipe_0_r[23:8];
	               jump_en = 1;
                       req_dslots = inst_pipe_0_r[25:24];
	            end

	            PCU_ITYPE_JUMP_ABS: begin
	               jump_pc = inst_pipe_0_r[23:8];
	               jump_en = 1;
                       req_dslots = inst_pipe_0_r[25:24];
	            end

                    PCU_ITYPE_BKREP: begin
                    end
                  endcase
               end
             else
               begin  /* 16 bit instruction encoding */
                  case (inst_pipe_0_r[7:4])
/*
                    PCU_ITYPE_CALL_ABS: begin
                       ptr_rd_en_o  = 1;
                       ptr_rd_idx_o = inst_pipe_0_r[10:8];
	               jump_pc = ptr_rd_data_i;
	               jump_en = 1;
                       req_dslots = inst_pipe_0_r[13:12];
	            end

	            PCU_ITYPE_JUMP_ABS: begin
                       ptr_rd_en_o  = 1;
                       ptr_rd_idx_o = inst_pipe_0_r[10:8];
	               jump_pc = ptr_rd_data_i;
	               jump_en = 1;
                       req_dslots = inst_pipe_0_r[13:12];
	            end
*/
                    PCU_ITYPE_RETS: begin
	               jump_pc = retpc_r;
	               jump_en = 1;
                       req_dslots = inst_pipe_0_r[13:12];
	            end

                    PCU_ITYPE_RETI: begin
	               jump_pc = retipc_r;
	               jump_en = 1;
                       req_dslots = inst_pipe_0_r[13:12];
	            end

                    PCU_ITYPE_HALT: begin
                       halt_o = 1;
                    end
                  endcase
               end
          end
        else if (interrupt_req_i && ~dslot_r[0] && interrupt_enable_r)
          begin
             jump_pc = 16'h0004;  /* FIXME: Should be the interrupt vector */
             jump_en = 1;
             interrupt_ack_o = 1;
          end
     end // always @ (inst_pipe_0_r or pred_tst_bit_w or bkrep_en_w or bkrep_pc_at_end_w)

endmodule // pcu
