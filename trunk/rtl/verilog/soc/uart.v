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

// For 50mhz
// `define UART_FULL_BIT_TIME 434
// `define UART_HALF_BIT_TIME 217

// For 40mhz
//`define UART_FULL_BIT_TIME 347
//`define UART_HALF_BIT_TIME 174

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

   // For 50mhz
   parameter UART_FULL_BIT_TIME = 434,
             UART_HALF_BIT_TIME = 217;

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
             clk_counter <= UART_HALF_BIT_TIME;
          end
        else if (rx_strobe && (rx_state == rx_state_startbit ||
                               rx_state == rx_state_databit))
          begin
             clk_counter <= UART_FULL_BIT_TIME;
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

   // For 50mhz
   parameter UART_FULL_BIT_TIME = 434,
             UART_HALF_BIT_TIME = 217;

   parameter tx_state_idle     = 4'b0001,
	       tx_state_startbit = 4'b0010,
	       tx_state_databit  = 4'b0100,
	       tx_state_stopbit  = 4'b1000;


   assign    tx_strobe = (clk_counter == UART_FULL_BIT_TIME);
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
