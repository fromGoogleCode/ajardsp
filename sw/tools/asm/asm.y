%{
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
#include <string.h>
#include <stdio.h>
#include <assert.h>
#include "asm.h"

inst_bundle_t *code_section_p = NULL;
data_element_t *data_section_p = NULL;
extern int lineno;
%}

%union {
  struct {char *str; int lineno;} mnemonic;
  int ival;
  char *str;
  void *op_p;
  void *inst_p;
  void *inst_bundle_p;
  void *data_element_p;
}

%token TOK_PIPE
%token TOK_COMMA
%token TOK_PAR_OPEN
%token TOK_PAR_CLOSE
%token TOK_IF
%token TOK_NOT
%token TOK_ALIGN

%token <ival> TOK_DATA_DWORD
%token <ival> TOK_INTEGER
%token <mnemonic>  TOK_MNEMONIC
%token <str>  TOK_REGISTER
%token <str>  TOK_SYMBOL_REF
%token <str>  TOK_LABEL

%token TOK_DATA_WORD
%token TOK_DATA_SKIP

%token <ival> TOK_DATA_INTEGER
%token <str>  TOK_DATA_SYMBOL_REF
%token <str>  TOK_DATA_LABEL


%type <op_p> operand;
%type <op_p> operand_list;
%type <inst_p> instruction;
%type <inst_p> instruction_list;
%type <inst_bundle_p> inst_bundle;
%type <inst_bundle_p> inst_bundle_list;

%type <data_element_p> data_element;
%type <data_element_p> data_element_list;

%%

program: data_section code_section
       | code_section
       | data_section
       ;

code_section: inst_bundle_list
            {
              code_section_p = $1;
            }
            ;

inst_bundle_list: inst_bundle
                {
                  $$ = $1;
                }
                | inst_bundle_list inst_bundle
                {
                  inst_bundle_t *tmp_inst_bundle_p = $1;
                  while (tmp_inst_bundle_p->next_p) {
                    tmp_inst_bundle_p = tmp_inst_bundle_p->next_p;
                  }
                  tmp_inst_bundle_p->next_p = $2;
                }
		;

inst_bundle: instruction_list
           {
             inst_bundle_t *inst_bundle_p = calloc(1, sizeof(inst_bundle_t));
             inst_bundle_p->insts_p = $1;
             $$ = inst_bundle_p;
           }
           | TOK_LABEL
           {
             inst_bundle_t *inst_bundle_p = calloc(1, sizeof(inst_bundle_t));
             inst_bundle_p->label = $1;
             $$ = inst_bundle_p;
           }
           | TOK_ALIGN TOK_INTEGER
           {
             inst_bundle_t *inst_bundle_p = calloc(1, sizeof(inst_bundle_t));
             inst_bundle_p->align = $2;
             $$ = inst_bundle_p;
           }

	   ;

instruction_list: instruction
                {
                  $$ = $1;
                }
		| instruction_list TOK_PIPE instruction
                {
                  instruction_t *tmp_inst_p = $1;
                  while (tmp_inst_p->next_p) {
                    tmp_inst_p = tmp_inst_p->next_p;
                  }
                  tmp_inst_p->next_p = $3;
                }
                ;

instruction: TOK_MNEMONIC operand_list
           {
             instruction_t *inst_p = calloc(1, sizeof(instruction_t));
             inst_p->pred = NULL;
             inst_p->mnemonic = $1.str;
             inst_p->ops_p = $2;
             inst_p->lineno = $1.lineno;
             $$ = inst_p;
           }
	   | TOK_MNEMONIC
           {
             instruction_t *inst_p = calloc(1, sizeof(instruction_t));
             inst_p->pred = NULL;
             inst_p->mnemonic = $1.str;
             inst_p->lineno = $1.lineno;
             $$ = inst_p;
           }
           | TOK_IF TOK_PAR_OPEN TOK_REGISTER TOK_PAR_CLOSE TOK_MNEMONIC operand_list
           {
             instruction_t *inst_p = calloc(1, sizeof(instruction_t));
             inst_p->pred = $3;
             inst_p->mnemonic = $5.str;
             inst_p->ops_p = $6;
             inst_p->lineno = $5.lineno;
             $$ = inst_p;
           }
	   | TOK_IF TOK_PAR_OPEN TOK_REGISTER TOK_PAR_CLOSE TOK_MNEMONIC
           {
             instruction_t *inst_p = calloc(1, sizeof(instruction_t));
             inst_p->pred = $3;
             inst_p->mnemonic = $5.str;
             inst_p->lineno = $5.lineno;
             $$ = inst_p;
           }
           | TOK_IF TOK_PAR_OPEN TOK_NOT TOK_REGISTER TOK_PAR_CLOSE TOK_MNEMONIC operand_list
           {
             instruction_t *inst_p = calloc(1, sizeof(instruction_t));
             inst_p->pred = $4;
             inst_p->pred_neg = 1;
             inst_p->mnemonic = $6.str;
             inst_p->ops_p = $7;
             inst_p->lineno = $6.lineno;
             $$ = inst_p;
           }
	   | TOK_IF TOK_PAR_OPEN TOK_NOT TOK_REGISTER TOK_PAR_CLOSE TOK_MNEMONIC
           {
             instruction_t *inst_p = calloc(1, sizeof(instruction_t));
             inst_p->pred = $4;
             inst_p->pred_neg = 1;
             inst_p->mnemonic = $6.str;
             inst_p->lineno = $6.lineno;
             $$ = inst_p;
           }
	   ;

