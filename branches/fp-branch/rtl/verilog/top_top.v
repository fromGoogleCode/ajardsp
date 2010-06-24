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

/* UART bit times are calculated for a 50Mhz clk and a baud rate of 115200 bps */
`define UART_FULL_BIT_TIME 434
`define UART_HALF_BIT_TIME 217

module top_top(clk, rst, LED, RS232_DTE_RXD, RS232_DTE_TXD);

   input clk;
   input rst;
   input RS232_DTE_RXD;
   output RS232_DTE_TXD;

   output [7:0] LED;
   wire         rx_en;
   wire [7:0]   rx_byte;

   reg          tx_en;
   reg [7:0]    tx_byte;
   wire         tx_ready_w;

   reg [7:0]    state;

   reg [7:0]    read_state;

   reg          core_rst_r;
   reg          core_halt_r;
   wire         core_halt_w;

   reg [7:0]    imem_addr_r;
   reg [7:0]    imem_word_0_r;
   reg [7:0]    imem_word_1_r;
   reg [7:0]    imem_word_2_r;
   reg [7:0]    imem_word_3_r;
   reg [7:0]    imem_word_4_r;
   reg [7:0]    imem_word_5_r;
   reg [7:0]    imem_word_6_r;
   reg [7:0]    imem_word_7_r;
   wire [63:0]  imem_data_64_w;
   reg          imem_wen;

   reg [7:0]    dmem_addr_r;
   reg [7:0]    dmem_byte0_r;
   reg [7:0]    dmem_byte1_r;
   reg [7:0]    dmem_byte2_r;
   reg [7:0]    dmem_byte3_r;
   wire [31:0]  dmem_wr_data_32_w;
   wire [31:0]  dmem_rd_data_32_w;
   reg [31:0]   dmem_rd_data_32_r;

   reg          dmem_ren;
   reg          dmem_wen;

   parameter CMD_LOAD_IMEM = 8'hc0,
             CMD_LOAD_DMEM = 8'hc1,
             CMD_RESET     = 8'hc2,
             CMD_START     = 8'hc3,
             CMD_READ_DMEM = 8'hc4;

   parameter S_WRITE_IMEM_ADDR   = 0,
               S_WRITE_IMEM_DATA_0 = 1,
               S_WRITE_IMEM_DATA_1 = 2,
               S_WRITE_IMEM_DATA_2 = 3,
               S_WRITE_IMEM_DATA_3 = 4,
               S_WRITE_IMEM_DATA_4 = 5,
               S_WRITE_IMEM_DATA_5 = 6,
               S_WRITE_IMEM_DATA_6 = 7,
               S_WRITE_IMEM_DATA_7 = 8,

               S_WRITE_DMEM_ADDR   = 9,
               S_WRITE_DMEM_DATA_0 = 11,
               S_WRITE_DMEM_DATA_1 = 12,
               S_WRITE_DMEM_DATA_2 = 13,
               S_WRITE_DMEM_DATA_3 = 14,

               S_READ_DMEM_ADDR   = 15,
               S_READ_DMEM_DATA_0 = 16,
               S_READ_DMEM_DATA_1 = 17,
               S_READ_DMEM_DATA_2 = 18,
               S_READ_DMEM_DATA_3 = 19,

               S_IDLE = 20;

   assign LED = rst ? 8'haa : {6'h0, core_halt_r, core_rst_r};

   assign imem_data_64_w = {imem_word_0_r, imem_word_1_r, imem_word_2_r, imem_word_3_r,
                            imem_word_4_r, imem_word_5_r, imem_word_6_r, imem_word_7_r};

   assign dmem_wr_data_32_w = {dmem_byte2_r, dmem_byte3_r, dmem_byte0_r, dmem_byte1_r};

   uart_rx rx_0(.clk(clk),
                .rst(rst),
                .rx_ack(rx_en),
                .rx_data(rx_byte),
                .rx_bit(RS232_DTE_RXD)
                );

   uart_tx tx_0(.clk(clk),
                .rst(rst),
                .tx_data(tx_byte),
                .tx_req(tx_en),
                .tx_ready(tx_ready_w),
                .tx_bit(RS232_DTE_TXD)
                );

   ajardsp_top ajardsp_0(.clk(clk),
                         .rst_core(rst | core_rst_r | core_halt_r),
                         .rst_mem(rst),

                         .ext_imem_wr_addr_i(imem_addr_r),
                         .ext_imem_wr_data_i(imem_data_64_w),
                         .ext_imem_wr_en_i(imem_wen),

                         .ext_dmem_addr_i(dmem_addr_r),
                         .ext_dmem_wr_data_i(dmem_wr_data_32_w),
                         .ext_dmem_wr_en_i(dmem_wen),
                         .ext_dmem_rd_data_o(dmem_rd_data_32_w),
                         .ext_dmem_rd_en_i(dmem_ren),

                         .core_halt_o(core_halt_w)
                         );

   always @(posedge clk)
     begin
        if (rst || core_rst_r)
          begin
             core_halt_r <= 0;
          end
        else
          begin
             if (core_halt_w)
               begin
                  core_halt_r <= 1;
               end
          end
     end

   always @(posedge clk)
     begin

        dmem_wen = 0;
        imem_wen = 0;

        if (rst) begin
           state <= S_IDLE;
           dmem_addr_r <= 0;
           core_rst_r <= 1;
        end
        else if (rx_en) begin

           case (state)

             S_IDLE: begin
                case (rx_byte)
                  CMD_LOAD_IMEM: begin
                     state <= S_WRITE_IMEM_ADDR;
                  end
                  CMD_LOAD_DMEM: begin
                     state <= S_WRITE_DMEM_ADDR;
                  end
                  CMD_READ_DMEM: begin
                     state <= S_READ_DMEM_ADDR;
                  end
                  CMD_RESET: begin
                     core_rst_r <= 1;
                  end
                  CMD_START: begin
                     core_rst_r <= 0;
                  end
                endcase // case (rx_byte)
             end

             /* IMEM - load */

             S_WRITE_IMEM_ADDR: begin
                imem_addr_r <= rx_byte;
                state <= S_WRITE_IMEM_DATA_0;
             end

             S_WRITE_IMEM_DATA_0: begin
                imem_word_0_r <= rx_byte;
                state <= S_WRITE_IMEM_DATA_1;
             end

             S_WRITE_IMEM_DATA_1: begin
                imem_word_1_r <= rx_byte;
                state <= S_WRITE_IMEM_DATA_2;
             end

             S_WRITE_IMEM_DATA_2: begin
                imem_word_2_r <= rx_byte;
                state <= S_WRITE_IMEM_DATA_3;
             end

             S_WRITE_IMEM_DATA_3: begin
                imem_word_3_r <= rx_byte;
                state <= S_WRITE_IMEM_DATA_4;
             end

             S_WRITE_IMEM_DATA_4: begin
                imem_word_4_r <= rx_byte;
                state <= S_WRITE_IMEM_DATA_5;
             end

             S_WRITE_IMEM_DATA_5: begin
                imem_word_5_r <= rx_byte;
                state <= S_WRITE_IMEM_DATA_6;
             end

             S_WRITE_IMEM_DATA_6: begin
                imem_word_6_r <= rx_byte;
                state <= S_WRITE_IMEM_DATA_7;
             end

             S_WRITE_IMEM_DATA_7: begin
                imem_word_7_r <= rx_byte;
                state <= S_IDLE;
                imem_wen = 1;  /* Should really have a seperate state for this */
             end

             /* DMEM - load */

             S_WRITE_DMEM_ADDR: begin
                dmem_addr_r <= rx_byte;
                state <= S_WRITE_DMEM_DATA_0;
             end

             S_WRITE_DMEM_DATA_0: begin
                dmem_byte0_r <= rx_byte;
                state <= S_WRITE_DMEM_DATA_1;
             end

             S_WRITE_DMEM_DATA_1: begin
                dmem_byte1_r <= rx_byte;
                state <= S_WRITE_DMEM_DATA_2;
             end

             S_WRITE_DMEM_DATA_2: begin
                dmem_byte2_r <= rx_byte;
                state <= S_WRITE_DMEM_DATA_3;
             end

             S_WRITE_DMEM_DATA_3: begin
                dmem_byte3_r <= rx_byte;
                state <= S_IDLE;
                dmem_wen = 1;  /* Should really have a seperate state for this */
             end

             /* DMEM - read */

             S_READ_DMEM_ADDR: begin
                dmem_addr_r <= rx_byte;
                state <= S_IDLE;
             end

           endcase // case (state)
        end // if (rx_en)


     end // always @ (posedge clk)

   reg [3:0] dmem_read_state;
   reg [3:0] dmem_read_next_state;

   parameter dmem_read_wait  = 0,
             dmem_read_wait2 = 1,
             dmem_read_read  = 2,
             dmem_read_tx_0  = 3,
             dmem_read_tx_1  = 4,
             dmem_read_tx_2  = 5,
             dmem_read_tx_3  = 6;

   always @(posedge clk)
     begin
        if (rst)
          begin
             dmem_read_state <= dmem_read_wait;
             dmem_rd_data_32_r <= 0;
          end
        else
          begin
             dmem_read_state <= dmem_read_next_state;
             if (dmem_read_state == dmem_read_read)
               begin
                  dmem_rd_data_32_r <= dmem_rd_data_32_w;
               end
          end
     end // always @ (posedge clk)

   always @(dmem_read_state or state or dmem_rd_data_32_r or tx_ready_w)
     begin
        tx_en = 0;
        tx_byte = 0;
        dmem_ren = 0;
        dmem_read_next_state = dmem_read_state;

        case (dmem_read_state)
          dmem_read_wait: begin
             if (state == S_READ_DMEM_ADDR)
               begin
                  dmem_read_next_state = dmem_read_wait2;
               end
          end

          dmem_read_wait2: begin
             if (state == S_IDLE)
               begin
                  dmem_read_next_state = dmem_read_read;
                  dmem_ren = 1;
               end
          end

          dmem_read_read: begin
             dmem_read_next_state = dmem_read_tx_0;
          end

          dmem_read_tx_0: begin
             //tx_byte = dmem_rd_data_32_r[31:24];
             tx_byte = dmem_rd_data_32_r[15:8];
             tx_en = 1;
             if (tx_ready_w)
               begin
                  dmem_read_next_state = dmem_read_tx_1;
               end
          end

          dmem_read_tx_1: begin
             //tx_byte = dmem_rd_data_32_r[23:16];
             tx_byte = dmem_rd_data_32_r[7:0];
             tx_en = 1;
             if (tx_ready_w)
               begin
                  dmem_read_next_state = dmem_read_tx_2;
               end
          end

          dmem_read_tx_2: begin
             //tx_byte = dmem_rd_data_32_r[15:8];
             tx_byte = dmem_rd_data_32_r[31:24];
             tx_en = 1;
             if (tx_ready_w)
               begin
                  dmem_read_next_state = dmem_read_tx_3;
               end
          end

          dmem_read_tx_3: begin
             //tx_byte = dmem_rd_data_32_r[7:0];
             tx_byte = dmem_rd_data_32_r[23:16];
             tx_en = 1;
             if (tx_ready_w)
               begin
                  dmem_read_next_state = dmem_read_wait;
               end
          end

        endcase
     end // always @ ()

