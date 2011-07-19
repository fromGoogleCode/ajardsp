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

`include "config.v"

module wb_ajardsp(
                  clk,
                  rst,

                  /* Wishbone interface */
                  wb_clk_i,
                  wb_rst_i,

                  wb_ack_i,
                  wb_dat_o,
                  wb_dat_i,
                  wb_adr_o,

                  wb_cyc_o,
                  wb_sel_o,
                  wb_stb_o,
                  wb_we_o
                  );

   input clk;
   input rst;

   input         wb_clk_i;
   input         wb_rst_i;
   input         wb_ack_i;
   input  [31:0] wb_dat_i;
   output reg [31:0] wb_dat_o;
   output reg [31:0] wb_adr_o;
   output reg        wb_cyc_o;
   output reg [3:0]  wb_sel_o;
   output reg    wb_stb_o;
   output reg    wb_we_o;

   reg [3:0]     wb_state_r;

   wire [31:0]   m_if_addr_w;
   wire [31:0]   m_if_data_w;
   wire          m_if_read_req_w;
   wire          m_if_write_req_w;
   wire          m_if_write_burst_req_w;

   wire [31:0]   m_if_burst_ext_addr_w;
   wire [15:0]   m_if_burst_int_addr_w;
   wire [7:0]    m_if_burst_flags_w;

   wire [31:0]   dmem_rd_data_32_w;


   reg [31:0]    read_data;
   reg           m_if_ack;
   wire [15:0]   m_if_burst_len_w;

   /* Address generation */
   reg [15:0]    m_if_burst_len_r;
   reg [15:0]    m_if_int_addr_r;
   reg [7:0]     m_if_burst_flags_r;

   reg           m_if_dmem_ren,
                 m_if_dmem_wen,
                 m_if_imem_wen;

   parameter EXT_BOOT_ADDR = 32'hD0000000,
             EXT_BOOT_LEN  = 16'h0100;


   parameter wb_m_idle = 0,
             wb_m_read = 1,
             wb_m_write = 2,
             wb_m_read_ack = 3,
             wb_m_burst = 4,
             wb_m_burst_0 = 5,
             wb_m_burst_1 = 6,
             wb_m_back_off = 7;

   parameter bflag_inc_ext   = 0,
             bflag_inc_int   = 1,
             bflag_write_ext = 2,
             bflag_imem      = 3,
             bflag_transp0   = 4,
             bflag_square    = 5,
             blfag_nowait    = 6;

   always @(posedge clk)
     begin
        wb_cyc_o <= 0;
        wb_stb_o <= 0;

        m_if_ack <= 0;

        if (rst)
          begin
`ifdef AJARDSP_CONFIG_EXT_BOOT
             wb_state_r <= wb_m_burst;
             m_if_imem_wen <= 1;

             wb_adr_o           <= EXT_BOOT_ADDR;
             m_if_int_addr_r    <= 0;
             m_if_burst_len_r   <= EXT_BOOT_LEN >> 2;

             m_if_burst_flags_r <= 1 << bflag_inc_ext |
                                   1 << bflag_inc_int |
                                   1 << bflag_imem;
