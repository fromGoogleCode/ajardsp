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
#include <gtk/gtk.h>
#include <glib.h>
#include <pthread.h>
#include "debug.h"
#include "asm.h"

enum
{
  COL_REG_NAME = 0,
  COL_REG_VALUE,
  NUM_COLS
};

static GtkListStore* RegListStore_p = NULL;
static GtkListStore* MemListStore_p = NULL;
static GtkWidget *CycleLabel = NULL;

extern int MemoryCurr[];
extern int MemoryPrev[];

#if STANDALONE
Reg_t RegsOfInterest[] = {
  {"testbench.ajardsp_0.pcu_0.pc_i", "pc", -1, NULL},

  {"testbench.ajardsp_0.ptrrf_0.ptr_regs", "$ptr0", 0, NULL},
  {"testbench.ajardsp_0.ptrrf_0.ptr_regs", "$ptr1", 1, NULL},
  {"testbench.ajardsp_0.ptrrf_0.ptr_regs", "$ptr2", 2, NULL},
  {"testbench.ajardsp_0.ptrrf_0.ptr_regs", "$ptr3", 3, NULL},
  {"testbench.ajardsp_0.ptrrf_0.ptr_regs", "$ptr4", 4, NULL},
  {"testbench.ajardsp_0.ptrrf_0.ptr_regs", "$ptr5", 5, NULL},
  {"testbench.ajardsp_0.ptrrf_0.ptr_regs", "$ptr6", 6, NULL},
  {"testbench.ajardsp_0.ptrrf_0.ptr_regs", "$ptr7", 7, NULL},

  {"testbench.ajardsp_0.accrf_0.acc_regs_low", "$acc0l", 0, NULL},
  {"testbench.ajardsp_0.accrf_0.acc_regs_high", "$acc0h", 0, NULL},
  {"testbench.ajardsp_0.accrf_0.acc_regs_low", "$acc1l", 1, NULL},
  {"testbench.ajardsp_0.accrf_0.acc_regs_high", "$acc1h", 1, NULL},
  {"testbench.ajardsp_0.accrf_0.acc_regs_low", "$acc2l", 2, NULL},
  {"testbench.ajardsp_0.accrf_0.acc_regs_high", "$acc2h", 2, NULL},
  {"testbench.ajardsp_0.accrf_0.acc_regs_low", "$acc3l", 3, NULL},
  {"testbench.ajardsp_0.accrf_0.acc_regs_high", "$acc3h", 3, NULL},
  {"testbench.ajardsp_0.accrf_0.acc_regs_low", "$acc4l", 4, NULL},
  {"testbench.ajardsp_0.accrf_0.acc_regs_high", "$acc4h", 4, NULL},
  {"testbench.ajardsp_0.accrf_0.acc_regs_low", "$acc5l", 5, NULL},
  {"testbench.ajardsp_0.accrf_0.acc_regs_high", "$acc5h", 5, NULL},
  {"testbench.ajardsp_0.accrf_0.acc_regs_low", "$acc6l", 6, NULL},
  {"testbench.ajardsp_0.accrf_0.acc_regs_high", "$acc6h", 6, NULL},
  {"testbench.ajardsp_0.accrf_0.acc_regs_low", "$acc7l", 7, NULL},
  {"testbench.ajardsp_0.accrf_0.acc_regs_high", "$acc7h", 7, NULL},

};

#else
extern Reg_t RegsOfInterest[];
#endif

void RegInitializeRegisters(Reg_t* Regs_p, int RegsLength)
{
  int i;

  gdk_threads_enter();
  for (i = 0; i < RegsLength; i++) {
    Regs_p[i].Iter_p = malloc(sizeof(GtkTreeIter));
    gtk_list_store_append(RegListStore_p, Regs_p[i].Iter_p);
    gtk_list_store_set(RegListStore_p, Regs_p[i].Iter_p,
                       COL_REG_NAME, i,
                       -1);

  }
  gdk_threads_leave();
}

GtkTreeIter* MemoryIters_p[LDM_SIZE/8];