endmodule // top_top

module uart_rx(clk, rst, rx_data, rx_ack, rx_bit);

   input clk;
   input rst;
   output [7:0] rx_data;
   output       rx_ack;
   input        rx_bit;

   wire         rx_strobe;
   wire         rx_bit_negedge;

   reg [15:0]   clk_counter;

   reg [4:0]    rx_state;
   reg [4:0]    next_rx_state;
   reg [7:0]    rx_shiftreg;

   reg          rx_bit_l1;
   reg          rx_bit_l2;
   reg          rx_bit_l3;

   reg [2:0]    rx_bitcounter;

   parameter rx_state_idle     = 5'b00001,
             rx_state_startbit = 5'b00010,
             rx_state_databit  = 5'b00100,
             rx_state_stopbit  = 5'b01000,
             rx_state_recvd    = 5'b10000;


   assign    rx_strobe = (clk_counter == 0);
   assign    rx_bit_negedge = rx_bit_l3 & ~rx_bit_l2;

   assign    rx_data = rx_shiftreg;
   assign    rx_ack = (rx_state == rx_state_recvd);

   always @(posedge clk)
     begin
        rx_bit_l1 <= rx_bit;
     end

   always @(posedge clk)
     begin
        rx_bit_l2 <= rx_bit_l1;
     end

   always @(posedge clk)
     begin
        rx_bit_l3 <= rx_bit_l2;
     end



   always @(posedge clk)
     begin
        if (rst || rx_state == rx_state_idle)
          begin
             clk_counter <= `UART_HALF_BIT_TIME;
          end
        else if (rx_strobe && (rx_state == rx_state_startbit ||
                               rx_state == rx_state_databit))
          begin
             clk_counter <= `UART_FULL_BIT_TIME;
          end
        else
          begin
             clk_counter <= clk_counter - 1;
          end
     end

   always @(posedge clk)
     begin
        if (rx_strobe)
          begin
             if (rx_state == rx_state_databit)
               begin
                  rx_shiftreg[7:0] <= {rx_bit_l3, rx_shiftreg[7:1]};
               end
          end
     end

   always @(posedge clk)
     begin
        if (rst)
          begin
             rx_state <= rx_state_idle;
          end
        else
          begin
             rx_state <= next_rx_state;
          end
     end


   always @(posedge clk)
     begin
        if (rst)
          begin
             rx_bitcounter <= 0;
          end
        else if (rx_strobe && rx_state == rx_state_databit)
          begin
             rx_bitcounter <= rx_bitcounter + 1;
          end
     end


   always @(rx_state or rx_bit_negedge or rx_bitcounter
            or rx_bit_l3 or clk_counter or rx_strobe)
     begin

        case (rx_state)
          rx_state_idle: begin
             if (rx_bit_negedge)
               begin
                  next_rx_state = rx_state_startbit;
               end
             else
               begin
                  next_rx_state = rx_state_idle;
               end
          end

          rx_state_startbit: begin
             if (rx_strobe)
               begin
                  if (~rx_bit_l3)
                    begin
                       next_rx_state = rx_state_databit;
                    end
                  else
                    begin
                       /* False startbit, return to idle */
                       next_rx_state = rx_state_idle;
                    end
               end
             else
               begin
                  next_rx_state = rx_state_startbit;
               end
          end

          rx_state_databit: begin
             if (rx_strobe && rx_bitcounter == 7)
               begin
                  next_rx_state = rx_state_stopbit;
               end
             else
               begin
                  next_rx_state = rx_state_databit;
               end
          end

          rx_state_stopbit: begin
             if (rx_strobe)
               begin
                  if (rx_bit_l3)
                    begin
                       next_rx_state = rx_state_recvd;
                    end
                  else
                    begin
                       /* Framing error, this is not a valid stopbit */
                       next_rx_state = rx_state_idle;
                    end
               end
             else
               begin
                  next_rx_state = rx_state_stopbit;
               end
          end // case: rx_state_stopbit

          rx_state_recvd: begin
             next_rx_state = rx_state_idle;
          end

        endcase // case (rx_state)
     end // always @ (rx_state)

