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

module wb_adc_ctrl(
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

                   /* ADC interface */
                   ADC_SS_o,
                   ADC_MISO_i,
                   ADC_SCK_o
                   );

   output reg    wb_ack_o;
   input         wb_clk_i;
   input [31:0]  wb_adr_i;
   input [31:0]  wb_dat_i;
   output [31:0] wb_dat_o;
   input         wb_rst_i;
   input [3:0]   wb_sel_i;
   input         wb_cyc_i;
   input         wb_stb_i;
   input         wb_we_i;

   output reg    ADC_SS_o;
   output        ADC_SCK_o;
   input         ADC_MISO_i;

   wire          clk, rst;

   reg [1:0]     clk_div_cnt_r;

   wire          adc_clk_en_w;
   reg [15:0]    adc_sample_r;
   reg [1:0]     state_r;
   reg [4:0]     bitcnt_r;

   parameter s_idle = 0, s_reading = 1, s_ack = 2;

   assign wb_dat_o = {16'h0, adc_sample_r};

   assign clk = wb_clk_i;
   assign rst = wb_rst_i;

   /* ADC clk (ADC_SCK) is clk/4 */
   assign adc_clk_en_w = clk_div_cnt_r == 2'b10 ? 1'b1 : 1'b0;
   assign ADC_SCK_o    = clk_div_cnt_r[1];

   always @(posedge clk)
     begin
        if (rst)
          begin
             clk_div_cnt_r <= 0;
          end
        else
          begin
             clk_div_cnt_r <= clk_div_cnt_r + 1;
          end
     end

   always @(posedge clk)
     begin
        if (rst)
          begin
             adc_sample_r[15:0] <= 0;
          end
        else if (adc_clk_en_w)
          begin
             adc_sample_r[15:0] <= {adc_sample_r[14:0], ADC_MISO_i};
          end
     end

   always @(posedge clk)
     begin
        ADC_SS_o = 1;
        wb_ack_o = 0;

        if (rst)
          begin
             state_r <= s_idle;
             bitcnt_r <= 0;
          end
        else
          begin

             case (state_r)
               s_idle: begin
                  if (wb_cyc_i & wb_stb_i)
                    begin
                       state_r <= s_reading;
                       bitcnt_r <= 0;
                    end
               end
               s_reading: begin
                  ADC_SS_o = 0;
                  if (bitcnt_r < 16)
                    begin
                       if (adc_clk_en_w)
                         begin
                            bitcnt_r <= bitcnt_r + 1;
                         end
                    end
                  else
                    begin
                       state_r <= s_ack;
                    end
               end
               s_ack: begin
                  wb_ack_o = 1;
                  state_r <= s_idle;
               end
             endcase
          end
     end

endmodule
