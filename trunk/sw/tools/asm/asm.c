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
#include "symtab.h"

#define DMEM_UNINIT_VALUE 0xdead;

#define PRED_NEG_BIT (1 << 28)

extern inst_def_t ajardsp_insns[];
extern char *outfile;
extern int option_fill_mems;

static int ignore_sym_refs = 0;

static uint16 imem[0x10000];
static uint16 imem_addr = 0;

static uint16 dmem[0x10000];
static uint16 dmem_addr = 0;

static FILE *lineno_fp;
struct {
  char *name;
  uint32 reg;
} SpecialRegs[] = {
  {"retpc", 1},
  {"sp", 2},
  {"satctrl", 3},
  {"mulsign", 4},

  {"masksel", 5},
  {"mask0",   6},
  {"mask1",   7},

  {"modsel",  8},
  {"mod0",    9},
  {"mod1",   10},
  {"bitrev", 11},

  {"retipc", 12},
  {"pred",   13},
  {"bkrepcnt",   14},

  {"gpio2",  30},
  {"gpio",   31},
  {NULL, 0}
};

Result_t encode_spec(operand_def_t *op_def_p, operand_t *op_p, uint32 *pattern_p)
{
  uint32 tmp_pattern;
  uint32 reg = 0xffffffff;
  int i;

  for (i = 0; SpecialRegs[i].name != NULL; i++) {
    if (0 == strcmp(op_p->name, SpecialRegs[i].name)) {
      reg = SpecialRegs[i].reg;
      break;
    }
  }

  if (reg > 64) {
    return RES_BAD;
  }

  tmp_pattern = *pattern_p;

  tmp_pattern |= (reg & ((1 << op_def_p->width) - 1)) << op_def_p->offset;

  *pattern_p = tmp_pattern;

  return RES_GOOD;
}


Result_t encode_acc(operand_def_t *op_def_p, operand_t *op_p, uint32 *pattern_p)
{
  uint32 tmp_pattern;
  uint32 reg;


  if (strncmp(op_p->name, "acc", 3)) {
    return RES_BAD;
  }
  reg = op_p->name[3] - '0';

  if (op_p->name[4] != '\0') {
    return RES_BAD;
  }

  tmp_pattern = *pattern_p;

  tmp_pattern |= (reg & ((1 << op_def_p->width) - 1)) << op_def_p->offset;

  *pattern_p = tmp_pattern;

  return RES_GOOD;
}


Result_t encode_acc_half(operand_def_t *op_def_p, operand_t *op_p, uint32 *pattern_p)
{
  uint32 tmp_pattern;
  uint32 reg;


  if (strncmp(op_p->name, "acc", 3)) {
    return RES_BAD;
  }
  reg = op_p->name[3] - '0';

  switch (op_p->name[4]) {
  case 'l':
    reg = (reg << 1) + 0;
    break;
  case 'h':
    reg = (reg << 1) + 1;
    break;
  default:
    return RES_BAD;
  }

  tmp_pattern = *pattern_p;

  tmp_pattern |= (reg & ((1 << op_def_p->width) - 1)) << op_def_p->offset;

  *pattern_p = tmp_pattern;

  return RES_GOOD;
}



Result_t encode_ptr(operand_def_t *op_def_p, operand_t *op_p, uint32 *pattern_p)
{
  uint32 tmp_pattern;
  uint32 reg;


  if (strncmp(op_p->name, "ptr", 3)) {
    return RES_BAD;
  }
  reg = op_p->name[3] - '0';

  tmp_pattern = *pattern_p;

  tmp_pattern |= (reg & ((1 << op_def_p->width) - 1)) << op_def_p->offset;

  *pattern_p = tmp_pattern;

  return RES_GOOD;
}

Result_t encode_pred(operand_def_t *op_def_p, operand_t *op_p, uint32 *pattern_p)
{
  uint32 tmp_pattern;
  uint32 reg;


  if (strncmp(op_p->name, "pred", 4)) {
    return RES_BAD;
  }
  reg = op_p->name[4] - '0';

  tmp_pattern = *pattern_p;

  tmp_pattern |= (reg & ((1 << op_def_p->width) - 1)) << op_def_p->offset;

  *pattern_p = tmp_pattern;

  return RES_GOOD;
}

Result_t encode_reg(operand_def_t *op_def_p, operand_t *op_p, uint32 *pattern_p)
{
  uint32 tmp_pattern;
  uint32 reg;


  if (0 == strncmp(op_p->name, "ptr", 3)) {
    reg = op_p->name[3] - '0';

    tmp_pattern = *pattern_p;

    tmp_pattern |= (reg & ((1 << op_def_p->width) - 1)) << op_def_p->offset;

    *pattern_p = tmp_pattern;

    return RES_GOOD;
  }
  else if (0 == strncmp(op_p->name, "acc", 3)) {

    reg = op_p->name[3] - '0';

    switch (op_p->name[4]) {
    case 'l':
      reg = (reg << 1) + 0;
      break;
    case 'h':
      reg = (reg << 1) + 1;
      break;
    default:
      return RES_BAD;
    }


    tmp_pattern = *pattern_p;

    tmp_pattern |= (reg & ((1 << op_def_p->width) - 1)) << op_def_p->offset;
    tmp_pattern |= (1 << (op_def_p->width - 1 + op_def_p->offset));

    *pattern_p = tmp_pattern;

    return RES_GOOD;
  }


  return RES_BAD;
}