operand_list: operand
            {
              $$ = $1;
            }
	    | operand_list TOK_COMMA operand
            {
              operand_t *tmp_op_p = $1;
              while (tmp_op_p->next_p) {
                tmp_op_p = tmp_op_p->next_p;
              }
              tmp_op_p->next_p = $3;
            }
	    ;

operand: TOK_REGISTER
       {
         operand_t *op_p = calloc(1, sizeof(operand_t));
         op_p->type = REG;
         op_p->name = $1;
         $$ = op_p;
       }
       | TOK_REGISTER TOK_PAR_OPEN TOK_INTEGER TOK_PAR_CLOSE
       {
         operand_t *op_p, *op2_p;
         op_p = calloc(1, sizeof(operand_t));
         op_p->type = REG;
         op_p->name = $1;
         op2_p = calloc(1, sizeof(operand_t));
         op2_p->type = INTEGER;
         op2_p->offset = $3;
         op_p->next_p = op2_p;
         $$ = op_p;
       }
       | TOK_INTEGER
       {
         operand_t *op_p = calloc(1, sizeof(operand_t));
         op_p->type = INTEGER;
         op_p->offset = $1;
         $$ = op_p;
       }
       | TOK_SYMBOL_REF
       {
         operand_t *op_p = calloc(1, sizeof(operand_t));
         op_p->type = SYMBOL_REF;
         op_p->name = $1;
         $$ = op_p;
       }
       ;


data_section: data_element_list {data_section_p = $1;}

data_element_list: data_element
                 {
                   $$ = $1;
                 }
                 | data_element_list data_element
                 {
                   data_element_t *tmp_data_p = $1;
                   while (tmp_data_p->next_p) {
                     tmp_data_p = tmp_data_p->next_p;
                   }
                   tmp_data_p->next_p = $2;
                 }
                 ;

data_element: TOK_DATA_SKIP TOK_DATA_INTEGER
            {
              data_element_t *data_p = calloc(1, sizeof(data_element_t));
              data_p->skip_length = $2;
              $$ = data_p;
            }
            | TOK_DATA_WORD TOK_DATA_INTEGER
            {
              data_element_t *data_p = calloc(1, sizeof(data_element_t));
              data_p->value = $2;
              $$ = data_p;
            }
            | TOK_DATA_WORD TOK_DATA_SYMBOL_REF
            {
              data_element_t *data_p = calloc(1, sizeof(data_element_t));
              data_p->symref = $2;
              $$ = data_p;
            }
            | TOK_DATA_DWORD TOK_DATA_INTEGER
            {
              data_element_t *data_p = calloc(1, sizeof(data_element_t));
              data_p->value = $2;
              $$ = data_p;
            }
            | TOK_DATA_LABEL
            {
              data_element_t *data_p = calloc(1, sizeof(data_element_t));
              data_p->label = $1;
              $$ = data_p;
            }
            ;


%%

extern char *yytext;
extern FILE *yyin;
char *outfile;
char *inputfile;
int option_fill_mems = 0;

enum {code_sections, data_sections} lookfor_state = code_sections;

yyerror(const char *msg)
{
  fprintf(stderr, "%s:%d: %s around '%s'\n", inputfile, lineno, msg, yytext);
}

void print_usage(void)
{
  fprintf(stderr, "Usage: ajardsp-asm [-o=outfile] [-fill-mem] file\n");
  exit(1);
}

int main(int argc, char **argv)
{
  int i;

  yyin = NULL;

  outfile = NULL;

  for (i = 1; i < argc; i++) {

    if (argv[i][0] == '-') {

      if (argv[i][1] == 'o' && argv[i][2] == '=') {
        outfile = strdup(&argv[i][3]);
      }
      else if (!strcmp(&argv[i][1], "fill-mem")) {
        option_fill_mems = 1;
      }

      else {
        print_usage();
      }

    }
    else {
      inputfile = argv[i];
      yyin = fopen(inputfile, "r");
      if (yyin == NULL) {
        fprintf(stderr, "%s: Failed to open assembly file '%s'\n", argv[0], inputfile);
        exit(1);
      }
    }
  }

  if (yyin == NULL) {
    print_usage();
  }

  init();

  /* Parse twice; once for .code sections and once for .data sections */

  lookfor_state = code_sections;
  lineno = 1;
  if (yyparse() == 0) {
    rewind(yyin);
    lookfor_state = data_sections;
    lineno = 1;
    if (yyparse() == 0) {
      inst_bundle_t *ib_p = code_section_p;

      if (RES_GOOD == asm_gen_opcodes(ib_p)) {
        return 0;
      }
    }
  }

  return -1;
}