void MemInitializeMemory(int MemLength)
{
  int i;
  int j;
  GtkTreeIter* Iter_p;

  gdk_threads_enter();
  for (i = 0; i < MemLength; i += 8) {
    Iter_p = malloc(sizeof(GtkTreeIter));
    MemoryIters_p[i/8] = Iter_p;
    gtk_list_store_append(MemListStore_p, Iter_p);

    gtk_list_store_set(MemListStore_p, Iter_p,
                       0, i,
                       -1);

    for (j = 0; j < 8; j++) {
      gtk_list_store_set(MemListStore_p, Iter_p,
                         1 + j, i + j,
                         -1);
    }

  }
  gdk_threads_leave();
}

static void
Memory_DataFunc(GtkTreeViewColumn *col,
                GtkCellRenderer   *renderer,
                GtkTreeModel      *model,
                GtkTreeIter       *iter,
                gpointer           user_data)
{

  gchar* RegValueStr_p;
  int ColumnIndex = (int)user_data;
  int MemRowAddr;
  int MemAddr;
  Reg_t* Reg_p;

  gtk_tree_model_get(model, iter, 0, &MemRowAddr, -1);

  if (ColumnIndex == 0) {
    gchar buf[16];
    sprintf(buf, "0x%04X", MemRowAddr);
    g_object_set(renderer, "foreground-set", FALSE, NULL); /* print this normal */
    g_object_set(renderer, "background", "Gray", "background-set", TRUE, NULL);
    g_object_set(renderer, "text", buf, NULL);
  }
  else {
    gchar buf[16];
    int MemValue;
    gtk_tree_model_get(model, iter, ColumnIndex, &MemValue, -1);

    MemAddr = MemRowAddr + (ColumnIndex - 1);

    sprintf(buf, "%04X", MemoryCurr[MemAddr]);

    if (MemoryCurr[MemAddr] == MemoryPrev[MemAddr]) {
      g_object_set(renderer, "foreground-set", FALSE, NULL);
    }
    else {
      g_object_set(renderer, "foreground", "Red", "foreground-set", TRUE, NULL);
    }
    g_object_set(renderer, "text", buf, NULL);
  }

}

void PipelineGuiUpdate(FuDesc_t* FuDesc_p)
{
  int i;
  char buf[64];
  unsigned int RegValue;
  gdk_threads_enter();

  for (i = 0; i < FuDesc_p->NbrOfPipeStages; i++) {
    RegValue = SimReadReg(FuDesc_p->PipeStages[i].PipeStageRegPath_p);
    if (RES_GOOD == disasm(RegValue, buf)) {
      char buf2[64];
      if (0 == strcmp("nop", buf)) {
        sprintf(buf2, "<span foreground='#7F0000'>%s</span>", buf);
      }
      else {
        sprintf(buf2, "<span foreground='#FF0000'>%s</span>", buf);
      }
      gtk_label_set_markup(GTK_LABEL(FuDesc_p->PipeStages[i].RegLabel_p),
                           buf2);
    }
    else {
      sprintf(buf, "<%08X>", RegValue);
      gtk_label_set_text(GTK_LABEL(FuDesc_p->PipeStages[i].RegLabel_p),
                         buf);
    }
  }

  gdk_threads_leave();
}

void RegisterGuiUpdate(Reg_t* Reg_p)
{
  int i;

  gdk_threads_enter();
  gtk_list_store_set(RegListStore_p, Reg_p->Iter_p,
                     COL_REG_VALUE, Reg_p->CurrValue,
                     -1);
  gdk_threads_leave();
}

void MemoryGuiUpdate(int Address, int Value)
{
  int RowAddress;
  int ColAddress;

  RowAddress = Address / 8;
  ColAddress = Address - RowAddress * 8;

  /*  fprintf(stderr, "MemoryGuiUpdate: RowAddress: %d, ColAddress: %d: Address: %d, Value: 0x%04X\n", RowAddress, ColAddress, Address, Value); */

  gdk_threads_enter();
  gtk_list_store_set(MemListStore_p, MemoryIters_p[RowAddress],
                     1 + ColAddress, Value,
                     -1);
  gdk_threads_leave();
}


