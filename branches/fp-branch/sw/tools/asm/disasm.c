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
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include "asm.h"
#include "basictypes.h"

extern inst_def_t ajardsp_insns[];

/* Fake implementations (otherwise we get unresolved symbols from ajardsp_insn.c) */
Result_t encode_spec(operand_def_t *op_def_p, operand_t *op_p, uint32 *pattern_p){return RES_BAD;}
Result_t encode_acc(operand_def_t *op_def_p, operand_t *op_p, uint32 *pattern_p){return RES_BAD;}
Result_t encode_acc_half(operand_def_t *op_def_p, operand_t *op_p, uint32 *pattern_p){return RES_BAD;}
Result_t encode_ptr(operand_def_t *op_def_p, operand_t *op_p, uint32 *pattern_p){return RES_BAD;}
Result_t encode_pred(operand_def_t *op_def_p, operand_t *op_p, uint32 *pattern_p){return RES_BAD;}
Result_t encode_reg(operand_def_t *op_def_p, operand_t *op_p, uint32 *pattern_p){return RES_BAD;}
Result_t encode_int(operand_def_t *op_def_p, operand_t *op_p, uint32 *pattern_p){return RES_BAD;}
Result_t encode_symref(operand_def_t *op_def_p, operand_t *op_p, uint32 *pattern_p){return RES_BAD;}


Result_t disasm(uint32 insn_word, char* buf_p)
{
  uint32 mask;
  uint32 pattern;
  uint32 is32bits;
  int i;
  int j;

  /* Remove the parallel bit */
  insn_word &= ~(1 << PAR_BIT);

  /* For now also remove the predicate bits */
  insn_word &= 0x3FFFFFFF;

  if (insn_word & (1 << SIZE_BIT)) {
    /* 32 bit insn so do nothing */
    is32bits = 1;
  }
  else {
    /* 16 high bits are not part of this insn */
    insn_word &= 0x0000FFFF;
    is32bits = 0;
  }

  for (i = 0; ajardsp_insns[i].mnemonic; i++) {

    inst_def_t* insn_def_p = &ajardsp_insns[i];

    /* Build compare mask for inst_def */
    mask = 0;
    for (j = 0; j < insn_def_p->nr_operands; j++) {
      mask |= ((1 << insn_def_p->operands[j].width) - 1) << insn_def_p->operands[j].offset;
    }
    mask = ~mask;

    pattern = insn_def_p->pattern;
    if (insn_def_p->size == INST_32) {
      pattern |= (1 << SIZE_BIT);
    }

    if ((insn_word & mask) == pattern) {
      sprintf(buf_p, "%s", insn_def_p->mnemonic);
      return RES_GOOD;
    }
  }

  return RES_BAD;
}
