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

module vliwfetch(instmem_data,
		 instmem_addr,
		 instmem_ren,

		 clk,
		 rst,
                 clk_en,

                 pc_o,
                 next_pc_o,

		 jump_enable,
		 jump_pc,

		 inst_0_valid,
		 inst_0,
		 inst_1_valid,
		 inst_1,
		 inst_2_valid,
		 inst_2,
		 inst_3_valid,
		 inst_3);

   input  [63:0] instmem_data;
   output [13:0] instmem_addr;
   output        instmem_ren;

   input 	 clk;
   input 	 rst;
   input         clk_en;

   input 	 jump_enable;
   input [15:0]  jump_pc;

   output [15:0] pc_o;
   output [15:0] next_pc_o;

   output 	 inst_0_valid;
   output [31:0] inst_0;
   output 	 inst_1_valid;
   output [31:0] inst_1;
   output 	 inst_2_valid;
   output [31:0] inst_2;
   output 	 inst_3_valid;
   output [31:0] inst_3;

   parameter
       PRIMING_QUEUE_0 = 2'h0,
       PRIMING_QUEUE_1 = 2'h1,
       RUNNING = 2'h2,
       JUMPING = 2'h3;

   reg [1:0] 	 fetch_state;
   reg           insn_on_top;

   wire [63:0] 	 instmem_64_0;
   reg [63:0] 	 instmem_64_1;

   reg [63:0] 	 inst_64;

   reg [15:0] 	 pc;
   reg [15:0]    jump_pc_r;
   wire [15:0] 	 next_pc;

   wire [2:0] 	 inst_bundle_size;

   wire 	 fetch_enable;
   reg [13:0] 	 fetch_address;

   wire 	 inst_0_valid_;
   wire [31:0] 	 inst_0;
   wire 	 inst_1_valid_;
   wire [31:0] 	 inst_1;
   wire 	 inst_2_valid_;
   wire [31:0] 	 inst_2;
   wire 	 inst_3_valid_;
   wire [31:0] 	 inst_3;

   wire 	 inst_0_valid;
   wire 	 inst_1_valid;
   wire 	 inst_2_valid;
   wire 	 inst_3_valid;

   assign instmem_64_0 = instmem_data;
   assign instmem_ren = fetch_enable;
   assign pc_o = pc;
   assign next_pc_o = next_pc;

   vliwdec vliwdec_0(.vliw_inst(inst_64), .vliw_len(inst_bundle_size),
		     .inst_0_valid(inst_0_valid_), .inst_0(inst_0),
		     .inst_1_valid(inst_1_valid_), .inst_1(inst_1),
		     .inst_2_valid(inst_2_valid_), .inst_2(inst_2),
		     .inst_3_valid(inst_3_valid_), .inst_3(inst_3));

   assign inst_0_valid = inst_0_valid_ &&
                         (fetch_state == RUNNING || fetch_state == JUMPING);
   assign inst_1_valid = inst_1_valid_ &&
                         (fetch_state == RUNNING || fetch_state == JUMPING);
   assign inst_2_valid = inst_2_valid_ &&
                         (fetch_state == RUNNING || fetch_state == JUMPING);
   assign inst_3_valid = inst_3_valid_ &&
                         (fetch_state == RUNNING || fetch_state == JUMPING);

   assign instmem_addr = fetch_address;
   assign next_pc = pc + inst_bundle_size;

   assign fetch_enable = next_pc[2] != pc[2] || fetch_state != RUNNING ||
                         (fetch_state == RUNNING && insn_on_top && next_pc[1:0] != 2'b00);

`ifdef SIMULATION
  integer num_insns_issued ;

  initial begin
    num_insns_issued = 0 ;
  end

  always @(posedge clk)
  begin
    if (clk_en)
    begin
      num_insns_issued = num_insns_issued + inst_0_valid + inst_1_valid + inst_2_valid + inst_3_valid ;
    end
  end
`endif

   // instmem_64_0 => instmem_64_1
   always @(pc or instmem_64_0 or instmem_64_1 or insn_on_top)
     begin
        if (pc[1:0] == 2'b00 && insn_on_top)
          begin
             inst_64 = instmem_64_0;
          end
        else
          begin
	     case (pc[1:0])
	       2'b00: begin
	          inst_64 = instmem_64_1;
	       end

	       2'b01: begin
	          inst_64 = {instmem_64_0[15:0], instmem_64_1[63:16]};
	       end

	       2'b10: begin
	          inst_64 = {instmem_64_0[31:0], instmem_64_1[63:32]};
	       end

	       2'b11: begin
	          inst_64 = {instmem_64_0[47:0], instmem_64_1[63:48]};
	       end
	     endcase // case (pc[1:0])
          end
     end // always @ (pc or instmem_64_0 or instmem_64_1)


   always @(posedge clk)
     begin

	if (rst == 1)
	  begin
             instmem_64_1 <= 64'h0;
             fetch_address <= 14'h0;
             fetch_state <= PRIMING_QUEUE_0;
             pc <= 16'h0;
             jump_pc_r <= 0;
             insn_on_top <= 0;
	  end
	else if (clk_en)
	  begin

             // Fetch next 64bit word from memory and advance the aligner queue when
             // next_pc is no longer pointing into the same 64bit word as pc
             if  (fetch_enable == 1)
	       begin
		  instmem_64_1 <= instmem_64_0;
               end

             case (fetch_state)
               PRIMING_QUEUE_0: begin
		  fetch_address <= fetch_address + 1;
		  fetch_state <= PRIMING_QUEUE_1;
	       end

               PRIMING_QUEUE_1: begin
		  fetch_address <= fetch_address + 1;
		  fetch_state <= RUNNING;
	       end

               JUMPING: begin
		  fetch_address <= fetch_address + 1;
                  pc <= jump_pc_r;
                  if (jump_pc_r[1:0] == 2'b0)
                    begin
                       fetch_state <= RUNNING;
                       insn_on_top <= 1;
                    end
                  else
                    begin
                       fetch_state <= PRIMING_QUEUE_1;
                       insn_on_top <= 0;
                    end
	       end

               RUNNING: begin

		  pc <= next_pc;

                  if (insn_on_top && next_pc[1:0] != 2'b0)
                    begin
                       insn_on_top <= 0;
                    end

		  if (jump_enable == 1)
		    begin
		       jump_pc_r <= jump_pc;
		       fetch_address <= jump_pc[15:2];
		       fetch_state <= JUMPING;
		    end
		  else
		    begin

		       if (fetch_enable == 1)
			 begin
			    fetch_address <= fetch_address + 1;
			 end

		    end // else: !if(jump_enable == 1)

	       end // case: RUNNING

	     endcase // case (fetch_state)

	  end // else: !if(rst == 1)

     end // always @ (posedge clk)

`ifdef SIMULATION_VERBOSE

   always @(posedge clk)
     begin
	if (fetch_state == RUNNING)
	  begin
	     $display("\n--- pc = %h ---", pc);

	     print_inst(inst_0_valid, inst_0);
	     print_inst(inst_1_valid, inst_1);
	     print_inst(inst_2_valid, inst_2);
	     print_inst(inst_3_valid, inst_3);

	  end // if (fetch_state == RUNNING)

     end // always @ (posedge clk)


   task print_inst;
      input valid;
      input [31:0] inst;
      begin
	 if (valid)
	   begin
	      if (inst[1])
		$display("%h", inst);
	      else
		$display("%h", inst[15:0]);
	   end
      end
   endtask // print_inst
`endif //  `ifdef SIMULATION

endmodule // vliwfetch