Result_t encode_int(operand_def_t *op_def_p, operand_t *op_p, uint32 *pattern_p)
{
  uint32 tmp_pattern;

  tmp_pattern = *pattern_p;

  if (op_p->offset >= (1 << op_def_p->width)) {
    fprintf(stderr, "Integer out of range\n");
    return RES_BAD;
  }


  tmp_pattern |= (op_p->offset & ((1 << op_def_p->width) - 1)) << op_def_p->offset;

  *pattern_p = tmp_pattern;

  return RES_GOOD;
}

Result_t encode_symref(operand_def_t *op_def_p, operand_t *op_p, uint32 *pattern_p)
{
  uint32 tmp_pattern;
  uint32 address;

  if (ignore_sym_refs) {
    return RES_GOOD;
  }

  if (RES_GOOD == symtab_lookup(op_p->name, &address)) {

    tmp_pattern = *pattern_p;

    tmp_pattern |= (address & ((1 << op_def_p->width) - 1)) << op_def_p->offset;

    *pattern_p = tmp_pattern;

    return RES_GOOD;
  }
  else {
    return RES_BAD;
  }
}

int operand_match(inst_def_t *id_p, instruction_t *inst_p)
{
  int j;
  operand_t *op_p;

  op_p = inst_p->ops_p;

  for (j = 0; j < id_p->nr_operands; j++) {
    if (op_p && id_p->operands[j].type != op_p->type) {
      return RES_BAD;
    }

    op_p = op_p->next_p;
  }

  if (op_p == NULL) {
    return RES_GOOD;
  }
  else {
    return RES_BAD;
  }
}


int try_assemble_inst_bundle(inst_bundle_t *ib_p)
{
  instruction_t *inst_p;
  int total_size = 0;
  uint32 pattern;

  inst_p = ib_p->insts_p;

  while (inst_p) {
    int i;

    int inst_properly_encoded = 0;

    for (i = 0; ajardsp_insns[i].mnemonic; i++) {
      inst_def_t *id_p;
      id_p = &ajardsp_insns[i];

      if (0 == strcmp(id_p->mnemonic, inst_p->mnemonic) &&
	  RES_GOOD == operand_match(id_p, inst_p)) {

	operand_t *op_p;
	int op_idx;

	pattern = id_p->pattern;
	if (inst_p->next_p) {
	  /* Not last in VLIW bundle */
	  pattern |= (1 << PAR_BIT);
	}

	op_p = inst_p->ops_p;
	op_idx = 0;
	while (op_p) {
	  assert(id_p->operands[op_idx].encode);
	  if (RES_GOOD != id_p->operands[op_idx].encode(&id_p->operands[op_idx], op_p, &pattern)) {
	    goto encode_failure;
	  }

	  op_idx++;
	  op_p = op_p->next_p;
	}

        if (inst_p->pred) {
          if (0 == strncmp(inst_p->pred, "pred", 4)) {
            int reg;
            reg = atoi(&inst_p->pred[4]);
            if (inst_p->pred_neg) {
              pattern |= PRED_NEG_BIT;
            }
            pattern &= 0x3fffffff;
            pattern |= (reg & 0x3) << 30;
          }
          else {
            goto encode_failure;
          }
        }

	if (id_p->size == INST_32 || inst_p->pred) {
          pattern |= (1 << SIZE_BIT);
	  total_size += 2;
	  imem[imem_addr] = pattern & 0xffff;
	  imem[imem_addr+1] = pattern >> 16;
	  imem_addr += 2;
        }
	else if (id_p->size == INST_16) {
          pattern &= ~(1 << SIZE_BIT);
	  total_size += 1;
	  imem[imem_addr] = pattern & 0xffff;
	  imem_addr++;
        }
        else {
	  assert(0);
	}

	inst_properly_encoded = 1;
      }

    encode_failure:
      /**/;
    }

    if (!inst_properly_encoded) {
      fprintf(stderr, "Could not encode mnemonic '%s'\n", inst_p->mnemonic);
      return RES_BAD;
    }

    if (total_size > 4) {
      fprintf(stderr, "VLIW bundle size exceeded when trying to add menemonic '%s'\n", inst_p->mnemonic);
      return RES_BAD;
    }

    inst_p = inst_p->next_p;
  }

  return RES_GOOD;

}