`else
             wb_state_r <= wb_m_idle;
             m_if_imem_wen <= 0;
`endif
             m_if_dmem_ren <= 0;
             m_if_dmem_wen <= 0;
             wb_we_o  <= 0;
             read_data <= 0;
          end
        else
          begin
             read_data <= wb_dat_i;

             case (wb_state_r)

               wb_m_idle: begin
                  if (m_if_read_req_w)
                    begin
                       wb_adr_o   <= m_if_addr_w;
                       wb_state_r <= wb_m_read;
                    end
                  else if (m_if_write_req_w)
                    begin
                       wb_adr_o   <= m_if_addr_w;
                       wb_dat_o   <= m_if_data_w;
                       wb_sel_o   <= 4'b1111;
                       wb_state_r <= wb_m_write;
                    end
                  else if (m_if_write_burst_req_w)
                    begin
                       wb_adr_o           <= m_if_burst_ext_addr_w;
                       m_if_int_addr_r    <= m_if_burst_int_addr_w;
                       m_if_burst_len_r   <= m_if_burst_len_w >> 2;
                       m_if_burst_flags_r <= m_if_burst_flags_w;

                       wb_we_o       <=  m_if_burst_flags_w[bflag_write_ext];

                       m_if_dmem_ren <=  m_if_burst_flags_w[bflag_write_ext] &
                                        ~m_if_burst_flags_w[bflag_imem];

                       m_if_dmem_wen <= ~m_if_burst_flags_w[bflag_write_ext] &
                                        ~m_if_burst_flags_w[bflag_imem];

                       m_if_imem_wen <= ~m_if_burst_flags_w[bflag_write_ext] &
                                         m_if_burst_flags_w[bflag_imem];

                       wb_state_r <= wb_m_burst;
                    end
               end

               wb_m_read: begin
                  wb_cyc_o <= 1;
                  wb_stb_o <= 1;
                  wb_we_o  <= 0;

                  if (wb_ack_i)
                    begin
                       wb_state_r <= wb_m_read_ack;
                    end
               end

               wb_m_read_ack: begin
                  wb_cyc_o <= 0;
                  wb_stb_o <= 0;
                  wb_we_o  <= 0;

                  m_if_ack <= 1;

                  wb_state_r <= wb_m_idle;
               end

               wb_m_write: begin
                  wb_cyc_o <= 1;
                  wb_stb_o <= 1;
                  wb_we_o  <= 1;

                  if (wb_ack_i)
                    begin
                       wb_state_r <= wb_m_idle;
                       m_if_ack <= 1;
                    end
               end

               wb_m_back_off: begin
                  wb_state_r <= wb_m_burst_1;
               end

               wb_m_burst: begin
                  wb_state_r <= wb_m_burst_0;
               end

               wb_m_burst_0: begin
                  /* Due to pipeline effect of BRAMs we need to be one step ahead if DMEM is source */
                  if (m_if_burst_flags_r[bflag_write_ext] & m_if_burst_flags_r[bflag_inc_int])
                    m_if_int_addr_r <= m_if_int_addr_r + 2;

                  wb_dat_o <= dmem_rd_data_32_w;
                  if (m_if_burst_flags_r[bflag_transp0])
                    wb_sel_o <= {dmem_rd_data_32_w[31:24] != 0 ? 1'b1 : 1'b0,
                                 dmem_rd_data_32_w[23:16] != 0 ? 1'b1 : 1'b0,
                                 dmem_rd_data_32_w[15:8]  != 0 ? 1'b1 : 1'b0,
                                 dmem_rd_data_32_w[7:0]   != 0 ? 1'b1 : 1'b0};
                  else
                    wb_sel_o <= 4'b1111;

                  wb_state_r <= wb_m_burst_1;
               end

               wb_m_burst_1: begin
                  wb_cyc_o <= 1;
                  wb_stb_o <= 1;

                  if (wb_ack_i)
                    begin

                       wb_dat_o <= dmem_rd_data_32_w;
                       if (m_if_burst_flags_r[bflag_transp0])
                         wb_sel_o <= {dmem_rd_data_32_w[31:24] != 0 ? 1'b1 : 1'b0,
                                      dmem_rd_data_32_w[23:16] != 0 ? 1'b1 : 1'b0,
                                      dmem_rd_data_32_w[15:8]  != 0 ? 1'b1 : 1'b0,
                                      dmem_rd_data_32_w[7:0]   != 0 ? 1'b1 : 1'b0};
                       else
                         wb_sel_o <= 4'b1111;

                       if (m_if_burst_len_r > 1 /* does not work when != 1*/ )
                         begin

                            m_if_burst_len_r <= m_if_burst_len_r - 1;

                            if (m_if_burst_flags_r[bflag_inc_ext])
                              wb_adr_o <= wb_adr_o + 4;

                            if (m_if_burst_flags_r[bflag_inc_int])
                              m_if_int_addr_r <= m_if_int_addr_r + 2;

                            if (m_if_burst_len_r[3:0] == 0)
                              begin
                                 wb_cyc_o <= 0;
                                 wb_stb_o <= 0;

                                 wb_state_r <= wb_m_back_off;
                              end
                         end
                       else
                         begin
                            m_if_ack <= 1;

                            wb_cyc_o <= 0;
                            wb_stb_o <= 0;
                            wb_we_o  <= 0;

                            m_if_dmem_ren <= 0;
                            m_if_dmem_wen <= 0;
                            m_if_imem_wen <= 0;

                            wb_state_r <= wb_m_idle;
                         end
                    end
               end

             endcase
          end
     end

   ajardsp_top ajardsp_0(.clk(clk),

                         .rst_core(rst),
                         .rst_mem(rst),

                         .ext_imem_wr_addr_i(m_if_int_addr_r),
                         .ext_imem_wr_data_i(wb_dat_i),
                         .ext_imem_wr_en_i(m_if_imem_wen),

                         .ext_dmem_addr_i(m_if_int_addr_r),
                         .ext_dmem_wr_data_i(wb_dat_i),
                         .ext_dmem_wr_en_i(m_if_dmem_wen),
                         .ext_dmem_rd_data_o(dmem_rd_data_32_w),
                         .ext_dmem_rd_en_i(m_if_dmem_ren),

                         .core_halt_o(core_halt_w),

                         .gpio_i(0),
                         .gpio_o(),

                         .gpio_2_o(),
                         .gpio_2_ren_o(),
                         .gpio_2_wen_o(),

                         .interrupt_req_i(0),

                         .m_if_addr_o(m_if_addr_w),
                         .m_if_data_o(m_if_data_w),
                         .m_if_data_i(read_data),
                         .m_if_read_req_o(m_if_read_req_w),
                         .m_if_write_req_o(m_if_write_req_w),
                         .m_if_write_burst_req_o(m_if_write_burst_req_w),
                         .m_if_ack_i(m_if_ack),
                         .m_if_burst_len_o(m_if_burst_len_w),
                         .m_if_burst_ext_addr_o(m_if_burst_ext_addr_w),
                         .m_if_burst_int_addr_o(m_if_burst_int_addr_w),
                         .m_if_burst_flags_o(m_if_burst_flags_w)
                         );

endmodule
