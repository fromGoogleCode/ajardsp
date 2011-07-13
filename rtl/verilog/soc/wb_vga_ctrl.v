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

/* `define CONFIG_VGA_RES_640_480_60_HZ 1 */
`define CONFIG_VGA_TEXT_MODE 1

module wb_vga_ctrl(
                   /* Wishbone interface */
                   wb_clk_i,
                   wb_rst_i,
                   /* Master */
                   m_wb_ack_i,
                   m_wb_dat_o,
                   m_wb_dat_i,
                   m_wb_adr_o,

                   m_wb_cyc_o,
                   m_wb_cti_o,
                   m_wb_sel_o,
                   m_wb_stb_o,
                   m_wb_we_o,

                   /* Slave */
                   s_wb_ack_o,
                   s_wb_dat_i,
                   s_wb_dat_o,
                   s_wb_adr_i,

                   s_wb_cyc_i,
                   s_wb_sel_i,
                   s_wb_stb_i,
                   s_wb_we_i,

                   pixel_clk,

                   /* VGA interface */
                   VGA_RED,
                   VGA_GREEN,
                   VGA_BLUE,
                   VGA_HSYNC,
                   VGA_VSYNC

                   );

   input         wb_clk_i;
   input         wb_rst_i;
   input         m_wb_ack_i;
   input [31:0]  m_wb_dat_i;
   output [31:0] m_wb_dat_o;
   output [31:0]     m_wb_adr_o;
   output reg        m_wb_cyc_o;
   output [2:0]   m_wb_cti_o;
   output [3:0]   m_wb_sel_o;
   output reg     m_wb_stb_o;
   output         m_wb_we_o;



   output        s_wb_ack_o;
   input [31:0]  s_wb_adr_i;
   input [31:0]  s_wb_dat_i;
   output [31:0] s_wb_dat_o;
   input [3:0]   s_wb_sel_i;
   input         s_wb_cyc_i;
   input         s_wb_stb_i;
   input         s_wb_we_i;

   input         pixel_clk;

   output reg    VGA_RED,
                 VGA_GREEN,
                 VGA_BLUE;

   output reg    VGA_HSYNC,
                 VGA_VSYNC;

   wire          rst;

   reg [11:0]    hsync_cntr;
   reg [11:0]    vsync_cntr;
   reg           vysnc_cntr_zero_r;
   reg [11:0]    x_pos_r;
   reg [11:0]    y_pos;

   wire [11:0]   x_pos;
   wire          oe_w, red_w, green_w, blue_w;

   reg           x_oe_r, y_oe_r;

   reg [10:0]    graph_wr_addr_r;
   wire [15:0]   graph_data_w;

   reg [31:0]    fb_r_addr;

   wire [8:0]    fifo_fill_level;
   wire [31:0]   fifo_r_data;
   wire [8:0]    fifo_r_addr;
   reg [8:0]     fifo_w_addr;
   reg [7:0]     pixel_value,
                 pixel_value_r,
                 pixel_value_p_r;
   reg [15:0]    pixel_cntr_r;
   wire [15:0]   pixel_cntr;

   wire [31:0]   text_word_w;
   wire [7:0]    font_row_w;
   reg [7:0]     char_ascii_code;
   reg [2:0]     font_x_pos_r;

   reg [7:0]     m_state_r;

   reg [1:0]     r_vga_ctrl;
   reg [31:0]    r_vga_fb_addr;

   parameter m_s_idle        = (1 << 0),
             m_s_begin_burst = (1 << 1);

`ifdef CONFIG_VGA_RES_640_480_60_HZ
   parameter HSYNC_Ts    = 1600,    /* Whole line   */
             HSYNC_Tdisp = 1280,    /* Visible area */
             HSYNC_Tpw   = 192,     /* Sync pulse   */
             HSYNC_Tfp   = 32,      /* Front porch  */
             HSYNC_Tbp   = 96 - 10; /* Back porch   */

   parameter VSYNC_Ts    = 521,     /* Whole line   */
             VSYNC_Tdisp = 480,     /* Visible area */
             VSYNC_Tpw   = 2,       /* Sync pulse   */
             VSYNC_Tfp   = 10,      /* Front porch  */
             VSYNC_Tbp   = 29;      /* Back porch   */
