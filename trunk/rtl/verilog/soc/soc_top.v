// This file is part of AjarDSP
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

module soc_top(
               CLK_50_MHZ,
               RST,

               SD_A,
               SD_DQ,
               SD_BA,
               SD_CAS,
               SD_CK_N,
               SD_CK_P,
               SD_CKE,
               SD_CS,
               SD_LDM,
               SD_LDQS,
               SD_RAS,
               SD_UDM,
               SD_UDQS,
               SD_WE,
               SD_CK_FB,

               /* ETH-PHY IF */
               E_COL,
               E_CRS,
               E_MDC,
               E_MDIO,
               E_RX_CLK,
               E_RX_DV,
               E_RXD,
               E_TX_CLK,
               E_TX_EN,
               E_TXD,

               SW,
               BTN_NORTH,
               BTN_EAST,
               BTN_SOUTH,
               LED,

               RS232_DTE_RXD, RS232_DTE_TXD,
               LCD_E, LCD_RS, LCD_RW, LCD_D,
               IRQ,
               ROT_A, ROT_B, ROT_CENTER,
               VGA_RED,
               VGA_GREEN,
               VGA_BLUE,
               VGA_HSYNC,
               VGA_VSYNC,

               ADC_SS,
               ADC_SCK,
               ADC_MISO,

               PS2_CLK,
               PS2_DATA
               );

   input CLK_50_MHZ;
   input RST;

   input [3:0] SW;
   input       BTN_NORTH;
   input       BTN_EAST;
   input       BTN_SOUTH;
