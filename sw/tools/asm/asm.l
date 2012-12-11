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

#include "asm.tab.h"
#include <string.h>
#include <assert.h>

static enum {initial, code, data, comment} current_state = initial, last_state = initial;
extern enum {code_sections, data_sections} lookfor_state;
int lineno = 1;

%}

%x COMMENT
%s CODE
%s DATA

%%


".code" {last_state = current_state; current_state = code; BEGIN CODE;}
".data" {last_state = current_state; current_state = data; BEGIN DATA;}

";#".*$       {lineno++;};
"/*" {last_state = current_state; current_state = comment; BEGIN COMMENT;}
<COMMENT>.    ;
<COMMENT>\n   {lineno++;};
<COMMENT>"*/" {
                current_state = last_state;

                switch(last_state) {
                case initial:
                  BEGIN INITIAL;
                  break;
                case code:
                  BEGIN CODE;
                  break;
                case data:
                  BEGIN DATA;
                  break;
                default:
                  assert(0);
                  break;
                }
              }

<CODE>"|" {if (lookfor_state == code_sections) return TOK_PIPE;}
<CODE>"," {if (lookfor_state == code_sections) return TOK_COMMA;}
<CODE>"(" {if (lookfor_state == code_sections) return TOK_PAR_OPEN;}
<CODE>")" {if (lookfor_state == code_sections) return TOK_PAR_CLOSE;}
<CODE>"if" {if (lookfor_state == code_sections) return TOK_IF;}
<CODE>"!"  {if (lookfor_state == code_sections) return TOK_NOT;}
<CODE>".align" {if (lookfor_state == code_sections) return TOK_ALIGN;}

<CODE>"$"[a-z0-9]+                  {if (lookfor_state == code_sections) {yylval.str  = strdup(&yytext[1]); return TOK_REGISTER;}}
<CODE>"#"[._0-9a-zA-Z]+             {if (lookfor_state == code_sections) {yylval.str  = strdup(&yytext[1]); return TOK_SYMBOL_REF;}}
<CODE>"-"?("0x"[0-9a-fA-F]+|[0-9]+) {if (lookfor_state == code_sections) {yylval.ival = strtol(yytext, NULL, 0); return TOK_INTEGER;}}
<CODE>[a-z][._0-9a-z]*              {if (lookfor_state == code_sections) {yylval.mnemonic.str = strdup(yytext); yylval.mnemonic.lineno = lineno; return TOK_MNEMONIC;}}
<CODE>^[._0-9a-zA-Z]+":"            {if (lookfor_state == code_sections) {yylval.str  = strdup(yytext); yylval.str[strlen(yylval.str) - 1] = '\0'; return TOK_LABEL;}}

<DATA>".dword" {if (lookfor_state == data_sections) {return TOK_DATA_DWORD;}}
<DATA>".word" {if (lookfor_state == data_sections) {return TOK_DATA_WORD;}}
<DATA>".skip" {if (lookfor_state == data_sections) {return TOK_DATA_SKIP;}}
<DATA>"-"?("0x"[0-9a-fA-F]+|[0-9]+) {if (lookfor_state == data_sections) {yylval.ival = strtol(yytext, NULL, 0); return TOK_DATA_INTEGER;}}
<DATA>"#"[._0-9a-zA-Z]+             {if (lookfor_state == data_sections) {yylval.str  = strdup(&yytext[1]); return TOK_DATA_SYMBOL_REF;}}
<DATA>^[._0-9a-zA-Z]+":"            {if (lookfor_state == data_sections) {yylval.str  = strdup(yytext); yylval.str[strlen(yylval.str) - 1] = '\0'; return TOK_DATA_LABEL;}}

[ \t]  ;  /* Ignore whitespace*/
[\n]  {lineno++;} ;
%%
