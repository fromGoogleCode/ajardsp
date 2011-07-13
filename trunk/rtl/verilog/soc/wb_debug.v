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

module wb_debug(
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

                uart_rx,
                uart_tx

                );

   input clk;
   input rst;

   input         wb_clk_i;
   input         wb_rst_i;
   input         wb_ack_i;
   input  [31:0] wb_dat_i;
   output [31:0] wb_dat_o;
   output [31:0] wb_adr_o;
   output reg    wb_cyc_o;
   output [3:0]  wb_sel_o;
   output reg    wb_stb_o;
   output reg    wb_we_o;

   input         uart_rx;
   output        uart_tx;

   /* Begin - Old UART loader */

   wire         rx_en;
   wire [7:0]   rx_byte;

   reg          tx_en;
   reg [7:0]    tx_byte;
   wire         tx_ready_w;

   reg [7:0]    state;

   reg [7:0]    addr_0_r,
                addr_1_r,
                addr_2_r,
                addr_3_r;

   reg [7:0]    byte0_r,
                byte1_r,
                byte2_r,
                byte3_r;

   reg [31:0]   rd_data_32_r;


   parameter CMD_WRITE = 8'hc1,
             CMD_READ  = 8'hc2;

   parameter   S_WRITE_ADDR_0 = 0,
               S_WRITE_ADDR_1 = 1,
               S_WRITE_ADDR_2 = 2,
               S_WRITE_ADDR_3 = 3,
               S_WRITE_DATA_0 = 4,
               S_WRITE_DATA_1 = 5,
               S_WRITE_DATA_2 = 6,
               S_WRITE_DATA_3 = 7,

               S_READ_ADDR_0 = 8,
               S_READ_ADDR_1 = 9,
               S_READ_ADDR_2 = 10,
               S_READ_ADDR_3 = 11,

               S_IDLE = 16;

   assign wb_dat_o = {byte3_r, byte2_r, byte1_r, byte0_r};
   assign wb_sel_o = 4'b1111;
   assign wb_adr_o = {addr_3_r, addr_2_r, addr_1_r, addr_0_r};

`ifdef SIMULATION_UART
   /* B921600 */
   defparam
     rx_0.UART_FULL_BIT_TIME = 43,
     rx_0.UART_HALF_BIT_TIME = 22;

`else
   /* B115200 */
   defparam
     rx_0.UART_FULL_BIT_TIME = 347,
     rx_0.UART_HALF_BIT_TIME = 174;
`endif

   uart_rx rx_0(.clk(clk),
                .rst(rst),
                .rx_ack(rx_en),
                .rx_data(rx_byte),
                .rx_bit(uart_rx)
                );


`ifdef SIMULATION_UART
   /* B921600 */
   defparam
     tx_0.UART_FULL_BIT_TIME = 43,
     tx_0.UART_HALF_BIT_TIME = 22;

