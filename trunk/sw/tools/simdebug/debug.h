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

#ifndef DEBUG_H__
#define DEBUG_H__

#include <gtk/gtk.h>
#include <glib.h>

#include "vpi_user.h"
#include "cv_vpi_user.h"

#define LDM_SIZE 0x10000/16

typedef struct {
  char* path;
  char* name;
  int index;
  vpiHandle obj;
  GtkTreeIter* Iter_p;
  int CurrValue;
  int PrevValue;
} Reg_t;

#define MAX_PIPE_STAGES 5

typedef struct {
  char* Name_p;
  int NbrOfPipeStages;
  struct {
    char* PipeStageDesc_p;
    char* PipeStageRegPath_p;
    GtkWidget* RegLabel_p;
  } PipeStages[MAX_PIPE_STAGES];
} FuDesc_t;


void RegInitializeRegisters(Reg_t* Regs_p, int RegsLength);
void MemInitializeMemory(int MemLength);

void RegisterGuiUpdate(Reg_t* Reg_p);
void MemoryGuiUpdate(int Address, int Value);
void UpdateMemoryInDesign(int Address, int NewValue);

void WaitForGUI();
void UpdateCycleCount(int CurrentCycles);

void RegUpdateValueInDesign(char* RegName_p, int NewValue);


#endif
