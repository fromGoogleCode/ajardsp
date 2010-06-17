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

	   inst,

	   ptr_rd_en_o,
	   ptr_rd_idx_o,
	   ptr_rd_data_i,

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
           stack_width_o
           );

`include "insns.v"

   input clk;
   input rst;
   input [31:0] inst;

   output 	ptr_rd_en_o;
   reg 		ptr_rd_en_o;
   output [2:0] ptr_rd_idx_o;
   reg    [2:0] ptr_rd_idx_o;
   input [15:0] ptr_rd_data_i;

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

   assign dmem_addr_o = {dmem_log_addr[15:1], 1'b0};
   assign dmem_rd_en_o = dmem_log_read_en;
   assign dmem_wr_en_o = dmem_log_write_en;

   /* DMEM read logic */
   always @(posedge clk)
     begin
        if (rst)
          begin
             dmem_log_addr_r <= 0;
          end
        else
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
	  end
	else
	  begin
	     inst_pipe_0_r <= inst;
	     inst_pipe_1_r <= inst_pipe_0_r;
	     addr_pipe_1_r <= ptr_rd_data_i;
             spec_regs_data_i_r <= spec_regs_data_i;
             spec_regs_data_o_r <= spec_regs_data_o_w;
             mv_16_r <= mv_16_w;
	  end
     end

   /*
    * Pipeline stage #0
    */
   always @(inst_pipe_0_r or ptr_rd_data_i or acc_rd_data_i or sp_i or spec_regs_data_i)
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

        push_en_o = 0;
        pop_en_o  = 0;
        stack_width_o = 0;

        mv_16_w = 0;

        if (inst_pipe_0_r[INSN_SIZE_BIT] & inst_pipe_0_r[INSN_ENC_BIT])
          begin  /* 32 bit instruction encoding */
             if (inst_pipe_0_r[7:4] == LSU_ITYPE_LD_OFF_16 ||
                 inst_pipe_0_r[7:4] == LSU_ITYPE_LD_OFF_32)
	       begin
	          ptr_rd_en_o = 1;
	          ptr_rd_idx_o = inst_pipe_0_r[28:26];
	          dmem_log_read_en = 1;
                  dmem_log_size_16  = 1;
	          dmem_log_addr = ptr_rd_data_i +
                                  {{3{inst_pipe_0_r[25]}}, inst_pipe_0_r[25:13]};
	       end

             if (inst_pipe_0_r[7:4] == LSU_ITYPE_ST_OFF_32)
	       begin
	          ptr_rd_en_o = 1;
	          ptr_rd_idx_o = inst_pipe_0_r[28:26];

                  dmem_log_write_en = 1;
                  dmem_log_size_16  = 0;
	          dmem_log_addr = ptr_rd_data_i +
                                  {{3{inst_pipe_0_r[25]}}, inst_pipe_0_r[25:13]};

		  acc_rd_en_o = 1;
		  acc_rd_idx_o = inst_pipe_0_r[11:9];
                  dmem_log_write_data_32 = acc_rd_data_i;
	       end

             if (inst_pipe_0_r[7:4] == LSU_ITYPE_ST_OFF_16)
	       begin
	          ptr_rd_en_o = 1;
	          ptr_rd_idx_o = inst_pipe_0_r[28:26];

                  dmem_log_write_en = 1;
                  dmem_log_size_16  = 1;
                  dmem_log_addr = ptr_rd_data_i +
                                  {{3{inst_pipe_0_r[25]}}, inst_pipe_0_r[25:13]};

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
                       $display("!!!Not implemented yet!!!\n");
`ifdef SIMULATION
                       $finish;
`endif
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
	       end

	     if (inst_pipe_0_r[7:4] == LSU_ITYPE_LD_32 ||
                 inst_pipe_0_r[7:4] == LSU_ITYPE_LD_INC_32)
	       begin
	          ptr_rd_en_o = 1;
	          ptr_rd_idx_o = inst_pipe_0_r[10:8];
	          dmem_log_read_en = 1;
                  dmem_log_size_16  = 0;
	          dmem_log_addr = ptr_rd_data_i;
	       end

	     if (inst_pipe_0_r[7:4] == LSU_ITYPE_ST_16 ||
                 inst_pipe_0_r[7:4] == LSU_ITYPE_ST_INC_16)
	       begin
	          ptr_rd_en_o = 1;
	          ptr_rd_idx_o = inst_pipe_0_r[10:8];

                  dmem_log_write_en = 1;
                  dmem_log_size_16  = 1;
	          dmem_log_addr = ptr_rd_data_i;

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
                       $display("!!!Not implemented yet!!!\n");
`ifdef SIMULATION
                       $finish;