static void
Registers_DataFunc(GtkTreeViewColumn *col,
                             GtkCellRenderer   *renderer,
                             GtkTreeModel      *model,
                             GtkTreeIter       *iter,
                             gpointer           user_data)
{

  gchar* RegValueStr_p;
  int ColumnIndex = (int)user_data;
  int RegNameIndex;
  Reg_t* Reg_p;

  gtk_tree_model_get(model, iter, COL_REG_NAME, &RegNameIndex, -1);

  Reg_p = &RegsOfInterest[RegNameIndex];

  if (ColumnIndex == COL_REG_NAME) {
    g_object_set(renderer, "foreground-set", FALSE, NULL);
    g_object_set(renderer, "background", "Gray", "background-set", TRUE, NULL);

    g_object_set(renderer, "text", Reg_p->name, NULL);
  }
  else if (ColumnIndex == COL_REG_VALUE) {
    gchar buf[16];
    int RegValue;
    gtk_tree_model_get(model, iter, COL_REG_VALUE, &RegValue, -1);

    sprintf(buf, "0x%04X", RegValue);

    if (Reg_p->CurrValue == Reg_p->PrevValue) {
      g_object_set(renderer, "foreground-set", FALSE, NULL);
    }
    else {
      g_object_set(renderer, "foreground", "Red", "foreground-set", TRUE, NULL);
    }

    g_object_set(renderer, "text", buf, NULL);
  }

}

static void
RegValueEdited(GtkCellRendererText *cell,
               const gchar         *path_string,
               const gchar         *new_text,
               gpointer             data)
{
  GtkTreeModel *model = (GtkTreeModel *)data;
  GtkTreePath *path = gtk_tree_path_new_from_string (path_string);
  GtkTreeIter iter;
  int NewValue;
  int RegNameIndex;
  gchar* RegName_p;

  gint column = GPOINTER_TO_INT (g_object_get_data (G_OBJECT (cell), "column"));

  NewValue = strtoul(new_text, NULL, 0);

  gtk_tree_model_get_iter (model, &iter, path);
  gtk_list_store_set(RegListStore_p, &iter,
                     COL_REG_VALUE, NewValue,
                     -1);

  gtk_tree_model_get(model, &iter, COL_REG_NAME, &RegNameIndex, -1);


  RegName_p = RegsOfInterest[RegNameIndex].name;

  fprintf(stderr, "Register cell edited: %s = 0x%04X\n", RegName_p, NewValue);

#ifndef STANDALONE
  RegUpdateValueInDesign(RegName_p, NewValue);
#endif
}



static GtkWidget *
CreateRegisterViewAndModel(void)
{
  GtkTreeViewColumn   *col;
  GtkCellRenderer     *renderer;
  GtkWidget           *treeview;
  GtkTreeModel        *model;

  treeview = gtk_tree_view_new();

  gtk_tree_view_set_enable_search(GTK_TREE_VIEW(treeview), FALSE);

  RegListStore_p = gtk_list_store_new(NUM_COLS,
                                      G_TYPE_INT,
                                      G_TYPE_INT);

  model = GTK_TREE_MODEL(RegListStore_p);

  gtk_tree_view_set_model(GTK_TREE_VIEW(treeview), model);

  /* Register Name column*/
  renderer = gtk_cell_renderer_text_new ();
  g_object_set_data (G_OBJECT (renderer), "column", GINT_TO_POINTER (COL_REG_NAME));

  gtk_tree_view_insert_column_with_attributes (GTK_TREE_VIEW (treeview),
                                               -1, "Register", renderer,
                                               "text", COL_REG_NAME,
                                               NULL);

  col = gtk_tree_view_get_column(GTK_TREE_VIEW(treeview), COL_REG_NAME);
  gtk_tree_view_column_set_cell_data_func(col, renderer, Registers_DataFunc,
                                          GINT_TO_POINTER(COL_REG_NAME), NULL);


  /* Register Value column*/
  renderer = gtk_cell_renderer_text_new ();

  g_object_set (renderer,
                "editable", TRUE,
                NULL);
  g_signal_connect (renderer, "edited",
                    G_CALLBACK(RegValueEdited), model);
  g_object_set_data (G_OBJECT(renderer), "column", GINT_TO_POINTER(COL_REG_VALUE));

  gtk_tree_view_insert_column_with_attributes (GTK_TREE_VIEW (treeview),
                                               -1, "Value", renderer,
                                               "text", COL_REG_VALUE,
                                               NULL);
  col = gtk_tree_view_get_column(GTK_TREE_VIEW(treeview), COL_REG_VALUE);
  gtk_tree_view_column_set_cell_data_func(col, renderer, Registers_DataFunc,
                                          GINT_TO_POINTER(COL_REG_VALUE), NULL);

  return treeview;
}