void init(void)
{
  int i;
  for (i = 0; i < sizeof(dmem)/sizeof(dmem[0]); i++) {
    dmem[i] = DMEM_UNINIT_VALUE;
  }

  dmem_addr = 0;

  for (i = 0; i < sizeof(imem)/sizeof(imem[0]); i++) {
    imem[i] = 0;
  }

  imem_addr = 0;

  {
    char str[64];
    sprintf(str, "%s.lineno", outfile ? outfile : "out");
    lineno_fp = fopen(str, "w");
  }
}

void output_hex(void)
{
  int i;
  FILE *fp;
  char filename[256];


  sprintf(filename, "%s.dmem", outfile ? outfile : "out");

  fp = fopen(filename, "w");

  for (i = 0; i < (option_fill_mems ? sizeof(dmem)/sizeof(dmem[0]) : dmem_addr); i++) {
    fprintf(fp, "%04x\n", dmem[i]);
  }

  fclose(fp);


  sprintf(filename, "%s.imem", outfile ? outfile : "out");

  fp = fopen(filename, "w");

  for (i = 0; i < (option_fill_mems ? sizeof(imem)/sizeof(imem[0]) : imem_addr); i += 4) {
    fprintf(fp, "%04x%04x%04x%04x\n", imem[i+3], imem[i+2], imem[i+1], imem[i+0]);
  }

  fclose(fp);

  sprintf(filename, "%s.map", outfile ? outfile : "out");
  symtab_output_mapfile(filename);

}


int asm_do_pass_0(inst_bundle_t *ib_p, data_element_t *data_p)
{

  while (data_p) {
    if (data_p->label) {
      symtab_add(data_p->label, dmem_addr);
    }
    else {
      if (data_p->skip_length) {
        dmem_addr += data_p->skip_length;
      }
      else {
        dmem_addr++;
      }
    }

    data_p = data_p->next_p;
  }

  while (ib_p) {

    if (ib_p->label) {
      symtab_add(ib_p->label, imem_addr);
    }
    else if (ib_p->align) {
      imem_addr += ib_p->align - 1;
      imem_addr &= ~(ib_p->align - 1);
    }
    else {
      if (RES_GOOD != try_assemble_inst_bundle(ib_p)) {
        fprintf(stderr, "Assemble failure for instruction packet starting around line: %d\n", ib_p->insts_p->lineno);
        exit(1);
      }
    }

    ib_p = ib_p->next_p;
  }

  return RES_GOOD;
}


int asm_do_pass_1(inst_bundle_t *ib_p, data_element_t *data_p)
{

  while (data_p) {
    if (data_p->label) {
      /* do nothing */
    }
    else {
      if (data_p->skip_length) {
        int i;
        for (i = 0; i < data_p->skip_length; i++) {
          dmem[dmem_addr++] = DMEM_UNINIT_VALUE;
        }
      }
      else {
        if (data_p->symref) {
          int symvalue;
          if (RES_GOOD == symtab_lookup(data_p->symref, &symvalue)) {
            dmem[dmem_addr++] = symvalue;
          }
          else {
            fprintf(stderr, "Unknown .data symbol reference for '%s'\n", data_p->symref);
            exit(1);
          }
        }
        else {
          dmem[dmem_addr++] = data_p->value;
        }
      }
    }

    data_p = data_p->next_p;
  }


  while (ib_p) {

    if (ib_p->label) {
      /* Do nothing */
      fprintf(lineno_fp, "\n<%s>:\n", ib_p->label);

    }
    else if (ib_p->align) {
      int i;
      int nops_to_add;
      int aligned_imem_addr;

      aligned_imem_addr = imem_addr + ib_p->align - 1;
      aligned_imem_addr &= ~(ib_p->align - 1);

      nops_to_add = aligned_imem_addr - imem_addr;

      if (nops_to_add > 0) {
        for (i = 0; i < nops_to_add - 1; i++) {
          imem[imem_addr++] = 0x0001;  /* nop with par bit set */
        }
        imem[imem_addr++] = 0x0000;  /* nop without par bit set */
      }
    }
    else {
      fprintf(lineno_fp, "0x%04X:%d\t%s\n", imem_addr, ib_p->insts_p->lineno, ib_p->insts_p->mnemonic);
      if (RES_GOOD != try_assemble_inst_bundle(ib_p)) {
        fprintf(stderr, "Assemble failure for instruction packet starting around line: %d\n", ib_p->insts_p->lineno);
        exit(1);
      }
    }

    ib_p = ib_p->next_p;
  }

  return RES_GOOD;
}

extern data_element_t *data_section_p;

int asm_gen_opcodes(inst_bundle_t *ib_p)
{
  imem_addr = 0;
  dmem_addr = 0;
  ignore_sym_refs = 1;
  asm_do_pass_0(ib_p, data_section_p);
  ignore_sym_refs = 0;

  imem_addr = 0;
  dmem_addr = 0;

  asm_do_pass_1(ib_p, data_section_p);

  output_hex();

  return RES_GOOD;
}

