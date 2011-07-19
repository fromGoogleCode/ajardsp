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

module wb_ram(
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
              wb_we_i
              );

   output reg wb_ack_o;
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

   reg [1:0]     wb_state_r;

   parameter wb_idle_s = 2'b01,
             wb_ack_s = 2'b10;

   always @(posedge wb_clk_i)
     begin
        wb_ack_o = 0;
        if (wb_rst_i)
          begin
             wb_state_r <= wb_idle_s;
          end
        else
          begin
             case (wb_state_r)
               wb_idle_s: begin
                  if (wb_cyc_i & wb_stb_i)
                    begin
                       wb_state_r <= wb_ack_s;
                    end
               end
               wb_ack_s: begin
                  wb_ack_o = 1;
                  wb_state_r <= wb_idle_s;
               end
             endcase
          end
     end

`ifdef SIMULATION_WB_RAM
   reg [31:0]    wb_dat_o;
   reg [31:0] mem[0:1024];

   always @(posedge wb_clk_i)
     begin
        wb_dat_o <= mem[wb_adr_i[15:2]];
     end

   initial begin
      $readmemh("wb_ram.hex", mem);
   end
`else

`ifdef WB_RAM_WIDE_RAMB
   RAMB16_S36 mem_0(.DO(wb_dat_o),
		    //.DOP(),
		    .ADDR(wb_adr_i[31:2]),
		    .CLK(wb_clk_i),
		    .DI(wb_dat_i),
		    .DIP(4'h0),
		    .EN(wb_stb_i),
		    .SSR(wb_rst_i),
		    .WE(wb_we_i));
`else
   RAMB16_S9 mem_0(.DO(wb_dat_o[7:0]),
		   //.DOP(),
		   .ADDR(wb_adr_i[31:2]),
		   .CLK(wb_clk_i),
		   .DI(wb_dat_i[7:0]),
		   .DIP(0),
		   .EN(wb_stb_i & wb_sel_i[0]),
		   .SSR(wb_rst_i),
		   .WE(wb_we_i));

   RAMB16_S9 mem_1(.DO(wb_dat_o[15:8]),
		   //.DOP(),
		   .ADDR(wb_adr_i[31:2]),
		   .CLK(wb_clk_i),
		   .DI(wb_dat_i[15:8]),
		   .DIP(0),
		   .EN(wb_stb_i & wb_sel_i[1]),
		   .SSR(wb_rst_i),
		   .WE(wb_we_i));

   RAMB16_S9 mem_2(.DO(wb_dat_o[23:16]),
		   //.DOP(),
		   .ADDR(wb_adr_i[31:2]),
		   .CLK(wb_clk_i),
		   .DI(wb_dat_i[23:16]),
		   .DIP(0),
		   .EN(wb_stb_i & wb_sel_i[2]),
		   .SSR(wb_rst_i),
		   .WE(wb_we_i));

   RAMB16_S9 mem_3(.DO(wb_dat_o[31:24]),
		   //.DOP(),
		   .ADDR(wb_adr_i[31:2]),
		   .CLK(wb_clk_i),
		   .DI(wb_dat_i[31:24]),
		   .DIP(0),
		   .EN(wb_stb_i & wb_sel_i[3]),
		   .SSR(wb_rst_i),
		   .WE(wb_we_i));
`endif
`endif
endmodule