/*   input       BTN_WEST; */
   output [7:0] LED;

   input            RS232_DTE_RXD;
   output           RS232_DTE_TXD;

   output           LCD_E, LCD_RS, LCD_RW;
   output [3:0]     LCD_D;

   output           VGA_RED,
                    VGA_GREEN,
                    VGA_BLUE,
                    VGA_HSYNC,
                    VGA_VSYNC;

   output           ADC_SS,
                    ADC_SCK;
   input            ADC_MISO;

   input            PS2_CLK,
                    PS2_DATA;

   input            IRQ;

   input        ROT_A, ROT_B, ROT_CENTER;

   /* DDR-SDRAM */
   output [12:0] SD_A;
   inout [15:0]  SD_DQ;
   output [1:0]  SD_BA;
   output        SD_CAS;
   output        SD_CK_N;
   output        SD_CK_P;
   output        SD_CKE;
   output        SD_CS;
   output        SD_LDM;

   inout         SD_LDQS;
   output        SD_RAS;
   output        SD_UDM;
   inout         SD_UDQS;
   output        SD_WE;
   input         SD_CK_FB;
   /* Ethernet */
   input        E_COL,
                E_CRS;
   output       E_MDC;
   inout        E_MDIO;
   input        E_RX_CLK,
                E_RX_DV;
   input [4:0]  E_RXD;
   input        E_TX_CLK;
   output       E_TX_EN;
   output [4:0] E_TXD;


   reg [3:0]     rst_cnt_0, rst_cnt_1, rst_cnt_2;

   wire          clk_fb, clk_fb_, clk_fb_2, clk_fb_2_;

   wire          locked_0, locked_1, locked_2;

   wire          CLK_40_MHZ;
   wire [31:0]   read_data;
   wire          ack;

   wire          ddr_clk,
                 ddr_clk_n,
                 ddr_clk_p90,
                 ddr_clk_fb;

   wire          rst;

   wire          clk_p, clk_n, clk_p_fb;

   reg           sd_wb_cyc_o_w,
                 sd_wb_stb_o_w,
                 vga_wb_cyc_o_w,
                 vga_wb_stb_o_w,
                 adc_wb_cyc_o_w,
                 adc_wb_stb_o_w,
                 ram_wb_cyc_o_w,
                 ram_wb_stb_o_w,
                 misc_wb_cyc_o_w,
                 misc_wb_stb_o_w;

   reg [2:0]     sd_wb_cti_o_w;

   wire [31:0]   sd_wb_dat_i_w,
                 vga_wb_dat_i_w,
                 adc_wb_dat_i_w,
                 ram_wb_dat_i_w,
                 misc_wb_dat_i_w;

   wire          sd_wb_ack_i_w,
                 vga_wb_ack_i_w,
                 adc_wb_ack_i_w,
                 ram_wb_ack_i_w,
                 misc_wb_ack_i_w;

   reg           wb_ack_i_w;
   reg [31:0]    wb_dat_o_w;
   reg [31:0]    wb_dat_i_w;
   reg [31:0]    wb_adr_o_w;
   reg           wb_cyc_o_w;
   reg [2:0]     wb_cti_o_w;
   reg [3:0]     wb_sel_o_w;
   reg           wb_stb_o_w;
   reg           wb_we_o_w;

   reg         m_dsp_0_wb_ack_i_w;
   reg [31:0]  m_dsp_0_wb_dat_i_w;
   wire [31:0] m_dsp_0_wb_dat_o_w;
   wire [31:0] m_dsp_0_wb_adr_o_w;
   wire        m_dsp_0_wb_cyc_o_w;
   wire [3:0]  m_dsp_0_wb_sel_o_w;
   wire        m_dsp_0_wb_stb_o_w;
   wire        m_dsp_0_wb_we_o_w;

   reg         m_dsp_1_wb_ack_i_w;
   reg [31:0]  m_dsp_1_wb_dat_i_w;
   wire [31:0] m_dsp_1_wb_dat_o_w;
   wire [31:0] m_dsp_1_wb_adr_o_w;
   wire        m_dsp_1_wb_cyc_o_w;
   wire [3:0]  m_dsp_1_wb_sel_o_w;
   wire        m_dsp_1_wb_stb_o_w;
   wire        m_dsp_1_wb_we_o_w;

   reg         m_debug_wb_ack_i_w;
   reg [31:0]  m_debug_wb_dat_i_w;
   wire [31:0] m_debug_wb_dat_o_w;
   wire [31:0] m_debug_wb_adr_o_w;
   wire        m_debug_wb_cyc_o_w;
   wire [3:0]  m_debug_wb_sel_o_w;
   wire        m_debug_wb_stb_o_w;
   wire        m_debug_wb_we_o_w;

   reg         m_vga_wb_ack_i_w;
   reg [31:0]  m_vga_wb_dat_i_w;
   wire [31:0] m_vga_wb_dat_o_w;
   wire [31:0] m_vga_wb_adr_o_w;
   wire        m_vga_wb_cyc_o_w;
   wire [2:0]  m_vga_wb_cti_o_w;
   wire [3:0]  m_vga_wb_sel_o_w;
   wire        m_vga_wb_stb_o_w;
   wire        m_vga_wb_we_o_w;

   reg         m_eth_wb_ack_i_w;
   reg [31:0]  m_eth_wb_dat_i_w;
   wire [31:0] m_eth_wb_dat_o_w;
   wire [31:0] m_eth_wb_adr_o_w;
   wire        m_eth_wb_cyc_o_w;
   wire [2:0]  m_eth_wb_cti_o_w;
   wire [3:0]  m_eth_wb_sel_o_w;
   wire        m_eth_wb_stb_o_w;
   wire        m_eth_wb_we_o_w;

   reg [4:0]   active_wb_master;

   parameter M_DSP_0 = 5'b00001,
             M_DSP_1 = 5'b00010,
             M_VGA   = 5'b00100,
             M_DEBUG = 5'b01000,
             M_ETH   = 5'b10000;

   wire [7:0]  led_misc_io_w,
               reset_ctrl_misc_io_w;

   wire        uart_rx_dsp_w,
               uart_tx_dsp_w,
               uart_rx_debug_w,
               uart_tx_debug_w;

   wire [7:0]  lcd_w;

   assign SD_CS = 0;

   assign rst = RST || !locked_0 || !locked_1 || !locked_2;

   assign LED = rst ? 8'haa : led_misc_io_w;

   assign uart_rx_dsp_w   = 1'b1;
   assign uart_rx_debug_w = RS232_DTE_RXD;
   assign RS232_DTE_TXD   = uart_tx_debug_w;

   assign LCD_E       = lcd_w[4];
   assign LCD_RS      = lcd_w[5];
   assign LCD_RW      = 0;
   assign LCD_D[3:0]  = lcd_w[3:0];

   DCM_SP #(.CLKFX_DIVIDE(5),
            .CLKFX_MULTIPLY(4))
   dcm_2(.CLK0(clk_fb_2_),
         .CLK90(),
         .CLK180(),
         .CLK270(),
         .CLK2X(),

         .CLK2X180(),
	 .CLKDV(),
         .CLKFX(CLK_40_MHZ),
         .CLKFX180(),
         .LOCKED(locked_2),
         .PSDONE(),
         .STATUS(),
	 .CLKFB(clk_fb_2),
         .CLKIN(CLK_50_MHZ),
         .DSSEN(),
         .PSCLK(),
         .PSEN(),
         .PSINCDEC(),
         .RST(RST));


   BUFG bufg2(.I(clk_fb_2_), .O(clk_fb_2));

   always @(posedge CLK_40_MHZ)
     begin
        if (RST | !locked_2)
          rst_cnt_0 <= 0;
        else if (rst_cnt_0[3] == 0)
          rst_cnt_0 <= rst_cnt_0 + 1;
     end

   DCM_SP dcm_0(.CLK0(clk_fb_),
                .CLK90(),
                .CLK180(),
                .CLK270(),
                .CLK2X(clk),

                .CLK2X180(),
	        .CLKDV(),
                .CLKFX(),
                .CLKFX180(),
                .LOCKED(locked_0),
                .PSDONE(),
                .STATUS(),
	        .CLKFB(clk_fb),
                .CLKIN(CLK_40_MHZ),
                .DSSEN(),
                .PSCLK(),
                .PSEN(),
                .PSINCDEC(),
                .RST(RST | !locked_2 | !rst_cnt_0[3]));

   BUFG bufg0(.I(clk_fb_), .O(clk_fb));


   DCM_SP dcm_1(.CLK0(clk_p),
                .CLK90(ddr_clk_p90),
                .CLK180(clk_n),
/*                .CLK270(ddr_clk_n), */
                .CLK2X(),
                .CLK2X180(),
	        .CLKDV(),
                .CLKFX(),
                .CLKFX180(),
                .LOCKED(locked_1),
                .PSDONE(),
                .STATUS(),
	        .CLKFB(clk_p_fb),
                .CLKIN(clk),
                .DSSEN(),
                .PSCLK(),
                .PSEN(),
                .PSINCDEC(),
                .RST(RST | !locked_0));

   BUFG bufg1(.I(clk_p), .O(clk_p_fb));

   DCM_SP #(
            .CLKOUT_PHASE_SHIFT("FIXED"),
            .PHASE_SHIFT(32)
            )
          dcm_ddr_clk(.CLK0(ddr_clk),
                      .CLK90(),
                      .CLK180(ddr_clk_n),
                      .CLK270(),
                      .CLK2X(),
                      .CLK2X180(),
	              .CLKDV(),
                      .CLKFX(),
                      .CLKFX180(),
                      .LOCKED(),
                      .PSDONE(),
                      .STATUS(),
	              .CLKFB(ddr_clk_fb),
                      .CLKIN(ddr_clk_p90),
                      .DSSEN(),
                      .PSCLK(),
                      .PSEN(),
                      .PSINCDEC(),
                      .RST(rst));

   BUFG bufg_ddr_clk(.I(ddr_clk), .O(ddr_clk_fb));


   // synthesis attribute IOB of oddr2_clk_p "TRUE"
   // synthesis attribute IOB of oddr2_clk_n "TRUE"


   ODDR2 oddr2_clk_p(.Q(SD_CK_P), .C0(ddr_clk), .C1(ddr_clk_n), .CE(1'b1),
                     .D0(1'b1), .D1(1'b0), .R(rst), .S(1'b0));

   ODDR2 oddr2_clk_n(.Q(SD_CK_N), .C0(ddr_clk), .C1(ddr_clk_n), .CE(1'b1),
                     .D0(1'b0), .D1(1'b1), .R(rst), .S(1'b0));

   always @(posedge CLK_40_MHZ)
     begin
        if (rst)
          begin
             active_wb_master <= M_DSP_0;
          end
        else
          begin
             case (active_wb_master)
               M_DSP_0: begin
                  if (m_dsp_0_wb_cyc_o_w == 0)
                    active_wb_master <= M_DSP_1;
               end

               M_DSP_1: begin
                  if (m_dsp_1_wb_cyc_o_w == 0)
                    active_wb_master <= M_VGA;
               end

               M_VGA: begin
                  if (m_vga_wb_cyc_o_w == 0)
                    active_wb_master <= M_DEBUG;
               end

               M_DEBUG: begin
                  if (m_debug_wb_cyc_o_w == 0)
                    active_wb_master <= M_ETH;
               end

               M_ETH: begin
                  if (m_eth_wb_cyc_o_w == 0)
                    active_wb_master <= M_DSP_0;
               end

             endcase
          end
     end

   always @(active_wb_master or wb_dat_i_w or wb_ack_i_w or

            m_dsp_0_wb_dat_o_w or m_dsp_0_wb_adr_o_w or m_dsp_0_wb_cyc_o_w or
            m_dsp_0_wb_sel_o_w or m_dsp_0_wb_stb_o_w or m_dsp_0_wb_we_o_w or

            m_dsp_1_wb_dat_o_w or m_dsp_1_wb_adr_o_w or m_dsp_1_wb_cyc_o_w or
            m_dsp_1_wb_sel_o_w or m_dsp_1_wb_stb_o_w or m_dsp_1_wb_we_o_w or

            m_debug_wb_dat_o_w or m_debug_wb_adr_o_w or m_debug_wb_cyc_o_w or
            m_debug_wb_sel_o_w or m_debug_wb_stb_o_w or m_debug_wb_we_o_w or

            m_vga_wb_dat_o_w or m_vga_wb_adr_o_w or m_vga_wb_cyc_o_w or m_vga_wb_cti_o_w or
            m_vga_wb_sel_o_w or m_vga_wb_stb_o_w or m_vga_wb_we_o_w or

            m_eth_wb_dat_o_w or m_eth_wb_adr_o_w or m_eth_wb_cyc_o_w or m_eth_wb_cti_o_w or
            m_eth_wb_sel_o_w or m_eth_wb_stb_o_w or m_eth_wb_we_o_w
            )
     begin
        m_dsp_0_wb_ack_i_w = 0;
        m_dsp_0_wb_dat_i_w = wb_dat_i_w;
        m_dsp_1_wb_ack_i_w = 0;
        m_dsp_1_wb_dat_i_w = wb_dat_i_w;
        m_debug_wb_ack_i_w = 0;
        m_debug_wb_dat_i_w = wb_dat_i_w;
        m_vga_wb_ack_i_w = 0;
        m_vga_wb_dat_i_w = wb_dat_i_w;
        m_eth_wb_ack_i_w = 0;
        m_eth_wb_dat_i_w = wb_dat_i_w;


        wb_dat_o_w = 0;
        wb_adr_o_w = 0;
        wb_cyc_o_w = 0;
        wb_cti_o_w = 0;
        wb_sel_o_w = 0;
        wb_stb_o_w = 0;
        wb_we_o_w  = 0;

        case (active_wb_master)
          M_DSP_0: begin
             m_dsp_0_wb_ack_i_w = wb_ack_i_w;
             wb_dat_o_w = m_dsp_0_wb_dat_o_w;
             wb_adr_o_w = m_dsp_0_wb_adr_o_w;
             wb_cyc_o_w = m_dsp_0_wb_cyc_o_w;
             wb_cti_o_w = 0;
             wb_sel_o_w = m_dsp_0_wb_sel_o_w;
             wb_stb_o_w = m_dsp_0_wb_stb_o_w;
             wb_we_o_w  = m_dsp_0_wb_we_o_w;
          end

          M_DSP_1: begin
             m_dsp_1_wb_ack_i_w = wb_ack_i_w;
             wb_dat_o_w = m_dsp_1_wb_dat_o_w;
             wb_adr_o_w = m_dsp_1_wb_adr_o_w;
             wb_cyc_o_w = m_dsp_1_wb_cyc_o_w;
             wb_cti_o_w = 0;
             wb_sel_o_w = m_dsp_1_wb_sel_o_w;
             wb_stb_o_w = m_dsp_1_wb_stb_o_w;
             wb_we_o_w  = m_dsp_1_wb_we_o_w;
          end

          M_DEBUG: begin
             m_debug_wb_ack_i_w = wb_ack_i_w;
             wb_dat_o_w = m_debug_wb_dat_o_w;
             wb_adr_o_w = m_debug_wb_adr_o_w;
             wb_cyc_o_w = m_debug_wb_cyc_o_w;
             wb_cti_o_w = 0;
             wb_sel_o_w = m_debug_wb_sel_o_w;
             wb_stb_o_w = m_debug_wb_stb_o_w;
             wb_we_o_w  = m_debug_wb_we_o_w;
          end

          M_VGA: begin
             m_vga_wb_ack_i_w = wb_ack_i_w;
             wb_dat_o_w = m_vga_wb_dat_o_w;
             wb_adr_o_w = m_vga_wb_adr_o_w;
             wb_cyc_o_w = m_vga_wb_cyc_o_w;
             wb_cti_o_w = m_vga_wb_cti_o_w;
             wb_sel_o_w = m_vga_wb_sel_o_w;
             wb_stb_o_w = m_vga_wb_stb_o_w;
             wb_we_o_w  = m_vga_wb_we_o_w;
          end

          M_ETH: begin
             m_eth_wb_ack_i_w = wb_ack_i_w;
             wb_dat_o_w = m_eth_wb_dat_o_w;
             wb_adr_o_w = m_eth_wb_adr_o_w;
             wb_cyc_o_w = m_eth_wb_cyc_o_w;
             wb_cti_o_w = m_eth_wb_cti_o_w;
             wb_sel_o_w = m_eth_wb_sel_o_w;
             wb_stb_o_w = m_eth_wb_stb_o_w;
             wb_we_o_w  = m_eth_wb_we_o_w;
          end

        endcase
     end

   always @(wb_adr_o_w or vga_wb_dat_i_w or vga_wb_ack_i_w or
            sd_wb_dat_i_w or sd_wb_ack_i_w or adc_wb_dat_i_w or adc_wb_ack_i_w or
            ram_wb_dat_i_w or ram_wb_ack_i_w or misc_wb_dat_i_w or misc_wb_ack_i_w)
     begin
        wb_dat_i_w     = 0;
        wb_ack_i_w     = 0;

        case (wb_adr_o_w[31:28])
          4'hf: begin
             wb_dat_i_w     = vga_wb_dat_i_w;
             wb_ack_i_w     = vga_wb_ack_i_w;
          end
          4'he: begin
             wb_dat_i_w     = adc_wb_dat_i_w;
             wb_ack_i_w     = adc_wb_ack_i_w;
          end
          4'hd: begin
             wb_dat_i_w     = ram_wb_dat_i_w;
             wb_ack_i_w     = ram_wb_ack_i_w;
          end
          4'hc: begin
             wb_dat_i_w     = misc_wb_dat_i_w;
             wb_ack_i_w     = misc_wb_ack_i_w;
          end

          default: begin
             wb_dat_i_w    = sd_wb_dat_i_w;
             wb_ack_i_w    = sd_wb_ack_i_w;
          end
        endcase
     end

   always @(wb_adr_o_w or wb_cyc_o_w or wb_stb_o_w or wb_cti_o_w)
     begin
        vga_wb_cyc_o_w = 0;
        vga_wb_stb_o_w = 0;
        adc_wb_cyc_o_w = 0;
        adc_wb_stb_o_w = 0;
        sd_wb_cyc_o_w = 0;
        sd_wb_cti_o_w = 0;
        sd_wb_stb_o_w = 0;
        ram_wb_cyc_o_w = 0;
        ram_wb_stb_o_w = 0;
        misc_wb_cyc_o_w = 0;
        misc_wb_stb_o_w = 0;

        case (wb_adr_o_w[31:28])
          4'hf: begin
             vga_wb_cyc_o_w = wb_cyc_o_w;
             vga_wb_stb_o_w = wb_stb_o_w;
          end
          4'he: begin
             adc_wb_cyc_o_w = wb_cyc_o_w;
             adc_wb_stb_o_w = wb_stb_o_w;
          end
          4'hd: begin
             ram_wb_cyc_o_w = wb_cyc_o_w;
             ram_wb_stb_o_w = wb_stb_o_w;
          end
          4'hc: begin
             misc_wb_cyc_o_w = wb_cyc_o_w;
             misc_wb_stb_o_w = wb_stb_o_w;
          end


          default: begin
             sd_wb_cyc_o_w = wb_cyc_o_w;
             sd_wb_stb_o_w = wb_stb_o_w;
             sd_wb_cti_o_w = wb_cti_o_w;
          end
        endcase
     end

   defparam
     wb_ajardsp_0.EXT_BOOT_ADDR = 32'hD0000000,
     wb_ajardsp_0.EXT_BOOT_LEN  = 16'h0100;

   wb_ajardsp wb_ajardsp_0(.clk(CLK_40_MHZ),
                           .rst(~reset_ctrl_misc_io_w[0]),

                           /* Wishbone interface */
                           .wb_clk_i(CLK_40_MHZ),
                           .wb_rst_i(~reset_ctrl_misc_io_w[0]),

                           .wb_ack_i(m_dsp_0_wb_ack_i_w),
                           .wb_dat_o(m_dsp_0_wb_dat_o_w),
                           .wb_dat_i(m_dsp_0_wb_dat_i_w),
                           .wb_adr_o(m_dsp_0_wb_adr_o_w),

                           .wb_cyc_o(m_dsp_0_wb_cyc_o_w),
                           .wb_stb_o(m_dsp_0_wb_stb_o_w),
                           .wb_sel_o(m_dsp_0_wb_sel_o_w),
                           .wb_we_o(m_dsp_0_wb_we_o_w)
                           );

   defparam
     wb_ajardsp_1.EXT_BOOT_ADDR = 32'hD0000000,
     wb_ajardsp_1.EXT_BOOT_LEN  = 16'h0100;

   wb_ajardsp wb_ajardsp_1(.clk(CLK_40_MHZ),
                           .rst(~reset_ctrl_misc_io_w[1]),

                           /* Wishbone interface */
                           .wb_clk_i(CLK_40_MHZ),
                           .wb_rst_i(~reset_ctrl_misc_io_w[1]),

                           .wb_ack_i(m_dsp_1_wb_ack_i_w),
                           .wb_dat_o(m_dsp_1_wb_dat_o_w),
                           .wb_dat_i(m_dsp_1_wb_dat_i_w),
                           .wb_adr_o(m_dsp_1_wb_adr_o_w),

                           .wb_cyc_o(m_dsp_1_wb_cyc_o_w),
                           .wb_stb_o(m_dsp_1_wb_stb_o_w),
                           .wb_sel_o(m_dsp_1_wb_sel_o_w),
                           .wb_we_o(m_dsp_1_wb_we_o_w)
                           );


   wb_sdram_ctrl wb_sdram_ctrl_0(.wb_clk_i(CLK_40_MHZ),
                                 .wb_rst_i(rst),

                                 .wb_adr_i(wb_adr_o_w),
                                 .wb_dat_i(wb_dat_o_w),
                                 .wb_dat_o(sd_wb_dat_i_w),

                                 .wb_cyc_i(sd_wb_cyc_o_w),
                                 .wb_cti_i(sd_wb_cti_o_w),
                                 .wb_stb_i(sd_wb_stb_o_w),
                                 .wb_we_i(wb_we_o_w),
                                 .wb_sel_i(wb_sel_o_w),
                                 .wb_ack_o(sd_wb_ack_i_w),

                                 .clk(clk_p),
                                 .clk_n(clk_n),

                                 .ddr_clk(ddr_clk),
                                 .ddr_clk_n(ddr_clk_n),

                                 .ddr_cke(SD_CKE),
                                 .ddr_cmd({SD_RAS, SD_CAS, SD_WE}),
                                 .ddr_data(SD_DQ),
                                 .ddr_dm({SD_UDM, SD_LDM}),
                                 .ddr_dqs({SD_UDQS, SD_LDQS}),
                                 .ddr_addr(SD_A),
                                 .ddr_ba(SD_BA)
                                 );


   wb_vga_ctrl wb_vga_ctrl_0(
                             .wb_clk_i(CLK_40_MHZ),
                             .wb_rst_i(rst),

                             .m_wb_ack_i(m_vga_wb_ack_i_w),
                             .m_wb_dat_o(m_vga_wb_dat_o_w),
                             .m_wb_dat_i(m_vga_wb_dat_i_w),
                             .m_wb_adr_o(m_vga_wb_adr_o_w),

                             .m_wb_cyc_o(m_vga_wb_cyc_o_w),
                             .m_wb_stb_o(m_vga_wb_stb_o_w),
                             .m_wb_cti_o(m_vga_wb_cti_o_w),
                             .m_wb_sel_o(m_vga_wb_sel_o_w),
                             .m_wb_we_o(m_vga_wb_we_o_w),

                             .s_wb_adr_i(wb_adr_o_w),
                             .s_wb_dat_i(wb_dat_o_w),
                             .s_wb_dat_o(vga_wb_dat_i_w),

                             .s_wb_cyc_i(vga_wb_cyc_o_w),
                             .s_wb_stb_i(vga_wb_stb_o_w),
                             .s_wb_we_i(wb_we_o_w),
                             .s_wb_sel_i(wb_sel_o_w),
                             .s_wb_ack_o(vga_wb_ack_i_w),

                             .pixel_clk(CLK_40_MHZ),

                             .VGA_RED(VGA_RED),
                             .VGA_GREEN(VGA_GREEN),
                             .VGA_BLUE(VGA_BLUE),
                             .VGA_HSYNC(VGA_HSYNC),
                             .VGA_VSYNC(VGA_VSYNC)

                             );

   wb_adc_ctrl wb_adc_ctrl_0(.wb_clk_i(CLK_40_MHZ),
                             .wb_rst_i(rst),

                             .wb_adr_i(wb_adr_o_w),
                             .wb_dat_i(wb_dat_o_w),
                             .wb_dat_o(adc_wb_dat_i_w),

                             .wb_cyc_i(adc_wb_cyc_o_w),
                             .wb_stb_i(adc_wb_stb_o_w),
                             .wb_we_i(wb_we_o_w),
                             .wb_sel_i(wb_sel_o_w),
                             .wb_ack_o(adc_wb_ack_i_w),

                             /* ADC interface */
                             .ADC_SS_o(ADC_SS),
                             .ADC_MISO_i(ADC_MISO),
                             .ADC_SCK_o(ADC_SCK)

                             );


   wb_ram wb_ram_0(.wb_clk_i(CLK_40_MHZ),
                   .wb_rst_i(rst),

                   .wb_adr_i(wb_adr_o_w),
                   .wb_dat_i(wb_dat_o_w),
                   .wb_dat_o(ram_wb_dat_i_w),

                   .wb_cti_i(3'b000),
                   .wb_cyc_i(ram_wb_cyc_o_w),
                   .wb_stb_i(ram_wb_stb_o_w),
                   .wb_we_i(wb_we_o_w),
                   .wb_sel_i(wb_sel_o_w),
                   .wb_ack_o(ram_wb_ack_i_w)
                   );

   wb_misc_io wb_misc_io_0(.wb_clk_i(CLK_40_MHZ),
                           .wb_rst_i(rst),

                           .wb_adr_i(wb_adr_o_w),
                           .wb_dat_i(wb_dat_o_w),
                           .wb_dat_o(misc_wb_dat_i_w),

                           .wb_cti_i(3'b000),
                           .wb_cyc_i(misc_wb_cyc_o_w),
                           .wb_stb_i(misc_wb_stb_o_w),
                           .wb_we_i(wb_we_o_w),
                           .wb_sel_i(wb_sel_o_w),
                           .wb_ack_o(misc_wb_ack_i_w),

                           .lcd(lcd_w),
                           .led(led_misc_io_w),
                           .reset_ctrl(reset_ctrl_misc_io_w),
                           .ps2_clk_i(PS2_CLK),
                           .ps2_data_i(PS2_DATA)
                           );

   wb_debug wb_debug_0(.clk(CLK_40_MHZ),
                       .rst(rst),

                       /* Wishbone interface */
                       .wb_clk_i(CLK_40_MHZ),
                       .wb_rst_i(rst),

                       .wb_ack_i(m_debug_wb_ack_i_w),
                       .wb_dat_o(m_debug_wb_dat_o_w),
                       .wb_dat_i(m_debug_wb_dat_i_w),
                       .wb_adr_o(m_debug_wb_adr_o_w),

                       .wb_cyc_o(m_debug_wb_cyc_o_w),
                       .wb_stb_o(m_debug_wb_stb_o_w),
                       .wb_sel_o(m_debug_wb_sel_o_w),
                       .wb_we_o(m_debug_wb_we_o_w),

                       .uart_rx(uart_rx_debug_w),
                       .uart_tx(uart_tx_debug_w)

                       );

   wb_eth_ctrl wb_eth_ctrl_0(
                             .wb_clk_i(CLK_40_MHZ),
                             .wb_rst_i(rst),

                             .m_wb_ack_i(m_eth_wb_ack_i_w),
                             .m_wb_dat_o(m_eth_wb_dat_o_w),
                             .m_wb_dat_i(m_eth_wb_dat_i_w),
                             .m_wb_adr_o(m_eth_wb_adr_o_w),

                             .m_wb_cyc_o(m_eth_wb_cyc_o_w),
                             .m_wb_stb_o(m_eth_wb_stb_o_w),
                             .m_wb_cti_o(m_eth_wb_cti_o_w),
                             .m_wb_sel_o(m_eth_wb_sel_o_w),
                             .m_wb_we_o(m_eth_wb_we_o_w),
/*
                             .s_wb_adr_i(wb_adr_o_w),
                             .s_wb_dat_i(wb_dat_o_w),
                             .s_wb_dat_o(vga_wb_dat_i_w),

                             .s_wb_cyc_i(vga_wb_cyc_o_w),
                             .s_wb_stb_i(vga_wb_stb_o_w),
                             .s_wb_we_i(wb_we_o_w),
                             .s_wb_sel_i(wb_sel_o_w),
                             .s_wb_ack_o(vga_wb_ack_i_w),
*/
                             .E_COL(E_COL),
                             .E_CRS(E_CRS),
                             .E_MDC(E_MDC),
                             .E_MDIO(E_MDIO),
                             .E_RX_CLK(E_RX_CLK),
                             .E_RX_DV(E_RX_DV),
                             .E_RXD(E_RXD),
                             .E_TX_CLK(E_TX_CLK),
                             .E_TX_EN(E_TX_EN),
                             .E_TXD(E_TXD)

                             );


endmodule
