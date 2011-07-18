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

#include <stdlib.h>
#include "asm.h"

#define FU_PCU (0 << 2)
#define FU_LSU (1 << 2)
#define FU_CU  (2 << 2)
#define FU_BMU (3 << 2)

#define PCU_ITYPE_BKREP    (0x1 << 4)
#define PCU_ITYPE_CALL_ABS (0x2 << 4)
#define PCU_ITYPE_RETS     (0x3 << 4)
#define PCU_ITYPE_JUMP_ABS (0x4 << 4)
#define PCU_ITYPE_HALT     (0xf << 4)
#define PCU_ITYPE_RETI     (0x5 << 4)
#define PCU_ITYPE_EINT     (0x6 << 4)
#define PCU_ITYPE_DINT     (0x7 << 4)

#define BMU_OP_SIZE_16     (1 << 21)

#define BMU_SHIFT_LEFT     (1 << 23)

#define BMU_ITYPE_AND_16_32    (0x01 << 4)
#define	BMU_ITYPE_NOT_16_32    (0x02 << 4)
#define BMU_ITYPE_OR_16_32     (0x03 << 4)
#define BMU_ITYPE_XOR_16_32    (0x04 << 4)
#define BMU_ITYPE_SHIFTA_16_32 (0x05 << 4)
#define BMU_ITYPE_SHIFTL_16_32 (0x06 << 4)

#define CU_ITYPE_ADD_16 (1 << 4)
#define CU_ITYPE_SUB_16 (2 << 4)
#define CU_ITYPE_ADD_32 (3 << 4)
#define CU_ITYPE_SUB_32 (4 << 4)
#define	CU_ITYPE_MPY_16 (5 << 4)
#define CU_ITYPE_MAC_16 (6 << 4)

#define CU_ITYPE_CMP_16 (0x1 << 4)
#define CU_ITYPE_CMP_32 (0x2 << 4)

#define CMP_EQ (0x0 << 26)
#define CMP_NE (0x1 << 26)
#define CMP_LT (0x2 << 26)
#define CMP_LE (0x3 << 26)
#define CMP_GT (0x4 << 26)
#define CMP_GE (0x5 << 26)

/* 16 bit encoding */
#define LSU_ITYPE_LD_16      (0x1 << 4)
#define LSU_ITYPE_LD_INC_16  (0x2 << 4)
#define LSU_ITYPE_ST_16      (0x3 << 4)
#define LSU_ITYPE_ST_INC_16  (0x4 << 4)
#define LSU_ITYPE_LD_32      (0x5 << 4)
#define LSU_ITYPE_LD_INC_32  (0x6 << 4)
#define LSU_ITYPE_ST_32      (0x7 << 4)
#define LSU_ITYPE_ST_INC_32  (0x8 << 4)
#define LSU_ITYPE_PUSH_POP_16_32 (0x9 << 4)
#define LSU_ITYPE_MV_ACC_PTR_16  (0xa << 4)
#define LSU_ITYPE_MV_ACC_ACC_16  (0xb << 4)
#define LSU_ITYPE_MV_PTR_PTR_16  (0xc << 4)

/* 32 bit encoding */
#define LSU_ITYPE_MVTS_16    (0x1 << 4)
#define LSU_ITYPE_MVFS_16    (0x2 << 4)
//#define LSU_ITYPE_LD_IMM_16  (0x3 << 4)
#define LSU_ITYPE_LD_OFF_16  (0x4 << 4)
#define LSU_ITYPE_LD_OFF_32  (0x5 << 4)
#define LSU_ITYPE_ST_OFF_16  (0x6 << 4)
#define LSU_ITYPE_ST_OFF_32  (0x7 << 4)
#define LSU_ITYPE_ADDPTR_16  (0x8 << 4)
#define LSU_ITYPE_LD_IMM_PTR_16  (0x9 << 4)
#define LSU_ITYPE_LD_IMM_ACC_16  (0xa << 4)
#define LSU_ITYPE_LD_EXT_32 (0xb << 4)
#define LSU_ITYPE_ST_EXT_32 (0xc << 4)
#define LSU_ITYPE_EXT_BURST (0xd << 4)

#define INSN_ENC_32 (1 << 29)