static void
MemValueEdited(GtkCellRendererText *cell,
               const gchar         *path_string,
               const gchar         *new_text,
               gpointer             data)
{
  GtkTreeModel *model = (GtkTreeModel *)data;
  GtkTreePath *path = gtk_tree_path_new_from_string (path_string);
  GtkTreeIter iter;
  int NewValue;
  int RegNameIndex;
  gchar* RegName_p;
  int RowAddress;
  int Address;

  gint column = GPOINTER_TO_INT (g_object_get_data (G_OBJECT (cell), "column"));

  NewValue = strtoul(new_text, NULL, 16);

  gtk_tree_model_get_iter (model, &iter, path);


  gtk_list_store_set(MemListStore_p, &iter,
                     column, NewValue,
                     -1);

  gtk_tree_model_get(model, &iter, 0, &RowAddress, -1);
  Address = RowAddress + (column - 1);

  fprintf(stderr, "DMEM[0x%04X] = 0x%04X\n", Address, NewValue);

  UpdateMemoryInDesign(Address, NewValue);
}

static GtkWidget *
CreateMemoryViewAndModel(void)
{
  GtkTreeViewColumn   *col;
  GtkCellRenderer     *renderer;
  GtkWidget           *treeview;
  GtkTreeModel        *model;
  gchar                buf[64];
  int                  i;

  treeview = gtk_tree_view_new();

  gtk_tree_view_set_enable_search(GTK_TREE_VIEW(treeview), FALSE);

  MemListStore_p = gtk_list_store_new(8 + 1,
                                      G_TYPE_INT,
                                      G_TYPE_INT, G_TYPE_INT,
                                      G_TYPE_INT, G_TYPE_INT,
                                      G_TYPE_INT, G_TYPE_INT,
                                      G_TYPE_INT, G_TYPE_INT);

  model = GTK_TREE_MODEL(MemListStore_p);

  gtk_tree_view_set_model(GTK_TREE_VIEW(treeview), model);

  /* Memory address column */
  renderer = gtk_cell_renderer_text_new ();
  g_object_set_data (G_OBJECT (renderer), "column", GINT_TO_POINTER (0));

  gtk_tree_view_insert_column_with_attributes (GTK_TREE_VIEW (treeview),
                                               -1, "Address", renderer,
                                               "text", COL_REG_NAME,
                                               NULL);

    col = gtk_tree_view_get_column(GTK_TREE_VIEW(treeview), 0);
    gtk_tree_view_column_set_cell_data_func(col, renderer, Memory_DataFunc, GINT_TO_POINTER(0), NULL);


  /* Memory value columns */
  for (i = 0; i < 8; i++) {
    renderer = gtk_cell_renderer_text_new ();

    g_object_set (renderer,
                  "editable", TRUE,
                  NULL);
    g_signal_connect (renderer, "edited",
                      G_CALLBACK(MemValueEdited), model);

    g_object_set_data (G_OBJECT(renderer), "column", GINT_TO_POINTER(1 + i));

    sprintf(buf, "A+%d", i);

    gtk_tree_view_insert_column_with_attributes (GTK_TREE_VIEW (treeview),
                                                 -1, buf, renderer,
                                                 "text", 1 + i,
                                                 NULL);

    col = gtk_tree_view_get_column(GTK_TREE_VIEW(treeview), 1 + i);
    gtk_tree_view_column_set_cell_data_func(col, renderer, Memory_DataFunc, GINT_TO_POINTER(1 + i), NULL);

  }

  /*  gtk_tree_selection_set_mode(gtk_tree_view_get_selection(GTK_TREE_VIEW(treeview)), GTK_SELECTION_NONE); */

  return treeview;
}

FuDesc_t PCU_Desc = {
  "PCU",
  2,
  {
    {
      "DEC",
      "testbench.ajardsp_0.pcu_0.inst_pipe_0_r"
    },

    {
      "EXEC",
      "testbench.ajardsp_0.pcu_0.inst_pipe_1_r"
    },
  }
};

