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

module wb_eth_ctrl(
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

                   /* Ethernet-PHY interface */
                   E_COL,
                   E_CRS,
                   E_MDC,
                   E_MDIO,
                   E_RX_CLK,
                   E_RX_DV,
                   E_RXD,
                   E_TX_CLK,
                   E_TX_EN,
                   E_TXD

                   );

   input         wb_clk_i;
   input         wb_rst_i;
   input         m_wb_ack_i;
   input [31:0]  m_wb_dat_i;
   output reg [31:0] m_wb_dat_o;
   output [31:0]     m_wb_adr_o;
   output reg        m_wb_cyc_o;
   output [2:0]   m_wb_cti_o;
   output [3:0]   m_wb_sel_o;
   output reg     m_wb_stb_o;
   output         m_wb_we_o;

   output        s_wb_ack_o;
   input [31:0]  s_wb_adr_i;
   input [31:0]  s_wb_dat_i;
   output reg [31:0] s_wb_dat_o;
   input [3:0]   s_wb_sel_i;
   input         s_wb_cyc_i;
   input         s_wb_stb_i;
   input         s_wb_we_i;

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

   reg [7:0]     m_state_r;

   reg           fifo_ren;
   wire          fifo_rempty;
   wire [35:0]   fifo_rdata;


   /* Wisbone accessible control registers - begin */
   reg [31:0]    r_eth_rx_rb_ctrl;
   reg [31:0]    r_eth_rx_rb_status;
   reg [31:0]    r_eth_rx_rb_start;
   reg [31:0]    r_eth_rx_rb_end;
   reg [31:0]    r_eth_rx_rb_rp;
   reg [31:0]    r_eth_rx_rb_wp;
   /* Wisbone accessible control registers - end */

   parameter m_s_idle        = (1 << 0),
             m_s_begin_burst = (1 << 1);

   assign m_wb_adr_o = r_eth_rx_rb_wp;
   assign m_wb_cti_o = 3'b010;
   assign m_wb_we_o  = 1;
   assign m_wb_sel_o = 4'b1111;

   assign rst = wb_rst_i;

   assign s_wb_ack_o = s_wb_stb_i;

   always @(posedge wb_clk_i)
     begin
        if (wb_rst_i)
          begin
             r_eth_rx_rb_ctrl   <= 0;
             r_eth_rx_rb_status <= 0;
             r_eth_rx_rb_start  <= 0;
             r_eth_rx_rb_end    <= 0;
             r_eth_rx_rb_rp     <= 0;
          end
        else if (s_wb_stb_i & s_wb_we_i)
          begin
             case (s_wb_adr_i[3:0])
               4'h0: begin
                  r_eth_rx_rb_ctrl  <= s_wb_dat_i;
               end
               4'h4: begin
                  r_eth_rx_rb_start <= s_wb_dat_i;
               end
               4'h8: begin
                  r_eth_rx_rb_end   <= s_wb_dat_i;
               end
               4'hc: begin
                  r_eth_rx_rb_rp    <= s_wb_dat_i;
               end
             endcase
          end
     end

   always @(s_wb_adr_i /* or r_eth_rx_... */)
     begin
        case (s_wb_adr_i[3:0])
          4'h0: begin
             s_wb_dat_o = r_eth_rx_rb_ctrl;
          end
          4'h4: begin
             s_wb_dat_o = r_eth_rx_rb_start;
          end
          4'h8: begin
             s_wb_dat_o = r_eth_rx_rb_end;
          end
          4'hc: begin
             s_wb_dat_o = r_eth_rx_rb_rp;
          end
        endcase
     end

   always @(posedge wb_clk_i)
     begin
        if (wb_rst_i)
          begin
             m_wb_cyc_o <= 0;
             m_wb_stb_o <= 0;
             fifo_ren <= 0;

             r_eth_rx_rb_wp <= 0;

             m_state_r <= m_s_idle;
          end
        else
          begin

             fifo_ren <= 0;

             case (m_state_r)
               m_s_idle: begin
                  if (~fifo_rempty)
                    begin
                       fifo_ren <= 1;
                       m_wb_dat_o <= fifo_rdata[31:0];
                       m_wb_cyc_o <= 1;
                       m_wb_stb_o <= 1;

                       m_state_r  <= m_s_begin_burst;
                    end
               end
               m_s_begin_burst: begin
                  if (m_wb_ack_i)
                    begin
                       r_eth_rx_rb_wp <= r_eth_rx_rb_wp + 4;
                       if (~fifo_rempty)
                         begin
                            fifo_ren <= 1;
                            m_wb_dat_o <= fifo_rdata[31:0];
                            m_wb_cyc_o <= 1;
                            m_wb_stb_o <= 1;
                         end
                       else
                         begin
                            m_wb_cyc_o <= 0;
                            m_wb_stb_o <= 0;

                            m_state_r <= m_s_idle;
                         end
                    end
               end

             endcase
          end
     end

   eth_mac_rx eth_rx(.rst(rst),
                     /* ETH-PHY IF */
                     .E_COL(E_COL),
                     .E_CRS(E_CRS),
                     .E_MDC(E_MDC),
                     .E_MDIO(E_MDIO),
                     .E_RX_CLK(E_RX_CLK),
                     .E_RX_DV(E_RX_DV),
                     .E_RXD(E_RXD),
                     .E_TX_CLK(E_TX_CLK),
                     .E_TX_EN(E_TX_EN),
                     .E_TXD(E_TXD),
                     /* FIFO IF */
                     .fifo_rclk(wb_clk_i),
                     .fifo_rdata(fifo_rdata),
                     .fifo_ren(fifo_ren),
                     .fifo_rempty(fifo_rempty)
                     );