inst_def_t ajardsp_insns[] = {

  {
    .mnemonic = "nop",
    .size = INST_16,
    .pattern = 0x0000,
    .nr_operands = 0,

    .operands = {
    },
  },

  /* BMU instructions */

  {
    .mnemonic = "and32",
    .size = INST_32,
    .pattern = INSN_ENC_32 | BMU_ITYPE_AND_16_32 | FU_BMU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 10,
	.width  = 3,
	.encode = encode_acc,
      },
      {
	.type = REG,
	.offset = 14,
	.width  = 3,
	.encode = encode_acc,
      },
      {
	.type = REG,
	.offset = 18,
	.width  = 3,
	.encode = encode_acc,
      },

    },
  },

  {
    .mnemonic = "or32",
    .size = INST_32,
    .pattern = INSN_ENC_32 | BMU_ITYPE_OR_16_32 | FU_BMU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 10,
	.width  = 3,
	.encode = encode_acc,
      },
      {
	.type = REG,
	.offset = 14,
	.width  = 3,
	.encode = encode_acc,
      },
      {
	.type = REG,
	.offset = 18,
	.width  = 3,
	.encode = encode_acc,
      },

    },
  },

  {
    .mnemonic = "xor32",
    .size = INST_32,
    .pattern = INSN_ENC_32 | BMU_ITYPE_XOR_16_32 | FU_BMU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 10,
	.width  = 3,
	.encode = encode_acc,
      },
      {
	.type = REG,
	.offset = 14,
	.width  = 3,
	.encode = encode_acc,
      },
      {
	.type = REG,
	.offset = 18,
	.width  = 3,
	.encode = encode_acc,
      },

    },
  },

  {
    .mnemonic = "not32",
    .size = INST_32,
    .pattern = INSN_ENC_32 | BMU_ITYPE_NOT_16_32 | FU_BMU,
    .nr_operands = 2,

    .operands = {
      {
	.type = REG,
	.offset = 10,
	.width  = 3,
	.encode = encode_acc,
      },
      {
	.type = REG,
	.offset = 18,
	.width  = 3,
	.encode = encode_acc,
      },

    },
  },

  {
    .mnemonic = "shiftra32",
    .size = INST_32,
    .pattern = INSN_ENC_32 | BMU_ITYPE_SHIFTA_16_32 | FU_BMU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 10,
	.width  = 3,
	.encode = encode_acc,
      },
      {
	.type = REG,
	.offset = 13,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 18,
	.width  = 3,
	.encode = encode_acc,
      },

    },
  },

  {
    .mnemonic = "shiftrl32",
    .size = INST_32,
    .pattern = INSN_ENC_32 | BMU_ITYPE_SHIFTL_16_32 | FU_BMU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 10,
	.width  = 3,
	.encode = encode_acc,
      },
      {
	.type = REG,
	.offset = 13,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 18,
	.width  = 3,
	.encode = encode_acc,
      },

    },
  },

  {
    .mnemonic = "shiftll32",
    .size = INST_32,
    .pattern = INSN_ENC_32 | BMU_SHIFT_LEFT | BMU_ITYPE_SHIFTL_16_32 | FU_BMU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 10,
	.width  = 3,
	.encode = encode_acc,
      },
      {
	.type = REG,
	.offset = 13,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 18,
	.width  = 3,
	.encode = encode_acc,
      },

    },
  },

  {
    .mnemonic = "and16",
    .size = INST_32,
    .pattern = INSN_ENC_32 | BMU_OP_SIZE_16 | BMU_ITYPE_AND_16_32 | FU_BMU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 9,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 13,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 17,
	.width  = 4,
	.encode = encode_acc_half,
      },

    },
  },

  {
    .mnemonic = "or16",
    .size = INST_32,
    .pattern = INSN_ENC_32 | BMU_OP_SIZE_16 | BMU_ITYPE_OR_16_32 | FU_BMU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 9,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 13,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 17,
	.width  = 4,
	.encode = encode_acc_half,
      },

    },
  },

  {
    .mnemonic = "xor16",
    .size = INST_32,
    .pattern = INSN_ENC_32 | BMU_OP_SIZE_16 | BMU_ITYPE_XOR_16_32 | FU_BMU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 9,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 13,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 17,
	.width  = 4,
	.encode = encode_acc_half,
      },

    },
  },

  {
    .mnemonic = "not16",
    .size = INST_32,
    .pattern = INSN_ENC_32 | BMU_OP_SIZE_16 | BMU_ITYPE_NOT_16_32 | FU_BMU,
    .nr_operands = 2,

    .operands = {
      {
	.type = REG,
	.offset = 9,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 17,
	.width  = 4,
	.encode = encode_acc_half,
      },

    },
  },

  {
    .mnemonic = "shiftra16",
    .size = INST_32,
    .pattern = INSN_ENC_32 | BMU_OP_SIZE_16 | BMU_ITYPE_SHIFTA_16_32 | FU_BMU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 9,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 13,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 17,
	.width  = 4,
	.encode = encode_acc_half,
      },

    },
  },

  {
    .mnemonic = "shiftrl16",
    .size = INST_32,
    .pattern = INSN_ENC_32 | BMU_OP_SIZE_16 | BMU_ITYPE_SHIFTL_16_32 | FU_BMU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 9,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 13,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 17,
	.width  = 4,
	.encode = encode_acc_half,
      },

    },
  },

  {
    .mnemonic = "shiftll16",
    .size = INST_32,
    .pattern = INSN_ENC_32 | BMU_OP_SIZE_16 | BMU_SHIFT_LEFT | BMU_ITYPE_SHIFTL_16_32 | FU_BMU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 9,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 13,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 17,
	.width  = 4,
	.encode = encode_acc_half,
      },

    },
  },


  /* CU instructions for the new encoding */

  {
    .mnemonic = "add32",
    .size = INST_16,
    .pattern = CU_ITYPE_ADD_32 | FU_CU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 7,
	.width  = 3,
	.encode = encode_acc,
      },
      {
	.type = REG,
	.offset = 10,
	.width  = 3,
	.encode = encode_acc,
      },
      {
	.type = REG,
	.offset = 13,
	.width  = 3,
	.encode = encode_acc,
      },

    },
  },

  {
    .mnemonic = "sub32",
    .size = INST_16,
    .pattern = CU_ITYPE_SUB_32 | FU_CU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 7,
	.width  = 3,
	.encode = encode_acc,
      },
      {
	.type = REG,
	.offset = 10,
	.width  = 3,
	.encode = encode_acc,
      },
      {
	.type = REG,
	.offset = 13,
	.width  = 3,
	.encode = encode_acc,
      },

    },
  },

  {
    .mnemonic = "add16",
    .size = INST_16,
    .pattern = CU_ITYPE_ADD_16 | FU_CU,
    .nr_operands = 2,

    .operands = {
      {
	.type = REG,
	.offset = 11,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 7,
	.width  = 4,
	.encode = encode_acc_half,
      },
    },
  },

  {
    .mnemonic = "sub16",
    .size = INST_16,
    .pattern = CU_ITYPE_SUB_16 | FU_CU,
    .nr_operands = 2,

    .operands = {
      {
	.type = REG,
	.offset = 11,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 7,
	.width  = 4,
	.encode = encode_acc_half,
      },
    },
  },

  {
    .mnemonic = "mpy16",
    .size = INST_16,
    .pattern = CU_ITYPE_MPY_16 | FU_CU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 7,
	.width  = 3,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 10,
	.width  = 3,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 13,
	.width  = 3,
	.encode = encode_acc,
      },

    },
  },

  {
    .mnemonic = "mac16",
    .size = INST_16,
    .pattern = CU_ITYPE_MAC_16 | FU_CU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 7,
	.width  = 3,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 10,
	.width  = 3,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 13,
	.width  = 3,
	.encode = encode_acc,
      },

    },
  },


  {
    .mnemonic = "cmp16eq",
    .size = INST_32,
    .pattern = INSN_ENC_32 | CMP_EQ | CU_ITYPE_CMP_16 | FU_CU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 9,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 13,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 24,
	.width  = 2,
	.encode = encode_pred,
      },

    },
  },

  {
    .mnemonic = "cmp16ne",
    .size = INST_32,
    .pattern = INSN_ENC_32 | CMP_NE | CU_ITYPE_CMP_16 | FU_CU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 9,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 13,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 24,
	.width  = 2,
	.encode = encode_pred,
      },

    },
  },

  {
    .mnemonic = "cmp16lt",
    .size = INST_32,
    .pattern = INSN_ENC_32 | CMP_LT | CU_ITYPE_CMP_16 | FU_CU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 9,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 13,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 24,
	.width  = 2,
	.encode = encode_pred,
      },

    },
  },

  {
    .mnemonic = "cmp16le",
    .size = INST_32,
    .pattern = INSN_ENC_32 | CMP_LE | CU_ITYPE_CMP_16 | FU_CU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 9,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 13,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 24,
	.width  = 2,
	.encode = encode_pred,
      },

    },
  },

  {
    .mnemonic = "cmp16gt",
    .size = INST_32,
    .pattern = INSN_ENC_32 | CMP_GT | CU_ITYPE_CMP_16 | FU_CU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 9,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 13,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 24,
	.width  = 2,
	.encode = encode_pred,
      },

    },
  },

  {
    .mnemonic = "cmp16ge",
    .size = INST_32,
    .pattern = INSN_ENC_32 | CMP_GE | CU_ITYPE_CMP_16 | FU_CU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 9,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 13,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 24,
	.width  = 2,
	.encode = encode_pred,
      },

    },
  },

  /* New CU encoding ends here */

  /* LSU instructions for the new encoding */
  {
    .mnemonic = "ld16",
    .size = INST_16,
    .pattern = LSU_ITYPE_LD_16 | FU_LSU,
    .nr_operands = 2,

    .operands = {
      {
	.type = REG,
	.offset = 8,
	.width  = 3,
	.encode = encode_ptr,
      },
      {
	.type = REG,
	.offset = 11,
	.width  = 5,
	.encode = encode_reg,
      },
    },
  },

  {
    .mnemonic = "ldinc16",
    .size = INST_16,
    .pattern = LSU_ITYPE_LD_INC_16 | FU_LSU,
    .nr_operands = 2,

    .operands = {
      {
	.type = REG,
	.offset = 8,
	.width  = 3,
	.encode = encode_ptr,
      },
      {
	.type = REG,
	.offset = 11,
	.width  = 5,
	.encode = encode_reg,
      },
    },
  },

  {
    .mnemonic = "st16",
    .size = INST_16,
    .pattern = LSU_ITYPE_ST_16 | FU_LSU,
    .nr_operands = 2,

    .operands = {
      {
	.type = REG,
	.offset = 11,
	.width  = 5,
	.encode = encode_reg,
      },
      {
	.type = REG,
	.offset = 8,
	.width  = 3,
	.encode = encode_ptr,
      },
    },
  },

  {
    .mnemonic = "stinc16",
    .size = INST_16,
    .pattern = LSU_ITYPE_ST_INC_16 | FU_LSU,
    .nr_operands = 2,

    .operands = {
      {
	.type = REG,
	.offset = 11,
	.width  = 5,
	.encode = encode_reg,
      },
      {
	.type = REG,
	.offset = 8,
	.width  = 3,
	.encode = encode_ptr,
      },
    },
  },

  {
    .mnemonic = "ld32",
    .size = INST_16,
    .pattern = LSU_ITYPE_LD_32 | FU_LSU,
    .nr_operands = 2,

    .operands = {
      {
	.type = REG,
	.offset = 8,
	.width  = 3,
	.encode = encode_ptr,
      },
      {
	.type = REG,
	.offset = 11,
	.width  = 3,
	.encode = encode_acc,
      },
    },
  },

  {
    .mnemonic = "ldinc32",
    .size = INST_16,
    .pattern = LSU_ITYPE_LD_INC_32 | FU_LSU,
    .nr_operands = 2,

    .operands = {
      {
	.type = REG,
	.offset = 8,
	.width  = 3,
	.encode = encode_ptr,
      },
      {
	.type = REG,
	.offset = 11,
	.width  = 3,
	.encode = encode_acc,
      },
    },
  },

  {
    .mnemonic = "st32",
    .size = INST_16,
    .pattern = LSU_ITYPE_ST_32 | FU_LSU,
    .nr_operands = 2,

    .operands = {
      {
	.type = REG,
	.offset = 11,
	.width  = 3,
	.encode = encode_acc,
      },
      {
	.type = REG,
	.offset = 8,
	.width  = 3,
	.encode = encode_ptr,
      },
    },
  },

  {
    .mnemonic = "stinc32",
    .size = INST_16,
    .pattern = LSU_ITYPE_ST_INC_32 | FU_LSU,
    .nr_operands = 2,

    .operands = {
      {
	.type = REG,
	.offset = 11,
	.width  = 3,
	.encode = encode_acc,
      },
      {
	.type = REG,
	.offset = 8,
	.width  = 3,
	.encode = encode_ptr,
      },
    },
  },


  {
    .mnemonic = "ldimm16",
    .size = INST_32,
    .pattern = INSN_ENC_32 | LSU_ITYPE_LD_IMM_ACC_16 | FU_LSU,
    .nr_operands = 2,

    .operands = {
      {
	.type = INTEGER,
	.offset = 12,
	.width  = 16,
	.encode = encode_int,
      },
      {
	.type = REG,
	.offset = 8,
	.width  = 4,
	.encode = encode_acc_half,
      },
    },
  },

  {
    .mnemonic = "ldimm16",
    .size = INST_32,
    .pattern = INSN_ENC_32 | LSU_ITYPE_LD_IMM_PTR_16 | FU_LSU,
    .nr_operands = 2,

    .operands = {
      {
	.type = INTEGER,
	.offset = 12,
	.width  = 16,
	.encode = encode_int,
      },
      {
	.type = REG,
	.offset = 8,
	.width  = 4,
	.encode = encode_ptr,
      },
    },
  },

  {
    .mnemonic = "ldimm16",
    .size = INST_32,
    .pattern = INSN_ENC_32 | LSU_ITYPE_LD_IMM_PTR_16 | FU_LSU,
    .nr_operands = 2,

    .operands = {
      {
	.type = SYMBOL_REF,
	.offset = 12,
	.width  = 16,
	.encode = encode_symref,
      },
      {
	.type = REG,
	.offset = 8,
	.width  = 4,
	.encode = encode_ptr,
      },
    },
  },
  {
    .mnemonic = "ldoff16",
    .size = INST_32,
    .pattern = INSN_ENC_32 | LSU_ITYPE_LD_OFF_16 | FU_LSU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 25,
	.width  = 3,
	.encode = encode_ptr,
      },
      {
	.type = INTEGER,
	.offset = 13,
	.width  = 12,
	.encode = encode_int,
      },
      {
	.type = REG,
	.offset = 8,
	.width  = 5,
	.encode = encode_reg,
      },
    },
  },


  {
    .mnemonic = "ldoff16",
    .size = INST_32,
    .pattern = INSN_ENC_32 | LSU_ITYPE_LD_OFF_16 | FU_LSU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 25,
	.width  = 3,
	.encode = encode_ptr,
      },
      {
	.type = SYMBOL_REF,
	.offset = 13,
	.width  = 12,
	.encode = encode_symref,
      },
      {
	.type = REG,
	.offset = 8,
	.width  = 5,
	.encode = encode_reg,
      },

    },
  },

  {
    .mnemonic = "ldoff32",
    .size = INST_32,
    .pattern = INSN_ENC_32 | LSU_ITYPE_LD_OFF_32 | FU_LSU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 25,
	.width  = 3,
	.encode = encode_ptr,
      },
      {
	.type = INTEGER,
	.offset = 13,
	.width  = 12,
	.encode = encode_int,
      },
      {
	.type = REG,
	.offset = 9,
	.width  = 3,
	.encode = encode_acc,
      },
    },
  },

  {
    .mnemonic = "stoff16",
    .size = INST_32,
    .pattern = INSN_ENC_32 | LSU_ITYPE_ST_OFF_16 | FU_LSU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 8,
	.width  = 5,
	.encode = encode_reg,
      },
      {
	.type = INTEGER,
	.offset = 13,
	.width  = 12,
	.encode = encode_int,
      },
      {
	.type = REG,
	.offset = 25,
	.width  = 3,
	.encode = encode_ptr,
      },
    },
  },

  {
    .mnemonic = "stoff16",
    .size = INST_32,
    .pattern = INSN_ENC_32 | LSU_ITYPE_ST_OFF_16 | FU_LSU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 8,
	.width  = 5,
	.encode = encode_reg,
      },
      {
	.type = SYMBOL_REF,
	.offset = 13,
	.width  = 12,
	.encode = encode_symref,
      },
      {
	.type = REG,
	.offset = 25,
	.width  = 3,
	.encode = encode_ptr,
      },
    },
  },

  {
    .mnemonic = "stoff32",
    .size = INST_32,
    .pattern = INSN_ENC_32 | LSU_ITYPE_ST_OFF_32 | FU_LSU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 9,
	.width  = 3,
	.encode = encode_acc,
      },
      {
	.type = INTEGER,
	.offset = 13,
	.width  = 12,
	.encode = encode_int,
      },
      {
	.type = REG,
	.offset = 25,
	.width  = 3,
	.encode = encode_ptr,
      },
    },
  },

  {
    .mnemonic = "addptr16",
    .size = INST_32,
    .pattern = INSN_ENC_32 | LSU_ITYPE_ADDPTR_16 | FU_LSU,
    .nr_operands = 2,
    .operands = {
      {
	.type = INTEGER,
	.offset = 13,
	.width  = 12,
	.encode = encode_int,
      },
      {
	.type = REG,
	.offset = 25,
	.width  = 3,
	.encode = encode_ptr,
      },
    },
  },



  {
    .mnemonic = "mvts16",
    .size = INST_32,
    .pattern = INSN_ENC_32 | LSU_ITYPE_MVTS_16 | FU_LSU,
    .nr_operands = 2,

    .operands = {
      {
	.type = REG,
	.offset = 8,
	.width  = 5,
	.encode = encode_reg,
      },
      {
	.type = REG,
	.offset = 13,
	.width  = 6,
	.encode = encode_spec,
      },
    },
  },

  {
    .mnemonic = "mvfs16",
    .size = INST_32,
    .pattern = INSN_ENC_32 | LSU_ITYPE_MVFS_16 | FU_LSU,
    .nr_operands = 2,

    .operands = {
      {
	.type = REG,
	.offset = 13,
	.width  = 6,
	.encode = encode_spec,
      },
      {
	.type = REG,
	.offset = 8,
	.width  = 5,
	.encode = encode_reg,
      },
    },
  },

  {
    .mnemonic = "push16",
    .size = INST_16,
    .pattern = (1 << 8) | LSU_ITYPE_PUSH_POP_16_32 | FU_LSU,
    .nr_operands = 1,

    .operands = {
      {
	.type = REG,
	.offset = 11,
	.width  = 5,
	.encode = encode_reg,
      },
    },
  },

  {
    .mnemonic = "push16",
    .size = INST_16,
    .pattern = (1 << 10) | (1 << 8) | LSU_ITYPE_PUSH_POP_16_32 | FU_LSU,
    .nr_operands = 1,

    .operands = {
      {
	.type = REG,
	.offset = 11,
	.width  = 5,
	.encode = encode_spec,
      },
    },
  },


  {
    .mnemonic = "push32",
    .size = INST_16,
    .pattern = (1 << 15) | (1 << 9) | (1 << 8) | LSU_ITYPE_PUSH_POP_16_32 | FU_LSU,
    .nr_operands = 1,

    .operands = {
      {
	.type = REG,
	.offset = 12,
	.width  = 3,
	.encode = encode_acc,
      },
    },
  },

  {
    .mnemonic = "pop16",
    .size = INST_16,
    .pattern = LSU_ITYPE_PUSH_POP_16_32 | FU_LSU,
    .nr_operands = 1,

    .operands = {
      {
	.type = REG,
	.offset = 11,
	.width  = 5,
	.encode = encode_reg,
      },
    },
  },

  {
    .mnemonic = "pop16",
    .size = INST_16,
    .pattern = (1 << 10) | LSU_ITYPE_PUSH_POP_16_32 | FU_LSU,
    .nr_operands = 1,

    .operands = {
      {
	.type = REG,
	.offset = 11,
	.width  = 5,
	.encode = encode_spec,
      },
    },
  },


  {
    .mnemonic = "pop32",
    .size = INST_16,
    .pattern = (1 << 15) | (1 << 9) | LSU_ITYPE_PUSH_POP_16_32 | FU_LSU,
    .nr_operands = 1,

    .operands = {
      {
	.type = REG,
	.offset = 12,
	.width  = 3,
	.encode = encode_acc,
      },
    },
  },

  {
    .mnemonic = "mv16",  /* mv $ptr -> $acc */
    .size = INST_16,
    .pattern = (0 << 8) | LSU_ITYPE_MV_ACC_PTR_16 | FU_LSU,
    .nr_operands = 2,

    .operands = {
      {
	.type = REG,
	.offset = 9,
	.width  = 3,
	.encode = encode_ptr,
      },
      {
	.type = REG,
	.offset = 12,
	.width  = 4,
	.encode = encode_acc_half,
      },
    },
  },

  {
    .mnemonic = "mv16",  /* mv $acc -> $ptr */
    .size = INST_16,
    .pattern = (1 << 8) | LSU_ITYPE_MV_ACC_PTR_16 | FU_LSU,
    .nr_operands = 2,

    .operands = {
      {
	.type = REG,
	.offset = 12,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 9,
	.width  = 3,
	.encode = encode_ptr,
      },
    },
  },

  {
    .mnemonic = "mv16",  /* mv $ptr -> $ptr */
    .size = INST_16,
    .pattern = LSU_ITYPE_MV_PTR_PTR_16 | FU_LSU,
    .nr_operands = 2,

    .operands = {
      {
	.type = REG,
	.offset = 9,
	.width  = 3,
	.encode = encode_ptr,
      },
      {
	.type = REG,
	.offset = 12,
	.width  = 3,
	.encode = encode_ptr,
      },
    },
  },

  {
    .mnemonic = "mv16",  /* mv $acc -> $acc */
    .size = INST_16,
    .pattern = LSU_ITYPE_MV_ACC_ACC_16 | FU_LSU,
    .nr_operands = 2,

    .operands = {
      {
	.type = REG,
	.offset = 12,
	.width  = 4,
	.encode = encode_acc_half,
      },
      {
	.type = REG,
	.offset = 8,
	.width  = 4,
	.encode = encode_acc_half,
      },
    },
  },

  {
    .mnemonic = "stext32",
    .size = INST_32,
    .pattern = INSN_ENC_32 | LSU_ITYPE_ST_EXT_32 | FU_LSU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 14,
	.width  = 3,
	.encode = encode_acc,
      },
      {
	.type = REG,
	.offset = 8,
	.width  = 3,
	.encode = encode_ptr,
      },
      {
	.type = REG,
	.offset = 11,
	.width  = 3,
	.encode = encode_ptr,
      },
    },
  },

  {
    .mnemonic = "ldext32",
    .size = INST_32,
    .pattern = INSN_ENC_32 | LSU_ITYPE_LD_EXT_32 | FU_LSU,
    .nr_operands = 3,

    .operands = {
      {
	.type = REG,
	.offset = 8,
	.width  = 3,
	.encode = encode_ptr,
      },
      {
	.type = REG,
	.offset = 11,
	.width  = 3,
	.encode = encode_ptr,
      },
      {
	.type = REG,
	.offset = 14,
	.width  = 3,
	.encode = encode_acc,
      },
    },
  },

  {
    .mnemonic = "extburst",
    .size = INST_32,
    .pattern = INSN_ENC_32 | LSU_ITYPE_EXT_BURST | FU_LSU,
    .nr_operands = 4,

    .operands = {
      {
	.type = INTEGER,
	.offset = 17,
	.width  = 8,
	.encode = encode_int,
      },
      {
	.type = REG,
	.offset = 8,
	.width  = 3,
	.encode = encode_ptr,
      },
      {
	.type = REG,
	.offset = 11,
	.width  = 3,
	.encode = encode_ptr,
      },
      {
	.type = REG,
	.offset = 14,
	.width  = 3,
	.encode = encode_acc,
      },
    },
  },


  /* LSU instructions for the new encoding ends here */

  {
    .mnemonic = "bra",
    .size = INST_32,
    .pattern = INSN_ENC_32 | PCU_ITYPE_JUMP_ABS | FU_PCU,
    .nr_operands = 1,

    .operands = {
      {
	.type = SYMBOL_REF,
	.offset = 8,
	.width  = 16,
	.encode = encode_symref,
      },
    },
  },

  {
    .mnemonic = "bra.2ds",
    .size = INST_32,
    .pattern = (2 << 24) | INSN_ENC_32 | PCU_ITYPE_JUMP_ABS | FU_PCU,
    .nr_operands = 1,

    .operands = {
      {
	.type = SYMBOL_REF,
	.offset = 8,
	.width  = 16,
	.encode = encode_symref,
      },
    },
  },

  {
    .mnemonic = "bra.1ds",
    .size = INST_32,
    .pattern = (1 << 24) | INSN_ENC_32 | PCU_ITYPE_JUMP_ABS | FU_PCU,
    .nr_operands = 1,

    .operands = {
      {
	.type = SYMBOL_REF,
	.offset = 8,
	.width  = 16,
	.encode = encode_symref,
      },
    },
  },
