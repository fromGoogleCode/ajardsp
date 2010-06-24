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

/**********************************************
 * General - begin
 **********************************************/
parameter INSN_PAR_BIT  =  0,
          INSN_SIZE_BIT =  1,
          INSN_ENC_BIT  = 29;

parameter ITYPE_PCU = 2'b00,
          ITYPE_LSU = 2'b01,
          ITYPE_CU  = 2'b10;

/**********************************************
 * General - end
 **********************************************/

/**********************************************
 * PCU - begin
 **********************************************/

parameter PCU_ITYPE_BKREP    = 4'h1,
          PCU_ITYPE_CALL_ABS = 4'h2,
          PCU_ITYPE_RETS     = 4'h3,
          PCU_ITYPE_JUMP_ABS = 4'h4,
          PCU_ITYPE_HALT     = 4'hf;

/**********************************************
 * PCU - end
 **********************************************/

/**********************************************
 * LSU - begin
 **********************************************/

/* Instructions with 16 bit encoding */
parameter LSU_ITYPE_LD_16     = 4'h1,
          LSU_ITYPE_LD_INC_16 = 4'h2,
          LSU_ITYPE_ST_16     = 4'h3,
          LSU_ITYPE_ST_INC_16 = 4'h4,
          LSU_ITYPE_LD_32     = 4'h5,
          LSU_ITYPE_LD_INC_32 = 4'h6,
          LSU_ITYPE_ST_32     = 4'h7,
          LSU_ITYPE_ST_INC_32 = 4'h8,

          LSU_ITYPE_PUSH_POP_16_32 = 4'h9,

          LSU_ITYPE_MV_ACC_PTR_16  = 4'ha,
          LSU_ITYPE_MV_ACC_ACC_16  = 4'hb,
          LSU_ITYPE_MV_PTR_PTR_16  = 4'hc;



/* Instructions with 32 bit encoding */
parameter LSU_ITYPE_MVTS_16   = 4'h1,
          LSU_ITYPE_MVFS_16   = 4'h2,
          LSU_ITYPE_LD_IMM_16 = 4'h3,
          LSU_ITYPE_LD_OFF_16 = 4'h4,
          LSU_ITYPE_LD_OFF_32 = 4'h5,
          LSU_ITYPE_ST_OFF_16 = 4'h6,
          LSU_ITYPE_ST_OFF_32 = 4'h7;

/**********************************************
 * LSU - end
 **********************************************/

/**********************************************
 * CU - begin
 **********************************************/

/* 16 bit encoded instuctions */
parameter CU_ITYPE_ADD_16 = 3'h1,
	  CU_ITYPE_SUB_16 = 3'h2,
          CU_ITYPE_ADD_32 = 3'h3,
	  CU_ITYPE_SUB_32 = 3'h4,
	  CU_ITYPE_MPY_16 = 3'h5,
          CU_ITYPE_MAC_16 = 3'h6;

/* 32 bit encoded instuctions */
parameter CU_ITYPE_CMP_16 = 5'h1,
	  CU_ITYPE_CMP_32 = 5'h2,
	  CU_ITYPE_FP_MUL = 5'h3;

parameter cmp_eq = 3'b000,
          cmp_ne = 3'b001,
          cmp_lt = 3'b010,
          cmp_le = 3'b011,
          cmp_gt = 3'b100,
          cmp_ge = 3'b101;

/**********************************************
 * CU - end
 **********************************************/

/**********************************************
 * BMU - begin
 **********************************************/

/* 16 bit encoded instuctions */
parameter BMU_ITYPE_AND_16 = 3'h1,
	  BMU_ITYPE_NOT_16 = 3'h2,
          BMU_ITYPE_OR_16  = 3'h3,
	  BMU_ITYPE_XOR_16 = 3'h4,

          BMU_ITYPE_AND_32 = 3'h5,
	  BMU_ITYPE_NOT_32 = 3'h6,
          BMU_ITYPE_OR_32  = 3'h7,
          BMU_ITYPE_XOR_32 = 3'h8,

          BMU_ITYPE_SHIFT_16 = 3'h9,
          BMU_ITYPE_SHIFT_32 = 3'ha;

/* 32 bit encoded instuctions */


/**********************************************
 * BMU - end
 **********************************************/