endmodule // uart_rx

module uart_tx(clk, rst, tx_data, tx_req, tx_ready, tx_bit);

   input clk;
   input rst;
   input [7:0] tx_data;
   input       tx_req;
   output      tx_ready;
   output      tx_bit;

   wire        tx_strobe;

   reg [15:0]  clk_counter;

   reg [3:0]   tx_state;  // synthesis attribute SIGNAL_ENCODING of tx_state is user
   reg [3:0]   next_tx_state;  // synthesis attribute SIGNAL_ENCODING of next_tx_state is user
   reg [7:0]   tx_shiftreg;

   reg         tx_bit;
   reg [2:0]   tx_counter;

   parameter tx_state_idle     = 4'b0001,
	       tx_state_startbit = 4'b0010,
	       tx_state_databit  = 4'b0100,
	       tx_state_stopbit  = 4'b1000;


   assign    tx_strobe = (clk_counter == `UART_FULL_BIT_TIME);
   assign    tx_ready = (tx_state == tx_state_idle);


   always @(posedge clk)
     begin
        if (rst | tx_strobe)
          begin
	     clk_counter <= 0;
          end
        else
          begin
	     clk_counter <= clk_counter + 1;
          end
     end

   always @(posedge clk)
     begin
        if (tx_req && tx_state == tx_state_idle)
          begin
	     tx_shiftreg <= tx_data;
          end
        else if (tx_strobe)
          begin
	     if (tx_state == tx_state_databit)
               begin
	          tx_shiftreg[7:0] <= {1'b0, tx_shiftreg[7:1]};
	       end
          end
     end

   always @(posedge clk)
     begin
        if (rst)
          begin
	     tx_state <= tx_state_idle;
          end
        else
          begin
	     tx_state <= next_tx_state;
          end
     end

   always @(posedge clk)
     begin
        if (tx_strobe | rst)
          begin
	     if (rst)
               begin
	          tx_bit <= 1'b1;
	       end
	     else
               begin
	          case (tx_state)
	            tx_state_startbit: begin
		       tx_bit <= 1'b0;
	            end

	            tx_state_databit: begin
		       tx_bit <= tx_shiftreg[0];
	            end

	            tx_state_stopbit: begin
		       tx_bit <= 1'b1;
	            end
	          endcase // case (tx_state)
	       end
          end // if (tx_strobe)

     end // always @ (posedge clk)

   always @(posedge clk)
     begin
        if (rst)
          begin
	     tx_counter <= 0;
          end
        else if (tx_strobe && tx_state == tx_state_databit)
          begin
	     tx_counter <= tx_counter + 1;
          end
     end


   always @(tx_state or tx_strobe or tx_req or tx_counter)
     begin

        case (tx_state)
	  tx_state_idle: begin
	     if (tx_req)
               begin
	          next_tx_state = tx_state_startbit;
	       end
	     else
               begin
	          next_tx_state = tx_state_idle;
	       end
	  end

	  tx_state_startbit: begin
	     if (tx_strobe)
               begin
	          next_tx_state = tx_state_databit;
	       end
	     else
               begin
	          next_tx_state = tx_state_startbit;
	       end
	  end

	  tx_state_databit: begin
	     if (tx_strobe)
               begin
	          if (tx_counter == 7)
                    begin
		       next_tx_state = tx_state_stopbit;
	            end
	          else
                    begin
		       next_tx_state = tx_state_databit;
	            end
	       end
	     else
               begin
	          next_tx_state = tx_state_databit;
	       end
	  end

	  tx_state_stopbit: begin
	     if (tx_strobe)
               begin
	          next_tx_state = tx_state_idle;
	       end
	     else
               begin
	          next_tx_state = tx_state_stopbit;
	       end
	  end

        endcase // case (tx_state)
     end // always @ (tx_state)

endmodule // uart_tx