endmodule


module eth_mac_rx(rst,
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
                  /* FIFO IF */
                  fifo_rclk,
                  fifo_rdata,
                  fifo_ren,
                  fifo_rempty
                  );


   input        rst;

   /* ETH-PHY IF */
   input E_COL,
         E_CRS;

   output E_MDC;
   inout  E_MDIO;

   input        E_RX_CLK,
                E_RX_DV;

   input [4:0]  E_RXD;
   input        E_TX_CLK;
   output       E_TX_EN;
   output [4:0] E_TXD;

   /* FIFO IF */
   input         fifo_rclk, fifo_ren;
   output        fifo_rempty;
   output [35:0] fifo_rdata;


   wire [7:0]       rx_byte;

   wire             rx_clk,
                    rx_rst,
                    rx_val;

   wire [3:0]       rx_dat;

   assign RS232_DTE_TXD = 0;

`include "CRC32_D4.v"

   assign rx_rst = rst;

   assign rx_clk = E_RX_CLK;
   assign rx_val = E_RX_DV;

   assign rx_dat = E_RXD[3:0];

   assign E_MDC   = 0;
   assign E_MDIO  = 1'bz;
   assign E_TX_EN = 0;
   assign E_TXD   = 0;

   reg rx_val_prev;
   reg addr_match;

   reg [35:0] rx_fifo_wr_data;
   reg        rx_fifo_wr_en;

   reg [3:0] rx_state_r;

   reg [3:0] eth_dst_adr_nib [0:11];
   reg [3:0] eth_rx_32b_nib  [0:7];

   reg [3:0]  nib_cnt;

   reg [31:0] crc32_r;

   reg [3:0]  eth_rx_nibs [0:7];


   wire [47:0] eth_dst_adr;
   wire [31:0] eth_rx_32b;

   integer     i;

   parameter ETH_STATION_ADDRESS = 48'he528c8750423;

   parameter s_rx_wait_sfd  = 0,
             s_rx_dst_adr   = 1,
             s_rx_chk_adr   = 2,
             s_rx_rec_dat_0 = 3,
             s_rx_rec_dat_1 = 4,
             s_rx_ignore    = 5;

   assign       eth_dst_adr = {eth_dst_adr_nib[11], eth_dst_adr_nib[10],
                               eth_dst_adr_nib[9], eth_dst_adr_nib[8],
                               eth_dst_adr_nib[7], eth_dst_adr_nib[6],
                               eth_dst_adr_nib[5], eth_dst_adr_nib[4],
                               eth_dst_adr_nib[3], eth_dst_adr_nib[2],
                               eth_dst_adr_nib[1], eth_dst_adr_nib[0]};

   assign       eth_rx_32b = {eth_rx_32b_nib[7], eth_rx_32b_nib[6],
                              eth_rx_32b_nib[5], eth_rx_32b_nib[4],
                              eth_rx_32b_nib[3], eth_rx_32b_nib[2],
                              eth_rx_32b_nib[1], eth_rx_32b_nib[0]};

   always @(posedge rx_clk)
     begin

        rx_fifo_wr_en   <= 0;

        if (rx_rst)
          begin

             for (i = 0; i < 12; i = i + 1)
               begin
                  eth_dst_adr_nib[i] <= 0;
               end

             nib_cnt <= 0;
             rx_state_r <= s_rx_wait_sfd;
             rx_val_prev <= 0;
             addr_match  <= 0;

          end
        else
          begin
             rx_val_prev <= rx_val;

             if (~rx_val)
               begin
                  rx_state_r <= s_rx_wait_sfd;

                  if (rx_val_prev & addr_match)
                    begin

                       if (nib_cnt[2:0] != 0)
                         begin
                            rx_fifo_wr_data <= {4'h0, eth_rx_32b};
                            rx_fifo_wr_en   <= 1;
                         end

                       if (crc32_r == {eth_rx_nibs[0], eth_rx_nibs[1],
                                       eth_rx_nibs[2], eth_rx_nibs[3],
                                       eth_rx_nibs[4], eth_rx_nibs[5],
                                       eth_rx_nibs[6], eth_rx_nibs[7]})
                         begin

                         end
                    end
               end
             else
               begin

                  eth_rx_nibs[0] <= rx_dat;

                  for (i = 0; i < 7; i = i + 1)
                    eth_rx_nibs[i+1] <= eth_rx_nibs[i];

                  crc32_r <= nextCRC32_D4(eth_rx_nibs[7], crc32_r);

                  eth_rx_32b_nib[nib_cnt[2:0]] <= rx_dat;
                  nib_cnt <= nib_cnt + 1;

                  case (rx_state_r)

                    /* Wait for last nibble of SFD */
                    s_rx_wait_sfd: begin
                       if (rx_dat == 4'b1101)
                         begin
                            nib_cnt <= 0;
                            crc32_r <= 0;

                            for (i = 0; i < 8; i = i + 1)
                              eth_rx_nibs[i] <= 0;

                            rx_state_r <= s_rx_dst_adr;
                         end
                    end

                    /* Destination address (6 octets) */
                    s_rx_dst_adr: begin
                       eth_dst_adr_nib[nib_cnt] <= rx_dat;
                       if (nib_cnt == 11)
                         begin
                            rx_state_r <= s_rx_chk_adr;
                         end
                    end

                    s_rx_chk_adr: begin
                       /**/
                       if (eth_dst_adr == ETH_STATION_ADDRESS)
                         begin
                            addr_match <= 1;
                            rx_state_r <= s_rx_rec_dat_0;
                         end
                       else
                         begin
                            addr_match <= 0;
                            rx_state_r <= s_rx_ignore;
                         end
                    end

                    s_rx_rec_dat_0: begin
                       rx_fifo_wr_data <= {4'h1, eth_dst_adr[31:0]};
                       rx_fifo_wr_en   <= 1;
                       rx_state_r      <= s_rx_rec_dat_1;
                    end

                    s_rx_rec_dat_1: begin
                       if (nib_cnt[2:0] == 0)
                         begin
                            rx_fifo_wr_data <= {4'h0, eth_rx_32b};
                            rx_fifo_wr_en   <= 1;
                         end
                    end

                    s_rx_ignore: begin
                       /* Ignore rest of frame */
                    end

                  endcase
               end
          end
     end

   async_fifo afifo(.rst(rx_rst),

                    .wclk(rx_clk),
                    .wdata(rx_fifo_wr_data),
                    .wen(rx_fifo_wr_en),
                    .wfull(),

                    .rclk(fifo_rclk),
                    .rdata(fifo_rdata),
                    .ren(fifo_ren),
                    .rempty(fifo_rempty)
                    );

endmodule
