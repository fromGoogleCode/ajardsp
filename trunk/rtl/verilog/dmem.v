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

`include "config.v"

module dmem(clk,
	    rst,
            clk_en,

            dump_mem_i,

	    addr_0_i,
	    mask_0_i,
	    rd_data_0_o,
	    wr_data_0_i,
	    wr_en_0_i,
	    rd_en_0_i,

	    addr_1_i,
	    mask_1_i,
	    rd_data_1_o,
	    wr_data_1_i,
	    wr_en_1_i,
	    rd_en_1_i,

            ext_dmem_addr_i,
            ext_dmem_wr_data_i,
            ext_dmem_wr_en_i,
            ext_dmem_rd_data_o,
            ext_dmem_rd_en_i,

            stall_req_o
            );

   input clk;
   input rst;
   input clk_en;

   input dump_mem_i;

   output [31:0] rd_data_0_o;
   input [15:0]  addr_0_i;
   input [1:0]   mask_0_i;
   input [31:0]  wr_data_0_i;
   input 	 wr_en_0_i;
   input 	 rd_en_0_i;

   output [31:0] rd_data_1_o;
   input [15:0]  addr_1_i;
   input [1:0]   mask_1_i;
   input [31:0]  wr_data_1_i;
   input 	 wr_en_1_i;
   input 	 rd_en_1_i;

   input [15:0]  ext_dmem_addr_i;
   input [31:0]  ext_dmem_wr_data_i;
   input         ext_dmem_wr_en_i;
   output [31:0] ext_dmem_rd_data_o;
   input         ext_dmem_rd_en_i;

   output        stall_req_o;
   reg           resolve_cycle_r;

   wire          clk_en_;

   assign clk_en_ = clk_en | ext_dmem_wr_en_i | ext_dmem_rd_en_i;

`ifdef SIMULATION_DMEM
   reg [31:0]    rd_data_0_o;
   reg [31:0]    rd_data_1_o;

   reg [15:0]    dmem [0:16'hffff];
   integer       i;
   integer       fp;

   assign stall_req_o = 0;

   initial begin
 `ifdef DMEM_IN_FILE
      $readmemh(`DMEM_IN_FILE, dmem);
 `else
      for (i = 0; i < 16'hffff; i = i + 1)
	begin
	   dmem[i] = i;
	end
 `endif
   end

   always @(posedge clk)
     begin
	if (clk_en_ & rd_en_0_i)
	  begin
	     rd_data_0_o <= {dmem[{addr_0_i[15:1], 1'b1}], dmem[{addr_0_i[15:1], 1'b0}]};
	  end

	if (clk_en_ & wr_en_0_i)
	  begin
	     if (mask_0_i[1])
	       begin
		  dmem[{addr_0_i[15:1], 1'b1}] <= wr_data_0_i[31:16];
	       end

	     if (mask_0_i[0])
	       begin
		  dmem[{addr_0_i[15:1], 1'b0}] <= wr_data_0_i[15:0];
	       end

	  end
     end

   always @(posedge clk)
     begin
	if (clk_en_ & rd_en_1_i)
	  begin
	     rd_data_1_o <= {dmem[{addr_1_i[15:1], 1'b1}], dmem[{addr_1_i[15:1], 1'b0}]};
	  end

	if (clk_en_ & wr_en_1_i)
	  begin
	     if (mask_1_i[1])
	       begin
		  dmem[{addr_1_i[15:1], 1'b1}] <= wr_data_1_i[31:16];
	       end

	     if (mask_1_i[0])
	       begin
		  dmem[{addr_1_i[15:1], 1'b0}] <= wr_data_1_i[15:0];
	       end

	  end
     end // always @ (posedge clk)

   always @(dump_mem_i)
     begin
        if (dump_mem_i)
          begin
 `ifdef DMEM_OUT_FILE
 $display("Dumping dmem to %s\n", `DMEM_OUT_FILE) ;
             fp = $fopen(`DMEM_OUT_FILE, "w");

             for (i = 0; i < 16'hffff; i = i + 1)
	       begin
	          $fdisplay(fp, "%h", dmem[i]);
	       end
 `endif
             #5 $finish;
          end
     end // always @ (dump_mem_i)

   assign ext_dmem_rd_data_o = {dmem[{ext_dmem_addr_i[15:1], 1'b1}],
                                dmem[{ext_dmem_addr_i[15:1], 1'b0}]};

   always @(posedge clk)
     begin
	if (clk_en_ & ext_dmem_wr_en_i)
	  begin
	     dmem[{ext_dmem_addr_i[15:1], 1'b1}] <= ext_dmem_wr_data_i[31:16];
	     dmem[{ext_dmem_addr_i[15:1], 1'b0}] <= ext_dmem_wr_data_i[15:0];
	  end
     end


`else //`ifdef SIMULATION_DMEM

   wire ren_a_w;
   wire ren_b_w;

   reg  [31:0] doa_r;
   wire [31:0] dia_w, doa_w, dob_w;
   wire [15:0] addra_w;
   wire        ena_w, wea_high_w, wea_low_w;

   assign addra_w     = resolve_cycle_r ? addr_1_i    : addr_0_i;
   assign dia_w       = resolve_cycle_r ? wr_data_1_i : wr_data_0_i;

   assign ena_w       = resolve_cycle_r ? (rd_en_1_i | wr_en_1_i)   : (rd_en_0_i | wr_en_0_i);
   assign wea_high_w  = resolve_cycle_r ? (wr_en_1_i & mask_1_i[1]) : (wr_en_0_i & mask_0_i[1]);
   assign wea_low_w   = resolve_cycle_r ? (wr_en_1_i & mask_1_i[0]) : (wr_en_0_i & mask_0_i[0]);

   assign rd_data_0_o = resolve_cycle_r ? doa_r : doa_w;
   assign rd_data_1_o = resolve_cycle_r ? doa_w : dob_w;

   assign en_a_w = rd_en_0_i | wr_en_0_i;
   assign en_b_w = rd_en_1_i | wr_en_1_i | ext_dmem_wr_en_i | ext_dmem_rd_en_i;

   assign ext_dmem_rd_data_o = dob_w;

   assign stall_req_o = ((wr_en_1_i | rd_en_1_i) & (ext_dmem_wr_en_i | ext_dmem_rd_en_i)) & ~resolve_cycle_r;

   always @(posedge clk)
     begin
        if (rst)
          resolve_cycle_r <= 0;
        else if (~resolve_cycle_r & stall_req_o)
          resolve_cycle_r <= 1;
        else
          resolve_cycle_r <= 0;

        doa_r <= doa_w;
     end

   RAMB16_S18_S18 dmem_ram_high(
     .DOA(doa_w[31:16]),
     .DOB(dob_w[31:16]),
     //.DOPA(),
     //.DOPB(),
     .ADDRA(addra_w[15:1]),
     .ADDRB((ext_dmem_wr_en_i | ext_dmem_rd_en_i) ? ext_dmem_addr_i[15:1] : addr_1_i[15:1]),
     .CLKA(clk),
     .CLKB(clk),
     .DIA(dia_w[31:16]),
     .DIB(ext_dmem_wr_en_i ? ext_dmem_wr_data_i[31:16] : wr_data_1_i[31:16]),
     .DIPA(4'h0),
     .DIPB(4'h0),
     .ENA(clk_en_ & ena_w),
     .ENB(clk_en_ & en_b_w),
     .SSRA(res),
     .SSRB(res),
     .WEA(wea_high_w),
     .WEB((ext_dmem_wr_en_i | ext_dmem_rd_en_i) ?  ext_dmem_wr_en_i : (wr_en_1_i & mask_1_i[1])));

   RAMB16_S18_S18 dmem_ram_low(
     .DOA(doa_w[15:0]),
     .DOB(dob_w[15:0]),
     //.DOPA(),
     //.DOPB(),
     .ADDRA(addra_w[15:1]),
     .ADDRB((ext_dmem_wr_en_i | ext_dmem_rd_en_i) ? ext_dmem_addr_i[15:1] : addr_1_i[15:1]),
     .CLKA(clk),
     .CLKB(clk),
     .DIA(dia_w[15:0]),
     .DIB(ext_dmem_wr_en_i ? ext_dmem_wr_data_i[15:0] : wr_data_1_i[15:0]),
     .DIPA(4'h0),
     .DIPB(4'h0),
     .ENA(clk_en_ & ena_w),
     .ENB(clk_en_ & en_b_w),
     .SSRA(res),
     .SSRB(res),
     .WEA(wea_low_w),
     .WEB((ext_dmem_wr_en_i | ext_dmem_rd_en_i) ? ext_dmem_wr_en_i : (wr_en_1_i & mask_1_i[0])));

`endif //`ifdef SIMULATION_DMEM

endmodule // dmem