FuDesc_t CU_0_Desc = {
  "CU 0",
  3,
  {
    {
      "DEC",
      "testbench.ajardsp_0.cu_0.inst_pipe_0_r"
    },

    {
      "EXEC",
      "testbench.ajardsp_0.cu_0.inst_pipe_1_r"
    },

    {
      "WB",
      "testbench.ajardsp_0.cu_0.inst_pipe_2_r"
    },
  }
};


FuDesc_t CU_1_Desc = {
  "CU 1",
  3,
  {
    {
      "DEC",
      "testbench.ajardsp_0.cu_1.inst_pipe_0_r"
    },

    {
      "EXEC",
      "testbench.ajardsp_0.cu_1.inst_pipe_1_r"
    },

    {
      "WB",
      "testbench.ajardsp_0.cu_1.inst_pipe_2_r"
    },
  }
};

FuDesc_t LSU_0_Desc = {
  "LSU 0",
  2,
  {
    {
      "DEC/MEM",
      "testbench.ajardsp_0.lsu_0.inst_pipe_0_r"
    },

    {
      "WB",
      "testbench.ajardsp_0.lsu_0.inst_pipe_1_r"
    },
  }
};

FuDesc_t LSU_1_Desc = {
  "LSU 1",
  2,
  {
    {
      "DEC/MEM",
      "testbench.ajardsp_0.lsu_1.inst_pipe_0_r"
    },

    {
      "WB",
      "testbench.ajardsp_0.lsu_1.inst_pipe_1_r"
    },
  }
};



GtkWidget* FunctionalUnitPipelineWidget(FuDesc_t* Fu_p)
{
  int i;
  GtkWidget* StageRegLabel_p;
  GtkWidget* StageDescLabel_p;
  GtkWidget* vbox;
  GtkWidget* FuFrame;

  vbox = gtk_vbox_new (FALSE, 4);

  for (i = 0; i < Fu_p->NbrOfPipeStages; i++) {

      StageRegLabel_p = gtk_label_new("DEADBEEF");
      gtk_label_set_justify(GTK_LABEL(StageRegLabel_p), GTK_JUSTIFY_LEFT);
      gtk_box_pack_start(GTK_BOX(vbox), StageRegLabel_p, FALSE, FALSE, 0);
      Fu_p->PipeStages[i].RegLabel_p = StageRegLabel_p;

      StageDescLabel_p = gtk_label_new(Fu_p->PipeStages[i].PipeStageDesc_p);
      gtk_label_set_justify(GTK_LABEL(StageDescLabel_p), GTK_JUSTIFY_LEFT);
      gtk_box_pack_start(GTK_BOX(vbox), StageDescLabel_p, FALSE, FALSE, 0);
  }


  FuFrame = gtk_frame_new(Fu_p->Name_p);
  gtk_container_add(GTK_CONTAINER(FuFrame), vbox);

  return FuFrame;
}

/* Need to look into the locking (need a mutex for SimSyncMode) */

pthread_mutex_t SimSyncCondMutex = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t  SimSyncCond      = PTHREAD_COND_INITIALIZER;

enum {SYNC_MODE_STEP, SYNC_MODE_RUN, SYNC_MODE_STOP} SimSyncMode = SYNC_MODE_STEP;

int SimCyclesLeftToRun = 0;

void WaitForGUI(void)
{
  switch (SimSyncMode) {
  case SYNC_MODE_STOP:
  case SYNC_MODE_STEP:
    SimReadOutRegisters();
    SimReadOutMemory();

    PipelineGuiUpdate(&PCU_Desc);
    PipelineGuiUpdate(&CU_0_Desc);
    PipelineGuiUpdate(&CU_1_Desc);
    PipelineGuiUpdate(&LSU_0_Desc);
    PipelineGuiUpdate(&LSU_1_Desc);

    pthread_cond_wait(&SimSyncCond, &SimSyncCondMutex);
    break;

  case SYNC_MODE_RUN:
    if (--SimCyclesLeftToRun == 0) {
      SimReadOutRegisters();
      SimReadOutMemory();

      PipelineGuiUpdate(&PCU_Desc);
      PipelineGuiUpdate(&CU_0_Desc);
      PipelineGuiUpdate(&CU_1_Desc);
      PipelineGuiUpdate(&LSU_0_Desc);
      PipelineGuiUpdate(&LSU_1_Desc);

      pthread_cond_wait(&SimSyncCond, &SimSyncCondMutex);
    }
    break;

  default:
    break;
  }
}