`else
   /* B115200 */
   defparam
     tx_0.UART_FULL_BIT_TIME = 347,
     tx_0.UART_HALF_BIT_TIME = 174;
`endif

   uart_tx tx_0(.clk(clk),
                .rst(rst),
                .tx_data(tx_byte),
                .tx_req(tx_en),
                .tx_ready(tx_ready_w),
                .tx_bit(uart_tx)
                );

   reg [3:0]    wb_state_r;

   parameter WB_IDLE    = 0,
             WB_WRITE_0 = 1,
             WB_WRITE_1 = 2,
             WB_WRITE_2 = 3,
             WB_READ_0  = 4,
             WB_READ_1  = 5,
             WB_READ_2  = 6;

   always @(posedge wb_clk_i)
     begin
        if (wb_rst_i)
          begin
             wb_cyc_o <= 0;
             wb_stb_o <= 0;
             wb_we_o  <= 0;

             wb_state_r <= WB_IDLE;
          end
        else
          begin
             case (wb_state_r)
               WB_IDLE: begin
                  if (state == S_WRITE_DATA_3)
                    wb_state_r <= WB_WRITE_0;
                  if (state == S_READ_ADDR_3)
                    wb_state_r <= WB_READ_0;
               end

               WB_WRITE_0: begin
                  if (state == S_IDLE)
                    wb_state_r <= WB_WRITE_1;
               end

               WB_WRITE_1: begin
                  wb_cyc_o <= 1;
                  wb_stb_o <= 1;
                  wb_we_o  <= 1;

                  if (wb_ack_i)
                    wb_state_r <= WB_WRITE_2;
               end

               WB_WRITE_2: begin
                  wb_cyc_o <= 0;
                  wb_stb_o <= 0;
                  wb_we_o  <= 0;

                  $display("wb_debug: WRITE: %h = %h", wb_adr_o, wb_dat_o);

                  wb_state_r <= WB_IDLE;
               end

               WB_READ_0: begin
                  if (state == S_IDLE)
                    wb_state_r <= WB_READ_1;
               end

               WB_READ_1: begin
                  wb_cyc_o <= 1;
                  wb_stb_o <= 1;

                  if (wb_ack_i)
                    begin
                       wb_state_r <= WB_READ_2;
                    end
               end

               WB_READ_2: begin
                  rd_data_32_r <= wb_dat_i;

                  wb_cyc_o <= 0;
                  wb_stb_o <= 0;

                  wb_state_r <= WB_IDLE;
               end

             endcase
          end
     end

   always @(posedge clk)
     begin
        if (rst) begin
           state <= S_IDLE;
           addr_0_r <= 0;
           addr_1_r <= 0;
        end
        else if (rx_en) begin

           case (state)

             S_IDLE: begin
                case (rx_byte)
                  CMD_WRITE: begin
                     state <= S_WRITE_ADDR_0;
                  end
                  CMD_READ: begin
                     state <= S_READ_ADDR_0;
                  end
                endcase // case (rx_byte)
             end

             /* Write */

             S_WRITE_ADDR_0: begin
                addr_0_r <= rx_byte;
                state <= S_WRITE_ADDR_1;
             end

             S_WRITE_ADDR_1: begin
                addr_1_r <= rx_byte;
                state <= S_WRITE_ADDR_2;
             end

             S_WRITE_ADDR_2: begin
                addr_2_r <= rx_byte;
                state <= S_WRITE_ADDR_3;
             end

             S_WRITE_ADDR_3: begin
                addr_3_r <= rx_byte;
                state <= S_WRITE_DATA_0;
             end

             S_WRITE_DATA_0: begin
                byte0_r <= rx_byte;
                state <= S_WRITE_DATA_1;
             end

             S_WRITE_DATA_1: begin
                byte1_r <= rx_byte;
                state <= S_WRITE_DATA_2;
             end

             S_WRITE_DATA_2: begin
                byte2_r <= rx_byte;
                state <= S_WRITE_DATA_3;
             end

             S_WRITE_DATA_3: begin
                byte3_r <= rx_byte;
                state <= S_IDLE;
             end

             /* Read */
             S_READ_ADDR_0: begin
                addr_0_r <= rx_byte;
                state <= S_READ_ADDR_1;
             end

             S_READ_ADDR_1: begin
                addr_1_r <= rx_byte;
                state <= S_READ_ADDR_2;
             end

             S_READ_ADDR_2: begin
                addr_2_r <= rx_byte;
                state <= S_READ_ADDR_3;
             end

             S_READ_ADDR_3: begin
                addr_3_r <= rx_byte;
                state <= S_IDLE;
             end

           endcase // case (state)
        end // if (rx_en)

     end // always @ (posedge clk)

   reg [3:0] tx_state, next_tx_state;

   parameter TX_IDLE = 0,
             TX_WAIT = 1,
             TX_0    = 2,
             TX_1    = 3,
             TX_2    = 4,
             TX_3    = 5;

   always @(posedge clk)
     begin
        if (rst)
          begin
             tx_state <= TX_IDLE;
          end
        else
          begin
             tx_state <= next_tx_state;
          end
     end

   always @(tx_state or wb_state_r or tx_ready_w or rd_data_32_r)
     begin
        tx_en = 0;
        tx_byte = 0;
        next_tx_state = tx_state;

        case (tx_state)

          TX_IDLE: begin
             if (wb_state_r == WB_READ_2)
               next_tx_state = TX_WAIT;
          end

          TX_WAIT: begin
             if (wb_state_r == WB_IDLE)
               next_tx_state = TX_0;
          end

          TX_0: begin
             tx_byte = rd_data_32_r[7:0];
             tx_en   = 1;
             if (tx_ready_w)
               begin
                  next_tx_state = TX_1;
               end
          end

          TX_1: begin
             tx_byte = rd_data_32_r[15:8];
             tx_en   = 1;
             if (tx_ready_w)
               begin
                  next_tx_state = TX_2;
               end
          end

          TX_2: begin
             tx_byte = rd_data_32_r[23:16];
             tx_en   = 1;
             if (tx_ready_w)
               begin
                  next_tx_state = TX_3;
               end
          end

          TX_3: begin
             tx_byte = rd_data_32_r[31:24];
             tx_en   = 1;
             if (tx_ready_w)
               begin
                  next_tx_state = TX_IDLE;
               end
          end
        endcase

     end

endmodule