`else
   /* 800 * 600 @ 60 Hz */
   parameter HSYNC_Ts    = 1056,    /* Whole line   */
             HSYNC_Tdisp = 800,     /* Visible area */
             HSYNC_Tpw   = 128,     /* Sync pulse   */
             HSYNC_Tfp   = 40,      /* Front porch  */
             HSYNC_Tbp   = 88;      /* Back porch   */

   parameter VSYNC_Ts    = 628,     /* Whole line   */
             VSYNC_Tdisp = 600,     /* Visible area */
             VSYNC_Tpw   = 4,       /* Sync pulse   */
             VSYNC_Tfp   = 1,       /* Front porch  */
             VSYNC_Tbp   = 23;      /* Back porch   */
`endif

   assign m_wb_adr_o = fb_r_addr;
   assign m_wb_cti_o = 3'b010;
   assign m_wb_we_o  = 0;
   assign m_wb_dat_o = 0;
   assign m_wb_sel_o = 4'b1111;

   assign rst = wb_rst_i;

   assign oe_w = x_oe_r & y_oe_r;

   always @(posedge pixel_clk)
     begin
        pixel_value_r <= pixel_value;

        font_x_pos_r <= x_pos[2:0];

        VGA_GREEN <= oe_w & green_w;
        VGA_RED   <= oe_w & red_w;
        VGA_BLUE  <= oe_w & blue_w;
     end

   assign red_w   = font_row_w[font_x_pos_r] & r_vga_ctrl[1] ? 1'b1 : pixel_value_r[0];
   assign green_w = font_row_w[font_x_pos_r] & r_vga_ctrl[1] ? 1'b1 : pixel_value_r[1];
   assign blue_w  = font_row_w[font_x_pos_r] & r_vga_ctrl[1] ? 1'b1 : pixel_value_r[2];

   assign s_wb_ack_o = s_wb_stb_i;

`ifdef CONFIG_VGA_RES_640_480_60_HZ
   assign pixel_cntr = pixel_cntr_r[15:1];
   assign x_pos = {1'b0, x_pos_r[11:1]};
`else
   assign pixel_cntr = pixel_cntr_r;
   assign x_pos = x_pos_r;