void UpdateCycleCount(int CurrentCycles)
{
  gchar buf[64];
  gdk_threads_enter();
  sprintf(buf, "Current simulation cycle: %d", CurrentCycles);
  gtk_label_set_text(GTK_LABEL(CycleLabel), buf);
  gdk_threads_leave();
}

static void StepButtonCallBack(GtkWidget *widget,
                               gpointer   data )
{
  SimSyncMode = SYNC_MODE_STEP;
  pthread_cond_signal(&SimSyncCond);
}

static void StopButtonCallBack(GtkWidget *widget,
                               gpointer   data )
{
  SimSyncMode = SYNC_MODE_STOP;
}

static void RunButtonCallBack(GtkWidget *widget,
                              gpointer   data )
{

  GtkWidget *CycleSpin = (GtkWidget*)data;

  if (CycleSpin) {
    SimCyclesLeftToRun = gtk_spin_button_get_value_as_int(GTK_SPIN_BUTTON(CycleSpin));
  }
  else {
    SimCyclesLeftToRun = 0;  /* Run forever */
  }
  SimSyncMode = SYNC_MODE_RUN;
  pthread_cond_signal(&SimSyncCond);
}


void* GuiMainThread(void* arg_p)
{
  GtkWidget *CtrlWindow;
  GtkWidget *RegWindow;
  GtkWidget *MemWindow;
  GtkWidget *MemScrollWindow;
  GtkWidget *StepButton;
  GtkWidget *StopButton;
  GtkWidget *RunButton;
  GtkWidget *RunForButton;
  GtkWidget *CycleSpin;
  GtkWidget *ExecFrame;
  GtkWidget *FuFrame;

  GtkWidget *view;
  GtkWidget *hbox;
  GtkWidget *hbox1;
  GtkWidget *hbox2;
  GtkWidget *vbox;

  /* init threads */
  gdk_threads_enter();

  gtk_init(NULL, NULL);

  /* Control Window - begin */
  CtrlWindow = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  g_signal_connect(CtrlWindow, "delete_event", gtk_main_quit, NULL);
  gtk_container_set_border_width (GTK_CONTAINER (CtrlWindow), 10);

  StepButton = gtk_button_new();
  g_signal_connect(StepButton, "clicked",
                   G_CALLBACK (StepButtonCallBack), NULL);
  gtk_container_add(GTK_CONTAINER(StepButton), gtk_label_new("Step"));

  StopButton = gtk_button_new();
  g_signal_connect(StopButton, "clicked",
                   G_CALLBACK (StopButtonCallBack), NULL);
  gtk_container_add(GTK_CONTAINER(StopButton), gtk_label_new("Stop"));

  RunButton = gtk_button_new();
  g_signal_connect(RunButton, "clicked",
                   G_CALLBACK (RunButtonCallBack), NULL);
  gtk_container_add(GTK_CONTAINER(RunButton), gtk_label_new("Run"));

  RunForButton = gtk_button_new();
  CycleSpin = gtk_spin_button_new_with_range(1.0, 1000000.0, 1.0);
  g_signal_connect(RunForButton, "clicked",
                   G_CALLBACK (RunButtonCallBack), CycleSpin);
  gtk_container_add(GTK_CONTAINER(RunForButton), gtk_label_new("Run for"));

  CycleLabel = gtk_label_new("");
  gtk_label_set_selectable(GTK_LABEL(CycleLabel), TRUE);

  hbox1 = gtk_hbox_new (FALSE, 4);
  hbox2 = gtk_hbox_new (FALSE, 4);
  vbox = gtk_vbox_new (FALSE, 4);

  gtk_container_add(GTK_CONTAINER(vbox), hbox1);
  gtk_container_add(GTK_CONTAINER(vbox), hbox2);

  gtk_box_pack_start(GTK_BOX(hbox1), CycleLabel, FALSE, FALSE, 0);

  gtk_box_pack_start(GTK_BOX(hbox2), RunButton, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(hbox2), StopButton, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(hbox2), StepButton, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(hbox2), RunForButton, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(hbox2), CycleSpin, FALSE, FALSE, 0);

  ExecFrame = gtk_frame_new("Simulation control");

  gtk_container_add(GTK_CONTAINER(ExecFrame), vbox);

  vbox = gtk_vbox_new (FALSE, 4);
  hbox = gtk_hbox_new (TRUE, 4);

  FuFrame = gtk_frame_new("Pipelines");
  gtk_container_add(GTK_CONTAINER(FuFrame), hbox);

  gtk_container_add(GTK_CONTAINER(vbox), FuFrame);
  gtk_container_add(GTK_CONTAINER(vbox), ExecFrame);

  /* Add all the FU pipelines to the hbox */
  gtk_container_add(GTK_CONTAINER(hbox), FunctionalUnitPipelineWidget(&PCU_Desc));
  gtk_container_add(GTK_CONTAINER(hbox), FunctionalUnitPipelineWidget(&CU_0_Desc));
  gtk_container_add(GTK_CONTAINER(hbox), FunctionalUnitPipelineWidget(&CU_1_Desc));
  gtk_container_add(GTK_CONTAINER(hbox), FunctionalUnitPipelineWidget(&LSU_0_Desc));
  gtk_container_add(GTK_CONTAINER(hbox), FunctionalUnitPipelineWidget(&LSU_1_Desc));

  gtk_container_add(GTK_CONTAINER(CtrlWindow), vbox);
  gtk_window_set_title(GTK_WINDOW(CtrlWindow), "MyDSP debugger (RTL sim)");

  gtk_widget_show_all(CtrlWindow);
  /* Control Window - end */


  /* Register Window - begin */
  RegWindow = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  g_signal_connect(RegWindow, "delete_event", gtk_main_quit, NULL);

  view = CreateRegisterViewAndModel();

  gtk_container_add(GTK_CONTAINER(RegWindow), view);
  gtk_window_set_title(GTK_WINDOW(RegWindow), "Registers");

  gtk_widget_show_all(RegWindow);
  /* Register Window - end */


  /* Memory Window - begin */

  MemWindow = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_default_size(GTK_WINDOW(MemWindow), 320, 200);

  MemScrollWindow = gtk_scrolled_window_new (NULL, NULL);

  gtk_scrolled_window_set_shadow_type(GTK_SCROLLED_WINDOW(MemScrollWindow),
                                      GTK_SHADOW_ETCHED_IN);

  gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(MemScrollWindow),
                                 GTK_POLICY_NEVER,
                                 GTK_POLICY_ALWAYS);


  g_signal_connect(MemWindow, "delete_event", gtk_main_quit, NULL);

  view = CreateMemoryViewAndModel();

  gtk_container_add(GTK_CONTAINER(MemWindow), MemScrollWindow);
  gtk_container_add(GTK_CONTAINER(MemScrollWindow), view);

  gtk_window_set_title(GTK_WINDOW(MemWindow), "Memory");

  gtk_widget_show_all(MemWindow);
  /* Memory Window - end */

#if STANDALONE
  {
  Reg_t* Regs_p = RegsOfInterest;
  int RegsLength = sizeof(RegsOfInterest)/sizeof(RegsOfInterest[0]);
  int i;

  for (i = 0; i < RegsLength; i++) {
    Regs_p[i].Iter_p = malloc(sizeof(GtkTreeIter));
    gtk_list_store_append(RegListStore_p, Regs_p[i].Iter_p);
    gtk_list_store_set(RegListStore_p, Regs_p[i].Iter_p,
                       COL_REG_NAME, i,
                       -1);

  }
  }
#endif

  gtk_main();

  gdk_threads_leave();

  return 0;
}

void StartGUI(void)
{
  pthread_t gui_tid;

  g_thread_init(NULL);
  gdk_threads_init();

  pthread_create(&gui_tid, NULL, GuiMainThread, NULL);
  sleep(1);
}

#if STANDALONE
int main(int argc, char** argv)
{
  g_thread_init(NULL);
  gdk_threads_init();

  GuiMainThread(NULL);

  return 0;
}
#endif
