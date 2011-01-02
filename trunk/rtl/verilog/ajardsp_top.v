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

module ajardsp_top(clk, rst_core, rst_mem,

                   ext_imem_wr_addr_i,
                   ext_imem_wr_data_i,
                   ext_imem_wr_en_i,

                   ext_dmem_addr_i,
                   ext_dmem_wr_data_i,
                   ext_dmem_wr_en_i,
                   ext_dmem_rd_data_o,
                   ext_dmem_rd_en_i,

                   core_halt_o,

                   gpio_i,
                   gpio_o,

                   interrupt_req_i

                   );

`include "insns.v"
`include "specregs.v"

   input clk;
   input rst_core;
   input rst_mem;

   input [15:0] ext_imem_wr_addr_i;
   input [63:0] ext_imem_wr_data_i;
   input        ext_imem_wr_en_i;

   input [15:0] ext_dmem_addr_i;
   input [31:0] ext_dmem_wr_data_i;
   input        ext_dmem_wr_en_i;
   output [31:0] ext_dmem_rd_data_o;
   input         ext_dmem_rd_en_i;

   output       core_halt_o;

   input  [15:0] gpio_i;
   output [15:0] gpio_o;

   input         interrupt_req_i;

   wire          jump_en_w;
   wire [15:0]   jump_pc_w;

   wire         imem_ren_w;
   wire [13:0]  imem_addr_w;
   wire [63:0]  imem_data_w;

   reg [3:0]  cu_0_taken;
   reg [31:0] cu_0_inst;

   reg [31:0] cu_1_inst;

   reg [31:0] bmu_0_inst;

   reg [3:0]  lsu_0_taken;
   reg [31:0] lsu_0_inst;

   reg [31:0] lsu_1_inst;

   reg [31:0] pcu_inst;

   wire          inst_0_valid;
   wire [31:0]   inst_0;
   wire          inst_1_valid;
   wire [31:0]   inst_1;
   wire          inst_2_valid;
   wire [31:0]   inst_2;
   wire          inst_3_valid;
   wire [31:0]   inst_3;

   wire          inst_0_valid_;
   wire          inst_1_valid_;
   wire          inst_2_valid_;
   wire          inst_3_valid_;

   wire [2:0]    lsu_0_ptr_rd_idx_w;
   wire [15:0]   lsu_0_ptr_rd_data_w;
   wire [2:0]    lsu_0_ptr_wr_idx_w;
   wire          lsu_0_ptr_wr_en_w;
   wire [15:0]   lsu_0_ptr_wr_data_w;

   wire          lsu_0_ptr_2nd_rd_en_w;
   wire [2:0]    lsu_0_ptr_2nd_rd_idx_w;
   wire [15:0]   lsu_0_ptr_2nd_rd_data_w;

   wire [2:0]    lsu_1_ptr_rd_idx_w;
   wire [15:0]   lsu_1_ptr_rd_data_w;
   wire [2:0]    lsu_1_ptr_wr_idx_w;
   wire          lsu_1_ptr_wr_en_w;
   wire [15:0]   lsu_1_ptr_wr_data_w;

   wire [2:0]    lsu_0_lsu_1_ptr_rd_idx_w;

   wire [15:0]   lsu_0_addr_w;
   wire          lsu_0_rd_en_w;
   wire          lsu_0_wr_en_w;
   wire [1:0]    lsu_0_wr_mask_w;
   wire [31:0]   lsu_0_rd_data_w;
   wire [31:0]   lsu_0_wr_data_w;

   wire [15:0]   lsu_1_addr_w;
   wire          lsu_1_rd_en_w;
   wire          lsu_1_wr_en_w;
   wire [1:0]    lsu_1_wr_mask_w;
   wire [31:0]   lsu_1_rd_data_w;
   wire [31:0]   lsu_1_wr_data_w;

   wire [2:0]    lsu_0_accrf_0_rd_idx_w;
   wire          lsu_0_accrf_0_rd_en_w;
   wire [31:0]   lsu_0_accrf_0_rd_data_w;

   wire [2:0]    lsu_0_accrf_0_wr_idx_w;
   wire          lsu_0_accrf_0_wr_en_w;
   wire [1:0]    lsu_0_accrf_0_wr_mask_w;
   wire [31:0]   lsu_0_accrf_0_wr_data_w;

   wire [2:0]    cu_0_accrf_0_op_0_rd_idx_w;
   wire          cu_0_accrf_0_op_0_rd_en_w;
   wire [`AJARDSP_CONFIG_ACC_GUARD_BITS+31:0] cu_0_accrf_0_op_0_rd_data_w;

   wire [2:0]    cu_0_accrf_0_op_1_rd_idx_w;
   wire          cu_0_accrf_0_op_1_rd_en_w;
   wire [`AJARDSP_CONFIG_ACC_GUARD_BITS+31:0] cu_0_accrf_0_op_1_rd_data_w;

   wire [2:0]    cu_0_accrf_0_op_2_rd_idx_w;
   wire          cu_0_accrf_0_op_2_rd_en_w;
   wire [`AJARDSP_CONFIG_ACC_GUARD_BITS+31:0] cu_0_accrf_0_op_2_rd_data_w;

   wire [2:0]    cu_0_accrf_0_res_wr_idx_w;
   wire          cu_0_accrf_0_res_wr_en_w;
   wire [2:0]    cu_0_accrf_0_res_wr_mask_w;
   wire [`AJARDSP_CONFIG_ACC_GUARD_BITS+31:0] cu_0_accrf_0_res_wr_data_w;

   wire [2:0]    lsu_1_accrf_0_rd_idx_w;
   wire          lsu_1_accrf_0_rd_en_w;
   wire [31:0]   lsu_1_accrf_0_rd_data_w;

   wire [2:0]    lsu_1_accrf_0_wr_idx_w;
   wire          lsu_1_accrf_0_wr_en_w;
   wire [1:0]    lsu_1_accrf_0_wr_mask_w;
   wire [31:0]   lsu_1_accrf_0_wr_data_w;

   wire [2:0]    cu_1_accrf_0_op_0_rd_idx_w;
   wire          cu_1_accrf_0_op_0_rd_en_w;
   wire [`AJARDSP_CONFIG_ACC_GUARD_BITS+31:0] cu_1_accrf_0_op_0_rd_data_w;

   wire [2:0]    cu_1_accrf_0_op_1_rd_idx_w;
   wire          cu_1_accrf_0_op_1_rd_en_w;
   wire [`AJARDSP_CONFIG_ACC_GUARD_BITS+31:0] cu_1_accrf_0_op_1_rd_data_w;

   wire [2:0]    cu_1_accrf_0_op_2_rd_idx_w;
   wire          cu_1_accrf_0_op_2_rd_en_w;
   wire [`AJARDSP_CONFIG_ACC_GUARD_BITS+31:0] cu_1_accrf_0_op_2_rd_data_w;

   wire [2:0]    cu_1_accrf_0_res_wr_idx_w;
   wire          cu_1_accrf_0_res_wr_en_w;
   wire [2:0]    cu_1_accrf_0_res_wr_mask_w;
   wire [`AJARDSP_CONFIG_ACC_GUARD_BITS+31:0] cu_1_accrf_0_res_wr_data_w;

   wire [2:0]    bmu_0_accrf_0_op_0_rd_idx_w;
   wire          bmu_0_accrf_0_op_0_rd_en_w;
   wire [`AJARDSP_CONFIG_ACC_GUARD_BITS+31:0] bmu_0_accrf_0_op_0_rd_data_w;

   wire [2:0]    bmu_0_accrf_0_op_1_rd_idx_w;
   wire          bmu_0_accrf_0_op_1_rd_en_w;
   wire [`AJARDSP_CONFIG_ACC_GUARD_BITS+31:0] bmu_0_accrf_0_op_1_rd_data_w;

   wire [2:0]    bmu_0_accrf_0_res_wr_idx_w;
   wire          bmu_0_accrf_0_res_wr_en_w;
   wire [2:0]    bmu_0_accrf_0_res_wr_mask_w;
   wire [`AJARDSP_CONFIG_ACC_GUARD_BITS+31:0] bmu_0_accrf_0_res_wr_data_w;

   wire [1:0]    pred_0_pcu_0_rd_idx_w;
   wire          pred_0_pcu_0_rd_bit_w;

   wire [1:0]    pred_0_lsu_0_rd_idx_w;
   wire          pred_0_lsu_0_rd_bit_w;

   wire [1:0]    pred_0_lsu_1_rd_idx_w;
   wire          pred_0_lsu_1_rd_bit_w;

   wire [1:0]    pred_0_cu_0_rd_idx_w;
   wire          pred_0_cu_0_rd_bit_w;

   wire [1:0]    pred_0_cu_1_rd_idx_w;
   wire          pred_0_cu_1_rd_bit_w;

   wire [1:0]    cu_0_pred_0_wr_idx_w;
   wire          cu_0_pred_0_wr_wen_w;
   wire          cu_0_pred_0_wr_bit_w;

   wire [1:0]    cu_1_pred_0_wr_idx_w;
   wire          cu_1_pred_0_wr_wen_w;
   wire          cu_1_pred_0_wr_bit_w;

   wire          pcu_0_dmem_0_halt_w;

   wire [15:0]   vliwfetch_0_pcu_0_pc_w;
   wire [15:0]   vliwfetch_0_pcu_0_next_pc_w;

   wire [5:0]    spec_regs_raddr_w;
   wire [5:0]    spec_regs_waddr_w;
   wire          spec_regs_ren_w;
   wire          spec_regs_wen_w;
   wire [15:0]   spec_regs_rd_data_w;
   wire [15:0]   spec_regs_wr_data_w;

   wire [5:0]    lsu_0_spec_regs_raddr_w;
   wire [5:0]    lsu_0_spec_regs_waddr_w;
   wire          lsu_0_spec_regs_ren_w;
   wire          lsu_0_spec_regs_wen_w;
   wire [15:0]   lsu_0_spec_regs_wr_data_w;

   wire [5:0]    lsu_1_spec_regs_raddr_w;
   wire [5:0]    lsu_1_spec_regs_waddr_w;
   wire          lsu_1_spec_regs_ren_w;
   wire          lsu_1_spec_regs_wen_w;
   wire [15:0]   lsu_1_spec_regs_wr_data_w;


   wire [15:0]   sp_0_lsu_0_sp_w;
   wire          lsu_0_sp_0_push_en_w;
   wire          lsu_0_sp_0_pop_en_w;
   wire [1:0]    lsu_0_sp_0_stack_width_w;

   wire [15:0]   sp_0_lsu_1_sp_w;
   wire          lsu_1_sp_0_push_en_w;
   wire          lsu_1_sp_0_pop_en_w;
   wire [1:0]    lsu_1_sp_0_stack_width_w;

   wire [7:0]    curegs_0_cu_satctrl_w;
   wire [7:0]    curegs_0_cu_mulsign_w;

   wire [15:0]   lsuregs_0_bitrev_w;
   wire [15:0]   lsuregs_0_mask_sel_w;
   wire [15:0]   lsuregs_0_mask_0_w;
   wire [15:0]   lsuregs_0_mask_1_w;
   wire [15:0]   lsuregs_0_mod_sel_w;
   wire [15:0]   lsuregs_0_mod_0_w;
   wire [15:0]   lsuregs_0_mod_1_w;

   wire          invalidate_insns_w;

   reg [15:0]    gpio_r;

   assign gpio_o   = gpio_r;

   assign spec_regs_rd_data_w = (spec_regs_ren_w && spec_regs_raddr_w == SPEC_REGS_ADDR_GPIO)
     ? gpio_i : 16'hzzzz;

   always @(posedge clk)
     begin
        if (rst_core)
          begin
             gpio_r <= 0;
          end
        else if (spec_regs_wen_w && spec_regs_waddr_w == SPEC_REGS_ADDR_GPIO)
          begin
             gpio_r <= spec_regs_wr_data_w;
          end
     end

   assign inst_0_valid = inst_0_valid_ & ~invalidate_insns_w;
   assign inst_1_valid = inst_1_valid_ & ~invalidate_insns_w;
   assign inst_2_valid = inst_2_valid_ & ~invalidate_insns_w;
   assign inst_3_valid = inst_3_valid_ & ~invalidate_insns_w;

   assign core_halt_o = pcu_0_dmem_0_halt_w;

   assign lsu_0_ptr_2nd_rd_data_w = lsu_1_ptr_rd_data_w;
   assign lsu_0_lsu_1_ptr_rd_idx_w = lsu_0_ptr_2nd_rd_en_w ? lsu_0_ptr_2nd_rd_idx_w : lsu_1_ptr_rd_idx_w;

   imem imem_0(.clk(clk),
               .rst(rst_mem),
               .ren_i(imem_ren_w),
               .addr_i(imem_addr_w),
               .inst_o(imem_data_w),

               .ext_imem_wr_addr_i(ext_imem_wr_addr_i),
               .ext_imem_wr_data_i(ext_imem_wr_data_i),
               .ext_imem_wr_en_i(ext_imem_wr_en_i)
               );


   vliwfetch vliwfetch_0(.clk(clk),
                         .rst(rst_core),

                         .instmem_ren(imem_ren_w),
                         .instmem_data(imem_data_w),
                         .instmem_addr(imem_addr_w),

                         .pc_o(vliwfetch_0_pcu_0_pc_w),
                         .next_pc_o(vliwfetch_0_pcu_0_next_pc_w),

                         .jump_enable(jump_en_w),
                         .jump_pc(jump_pc_w),

                         .inst_0_valid(inst_0_valid_),
                         .inst_0(inst_0),
                         .inst_1_valid(inst_1_valid_),
                         .inst_1(inst_1),
                         .inst_2_valid(inst_2_valid_),
                         .inst_2(inst_2),
                         .inst_3_valid(inst_3_valid_),
                         .inst_3(inst_3));


   ptrrf ptrrf_0(.clk(clk),
                 .rst(rst_core),

                 .rd_idx_0_i(lsu_0_ptr_rd_idx_w),
                 .rd_data_0_o(lsu_0_ptr_rd_data_w),
                 .wr_idx_0_i(lsu_0_ptr_wr_idx_w),
                 .wr_en_0_i(lsu_0_ptr_wr_en_w),
                 .wr_data_0_i(lsu_0_ptr_wr_data_w),

                 .rd_idx_1_i(lsu_0_lsu_1_ptr_rd_idx_w),
                 .rd_data_1_o(lsu_1_ptr_rd_data_w),
                 .wr_idx_1_i(lsu_1_ptr_wr_idx_w),
                 .wr_en_1_i(lsu_1_ptr_wr_en_w),
                 .wr_data_1_i(lsu_1_ptr_wr_data_w));


   accrf_share accrf_share_0(
                 .clk(clk),
                 .rst(rst_core),

                 .rd_idx_lsu_0_i(lsu_0_accrf_0_rd_idx_w),
                 .rd_en_lsu_0_i(lsu_0_accrf_0_rd_en_w),
                 .rd_data_lsu_0_o(lsu_0_accrf_0_rd_data_w),

                 .wr_idx_lsu_0_i(lsu_0_accrf_0_wr_idx_w),
                 .wr_en_lsu_0_i(lsu_0_accrf_0_wr_en_w),
                 .wr_mask_lsu_0_i(lsu_0_accrf_0_wr_mask_w),
                 .wr_data_lsu_0_i(lsu_0_accrf_0_wr_data_w),

                 .rd_idx_cu_0_op_0_i(cu_0_accrf_0_op_0_rd_idx_w),
                 .rd_en_cu_0_op_0_i(cu_0_accrf_0_op_0_rd_en_w),
                 .rd_data_cu_0_op_0_o(cu_0_accrf_0_op_0_rd_data_w),

                 .rd_idx_cu_0_op_1_i(cu_0_accrf_0_op_1_rd_idx_w),
                 .rd_en_cu_0_op_1_i(cu_0_accrf_0_op_1_rd_en_w),
                 .rd_data_cu_0_op_1_o(cu_0_accrf_0_op_1_rd_data_w),

                 .rd_idx_cu_0_op_2_i(cu_0_accrf_0_op_2_rd_idx_w),
                 .rd_en_cu_0_op_2_i(cu_0_accrf_0_op_2_rd_en_w),
                 .rd_data_cu_0_op_2_o(cu_0_accrf_0_op_2_rd_data_w),

                 .wr_idx_cu_0_i(cu_0_accrf_0_res_wr_idx_w),
                 .wr_en_cu_0_i(cu_0_accrf_0_res_wr_en_w),
                 .wr_mask_cu_0_i(cu_0_accrf_0_res_wr_mask_w),
                 .wr_data_cu_0_i(cu_0_accrf_0_res_wr_data_w),

                 //
                 .rd_idx_lsu_1_i(lsu_1_accrf_0_rd_idx_w),
                 .rd_en_lsu_1_i(lsu_1_accrf_0_rd_en_w),
                 .rd_data_lsu_1_o(lsu_1_accrf_0_rd_data_w),

                 .wr_idx_lsu_1_i(lsu_1_accrf_0_wr_idx_w),
                 .wr_en_lsu_1_i(lsu_1_accrf_0_wr_en_w),
                 .wr_mask_lsu_1_i(lsu_1_accrf_0_wr_mask_w),
                 .wr_data_lsu_1_i(lsu_1_accrf_0_wr_data_w),

                 .rd_idx_cu_1_op_0_i(cu_1_accrf_0_op_0_rd_idx_w),
                 .rd_en_cu_1_op_0_i(cu_1_accrf_0_op_0_rd_en_w),
                 .rd_data_cu_1_op_0_o(cu_1_accrf_0_op_0_rd_data_w),

                 .rd_idx_cu_1_op_1_i(cu_1_accrf_0_op_1_rd_idx_w),
                 .rd_en_cu_1_op_1_i(cu_1_accrf_0_op_1_rd_en_w),
                 .rd_data_cu_1_op_1_o(cu_1_accrf_0_op_1_rd_data_w),

                 .rd_idx_cu_1_op_2_i(cu_1_accrf_0_op_2_rd_idx_w),
                 .rd_en_cu_1_op_2_i(cu_1_accrf_0_op_2_rd_en_w),
                 .rd_data_cu_1_op_2_o(cu_1_accrf_0_op_2_rd_data_w),

                 .wr_idx_cu_1_i(cu_1_accrf_0_res_wr_idx_w),
                 .wr_en_cu_1_i(cu_1_accrf_0_res_wr_en_w),
                 .wr_mask_cu_1_i(cu_1_accrf_0_res_wr_mask_w),
                 .wr_data_cu_1_i(cu_1_accrf_0_res_wr_data_w),

                 //
                 .rd_idx_bmu_0_op_0_i(bmu_0_accrf_0_op_0_rd_idx_w),
                 .rd_en_bmu_0_op_0_i(bmu_0_accrf_0_op_0_rd_en_w),
                 .rd_data_bmu_0_op_0_o(bmu_0_accrf_0_op_0_rd_data_w),

                 .rd_idx_bmu_0_op_1_i(bmu_0_accrf_0_op_1_rd_idx_w),
                 .rd_en_bmu_0_op_1_i(bmu_0_accrf_0_op_1_rd_en_w),
                 .rd_data_bmu_0_op_1_o(bmu_0_accrf_0_op_1_rd_data_w),

                 .wr_idx_bmu_0_i(bmu_0_accrf_0_res_wr_idx_w),
                 .wr_en_bmu_0_i(bmu_0_accrf_0_res_wr_en_w),
                 .wr_mask_bmu_0_i(bmu_0_accrf_0_res_wr_mask_w),
                 .wr_data_bmu_0_i(bmu_0_accrf_0_res_wr_data_w)
                 );

   predbits pred_0(.clk(clk),
                   .rst(rst_core),

                   .rd_0_idx_i(pred_0_pcu_0_rd_idx_w),
                   .rd_0_bit_o(pred_0_pcu_0_rd_bit_w),

                   .rd_1_idx_i(pred_0_lsu_0_rd_idx_w),
                   .rd_1_bit_o(pred_0_lsu_0_rd_bit_w),

                   .rd_2_idx_i(pred_0_lsu_1_rd_idx_w),
                   .rd_2_bit_o(pred_0_lsu_1_rd_bit_w),

                   .rd_3_idx_i(pred_0_cu_0_rd_idx_w),
                   .rd_3_bit_o(pred_0_cu_0_rd_bit_w),

                   .rd_4_idx_i(pred_0_cu_1_rd_idx_w),
                   .rd_4_bit_o(pred_0_cu_1_rd_bit_w),

                   .rd_5_idx_i(pred_0_bmu_0_rd_idx_w),
                   .rd_5_bit_o(pred_0_bmu_0_rd_bit_w),

                   .wr_0_idx_i(cu_0_pred_0_wr_idx_w),
                   .wr_0_wen_i(cu_0_pred_0_wr_wen_w),
                   .wr_0_bit_i(cu_0_pred_0_wr_bit_w),

                   .wr_1_idx_i(cu_1_pred_0_wr_idx_w),
                   .wr_1_wen_i(cu_1_pred_0_wr_wen_w),
                   .wr_1_bit_i(cu_1_pred_0_wr_bit_w),

                   .spec_regs_waddr_i(spec_regs_waddr_w),
                   .spec_regs_raddr_i(spec_regs_raddr_w),
                   .spec_regs_ren_i(spec_regs_ren_w),
                   .spec_regs_wen_i(spec_regs_wen_w),
                   .spec_regs_data_i(spec_regs_wr_data_w),
                   .spec_regs_data_o(spec_regs_rd_data_w)
                   );


   pcu pcu_0(.clk(clk),
             .rst(rst_core),
             .inst(pcu_inst),
             .pc_i(vliwfetch_0_pcu_0_pc_w),
             .next_pc_i(vliwfetch_0_pcu_0_next_pc_w),
             .jump_pc(jump_pc_w),
             .jump_en(jump_en_w),
             .halt_o(pcu_0_dmem_0_halt_w),
             .pred_tst_idx_o(pred_0_pcu_0_rd_idx_w),
             .pred_tst_bit_i(pred_0_pcu_0_rd_bit_w),

             .spec_regs_waddr_i(spec_regs_waddr_w),
             .spec_regs_raddr_i(spec_regs_raddr_w),
             .spec_regs_ren_i(spec_regs_ren_w),
             .spec_regs_wen_i(spec_regs_wen_w),
             .spec_regs_data_i(spec_regs_wr_data_w),
             .spec_regs_data_o(spec_regs_rd_data_w),

             .interrupt_req_i(interrupt_req_i),
             .invalidate_insns_o(invalidate_insns_w)
             );


   dmem dmem_0(.clk(clk),
               .rst(rst_mem),

               .dump_mem_i(pcu_0_dmem_0_halt_w),

               .addr_0_i(lsu_0_addr_w),
               .mask_0_i(lsu_0_wr_mask_w),
               .rd_data_0_o(lsu_0_rd_data_w),
               .wr_data_0_i(lsu_0_wr_data_w),
               .wr_en_0_i(lsu_0_wr_en_w),
               .rd_en_0_i(lsu_0_rd_en_w),

               .addr_1_i(lsu_1_addr_w),
               .mask_1_i(lsu_1_wr_mask_w),
               .rd_data_1_o(lsu_1_rd_data_w),
               .wr_data_1_i(lsu_1_wr_data_w),
               .wr_en_1_i(lsu_1_wr_en_w),
               .rd_en_1_i(lsu_1_rd_en_w),

               .ext_dmem_addr_i(ext_dmem_addr_i),
               .ext_dmem_wr_data_i(ext_dmem_wr_data_i),
               .ext_dmem_wr_en_i(ext_dmem_wr_en_i),
               .ext_dmem_rd_data_o(ext_dmem_rd_data_o),
               .ext_dmem_rd_en_i(ext_dmem_rd_en_i)
               );

   sp sp_0(.clk(clk),
           .rst(rst_core),
           .sp_0_o(sp_0_lsu_0_sp_w),
           .push_0_en_i(lsu_0_sp_0_push_en_w),
           .pop_0_en_i(lsu_0_sp_0_pop_en_w),
           .width_0_i(lsu_0_sp_0_stack_width_w),

           .sp_1_o(sp_0_lsu_1_sp_w),
           .push_1_en_i(lsu_1_sp_0_push_en_w),
           .pop_1_en_i(lsu_1_sp_0_pop_en_w),
           .width_1_i(lsu_1_sp_0_stack_width_w),

           .spec_regs_raddr_i(spec_regs_raddr_w),
           .spec_regs_waddr_i(spec_regs_waddr_w),
           .spec_regs_ren_i(spec_regs_ren_w),
           .spec_regs_wen_i(spec_regs_wen_w),
           .spec_regs_data_i(spec_regs_wr_data_w),
           .spec_regs_data_o(spec_regs_rd_data_w)
           );

   lsuregs lsuregs_0(.clk(clk),
                     .rst(rst_core),

                     .bitrev_o(lsuregs_0_bitrev_w),
                     .mask_sel_o(lsuregs_0_mask_sel_w),
                     .mask_0_o(lsuregs_0_mask_0_w),
                     .mask_1_o(lsuregs_0_mask_1_w),
                     .mod_sel_o(lsuregs_0_mod_sel_w),
                     .mod_0_o(lsuregs_0_mod_0_w),
                     .mod_1_o(lsuregs_0_mod_1_w),

                     .spec_regs_raddr_i(spec_regs_raddr_w),
                     .spec_regs_waddr_i(spec_regs_waddr_w),
                     .spec_regs_ren_i(spec_regs_ren_w),
                     .spec_regs_wen_i(spec_regs_wen_w),
                     .spec_regs_data_i(spec_regs_wr_data_w),
                     .spec_regs_data_o(spec_regs_rd_data_w)
                     );

   lsu lsu_0(.clk(clk),
             .rst(rst_core),

             .inst(lsu_0_inst),

             .pred_tst_idx_o(pred_0_lsu_0_rd_idx_w),
             .pred_tst_bit_i(pred_0_lsu_0_rd_bit_w),

             //.ptr_rd_en_o(),
             .ptr_rd_idx_o(lsu_0_ptr_rd_idx_w),
             .ptr_rd_data_i(lsu_0_ptr_rd_data_w),

             .ptr_2nd_rd_en_o(lsu_0_ptr_2nd_rd_en_w),
             .ptr_2nd_rd_idx_o(lsu_0_ptr_2nd_rd_idx_w),
             .ptr_2nd_rd_data_i(lsu_0_ptr_2nd_rd_data_w),

             .ptr_wr_en_o(lsu_0_ptr_wr_en_w),
             .ptr_wr_idx_o(lsu_0_ptr_wr_idx_w),
             .ptr_wr_data_o(lsu_0_ptr_wr_data_w),

             .acc_rd_en_o(lsu_0_accrf_0_rd_en_w),
             .acc_rd_idx_o(lsu_0_accrf_0_rd_idx_w),
             .acc_rd_data_i(lsu_0_accrf_0_rd_data_w),

             .acc_wr_en_o(lsu_0_accrf_0_wr_en_w),
             .acc_wr_idx_o(lsu_0_accrf_0_wr_idx_w),
             .acc_wr_mask_o(lsu_0_accrf_0_wr_mask_w),
             .acc_wr_data_o(lsu_0_accrf_0_wr_data_w),

             .dmem_addr_o(lsu_0_addr_w),
             .dmem_rd_en_o(lsu_0_rd_en_w),
             .dmem_wr_en_o(lsu_0_wr_en_w),
             .dmem_wr_mask_o(lsu_0_wr_mask_w),
             .dmem_rd_data_i(lsu_0_rd_data_w),
             .dmem_wr_data_o(lsu_0_wr_data_w),

             .spec_regs_raddr_o(lsu_0_spec_regs_raddr_w),
             .spec_regs_waddr_o(lsu_0_spec_regs_waddr_w),
             .spec_regs_ren_o(lsu_0_spec_regs_ren_w),
             .spec_regs_wen_o(lsu_0_spec_regs_wen_w),
             .spec_regs_data_o(lsu_0_spec_regs_wr_data_w),
             .spec_regs_data_i(spec_regs_rd_data_w),

             .sp_i(sp_0_lsu_0_sp_w),
             .push_en_o(lsu_0_sp_0_push_en_w),
             .pop_en_o(lsu_0_sp_0_pop_en_w),
             .stack_width_o(lsu_0_sp_0_stack_width_w),

             .bitrev_i(lsuregs_0_bitrev_w),
             .mask_sel_i(lsuregs_0_mask_sel_w),
             .mask_0_i(lsuregs_0_mask_0_w),
             .mask_1_i(lsuregs_0_mask_1_w),
             .mod_sel_i(lsuregs_0_mod_sel_w),
             .mod_0_i(lsuregs_0_mod_0_w),
             .mod_1_i(lsuregs_0_mod_1_w)
             );

   lsu lsu_1(.clk(clk),
             .rst(rst_core),

             .inst(lsu_1_inst),

             .pred_tst_idx_o(pred_0_lsu_1_rd_idx_w),
             .pred_tst_bit_i(pred_0_lsu_1_rd_bit_w),

             //.ptr_rd_en_o(),
             .ptr_rd_idx_o(lsu_1_ptr_rd_idx_w),
             .ptr_rd_data_i(lsu_1_ptr_rd_data_w),

             .ptr_wr_en_o(lsu_1_ptr_wr_en_w),
             .ptr_wr_idx_o(lsu_1_ptr_wr_idx_w),
             .ptr_wr_data_o(lsu_1_ptr_wr_data_w),

             .acc_rd_en_o(lsu_1_accrf_0_rd_en_w),
             .acc_rd_idx_o(lsu_1_accrf_0_rd_idx_w),
             .acc_rd_data_i(lsu_1_accrf_0_rd_data_w),

             .acc_wr_en_o(lsu_1_accrf_0_wr_en_w),
             .acc_wr_idx_o(lsu_1_accrf_0_wr_idx_w),
             .acc_wr_mask_o(lsu_1_accrf_0_wr_mask_w),
             .acc_wr_data_o(lsu_1_accrf_0_wr_data_w),

             .dmem_addr_o(lsu_1_addr_w),
             .dmem_rd_en_o(lsu_1_rd_en_w),
             .dmem_wr_en_o(lsu_1_wr_en_w),
             .dmem_wr_mask_o(lsu_1_wr_mask_w),
             .dmem_rd_data_i(lsu_1_rd_data_w),
             .dmem_wr_data_o(lsu_1_wr_data_w),

             .spec_regs_raddr_o(lsu_1_spec_regs_raddr_w),
             .spec_regs_waddr_o(lsu_1_spec_regs_waddr_w),
             .spec_regs_ren_o(lsu_1_spec_regs_ren_w),
             .spec_regs_wen_o(lsu_1_spec_regs_wen_w),
             .spec_regs_data_o(lsu_1_spec_regs_wr_data_w),
             .spec_regs_data_i(spec_regs_rd_data_w),

             .sp_i(sp_0_lsu_1_sp_w),
             .push_en_o(lsu_1_sp_0_push_en_w),
             .pop_en_o(lsu_1_sp_0_pop_en_w),
             .stack_width_o(lsu_1_sp_0_stack_width_w),

             .bitrev_i(lsuregs_0_bitrev_w),
             .mask_sel_i(lsuregs_0_mask_sel_w),
             .mask_0_i(lsuregs_0_mask_0_w),
             .mask_1_i(lsuregs_0_mask_1_w),
             .mod_sel_i(lsuregs_0_mod_sel_w),
             .mod_0_i(lsuregs_0_mod_0_w),
             .mod_1_i(lsuregs_0_mod_1_w)
             );


   curegs curegs_0(.clk(clk),
                   .rst(rst_core),
                   .satctrl_o(curegs_0_cu_satctrl_w),
                   .mulsign_o(curegs_0_cu_mulsign_w),

                   .spec_regs_raddr_i(spec_regs_raddr_w),
                   .spec_regs_waddr_i(spec_regs_waddr_w),
                   .spec_regs_ren_i(spec_regs_ren_w),
                   .spec_regs_wen_i(spec_regs_wen_w),
                   .spec_regs_data_i(spec_regs_wr_data_w),
                   .spec_regs_data_o(spec_regs_rd_data_w)
                   );

   cu cu_0(.clk(clk),
           .rst(rst_core),

           .inst(cu_0_inst),

           .satctrl_i(curegs_0_cu_satctrl_w),
           .mulsign_i(curegs_0_cu_mulsign_w),

           .op_0_idx_o(cu_0_accrf_0_op_0_rd_idx_w),
           .op_0_ren_o(cu_0_accrf_0_op_0_rd_en_w),
           .op_0_data_i(cu_0_accrf_0_op_0_rd_data_w),

           .op_1_idx_o(cu_0_accrf_0_op_1_rd_idx_w),
           .op_1_ren_o(cu_0_accrf_0_op_1_rd_en_w),
           .op_1_data_i(cu_0_accrf_0_op_1_rd_data_w),

           .op_2_idx_o(cu_0_accrf_0_op_2_rd_idx_w),
           .op_2_ren_o(cu_0_accrf_0_op_2_rd_en_w),
           .op_2_data_i(cu_0_accrf_0_op_2_rd_data_w),

           .res_idx_o(cu_0_accrf_0_res_wr_idx_w),
           .res_wen_o(cu_0_accrf_0_res_wr_en_w),
           .res_mask_o(cu_0_accrf_0_res_wr_mask_w),
           .res_data_o(cu_0_accrf_0_res_wr_data_w),

           .pred_tst_idx_o(pred_0_cu_0_rd_idx_w),
           .pred_tst_bit_i(pred_0_cu_0_rd_bit_w),

           .pred_set_idx_o(cu_0_pred_0_wr_idx_w),
           .pred_set_wen_o(cu_0_pred_0_wr_wen_w),
           .pred_set_bit_o(cu_0_pred_0_wr_bit_w)
           );

   cu cu_1(.clk(clk),
           .rst(rst_core),

           .inst(cu_1_inst),

           .satctrl_i(curegs_0_cu_satctrl_w),
           .mulsign_i(curegs_0_cu_mulsign_w),

           .op_0_idx_o(cu_1_accrf_0_op_0_rd_idx_w),
           .op_0_ren_o(cu_1_accrf_0_op_0_rd_en_w),
           .op_0_data_i(cu_1_accrf_0_op_0_rd_data_w),

           .op_1_idx_o(cu_1_accrf_0_op_1_rd_idx_w),
           .op_1_ren_o(cu_1_accrf_0_op_1_rd_en_w),
           .op_1_data_i(cu_1_accrf_0_op_1_rd_data_w),

           .op_2_idx_o(cu_1_accrf_0_op_2_rd_idx_w),
           .op_2_ren_o(cu_1_accrf_0_op_2_rd_en_w),
           .op_2_data_i(cu_1_accrf_0_op_2_rd_data_w),

           .res_idx_o(cu_1_accrf_0_res_wr_idx_w),
           .res_wen_o(cu_1_accrf_0_res_wr_en_w),
           .res_mask_o(cu_1_accrf_0_res_wr_mask_w),
           .res_data_o(cu_1_accrf_0_res_wr_data_w),

           .pred_tst_idx_o(pred_0_cu_1_rd_idx_w),
           .pred_tst_bit_i(pred_0_cu_1_rd_bit_w),

           .pred_set_idx_o(cu_1_pred_0_wr_idx_w),
           .pred_set_wen_o(cu_1_pred_0_wr_wen_w),
           .pred_set_bit_o(cu_1_pred_0_wr_bit_w)
           );

   bmu bmu_0(.clk(clk),
             .rst(rst_core),

             .inst(bmu_0_inst),

             .op_0_idx_o(bmu_0_accrf_0_op_0_rd_idx_w),
             .op_0_ren_o(bmu_0_accrf_0_op_0_rd_en_w),
             .op_0_data_i(bmu_0_accrf_0_op_0_rd_data_w),

             .op_1_idx_o(bmu_0_accrf_0_op_1_rd_idx_w),
             .op_1_ren_o(bmu_0_accrf_0_op_1_rd_en_w),
             .op_1_data_i(bmu_0_accrf_0_op_1_rd_data_w),

             .res_idx_o(bmu_0_accrf_0_res_wr_idx_w),
             .res_wen_o(bmu_0_accrf_0_res_wr_en_w),
             .res_mask_o(bmu_0_accrf_0_res_wr_mask_w),
             .res_data_o(bmu_0_accrf_0_res_wr_data_w),

             .pred_tst_idx_o(pred_0_bmu_0_rd_idx_w),
             .pred_tst_bit_i(pred_0_bmu_0_rd_bit_w)
             );


   /* LSU_0 and LSU_1 share the special registers bus. LSU_0 has priority. */
   assign  spec_regs_raddr_w   = (lsu_0_spec_regs_ren_w | lsu_0_spec_regs_wen_w) ? lsu_0_spec_regs_raddr_w   : lsu_1_spec_regs_raddr_w;
   assign  spec_regs_waddr_w   = (lsu_0_spec_regs_ren_w | lsu_0_spec_regs_wen_w) ? lsu_0_spec_regs_waddr_w   : lsu_1_spec_regs_waddr_w;
   assign  spec_regs_ren_w     = (lsu_0_spec_regs_ren_w | lsu_0_spec_regs_wen_w) ? lsu_0_spec_regs_ren_w     : lsu_1_spec_regs_ren_w;
   assign  spec_regs_wen_w     = (lsu_0_spec_regs_ren_w | lsu_0_spec_regs_wen_w) ? lsu_0_spec_regs_wen_w     : lsu_1_spec_regs_wen_w;
   assign  spec_regs_wr_data_w = (lsu_0_spec_regs_ren_w | lsu_0_spec_regs_wen_w) ? lsu_0_spec_regs_wr_data_w : lsu_1_spec_regs_wr_data_w;

   always @(inst_0_valid or inst_0 or inst_1_valid or inst_1 or
            inst_2_valid or inst_2 or inst_3_valid or inst_3 or
            cu_0_taken or lsu_0_taken)
     begin

        // PCU
        if (inst_0_valid && inst_0[3:2] == ITYPE_PCU)
          begin
             pcu_inst = inst_0;
          end
        else if (inst_1_valid && inst_1[3:2] == ITYPE_PCU)
          begin
             pcu_inst = inst_1;
          end
        else if (inst_2_valid && inst_2[3:2] == ITYPE_PCU)
          begin
             pcu_inst = inst_2;
          end
        else if (inst_3_valid && inst_3[3:2] == ITYPE_PCU)
          begin
             pcu_inst = inst_3;
          end
        else
          begin
             pcu_inst = 32'h0;
          end


        // LSU_0
        if (inst_0_valid && inst_0[3:2] == ITYPE_LSU)
          begin
             lsu_0_inst = inst_0;
             lsu_0_taken = 4'b0001;
          end
        else if (inst_1_valid && inst_1[3:2] == ITYPE_LSU)
          begin
             lsu_0_inst = inst_1;
             lsu_0_taken = 4'b0010;
          end
        else if (inst_2_valid && inst_2[3:2] == ITYPE_LSU)
          begin
             lsu_0_inst = inst_2;
             lsu_0_taken = 4'b0100;
          end
        else if (inst_3_valid && inst_3[3:2] == ITYPE_LSU)
          begin
             lsu_0_inst = inst_3;
             lsu_0_taken = 4'b1000;
          end
        else
          begin
             lsu_0_inst = 32'h0;
             lsu_0_taken = 4'b0000;
          end


        // LSU_1
        if (inst_0_valid && inst_0[3:2] == ITYPE_LSU && lsu_0_taken != 4'b0001)
          begin
             lsu_1_inst = inst_0;
          end
        else if (inst_1_valid && inst_1[3:2] == ITYPE_LSU && lsu_0_taken != 4'b0010)
          begin
             lsu_1_inst = inst_1;
          end
        else if (inst_2_valid && inst_2[3:2] == ITYPE_LSU && lsu_0_taken != 4'b0100)
          begin
             lsu_1_inst = inst_2;
          end
        else if (inst_3_valid && inst_3[3:2] == ITYPE_LSU && lsu_0_taken != 4'b1000)
          begin
             lsu_1_inst = inst_3;
          end
        else
          begin
             lsu_1_inst = 32'h0;
          end


        // CU_0
        if (inst_0_valid && inst_0[3:2] == ITYPE_CU)
          begin
             cu_0_inst = inst_0;
             cu_0_taken = 4'b0001;
          end
        else if (inst_1_valid && inst_1[3:2] == ITYPE_CU)
          begin
             cu_0_inst = inst_1;
             cu_0_taken = 4'b0010;
          end
        else if (inst_2_valid && inst_2[3:2] == ITYPE_CU)
          begin
             cu_0_inst = inst_2;
             cu_0_taken = 4'b0100;
          end
        else if (inst_3_valid && inst_3[3:2] == ITYPE_CU)
          begin
             cu_0_inst = inst_3;
             cu_0_taken = 4'b1000;
          end
        else
          begin
             cu_0_inst = 32'h0;
             cu_0_taken = 4'b0000;
          end


        // CU_1
        if (inst_0_valid && inst_0[3:2] == ITYPE_CU && cu_0_taken != 4'b0001)
          begin
             cu_1_inst = inst_0;
          end
        else if (inst_1_valid && inst_1[3:2] == ITYPE_CU && cu_0_taken != 4'b0010)
          begin
             cu_1_inst = inst_1;
          end
        else if (inst_2_valid && inst_2[3:2] == ITYPE_CU && cu_0_taken != 4'b0100)
          begin
             cu_1_inst = inst_2;
          end
        else if (inst_3_valid && inst_3[3:2] == ITYPE_CU && cu_0_taken != 4'b1000)
          begin
             cu_1_inst = inst_3;
          end
        else
          begin
             cu_1_inst = 32'h0;
          end

        // BMU_0
        if (inst_0_valid && inst_0[3:2] == ITYPE_BMU)
          begin
             bmu_0_inst = inst_0;
          end
        else if (inst_1_valid && inst_1[3:2] == ITYPE_BMU)
          begin
             bmu_0_inst = inst_1;
          end
        else if (inst_2_valid && inst_2[3:2] == ITYPE_BMU)
          begin
             bmu_0_inst = inst_2;
          end
        else if (inst_3_valid && inst_3[3:2] == ITYPE_BMU)
          begin
             bmu_0_inst = inst_3;
          end
        else
          begin
             bmu_0_inst = 32'h0;
          end

     end // always @ (inst_0_valid or inst_0 or inst_1_valid or inst_1 or...

`ifdef SIMULATION
   always @(posedge clk)
     begin
        $display("---");
        print_disp_inst("PCU  ", pcu_inst);
        print_disp_inst("LSU_0", lsu_0_inst);
        print_disp_inst("LSU_1", lsu_1_inst);
        print_disp_inst("CU_0 ", cu_0_inst);
        print_disp_inst("CU_1 ", cu_1_inst);

     end


   task print_disp_inst;
      input [256:0] str;
      input [31:0]  inst;
      begin
         if (inst[1])
           $display("%s: %h", str, inst);
         else
           $display("%s: %h", str, inst[15:0]);
      end
   endtask // print_inst
`endif //  `ifdef SIMULATION

endmodule // mydsp_top
