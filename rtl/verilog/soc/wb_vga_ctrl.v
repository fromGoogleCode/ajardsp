// This file is part of AjarDSP-SoC
//
// Copyright (c) 2011 Markus Lavin
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

module wb_vga_ctrl(
                   /* Wishbone interface */
                   wb_clk_i,
                   wb_rst_i,

                   wb_ack_o,
                   wb_dat_i,
                   wb_dat_o,
                   wb_adr_i,

                   wb_cyc_i,
                   wb_sel_i,
                   wb_stb_i,
                   wb_we_i,

                   /* VGA interface */
                   VGA_RED,
                   VGA_GREEN,
                   VGA_BLUE,
                   VGA_HSYNC,
                   VGA_VSYNC

                   );

   output        wb_ack_o;
   input         wb_clk_i;
   input [31:0]  wb_adr_i;
   input [31:0]  wb_dat_i;
   output [31:0] wb_dat_o;
   input         wb_rst_i;
   input [3:0]   wb_sel_i;
   input         wb_cyc_i;
   input         wb_stb_i;
   input         wb_we_i;

   output        VGA_RED,
                 VGA_GREEN,
                 VGA_BLUE,
                 VGA_HSYNC,
                 VGA_VSYNC;

   wire          clk, rst;

   reg [11:0]    hsync_cntr;
   reg [11:0]    vsync_cntr;
   reg [11:0]    x_pos_r;
   reg [11:0]    y_pos;

   wire [11:0]   x_pos;
   wire          oe_w, red_w, green_w, blue_w;

   reg [10:0]    graph_wr_addr_r;
   wire [15:0]   graph_data_w;

   parameter HSYNC_Ts    = 1600,
             HSYNC_Tdisp = 1280,
             HSYNC_Tpw   = 192,
             HSYNC_Tfp   = 32,
             HSYNC_Tbp   = 96 - 10;

   parameter VSYNC_Ts    = 521,
             VSYNC_Tdisp = 480,
             VSYNC_Tpw   = 2,
             VSYNC_Tfp   = 10,
             VSYNC_Tbp   = 29;

   assign clk = wb_clk_i;
   assign rst = wb_rst_i;

   assign x_pos = {1'b0, x_pos_r[11:1]};

   assign oe_w = (x_pos >= 0 && x_pos < 640 && y_pos >= 0 && y_pos < 480) ? 1'b1 : 1'b0;

   assign VGA_HSYNC = (hsync_cntr < HSYNC_Tpw) ? 1'b1 : 1'b0;
   assign VGA_VSYNC = (vsync_cntr < VSYNC_Tpw) ? 1'b1 : 1'b0;

   assign VGA_GREEN = oe_w & green_w;
   assign VGA_RED   = oe_w & red_w;
   assign VGA_BLUE  = oe_w & blue_w;

   assign green_w = (graph_data_w == y_pos ? 1'b1 : 1'b0);
   assign red_w   = (y_pos == 10 || y_pos == 256 ) ? 1'b1 : 1'b0;
   assign blue_w  = 0;

   assign wb_ack_o = wb_stb_i;

   RAMB16_S18_S18 graph_mem(.DOA(graph_data_w),
                            .DOB(),
                            .DOPA(),
                            .DOPB(),
                            .ADDRA(x_pos),
                            .ADDRB(wb_adr_i),
                            .CLKA(clk),
                            .CLKB(clk),
                            .DIA(0),
                            .DIB(wb_dat_i[15:0]),
                            .DIPA(0),
                            .DIPB(0),
                            .ENA(1),
                            .ENB(1),
                            .SSRA(res),
                            .SSRB(res),
                            .WEA(0),
                            .WEB(/*wb_cyc_i &*/ wb_stb_i & wb_we_i));

   always @(posedge clk)
     begin
        if (rst)
          begin
             hsync_cntr <= 0;
          end
        else
          begin
             if (hsync_cntr == HSYNC_Ts)
               begin
                  hsync_cntr <= 0;
               end
             else
               begin
                  hsync_cntr <= hsync_cntr + 1;
               end
          end
     end

   always @(posedge clk)
     begin
        if (rst)
          begin
             vsync_cntr <= 0;
          end
        else
          begin
             if (vsync_cntr == VSYNC_Ts)
               begin
                  vsync_cntr <= 0;
               end
             else if (hsync_cntr == HSYNC_Ts)
               begin
                  vsync_cntr <= vsync_cntr + 1;
               end
          end
     end

   always @(posedge clk)
     begin
        if (rst)
          begin
             x_pos_r <= 0;
          end
        else
          begin
             if (hsync_cntr == HSYNC_Tpw + HSYNC_Tbp)
               begin
                  x_pos_r <= 0;
               end
             else
               begin
                  x_pos_r <= x_pos_r + 1;
               end
          end
     end

   always @(posedge clk)
     begin
        if (rst)
          begin
             y_pos <= 0;
          end
        else
          begin
             if (hsync_cntr == HSYNC_Ts)
               begin
                  if (vsync_cntr == VSYNC_Tpw + VSYNC_Tbp)
                    begin
                       y_pos <= 0;
                    end
                  else
                    begin
                       y_pos <= y_pos + 1;
                    end
               end
          end
     end

endmodule
