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
                  wb_we_o,

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
   output [3:0]  wb_sel_o;
   output reg    wb_stb_o;
   output reg    wb_we_o;

   reg [3:0]     state_r;

   wire [31:0]   m_if_addr_w;
   wire [31:0]   m_if_data_w;
   wire          m_if_read_req_w;
   wire          m_if_write_req_w;

   assign wb_sel_o = 4'b1111;

   parameter wb_m_idle = 0, wb_m_read = 1, wb_m_write = 2;

   always @(posedge clk)
     begin

        wb_cyc_o = 0;
        wb_stb_o = 0;
        wb_we_o  = 0;

        if (rst)
          begin
             state_r <= wb_m_idle;
          end
        else
          begin

             case (state_r)

               wb_m_idle: begin
                  if (m_if_read_req_w)
                    begin
                       wb_adr_o <= m_if_addr_w;

                       state_r <= wb_m_read;
                    end
                  else if (m_if_write_req_w)
                    begin
                       wb_adr_o <= m_if_addr_w;
                       wb_dat_o <= m_if_data_w;

                       state_r <= wb_m_write;
                    end
               end

               wb_m_read: begin
                  wb_cyc_o = 1;
                  wb_stb_o = 1;
                  wb_we_o  = 0;

                  if (wb_ack_i)
                    begin
                       state_r <= wb_m_idle;
                    end
               end

               wb_m_write: begin
                  wb_cyc_o = 1;
                  wb_stb_o = 1;
                  wb_we_o  = 1;

                  if (wb_ack_i)
                    begin
                       state_r <= wb_m_idle;
                    end
               end
             endcase
          end
     end


   ajardsp_top ajardsp_0(.clk(clk), .rst_core(rst), .rst_mem(rst),

                         .ext_imem_wr_addr_i(0),
                         .ext_imem_wr_data_i(0),
                         .ext_imem_wr_en_i(0),

                         .ext_dmem_addr_i(0),
                         .ext_dmem_wr_data_i(0),
                         .ext_dmem_wr_en_i(0),
                         .ext_dmem_rd_data_o(),
                         .ext_dmem_rd_en_i(0),

                         .core_halt_o(),

                         .gpio_i(0),
                         .gpio_o(),

                         .gpio_2_o(),
                         .gpio_2_ren_o(),
                         .gpio_2_wen_o(),

                         .interrupt_req_i(0),

                         .m_if_addr_o(m_if_addr_w),
                         .m_if_data_o(m_if_data_w),
                         .m_if_data_i(wb_dat_i),
                         .m_if_read_req_o(m_if_read_req_w),
                         .m_if_write_req_o(m_if_write_req_w),
                         .m_if_read_ack_i(wb_ack_i),
                         .m_if_write_ack_i(wb_ack_i)

                         );

endmodule