#if 0
  {
    .mnemonic = "bra",
    .size = INST_16,
    .pattern = PCU_ITYPE_JUMP_ABS | FU_PCU,
    .nr_operands = 1,

    .operands = {
      {
	.type = REG,
	.offset = 8,
	.width  = 3,
	.encode = encode_ptr,
      },
    },
  },

  {
    .mnemonic = "bra.2ds",
    .size = INST_16,
    .pattern = (2 << 12) | PCU_ITYPE_JUMP_ABS | FU_PCU,
    .nr_operands = 1,

    .operands = {
      {
	.type = REG,
	.offset = 8,
	.width  = 3,
	.encode = encode_ptr,
      },
    },
  },

  {
    .mnemonic = "bra.1ds",
    .size = INST_16,
    .pattern = (1 << 12) | PCU_ITYPE_JUMP_ABS | FU_PCU,
    .nr_operands = 1,

    .operands = {
      {
	.type = REG,
	.offset = 8,
	.width  = 3,
	.encode = encode_ptr,
      },
    },
  },
#endif

  {
    .mnemonic = "call",
    .size = INST_32,
    .pattern = INSN_ENC_32 | PCU_ITYPE_CALL_ABS | FU_PCU,
    .nr_operands = 1,

    .operands = {
      {
	.type = SYMBOL_REF,
	.offset = 8,
	.width  = 16,
	.encode = encode_symref,
      },
    },
  },

  {
    .mnemonic = "call.2ds",
    .size = INST_32,
    .pattern = (2 << 24) | INSN_ENC_32 | PCU_ITYPE_CALL_ABS | FU_PCU,
    .nr_operands = 1,

    .operands = {
      {
	.type = SYMBOL_REF,
	.offset = 8,
	.width  = 16,
	.encode = encode_symref,
      },
    },
  },

  {
    .mnemonic = "call.1ds",
    .size = INST_32,
    .pattern = (1 << 24) | INSN_ENC_32 | PCU_ITYPE_CALL_ABS | FU_PCU,
    .nr_operands = 1,

    .operands = {
      {
	.type = SYMBOL_REF,
	.offset = 8,
	.width  = 16,
	.encode = encode_symref,
      },
    },
  },

