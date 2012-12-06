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

module testbench;

   reg clk, rst;
   wire interrupt;
   wire halt ;
   wire [15:0] gpio_w;
   reg [31:0]  cycle;


`ifdef INTCYCLE
   assign interrupt = (cycle == `INTCYCLE) ? 1'b1 : 1'b0;
`else
   assign interrupt = gpio_w[0];
`endif

   always @(posedge clk)
     begin
        if (rst)
          cycle <= 0;
        else
          cycle <= cycle + 1;
	
	if (halt)
	  $display("CPU Halted. Ran for %d cycles. Issued %d instructions, including %d nops Fraction of nops = %f.\n", cycle, ajardsp_0.vliwfetch_0.num_insns_issued, ajardsp_0.vliwfetch_0.num_nops_issued, real'(ajardsp_0.vliwfetch_0.num_nops_issued) / real'(ajardsp_0.vliwfetch_0.num_insns_issued)) ;

     end

   ajardsp_top ajardsp_0(.clk(clk),
                         .rst_core(rst),
                         .rst_mem(rst),

                         .ext_imem_wr_addr_i(0),
                         .ext_imem_wr_data_i(0),
                         .ext_imem_wr_en_i(0),

                         .ext_dmem_addr_i(0),
                         .ext_dmem_wr_data_i(0),
                         .ext_dmem_wr_en_i(0),
                         .ext_dmem_rd_data_o(),
                         .ext_dmem_rd_en_i(0),

                         .core_halt_o(halt),
                         .gpio_o(gpio_w),
                         .interrupt_req_i(interrupt),

                         .m_if_ack_i(1)

                         );



   initial begin
      $dumpvars;
      clk = 0;

      rst = 1;
      #5 rst = 0;

      #10000000 $finish;
   end

   always clk = #1 ~clk;

endmodule // testbench