`endif

   always @(posedge wb_clk_i)
     begin

        if (wb_rst_i)
          begin
             r_vga_ctrl <= 0;
             r_vga_fb_addr <= 0;
          end
        else if (s_wb_stb_i & s_wb_we_i & s_wb_adr_i[16])
          begin
             case (s_wb_adr_i[3:0])
               4'h0: begin
                  r_vga_ctrl <= s_wb_dat_i;
               end
               4'h4: begin
                  r_vga_fb_addr <= s_wb_dat_i;
               end
             endcase
          end
     end


   always @(posedge wb_clk_i)
     begin
        m_wb_cyc_o = 0;
        m_wb_stb_o = 0;

        if (wb_rst_i | vysnc_cntr_zero_r | ~r_vga_ctrl[0])
          begin
             m_state_r <= m_s_idle;
             fb_r_addr <= r_vga_fb_addr;
             fifo_w_addr <= 0;
          end
        else
          begin
             case (m_state_r)
               m_s_idle: begin
                  if (fifo_fill_level < 256)
                    begin
                       m_state_r <= m_s_begin_burst;
                    end
               end
               m_s_begin_burst: begin
                  m_wb_cyc_o = 1;
                  m_wb_stb_o = 1;
                  if (m_wb_ack_i)
                    begin
                       fifo_w_addr <= fifo_w_addr + 1;
                       fb_r_addr <= fb_r_addr + 4;
                    end
                  if (fifo_fill_level > 256 + 128)
                    begin
                       m_state_r <= m_s_idle;
                    end
               end

             endcase
          end
     end

   always @(posedge pixel_clk)
     begin
        if (rst || VGA_VSYNC)
          begin
             pixel_cntr_r <= 0;
          end
        else
          begin
             if (oe_w)
               begin
                  pixel_cntr_r <= pixel_cntr_r + 1;
               end
          end
     end

   assign fifo_r_addr = pixel_cntr[11:2];


   always @(pixel_cntr or fifo_r_data)
     begin
        case (pixel_cntr[1:0])
          0: pixel_value = fifo_r_data[7:0];
          1: pixel_value = fifo_r_data[15:8];
          2: pixel_value = fifo_r_data[23:16];
          3: pixel_value = fifo_r_data[31:24];
        endcase
     end

   assign fifo_fill_level = fifo_w_addr > fifo_r_addr ?
                            fifo_w_addr - fifo_r_addr :
                            512 - (fifo_r_addr - fifo_w_addr);


   RAMB16_S36_S36 vga_fb_fifo(.DOA(fifo_r_data),
                              .DOB(),
                              .DOPA(),
                              .DOPB(),
                              .ADDRA(fifo_r_addr),
                              .ADDRB(fifo_w_addr),
                              .CLKA(pixel_clk),
                              .CLKB(wb_clk_i),
                              .DIA(0),
                              .DIB(m_wb_dat_i),
                              .DIPA(0),
                              .DIPB(0),
                              .ENA(1),
                              .ENB(1),
                              .SSRA(rst),
                              .SSRB(rst),
                              .WEA(0),
                              .WEB(m_wb_cyc_o & m_wb_ack_i));

   always @(posedge pixel_clk)
     begin
        if (rst)
          begin
             hsync_cntr <= 0;
             VGA_HSYNC <= 0;
          end
        else
          begin
             if (hsync_cntr == HSYNC_Ts)
               begin
                  hsync_cntr <= 0;
                  VGA_HSYNC <= 1;
               end
             else
               begin
                  if (hsync_cntr == HSYNC_Tpw)
                    begin
                       VGA_HSYNC <= 0;
                    end
                  hsync_cntr <= hsync_cntr + 1;
               end
          end
     end

   always @(posedge pixel_clk)
     begin
        if (rst)
          begin
             vsync_cntr <= 0;
             vysnc_cntr_zero_r <= 1;
             VGA_VSYNC <= 0;
          end
        else
          begin
             if (vsync_cntr == VSYNC_Ts)
               begin
                  vsync_cntr <= 0;
                  vysnc_cntr_zero_r <= 1;
                  VGA_VSYNC <= 1;
               end
             else if (hsync_cntr == HSYNC_Ts)
               begin
                  if (vsync_cntr == VSYNC_Tpw)
                    begin
                       VGA_VSYNC <= 0;
                    end
                  vsync_cntr <= vsync_cntr + 1;
                  vysnc_cntr_zero_r <= 0;
               end
          end
     end

   always @(posedge pixel_clk)
     begin
        if (rst)
          begin
             x_pos_r <= 0;
             x_oe_r <= 0;
          end
        else
          begin
             if (hsync_cntr == HSYNC_Tpw + HSYNC_Tbp)
               begin
                  x_pos_r <= 0;
                  x_oe_r <= 1;
               end
             else if (hsync_cntr == HSYNC_Ts - HSYNC_Tfp)
               begin
                  x_oe_r <= 0;
               end
             else
               begin
                  x_pos_r <= x_pos_r + 1;
               end
          end
     end

   always @(posedge pixel_clk)
     begin
        if (rst)
          begin
             y_pos <= 0;
             y_oe_r <= 0;
          end
        else
          begin
             if (hsync_cntr == HSYNC_Ts)
               begin
                  if (vsync_cntr == VSYNC_Tpw + VSYNC_Tbp)
                    begin
                       y_pos <= 0;
                       y_oe_r <= 1;
                    end
                  else if (vsync_cntr == VSYNC_Ts - VSYNC_Tfp)
                    begin
                       y_oe_r <= 0;
                    end

                  else
                    begin
                       y_pos <= y_pos + 1;
                    end
               end
          end
     end

   /* Font support - begin */

`ifdef CONFIG_VGA_TEXT_MODE
   vga_font font16x8(.clk(pixel_clk), .rst(rst),
                     .char_ascii_i(char_ascii_code),
                     .char_row_i(y_pos[3:0]),
                     .char_row_o(font_row_w));

   RAMB16_S36_S36 text_ram(.DOA(text_word_w),
                           .DOB(),
                           .DOPA(),
                           .DOPB(),
                           .ADDRA({y_pos[9:4],x_pos[9:5]}),
                           .ADDRB(s_wb_adr_i[15:2]),
                           .CLKA(pixel_clk),
                           .CLKB(wb_clk_i),
                           .DIA(0),
                           .DIB(s_wb_dat_i),
                           .DIPA(0),
                           .DIPB(0),
                           .ENA(1),
                           .ENB(1),
                           .SSRA(rst),
                           .SSRB(rst),
                           .WEA(0),
                           .WEB(s_wb_cyc_i & s_wb_stb_i & ~s_wb_adr_i[16]));

   always @(text_word_w or x_pos)
     begin
        case (x_pos[4:3])
          0: char_ascii_code = text_word_w[7:0];
          1: char_ascii_code = text_word_w[15:8];
          2: char_ascii_code = text_word_w[23:16];
          3: char_ascii_code = text_word_w[31:24];
        endcase
     end
`else
   assign font_row_w = 0;
`endif

endmodule
