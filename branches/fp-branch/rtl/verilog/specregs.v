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

parameter SPEC_REGS_ADDR_RETPC      = 6'h1,
          SPEC_REGS_ADDR_SP         = 6'h2,
          SPEC_REGS_ADDR_CUSATCTRL  = 6'h3,
          SPEC_REGS_ADDR_CUMULSIGN  = 6'h4,

          SPEC_REGS_ADDR_MASK_SEL   = 6'h5,
          SPEC_REGS_ADDR_MASK_0     = 6'h6,
          SPEC_REGS_ADDR_MASK_1     = 6'h7,
          SPEC_REGS_ADDR_MOD_SEL    = 6'h8,
          SPEC_REGS_ADDR_MOD_0      = 6'h9,
          SPEC_REGS_ADDR_MOD_1      = 6'ha,
          SPEC_REGS_ADDR_BITREV     = 6'hb,
          SPEC_REGS_ADDR_RETIPC     = 6'hc,
          SPEC_REGS_ADDR_PRED       = 6'hd,
          SPEC_REGS_ADDR_BKREP_CNT  = 6'he,

          SPEC_REGS_ADDR_GPIO       = 6'h1f;
