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

// Possible instruction bundles
//
// 4 = 2 + 2
// 4 = 2 + 1 + 1
// 4 = 1 + 2 + 1
// 4 = 1 + 1 + 2
// 4 = 1 + 1 + 1 + 1
//
// 3 = 2 + 1
// 3 = 1 + 2
// 3 = 1 + 1 + 1
//
// 2 = 2
// 2 = 1 + 1
//
// 1 = 1
//

module vliwdec(vliw_inst,
               vliw_len,
               inst_0_valid,
               inst_0,
               inst_1_valid,
               inst_1,
               inst_2_valid,
               inst_2,
               inst_3_valid,
               inst_3);

   input [63:0] vliw_inst;
   output [2:0] vliw_len;

   output        inst_0_valid;
   output [31:0] inst_0;
   output        inst_1_valid;
   output [31:0] inst_1;
   output        inst_2_valid;
   output [31:0] inst_2;
   output        inst_3_valid;
   output [31:0] inst_3;

   reg [2:0]     vliw_len;

   reg           inst_0_valid;
   reg [31:0]    inst_0;
   reg           inst_1_valid;
   reg [31:0]    inst_1;
   reg           inst_2_valid;
   reg [31:0]    inst_2;
   reg           inst_3_valid;
   reg [31:0]    inst_3;

   reg           invalid_packet;

   always @(vliw_inst)
     begin
        // Default assignments
        vliw_len = 0;

        inst_0_valid = 1;
        inst_0       = vliw_inst[31:0];

        inst_1_valid = 0;
        inst_1       = 32'h0;

        inst_2_valid = 0;
        inst_2       = 32'h0;

        inst_3_valid = 0;
        inst_3       = 32'h0;
        invalid_packet = 0;


        if (vliw_inst[0] == 1)
          begin  //inst_0 parallel with inst_1
             inst_1_valid = 1;
             if (vliw_inst[1] == 1)
               begin  //inst_0 32bits
                  inst_1 = vliw_inst[63:32];

                  if (vliw_inst[32] == 1)
                    begin  //inst_1 parallel with inst_2
                       if (vliw_inst[33] == 1)
                         begin  //inst_1 32bits
                            // Invalid VLIW packet
                            //$stop;
                            invalid_packet = 1;
                         end
                       else
                         begin  //inst_1 16bits

                            inst_2_valid = 1;
                            inst_2 = {16'h0, vliw_inst[63:48]};
                            vliw_len = 4;
                         end
                    end // if (vliw_inst[32] == 1)
                  else
                    begin
                       if (vliw_inst[33] == 1)
                         begin
                            vliw_len = 4;
                         end
                       else
                         begin
                            vliw_len = 3;
                         end
                    end


               end
             else
               begin  //inst_0 16bits
                  inst_1 = vliw_inst[47:16];

                  if (vliw_inst[16] == 1)
                    begin  //inst_1 parallel with inst_2
                       inst_2_valid = 1;
                       if (vliw_inst[17] == 1)
                         begin  //inst_1 32bits
                            inst_2 = {16'h0, vliw_inst[63:48]};
                            vliw_len = 4;
                         end
                       else
                         begin  //inst_1 16bits
                            inst_2 = vliw_inst[63:32];
                            vliw_len = 3;

                            if (vliw_inst[32] == 1)
                              begin
                                 begin //inst_2 in prallel with inst_3
                                    inst_3_valid = 1;
                                    inst_3 = {16'h0, vliw_inst[63:48]};
                                    vliw_len = 4;
                                 end
                              end
                            else
                              begin
                                 if (vliw_inst[33] == 1)
                                   begin
                                      vliw_len = 4;
                                   end
                              end

                         end // else: !if(vliw_inst[17] == 1)
                    end // if (vliw_inst[16] == 1)
                  else
                    begin
                       if (vliw_inst[17] == 1)
                         begin
                            vliw_len = 3;
                         end
                       else
                         begin
                            vliw_len = 2;
                         end
                    end // else: !if(vliw_inst[16] == 1)

               end
          end // if (vliw_inst[0] == 1)
        else
          begin
             if (vliw_inst[1] == 1)
               begin
                  vliw_len = 2;
               end
             else
               begin
                  vliw_len = 1;
               end
          end // else: !if(vliw_inst[0] == 1)

     end // always @ (vliw_inst)

endmodule // vliwdec
