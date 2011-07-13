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

module wb_misc_io(
                  /* Wishbone interface */
                  wb_clk_i,
                  wb_rst_i,

                  wb_ack_o,
                  wb_dat_i,
                  wb_dat_o,
                  wb_adr_i,

                  wb_cyc_i,
                  wb_cti_i,
                  wb_sel_i,
                  wb_stb_i,
                  wb_we_i,

                  led,
                  reset_ctrl,
                  ps2_clk_i,
                  ps2_data_i
                  );

   output wb_ack_o;
   input  wb_clk_i;
   input [31:0] wb_adr_i;
   input [31:0] wb_dat_i;
   output [31:0] wb_dat_o;
   input         wb_rst_i;
   input [3:0]   wb_sel_i;
   input         wb_cyc_i;
   input [2:0]   wb_cti_i;
   input         wb_stb_i;
   input         wb_we_i;

   output reg [7:0] led;
   output reg [7:0] reset_ctrl;

   input            ps2_clk_i;
   input            ps2_data_i;

   reg              prev_ps2_clk_r;
   reg [32:0]       ps2_shift_r;

   assign wb_ack_o = wb_stb_i;
   assign wb_dat_o = {ps2_shift_r[31:24], ps2_shift_r[20:13], ps2_shift_r[9:2]};

   always @(posedge wb_clk_i)
     begin
        if (wb_rst_i)
          begin
             led <= 0;
             reset_ctrl <= 0;
          end
        else if (wb_stb_i && wb_we_i && wb_adr_i[7:0] == 8'h00)
          begin
             led <= wb_dat_i;
          end
        else if (wb_stb_i && wb_we_i && wb_adr_i[7:0] == 8'h04)
          begin
             reset_ctrl <= wb_dat_i;
          end
     end

   /* PS2 - begin */
   always @(posedge wb_clk_i)
     begin
        if (wb_rst_i)
          begin
             ps2_shift_r <= 0;
             prev_ps2_clk_r <= 1;
          end
        else if (ps2_clk_i ^ prev_ps2_clk_r)
          begin
             prev_ps2_clk_r <= ps2_clk_i;
             if (~ps2_clk_i)
               begin
                  ps2_shift_r <= {ps2_data_i, ps2_shift_r[32:1]};
               end
          end
     end
   /* PS2 - end */
endmodule
