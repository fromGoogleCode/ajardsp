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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symtab.h"

static symtab_entry_t *symtab_p = NULL;

void symtab_add(char *name, uint32 address)
{
  symtab_entry_t *node_p;
  node_p = calloc(1, sizeof(symtab_entry_t));

  node_p->name = strdup(name);
  node_p->address = address;

  node_p->next_p = symtab_p;
  symtab_p = node_p;
}

Result_t symtab_lookup(char *name, uint32 *address_p)
{
  symtab_entry_t *node_p;

  node_p = symtab_p;

  while (node_p) {
    if (0 == strcmp(node_p->name, name)) {
      *address_p = node_p->address;
      return RES_GOOD;
    }

    node_p = node_p->next_p;
  }

  *address_p = 0;

  return RES_BAD;
}

void symtab_output_mapfile(char *mapfile)
{
  symtab_entry_t *node_p;
  FILE *fp;

  fp = fopen(mapfile, "w");

  node_p = symtab_p;

  while (node_p) {

    fprintf(fp, "%-32s 0x%04x\n", node_p->name, node_p->address);

    node_p = node_p->next_p;
  }

  fclose(fp);
}
