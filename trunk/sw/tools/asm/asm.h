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

#ifndef ASM_H__
#define ASM_H__

#include "basictypes.h"

#define MAX_OPERANDS 8

#define PAR_BIT 0
#define SIZE_BIT 1



enum operand_type {REG, REG_WITH_OFFSET, INTEGER, SYMBOL_REF};

typedef struct operand {
  enum operand_type type;
  char *name;
  int offset;
  struct operand *next_p;
} operand_t;

typedef struct instruction {
  char *pred;
  int pred_neg;
  char *mnemonic;
  operand_t *ops_p;
  int lineno;
  struct instruction *next_p;
} instruction_t;

typedef struct inst_bundle {
  instruction_t *insts_p;
  char *label;
  int align;
  struct inst_bundle *next_p;
} inst_bundle_t;

typedef struct data_element {
  char *label;
  char *symref;
  int value;
  int skip_length;
  struct data_element *next_p;
} data_element_t;

typedef enum {RES_GOOD, RES_BAD} Result_t;



/* For instruction definition */

typedef struct operand_def {
  enum operand_type type;
  uint32 offset;
  uint32 width;
  Result_t (*encode)(struct operand_def *, operand_t *, uint32 *);

} operand_def_t;

typedef struct inst_def {
  char *mnemonic;
  int nr_operands;
  uint32 pattern;
  enum {INST_16, INST_32} size;
  operand_def_t operands[MAX_OPERANDS];

} inst_def_t;

Result_t encode_spec(operand_def_t *op_def_p, operand_t *op_p, uint32 *pattern_p);
Result_t encode_acc(operand_def_t *op_def_p, operand_t *op_p, uint32 *pattern_p);
Result_t encode_acc_half(operand_def_t *op_def_p, operand_t *op_p, uint32 *pattern_p);
Result_t encode_ptr(operand_def_t *op_def_p, operand_t *op_p, uint32 *pattern_p);
Result_t encode_pred(operand_def_t *op_def_p, operand_t *op_p, uint32 *pattern_p);
Result_t encode_reg(operand_def_t *op_def_p, operand_t *op_p, uint32 *pattern_p);
Result_t encode_int(operand_def_t *op_def_p, operand_t *op_p, uint32 *pattern_p);
Result_t encode_symref(operand_def_t *op_def_p, operand_t *op_p, uint32 *pattern_p);

Result_t disasm(uint32 insn_word, char* buf_p);

#endif