#if 0
  {
    .mnemonic = "call",
    .size = INST_16,
    .pattern = PCU_ITYPE_CALL_ABS | FU_PCU,
    .nr_operands = 1,

    .operands = {
      {
	.type = REG,
	.offset = 8,
	.width  = 3,
	.encode = encode_ptr,
      },
    },
  },

  {
    .mnemonic = "call.2ds",
    .size = INST_16,
    .pattern = (2 << 12) | PCU_ITYPE_CALL_ABS | FU_PCU,
    .nr_operands = 1,

    .operands = {
      {
	.type = REG,
	.offset = 8,
	.width  = 3,
	.encode = encode_ptr,
      },
    },
  },

  {
    .mnemonic = "call.1ds",
    .size = INST_16,
    .pattern = (1 << 12) | PCU_ITYPE_CALL_ABS | FU_PCU,
    .nr_operands = 1,

    .operands = {
      {
	.type = REG,
	.offset = 8,
	.width  = 3,
	.encode = encode_ptr,
      },
    },
  },
#endif
  {
    .mnemonic = "rets",
    .size = INST_16,
    .pattern = PCU_ITYPE_RETS | FU_PCU,
    .nr_operands = 0,
  },

  {
    .mnemonic = "rets.2ds",
    .size = INST_16,
    .pattern = (2 << 12) | PCU_ITYPE_RETS | FU_PCU,
    .nr_operands = 0,
  },

  {
    .mnemonic = "rets.1ds",
    .size = INST_16,
    .pattern = (1 << 12) | PCU_ITYPE_RETS | FU_PCU,
    .nr_operands = 0,
  },

  {
    .mnemonic = "reti",
    .size = INST_16,
    .pattern = PCU_ITYPE_RETI | FU_PCU,
    .nr_operands = 0,
  },

  {
    .mnemonic = "reti.2ds",
    .size = INST_16,
    .pattern = (2 << 12) | PCU_ITYPE_RETI | FU_PCU,
    .nr_operands = 0,
  },

  {
    .mnemonic = "reti.1ds",
    .size = INST_16,
    .pattern = (1 << 12) | PCU_ITYPE_RETI | FU_PCU,
    .nr_operands = 0,
  },

  {
    .mnemonic = "eint",
    .size = INST_16,
    .pattern = PCU_ITYPE_EINT | FU_PCU,
    .nr_operands = 0,
  },

  {
    .mnemonic = "dint",
    .size = INST_16,
    .pattern = PCU_ITYPE_DINT | FU_PCU,
    .nr_operands = 0,
  },

  {
    .mnemonic = "bkrep",
    .size = INST_32,
    .pattern = INSN_ENC_32 | PCU_ITYPE_BKREP | FU_PCU,
    .nr_operands = 1,

    .operands = {
      {
	.type   = SYMBOL_REF,
	.offset = 8,
	.width  = 16,
	.encode = encode_symref,
      },
    },
  },

  {
    .mnemonic = "halt",
    .size = INST_16,
    .pattern = PCU_ITYPE_HALT | FU_PCU,
    .nr_operands = 0,
  },

  /* EOL */
  {
    .mnemonic = NULL,
  }

};
