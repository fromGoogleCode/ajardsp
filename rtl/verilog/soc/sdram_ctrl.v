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

/* MT46V32M16 */

module iob_dqs(clk, rst, oen, ddr_dqs_io, ddr_clk_p, ddr_clk_n);
   input clk, rst, oen;
   input ddr_clk_p, ddr_clk_n;
   inout ddr_dqs_io;
   reg   oen_r;
   wire  d;

   // synthesis attribute IOB of oen_r "TRUE"
   // synthesis attribute IOB of oddr2_0 "TRUE"

   always @(posedge clk)
     begin
        if (rst)
          oen_r <= 1;
        else
          oen_r <= oen;
     end

   assign ddr_dqs_io  = oen_r ? 1'bz : d;

   ODDR2 oddr2_0(.Q(d), .C0(ddr_clk_p), .C1(ddr_clk_n), .CE(1'b1),
                 .D0(1'b1), .D1(1'b0), .R(rst), .S(1'b0));


endmodule

module iob_dq(clk_p, clk_n, rst, oen, din0, din1, dout0, dout1, ddr_dq_io,
              iclk_p, iclk_n);
   input clk_p, clk_n, rst, oen, din0, din1, iclk_p, iclk_n;
   output dout0, dout1;
   inout  ddr_dq_io;
   reg   oen_r;
   wire  d;

   // synthesis attribute IOB of oen_r "TRUE"
   // synthesis attribute IOB of iddr2_0 "TRUE"
   // synthesis attribute IOB of oddr2_0 "TRUE"

   always @(posedge clk_p)
     begin
        if (rst)
          oen_r <= 1;
        else
          oen_r <= oen;
     end

   assign ddr_dq_io  = oen_r ? 1'bz : d;

   IDDR2 iddr2_0(.D(ddr_dq_io), .C0(iclk_p), .C1(iclk_n), .CE(1'b1),
                  .Q0(dout0), .Q1(dout1), .R(rst), .S(1'b0));

   ODDR2 oddr2_0(.Q(d), .C0(clk_p), .C1(clk_n), .CE(1'b1),
                 .D0(din0), .D1(din1), .R(rst), .S(1'b0));

endmodule

module sdram_ctrl(clk,
                  rst,
                  clk_n,
                  user_read_req,
                  user_read_ack,
                  user_read_data,
                  user_write_req,
                  user_write_ack,
                  user_write_data,
                  user_write_mask,
                  user_addr,

                  ddr_clk,
                  ddr_clk_n,
                  ddr_cke,
                  ddr_cmd,
                  ddr_data,
                  ddr_dm,
                  ddr_dqs,
                  ddr_addr,
                  ddr_ba
                  );

   input clk, clk_n, rst;

   output [31:0] user_read_data;
   output reg   user_read_ack, user_write_ack;
   input [31:0] user_write_data;
   input [3:0]  user_write_mask;
   input [31:0] user_addr;
   input        user_read_req, user_write_req;

   input        ddr_clk, ddr_clk_n;
   output reg   ddr_cke;
   output reg [2:0]  ddr_cmd;
   inout [15:0]      ddr_data;
   output [1:0]      ddr_dm;
   inout [1:0]       ddr_dqs;
   output reg [12:0] ddr_addr;
   output reg [1:0]  ddr_ba;

   reg [2:0]         ddr_cmd_;
   reg [12:0]        ddr_addr_;
   reg [1:0]         ddr_ba_;

   wire              clk_p, ddr_clk_p;

   wire [15:0] ddr_data_;

   wire [31:0] read_data;
   reg  [31:0] read_data_r, read_data_n_r;
   reg [31:0] ddr_write_data;
   reg [31:0] ddr_write_data_;

   reg        ddr_data_oe;
   reg        ddr_data_oe_;
   reg [3:0]  ddr_write_mask;
   reg [3:0]  ddr_write_mask_;

   reg [31:0]  counter;
   reg [31:0]  burst_addr;

   reg         clk_edge_odd;

   assign clk_p = clk;
   assign ddr_clk_p = ddr_clk;

   always @(posedge clk)
     begin
        if (rst)
          clk_edge_odd <= 0;
        else
          clk_edge_odd <= ~clk_edge_odd;
     end

   always @(posedge clk)
     begin
        if (rst)
          counter <= 0;
        else
          counter <= counter + 1;
     end

   iob_dqs iob_dqs_0(.clk(clk), .rst(rst), .oen(~ddr_data_oe_),
                     .ddr_dqs_io(ddr_dqs[0]),
                     .ddr_clk_p(ddr_clk_p), .ddr_clk_n(ddr_clk_n));
   iob_dqs iob_dqs_1(.clk(clk), .rst(rst), .oen(~ddr_data_oe_),
                     .ddr_dqs_io(ddr_dqs[1]),
                     .ddr_clk_p(ddr_clk_p), .ddr_clk_n(ddr_clk_n));

   assign user_read_data = read_data_r;

   always @(posedge clk)
     begin
        if (rst)
          begin
             read_data_r <= 0;
             ddr_cmd <= 0;
             ddr_addr <= 0;
             ddr_ba <= 0;
             ddr_data_oe <= 0;
             ddr_write_data <= 0;
             ddr_write_mask <= 0;
          end
        else
          begin
             read_data_r <= read_data_n_r;
             ddr_cmd <= ddr_cmd_;
             ddr_addr <= ddr_addr_;
             ddr_ba <= ddr_ba_;
             ddr_data_oe <= ddr_data_oe_;
             ddr_write_data <= ddr_write_data_;
             ddr_write_mask <= ddr_write_mask_;
          end
     end

   always @(posedge clk_n)
     begin
        if (rst)
          begin
             read_data_n_r <= 0;
          end
        else
          begin
             read_data_n_r <= read_data;
          end
     end



   iob_dq iob_dq_0(.clk_p(clk_p), .clk_n(clk_n), .rst(rst), .oen(~ddr_data_oe_),
                   .din0(ddr_write_data[0]), .din1(ddr_write_data[16]),
                   .dout0(read_data[0]), .dout1(read_data[16]),
                   .ddr_dq_io(ddr_data[0]),
                   .iclk_p(ddr_dqs[0]), .iclk_n(~ddr_dqs[0]));

   iob_dq iob_dq_1(.clk_p(clk_p), .clk_n(clk_n), .rst(rst), .oen(~ddr_data_oe_),
                   .din0(ddr_write_data[1]), .din1(ddr_write_data[17]),
                   .dout0(read_data[1]), .dout1(read_data[17]),
                   .ddr_dq_io(ddr_data[1]),
                   .iclk_p(ddr_dqs[0]), .iclk_n(~ddr_dqs[0]));

   iob_dq iob_dq_2(.clk_p(clk_p), .clk_n(clk_n), .rst(rst), .oen(~ddr_data_oe_),
                   .din0(ddr_write_data[2]), .din1(ddr_write_data[18]),
                   .dout0(read_data[2]), .dout1(read_data[18]),
                   .ddr_dq_io(ddr_data[2]),
                   .iclk_p(ddr_dqs[0]), .iclk_n(~ddr_dqs[0]));

   iob_dq iob_dq_3(.clk_p(clk_p), .clk_n(clk_n), .rst(rst), .oen(~ddr_data_oe_),
                   .din0(ddr_write_data[3]), .din1(ddr_write_data[19]),
                   .dout0(read_data[3]), .dout1(read_data[19]),
                   .ddr_dq_io(ddr_data[3]),
                   .iclk_p(ddr_dqs[0]), .iclk_n(~ddr_dqs[0]));


   iob_dq iob_dq_4(.clk_p(clk_p), .clk_n(clk_n), .rst(rst), .oen(~ddr_data_oe_),
                   .din0(ddr_write_data[4]), .din1(ddr_write_data[20]),
                   .dout0(read_data[4]), .dout1(read_data[20]),
                   .ddr_dq_io(ddr_data[4]),
                   .iclk_p(ddr_dqs[0]), .iclk_n(~ddr_dqs[0]));

   iob_dq iob_dq_5(.clk_p(clk_p), .clk_n(clk_n), .rst(rst), .oen(~ddr_data_oe_),
                   .din0(ddr_write_data[5]), .din1(ddr_write_data[21]),
                   .dout0(read_data[5]), .dout1(read_data[21]),
                   .ddr_dq_io(ddr_data[5]),
                   .iclk_p(ddr_dqs[0]), .iclk_n(~ddr_dqs[0]));

   iob_dq iob_dq_6(.clk_p(clk_p), .clk_n(clk_n), .rst(rst), .oen(~ddr_data_oe_),
                   .din0(ddr_write_data[6]), .din1(ddr_write_data[22]),
                   .dout0(read_data[6]), .dout1(read_data[22]),
                   .ddr_dq_io(ddr_data[6]),
                   .iclk_p(ddr_dqs[0]), .iclk_n(~ddr_dqs[0]));

   iob_dq iob_dq_7(.clk_p(clk_p), .clk_n(clk_n), .rst(rst), .oen(~ddr_data_oe_),
                   .din0(ddr_write_data[7]), .din1(ddr_write_data[23]),
                   .dout0(read_data[7]), .dout1(read_data[23]),
                   .ddr_dq_io(ddr_data[7]),
                   .iclk_p(ddr_dqs[0]), .iclk_n(~ddr_dqs[0]));


   iob_dq iob_dq_8(.clk_p(clk_p), .clk_n(clk_n), .rst(rst), .oen(~ddr_data_oe_),
                   .din0(ddr_write_data[8]), .din1(ddr_write_data[24]),
                   .dout0(read_data[8]), .dout1(read_data[24]),
                   .ddr_dq_io(ddr_data[8]),
                   .iclk_p(ddr_dqs[1]), .iclk_n(~ddr_dqs[1]));

   iob_dq iob_dq_9(.clk_p(clk_p), .clk_n(clk_n), .rst(rst), .oen(~ddr_data_oe_),
                   .din0(ddr_write_data[9]), .din1(ddr_write_data[25]),
                   .dout0(read_data[9]), .dout1(read_data[25]),
                   .ddr_dq_io(ddr_data[9]),
                   .iclk_p(ddr_dqs[1]), .iclk_n(~ddr_dqs[1]));

   iob_dq iob_dq_10(.clk_p(clk_p), .clk_n(clk_n), .rst(rst), .oen(~ddr_data_oe_),
                    .din0(ddr_write_data[10]), .din1(ddr_write_data[26]),
                    .dout0(read_data[10]), .dout1(read_data[26]),
                    .ddr_dq_io(ddr_data[10]),
                    .iclk_p(ddr_dqs[1]), .iclk_n(~ddr_dqs[1]));

   iob_dq iob_dq_11(.clk_p(clk_p), .clk_n(clk_n), .rst(rst), .oen(~ddr_data_oe_),
                    .din0(ddr_write_data[11]), .din1(ddr_write_data[27]),
                    .dout0(read_data[11]), .dout1(read_data[27]),
                    .ddr_dq_io(ddr_data[11]),
                    .iclk_p(ddr_dqs[1]), .iclk_n(~ddr_dqs[1]));


   iob_dq iob_dq_12(.clk_p(clk_p), .clk_n(clk_n), .rst(rst), .oen(~ddr_data_oe_),
                    .din0(ddr_write_data[12]), .din1(ddr_write_data[28]),
                    .dout0(read_data[12]), .dout1(read_data[28]),
                    .ddr_dq_io(ddr_data[12]),
                    .iclk_p(ddr_dqs[1]), .iclk_n(~ddr_dqs[1]));

   iob_dq iob_dq_13(.clk_p(clk_p), .clk_n(clk_n), .rst(rst), .oen(~ddr_data_oe_),
                    .din0(ddr_write_data[13]), .din1(ddr_write_data[29]),
                    .dout0(read_data[13]), .dout1(read_data[29]),
                    .ddr_dq_io(ddr_data[13]),
                    .iclk_p(ddr_dqs[1]), .iclk_n(~ddr_dqs[1]));

   iob_dq iob_dq_14(.clk_p(clk_p), .clk_n(clk_n), .rst(rst), .oen(~ddr_data_oe_),
                    .din0(ddr_write_data[14]), .din1(ddr_write_data[30]),
                    .dout0(read_data[14]), .dout1(read_data[30]),
                    .ddr_dq_io(ddr_data[14]),
                    .iclk_p(ddr_dqs[1]), .iclk_n(~ddr_dqs[1]));

   iob_dq iob_dq_15(.clk_p(clk_p), .clk_n(clk_n), .rst(rst), .oen(~ddr_data_oe_),
                    .din0(ddr_write_data[15]), .din1(ddr_write_data[31]),
                    .dout0(read_data[15]), .dout1(read_data[31]),
                    .ddr_dq_io(ddr_data[15]),
                    .iclk_p(ddr_dqs[1]), .iclk_n(~ddr_dqs[1]));


   iob_dq iob_dm_0(.clk_p(clk_p), .clk_n(clk_n), .rst(rst), .oen(~ddr_data_oe_),
                    .din0(ddr_write_mask[0]), .din1(ddr_write_mask[2]),
                    .dout0(), .dout1(),
                    .ddr_dq_io(ddr_dm[0]),
                    .iclk_p(0), .iclk_n(0));

   iob_dq iob_dm_1(.clk_p(clk_p), .clk_n(clk_n), .rst(rst), .oen(~ddr_data_oe_),
                    .din0(ddr_write_mask[1]), .din1(ddr_write_mask[3]),
                    .dout0(), .dout1(),
                    .ddr_dq_io(ddr_dm[1]),
                    .iclk_p(0), .iclk_n(0));

   parameter CC_200US = 100 * 200,
             CC_tRP   = 3,
             CC_tRFC  = 10,
             CC_tREFI = 5000;

   parameter cmd_nop           = 3'b111,
             cmd_active        = 3'b011,
             cmd_read          = 3'b101,
             cmd_write         = 3'b100,
             cmd_burst_term    = 3'b110,
             cmd_precharge     = 3'b010,
             cmd_auto_refresh  = 3'b001,
             cmd_load_mode_reg = 3'b000;

   parameter s_idle       = 0,
             s_act_cmd    = 1,
             s_act_wait   = 2,
             s_write_cmd  = 3,
             s_write_data = 4,
             s_wait_0     = 5,
             s_wait_1     = 6,
             s_wait_2     = 7,
             s_wait_3     = 8,
             s_init_0 = 10,
             s_init_1 = 11,
             s_init_2 = 12,
             s_init_3 = 13,
             s_init_4 = 14,
             s_init_5 = 15,
             s_init_6 = 16,
             s_init_7 = 17,
             s_init_8 = 18,
             s_init_9 = 19,
             s_init_10 = 20,
             s_init_11 = 21,
             s_init_12 = 22,
             s_init_13 = 23,

             s_precharge_cmd = 25,
             s_precharge_wait_0 = 26,
             s_precharge_wait_1 = 27,
             s_row_active = 30,
             s_write_wait_0 = 31,

             s_refresh_0 = 88,
             s_refresh_1 = 89,

             s_read_cmd  = 93,
             s_read_cl_0 = 95,
             s_read_cl_1 = 96,
             s_read_cl_2 = 97,
             s_read_data = 94,
             s_read_wait_0 = 98;





   reg [7:0] ddr_state_r, ddr_state_next;
   reg [15:0] cycle_counter_r, cycle_counter;
   reg        cycle_counter_reload_en;
   reg        load_burst_addr;

   reg [12:0]  active_row_addr_r;

   always @(posedge clk)
     begin
        if (rst)
          begin
             ddr_state_r <= s_init_0;
             ddr_cke <= 0;
             active_row_addr_r <= 0;
             cycle_counter_r <= CC_200US;

             burst_addr <= 0;
          end
        else
          begin
             ddr_state_r <= ddr_state_next;

             if (cycle_counter_reload_en)
               begin
                  cycle_counter_r <= cycle_counter;
               end
             else if (cycle_counter_r)
               begin
                  cycle_counter_r <= cycle_counter_r - 1;
               end

             if (ddr_state_next == s_init_1)
               ddr_cke <= 1;

             if (ddr_state_r == s_act_cmd)
               active_row_addr_r <= user_addr[22:10];

             if (load_burst_addr)
               burst_addr <= user_addr;
          end
     end

   always @(ddr_state_r)
     begin
        user_read_ack = 0;
        user_write_ack = 0;

        case (ddr_state_r)
          s_read_data: begin
             user_read_ack = 1;
          end
          s_read_wait_0: begin
             user_read_ack = 1;
          end
          s_write_cmd: begin
             user_write_ack = 1;
          end
          s_write_data: begin
             user_write_ack = 1;
          end
        endcase
     end

   always @(ddr_state_r or burst_addr or cycle_counter_r or
            clk_edge_odd or user_read_req or user_write_req or
            user_addr or active_row_addr_r or user_write_data or
            user_write_mask)
     begin
        ddr_state_next = ddr_state_r;
        cycle_counter_reload_en = 0;
        cycle_counter = 0;

        ddr_cmd_ = cmd_nop;
        ddr_write_data_ = 0;
        ddr_data_oe_ = 0;
        ddr_addr_ = 0;
        ddr_ba_ = 0;

        ddr_write_mask_ = 4'b1111;

        load_burst_addr = 0;

        ddr_addr_ = {3'b000, burst_addr[9:0]};

        case (ddr_state_r)

          s_init_0: begin  /* After 200us with stable clocks assert clk enable  */
             if (cycle_counter_r == 0)
               begin
                  ddr_state_next = s_init_1;
               end
          end

          s_init_1: begin  /* Nop for one cycle */
             ddr_state_next = s_init_2;
          end

          s_init_2: begin  /* Precharge all */
             ddr_cmd_ = cmd_precharge;
             ddr_addr_ = {1'b1, 10'h0};
             ddr_state_next = s_init_3;
             cycle_counter = CC_tRP;
             cycle_counter_reload_en = 1;

          end

          s_init_3: begin  /* Wait for tRP */
             if (cycle_counter_r == 0)
               begin
                  ddr_state_next = s_init_4;
               end
          end

          s_init_4: begin  /* Load mode register (extended) */
             ddr_cmd_ = cmd_load_mode_reg;
             ddr_addr_ = 0;
             ddr_ba_ = 2'b01;
             ddr_state_next = s_init_5;
          end

          s_init_5: begin  /* Nop for one cycle */
             ddr_state_next = s_init_6;
          end

          s_init_6: begin  /* Load mode register */
             ddr_cmd_ = cmd_load_mode_reg;
             ddr_addr_ = {5'b00010, 3'b110, 1'b0, 3'b001};
             ddr_ba_ = 2'b00;
             ddr_state_next = s_init_7;
          end

          s_init_7: begin  /* Nop for one cycle */
             ddr_state_next = s_init_8;
          end

          s_init_8: begin  /* Precharge all */
             ddr_cmd_ = cmd_precharge;
             ddr_addr_ = {1'b1, 10'h0};
             ddr_state_next = s_init_9;
             cycle_counter = CC_tRP;
             cycle_counter_reload_en = 1;
          end

          s_init_9: begin  /* Wait for tRP */
             if (cycle_counter_r == 0)
               begin
                  ddr_state_next = s_init_10;
               end
          end

          s_init_10: begin  /* Auto refresh */
             ddr_cmd_ = cmd_auto_refresh;
             ddr_state_next = s_init_11;
             cycle_counter = CC_tRFC;
             cycle_counter_reload_en = 1;
          end

          s_init_11: begin  /* Wait for tRFC */
             if (cycle_counter_r == 0)
               begin
                  ddr_state_next = s_init_12;
               end
          end

          s_init_12: begin  /* Auto refresh */
             ddr_cmd_ = cmd_auto_refresh;
             ddr_state_next = s_init_13;
             cycle_counter = CC_tRFC + 200;
             cycle_counter_reload_en = 1;
          end

          s_init_13: begin  /* Wait for tRFC + 200cc */
             if (cycle_counter_r == 0)
               begin
                  ddr_state_next = s_idle;
                  cycle_counter = CC_tREFI;
                  cycle_counter_reload_en = 1;
               end
          end

          s_idle: begin

             if (cycle_counter_r == 0)
               begin
                  ddr_state_next = s_refresh_0;
               end
             else if (clk_edge_odd && (user_read_req || user_write_req))
               begin
                  ddr_state_next = s_act_cmd;
               end
          end

          s_refresh_0: begin
             ddr_cmd_ = cmd_auto_refresh;
             ddr_state_next = s_refresh_1;
             cycle_counter = CC_tRFC;
             cycle_counter_reload_en = 1;
          end

          s_refresh_1: begin
             if (cycle_counter_r == 0)
               begin
                  ddr_state_next = s_idle;
                  cycle_counter = CC_tREFI;
                  cycle_counter_reload_en = 1;
               end
          end

          s_precharge_cmd: begin
             ddr_cmd_ = cmd_precharge;
             ddr_addr_ = {1'b1, 10'h000};
             ddr_state_next = s_precharge_wait_0;
          end

          s_precharge_wait_0: begin
             ddr_state_next = s_precharge_wait_1;
          end

          s_precharge_wait_1: begin
             ddr_state_next = s_idle;
          end

          s_act_cmd: begin
             ddr_cmd_ = cmd_active;
             ddr_addr_ = {user_addr[22:10]};
             ddr_state_next = s_act_wait;
          end

          s_act_wait: begin
             ddr_state_next = s_row_active;
          end

          s_row_active: begin
             if (cycle_counter_r == 0 ||
                 ((user_read_req || user_write_req) && active_row_addr_r != user_addr[22:10]))
               begin
                  ddr_state_next = s_precharge_cmd;
               end
             else if (!clk_edge_odd)
               begin
                  if (user_write_req)
                    ddr_state_next = s_write_cmd;
                  else if(user_read_req)
                    ddr_state_next = s_read_cmd;

                  if (user_write_req || user_read_req)
                    load_burst_addr = 1;
               end
          end

          s_write_cmd: begin
             ddr_cmd_ = cmd_write;
             ddr_addr_ = {3'b000, burst_addr[9:0]};
             ddr_write_data_ = user_write_data;
             ddr_write_mask_ = user_write_mask;
             ddr_state_next = s_write_data;
          end

          s_write_data: begin
             ddr_write_data_ = user_write_data;
             ddr_write_mask_ = user_write_mask;
             ddr_data_oe_    = 1;

             ddr_state_next = s_write_wait_0;
          end

          s_write_wait_0: begin
             ddr_state_next = s_row_active;
          end


          s_wait_0: begin
             ddr_state_next = s_wait_1;
          end

          s_wait_1: begin
             ddr_state_next = s_wait_2;
          end

          s_wait_2: begin
             ddr_state_next = s_idle;
          end

          s_read_cmd: begin
             ddr_cmd_ = cmd_read;
             ddr_addr_ = {3'b000, burst_addr[9:0]};
             ddr_state_next = s_read_cl_0;
          end

          s_read_cl_0: begin
             ddr_state_next = s_read_cl_1;
          end

          s_read_cl_1: begin
             ddr_state_next = s_read_cl_2;
          end

          s_read_cl_2: begin

             ddr_state_next = s_read_data;
          end

          s_read_data: begin
             ddr_state_next = s_read_wait_0;
          end

          s_read_wait_0: begin
             ddr_state_next = s_row_active;
          end

        endcase

     end

endmodule
