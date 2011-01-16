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

module wb_sdram_ctrl(
                     /* Wishbone interface */
                     wb_clk_i,
                     wb_rst_i,

                     wb_ack_o,
                     wb_dat_i,
                     wb_dat_o,
                     wb_adr_i,

                     wb_sel_i,
                     wb_stb_i,
                     wb_we_i,

                     /* DDR-SDRAM interface */
                     ddr_cke,
                     ddr_cmd,
                     ddr_data,
                     ddr_dqs,
                     ddr_addr,
                     ddr_ba,

                     /* Clock interfaces */
                     clk,
                     clk_n,
                     ddr_clk,
                     ddr_clk_n
                     );

   output reg wb_ack_o;
   input  wb_clk_i;
   input [31:0] wb_adr_i;
   input [31:0] wb_dat_i;
   output [31:0] wb_dat_o;
   input         wb_rst_i;
   input [3:0]   wb_sel_i;
   input         wb_stb_i;
   input         wb_we_i;

   input         clk,
                 clk_n,
                 ddr_clk,
                 ddr_clk_n;

   output        ddr_cke;
   output [2:0]  ddr_cmd;
   inout [15:0]     ddr_data;
   inout [1:0]      ddr_dqs;
   output [12:0]    ddr_addr;
   output [1:0]     ddr_ba;

   reg [7:0]     next_state, state_r;
   reg [31:0]    addr_r;
   reg           rd_req, wr_req;
   wire          rd_ack, wr_ack;

   parameter wb_s_idle = 0, wb_s_read = 1, wb_s_write = 2;

   sdram_ctrl sdram_ctrl_0(.clk(clk), .rst(wb_rst_i),
                           .clk_n(clk_n),
                           .user_addr(addr_r),
                           .user_write_data(wb_dat_i),
                           .user_read_data(wb_dat_o),
                           .user_read_req(rd_req),
                           .user_write_req(wr_req),
                           .user_read_ack(rd_ack),
                           .user_write_ack(wr_ack),

                           .ddr_clk(ddr_clk),
                           .ddr_clk_n(ddr_clk_n),
                           .ddr_cke(ddr_cke),
                           .ddr_cmd(ddr_cmd),
                           .ddr_data(ddr_data),
                           .ddr_dqs(ddr_dqs),
                           .ddr_addr(ddr_addr),
                           .ddr_ba(ddr_ba)
                           );

   always @(posedge wb_clk_i)
     begin
        if (wb_rst_i)
          begin
             state_r <= wb_s_idle;
             addr_r <= 0;
          end
        else
          begin
             state_r <= next_state;

             if (next_state == wb_s_idle && wb_stb_i)
               begin
                  addr_r <= wb_adr_i;
               end
          end
     end

   always @(state_r or wb_stb_i or wb_we_i or rd_ack or wr_ack)
     begin
        next_state = state_r;
        wb_ack_o = 0;
        rd_req = 0;
        wr_req = 0;

        case (state_r)

          wb_s_idle: begin
             if (wb_stb_i)
               begin
                  if (wb_we_i)
                    begin
                       next_state = wb_s_write;
                       wr_req = 1;
                    end
                  else
                    begin
                       next_state = wb_s_read;
                       rd_req = 1;
                    end
               end
          end

          wb_s_read: begin
             if (rd_ack)
               begin
                  next_state = wb_s_idle;
                  wb_ack_o = 1;
               end
             else
               begin
                  rd_req = 1;
               end
          end

          wb_s_write: begin
             if (wr_ack)
               begin
                  next_state = wb_s_idle;
                  wb_ack_o = 1;
               end
             else
               begin
                  wr_req = 1;
               end
          end
        endcase
     end

endmodule
