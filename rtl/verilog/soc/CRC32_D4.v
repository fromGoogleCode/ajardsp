////////////////////////////////////////////////////////////////////////////////
// Copyright (C) 1999-2008 Easics NV.
// This source file may be used and distributed without restriction
// provided that this copyright statement is not removed from the file
// and that any derivative work contains the original copyright notice
// and the associated disclaimer.
//
// THIS SOURCE FILE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
// OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
// WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
//
// Purpose : synthesizable CRC function
//   * polynomial: (0 1 2 4 5 7 8 10 11 12 16 22 23 26 32)
//   * data width: 4
//
// Info : tools@easics.be
//        http://www.easics.com
////////////////////////////////////////////////////////////////////////////////
//module CRC32_D4;

  // polynomial: (0 1 2 4 5 7 8 10 11 12 16 22 23 26 32)
  // data width: 4
  // convention: the first serial bit is D[3]
  function [31:0] nextCRC32_D4;

    input [3:0] Data;
    input [31:0] crc;
    reg [3:0] d;
    reg [31:0] c;
    reg [31:0] newcrc;
  begin
    d = Data;
    c = crc;

    newcrc[0] = d[0] ^ c[28];
    newcrc[1] = d[1] ^ d[0] ^ c[28] ^ c[29];
    newcrc[2] = d[2] ^ d[1] ^ d[0] ^ c[28] ^ c[29] ^ c[30];
    newcrc[3] = d[3] ^ d[2] ^ d[1] ^ c[29] ^ c[30] ^ c[31];
    newcrc[4] = d[3] ^ d[2] ^ d[0] ^ c[0] ^ c[28] ^ c[30] ^ c[31];
    newcrc[5] = d[3] ^ d[1] ^ d[0] ^ c[1] ^ c[28] ^ c[29] ^ c[31];
    newcrc[6] = d[2] ^ d[1] ^ c[2] ^ c[29] ^ c[30];
    newcrc[7] = d[3] ^ d[2] ^ d[0] ^ c[3] ^ c[28] ^ c[30] ^ c[31];
    newcrc[8] = d[3] ^ d[1] ^ d[0] ^ c[4] ^ c[28] ^ c[29] ^ c[31];
    newcrc[9] = d[2] ^ d[1] ^ c[5] ^ c[29] ^ c[30];
    newcrc[10] = d[3] ^ d[2] ^ d[0] ^ c[6] ^ c[28] ^ c[30] ^ c[31];
    newcrc[11] = d[3] ^ d[1] ^ d[0] ^ c[7] ^ c[28] ^ c[29] ^ c[31];
    newcrc[12] = d[2] ^ d[1] ^ d[0] ^ c[8] ^ c[28] ^ c[29] ^ c[30];
    newcrc[13] = d[3] ^ d[2] ^ d[1] ^ c[9] ^ c[29] ^ c[30] ^ c[31];
    newcrc[14] = d[3] ^ d[2] ^ c[10] ^ c[30] ^ c[31];
    newcrc[15] = d[3] ^ c[11] ^ c[31];
    newcrc[16] = d[0] ^ c[12] ^ c[28];
    newcrc[17] = d[1] ^ c[13] ^ c[29];
    newcrc[18] = d[2] ^ c[14] ^ c[30];
    newcrc[19] = d[3] ^ c[15] ^ c[31];
    newcrc[20] = c[16];
    newcrc[21] = c[17];
    newcrc[22] = d[0] ^ c[18] ^ c[28];
    newcrc[23] = d[1] ^ d[0] ^ c[19] ^ c[28] ^ c[29];
    newcrc[24] = d[2] ^ d[1] ^ c[20] ^ c[29] ^ c[30];
    newcrc[25] = d[3] ^ d[2] ^ c[21] ^ c[30] ^ c[31];
    newcrc[26] = d[3] ^ d[0] ^ c[22] ^ c[28] ^ c[31];
    newcrc[27] = d[1] ^ c[23] ^ c[29];
    newcrc[28] = d[2] ^ c[24] ^ c[30];
    newcrc[29] = d[3] ^ c[25] ^ c[31];
    newcrc[30] = c[26];
    newcrc[31] = c[27];
    nextCRC32_D4 = newcrc;
  end
  endfunction
//endmodule