`endif
	            end

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

	     if (inst_pipe_0_r[7:4] == LSU_ITYPE_ST_32 ||
                 inst_pipe_0_r[7:4] == LSU_ITYPE_ST_INC_32)
	       begin
	          ptr_rd_en_o = 1;
	          ptr_rd_idx_o = inst_pipe_0_r[10:8];

                  dmem_log_write_en = 1;
                  dmem_log_size_16  = 0;
	          dmem_log_addr = ptr_rd_data_i;

		  acc_rd_en_o = 1;
		  acc_rd_idx_o = inst_pipe_0_r[13:11];
                  dmem_log_write_data_32 = acc_rd_data_i;

	       end

             if (inst_pipe_0_r[7:4] == LSU_ITYPE_PUSH_POP_16_32)
               begin

                  dmem_log_size_16  = ~inst_pipe_0_r[9];
	          dmem_log_addr = sp_i;
                  stack_width_o = inst_pipe_0_r[9] ? 2'b10 : 2'b01;

                  spec_regs_raddr_o = inst_pipe_0_r[15:11];
                  spec_regs_ren_o = 1;

                  if (inst_pipe_0_r[8])  /* Push */
                    begin
                       push_en_o = 1;
                       dmem_log_write_en = 1;
                       dmem_log_write_data_32 = acc_rd_data_i;

                       if (inst_pipe_0_r[10])
                         begin
                            dmem_log_write_data_16 = spec_regs_data_i;
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
            spec_regs_data_i_r or spec_regs_data_o_r or mv_16_r)
     begin
	ptr_wr_en_o = 0;
	ptr_wr_idx_o = 0;
	ptr_wr_data_o = 0;

	acc_wr_en_o = 0;
	acc_wr_idx_o = 0;
        acc_wr_mask_o = 0;
	acc_wr_data_o = 0;

        spec_regs_data_o = 0;
        spec_regs_wen_o  = 0;

        if (inst_pipe_1_r[INSN_SIZE_BIT] & inst_pipe_1_r[INSN_ENC_BIT])
          begin  /* 32 bit instruction encoding */

	     if (inst_pipe_1_r[7:4] == LSU_ITYPE_LD_IMM_16)
	       begin
	          if (inst_pipe_1_r[12])
	            begin
		       acc_wr_en_o = 1;
		       acc_wr_idx_o = inst_pipe_1_r[11:9];
                       if (inst_pipe_1_r[8])
                         begin
		            acc_wr_data_o[31:16] = inst_pipe_1_r[28:13];
                            acc_wr_mask_o = 2'b10;
                         end
                       else
                         begin
                            acc_wr_data_o[15:0] = inst_pipe_1_r[28:13];
                            acc_wr_mask_o = 2'b01;
                         end
	            end
	          else
	            begin
		       ptr_wr_en_o = 1;
		       ptr_wr_idx_o = inst_pipe_1_r[10:8];
		       ptr_wr_data_o = inst_pipe_1_r[28:13];
	            end
	       end

             if (inst_pipe_1_r[7:4] == LSU_ITYPE_LD_OFF_16)
	       begin
	          if (inst_pipe_1_r[12])
	            begin
		       acc_wr_en_o = 1;
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
		       ptr_wr_en_o = 1;
		       ptr_wr_idx_o = inst_pipe_1_r[10:8];
		       ptr_wr_data_o = dmem_log_read_data_16;
	            end
	       end

             if (inst_pipe_1_r[7:4] == LSU_ITYPE_LD_OFF_32)
	       begin
		  acc_wr_en_o   = 1;
                  acc_wr_idx_o  = inst_pipe_1_r[11:9];
		  acc_wr_data_o = dmem_log_read_data_32;
                  acc_wr_mask_o = 2'b11;
	       end

             if (inst_pipe_1_r[7:4] == LSU_ITYPE_MVTS_16)
               begin
                  spec_regs_waddr_o = inst_pipe_1_r[18:13];
                  spec_regs_wen_o  = 1;
                  spec_regs_data_o = spec_regs_data_o_r;
               end

             if (inst_pipe_1_r[7:4] == LSU_ITYPE_MVFS_16)
               begin
	          if (inst_pipe_1_r[12])  /* $acc */
	            begin
		       acc_wr_en_o = 1;
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
                       ptr_wr_en_o   = 1;
                       ptr_wr_idx_o  = inst_pipe_1_r[10:8];
                       ptr_wr_data_o = spec_regs_data_i_r;
                    end

               end
          end  /* 32 bit instruction encoding */
        else
          begin  /* 16 bit instruction encoding */

             if (inst_pipe_1_r[7:4] == LSU_ITYPE_MV_ACC_PTR_16)
	       begin
	          if (inst_pipe_1_r[8])  /* mv $acc -> $ptr */
                    begin
		       ptr_wr_en_o = 1;
		       ptr_wr_idx_o = inst_pipe_1_r[11:9];
		       ptr_wr_data_o = mv_16_r;
	            end
	          else  /* mv $ptr -> $acc */
                    begin
		       acc_wr_en_o = 1;
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
		     ptr_wr_en_o = 1;
		     ptr_wr_idx_o = inst_pipe_1_r[14:12];
		     ptr_wr_data_o = mv_16_r;
	          end
	       end

             if (inst_pipe_1_r[7:4] == LSU_ITYPE_MV_ACC_ACC_16)
	       begin
		  acc_wr_en_o = 1;
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
		       acc_wr_en_o = 1;
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
		       ptr_wr_en_o = 1;
		       ptr_wr_idx_o = inst_pipe_1_r[13:11];
		       ptr_wr_data_o = dmem_log_read_data_16;
	            end

                  if (inst_pipe_1_r[7:4] == LSU_ITYPE_LD_INC_16 && inst_pipe_1_r[15])
                    begin
	               ptr_wr_en_o   = 1;
	               ptr_wr_idx_o  = inst_pipe_1_r[10:8];
	               ptr_wr_data_o = addr_pipe_1_r + 1;
                    end
	       end

	     if (inst_pipe_1_r[7:4] == LSU_ITYPE_LD_32 ||
                 inst_pipe_1_r[7:4] == LSU_ITYPE_LD_INC_32)
	       begin
		  acc_wr_en_o   = 1;
                  acc_wr_idx_o  = inst_pipe_1_r[13:11];
		  acc_wr_data_o = dmem_log_read_data_32;
                  acc_wr_mask_o = 2'b11;

                  if (inst_pipe_1_r[7:4] == LSU_ITYPE_LD_INC_32)
                    begin
                       ptr_wr_en_o   = 1;
	               ptr_wr_idx_o  = inst_pipe_1_r[10:8];
	               ptr_wr_data_o = addr_pipe_1_r + 2;
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
                            spec_regs_wen_o   = 1;
                            spec_regs_data_o  = dmem_log_read_data_16;
                         end
                       else
                         begin
                            if (inst_pipe_1_r[15])  /* $acc */
	                      begin
		                 acc_wr_en_o = 1;
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
                                 ptr_wr_en_o   = 1;
                                 ptr_wr_idx_o  = inst_pipe_1_r[13:11];
                                 ptr_wr_data_o = dmem_log_read_data_16;
	                      end
                         end
                    end
               end

             if (inst_pipe_1_r[7:4] == LSU_ITYPE_ST_INC_16 && inst_pipe_1_r[15])
               begin
	          ptr_wr_en_o   = 1;
	          ptr_wr_idx_o  = inst_pipe_1_r[10:8];
	          ptr_wr_data_o = addr_pipe_1_r + 1;
               end

             if (inst_pipe_1_r[7:4] == LSU_ITYPE_ST_INC_32)
               begin
                  ptr_wr_en_o   = 1;
	          ptr_wr_idx_o  = inst_pipe_1_r[10:8];
	          ptr_wr_data_o = addr_pipe_1_r + 2;
               end
          end  /* 16 bit instruction encoding */
     end

endmodule // lsu
