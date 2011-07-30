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

typedef struct {
  GtkTreeIter *Iter_p;
  int addr;
  int bp;
  char *str;
} SourceFileLine_t;

typedef struct {
  int addr;
} BreakPoint_t;

GList *BreakPoint_List_p = NULL;

static SourceFileLine_t SourceFileLines[10*1024];
static int SourceFileLinesMax = 0;

static GtkTreeModel* SourceTreeModel = NULL;
static GtkTreeView*  SourceTreeView  = NULL;

static GtkListStore* SourceListStore_p = NULL;
static GtkListStore* RegListStore_p = NULL;
static GtkListStore* MemListStore_p = NULL;
static GtkWidget *CycleLabel = NULL;

extern int MemoryCurr[];
extern int MemoryPrev[];

extern Reg_t RegsOfInterest[];

int BreakPoint_Hit(void)
{
  GList *Curr_p = g_list_first(BreakPoint_List_p);

  while (Curr_p) {
    if (((BreakPoint_t *)Curr_p->data)->addr == SimReadReg(RegsOfInterest[0].path)) {
      return 1;
    }
    Curr_p = g_list_next(Curr_p);
  }

  return 0;
}

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

#if 0
    {
      int i;

      g_object_set(renderer, "background-set", FALSE, NULL);

      for (i = 0; i < 8; i++) {
        if (RegsOfInterest[i + 14].CurrValue == MemAddr) {
          g_object_set(renderer, "background", "Yellow", "background-set", TRUE, NULL);
        }
      }
    }
#endif

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

void SourceGuiUpdate(void)
{
  int i;

  gdk_threads_enter();

  for (i = 1; i < SourceFileLinesMax; i++) {
    /* Just touch every Flags column so that it gets redrawn (the magic happens from there) */
    gtk_list_store_set(SourceListStore_p, SourceFileLines[i].Iter_p,
                       0, 0, -1);

#if 1
    if (RegsOfInterest[0].CurrValue == SourceFileLines[i].addr) {
      /* Make source line visible */

      GtkTreePath *start_path;
      GtkTreePath *end_path;
      GtkTreePath *curr_path;

      gtk_tree_view_get_visible_range(SourceTreeView,
                                      &start_path,
                                      &end_path);

      curr_path = gtk_tree_model_get_path(SourceTreeModel, SourceFileLines[i].Iter_p);

      if (gtk_tree_path_compare(start_path, curr_path) >= 0 || gtk_tree_path_compare(curr_path, end_path) >= 0) {

        gtk_tree_view_scroll_to_cell(SourceTreeView,
                                     curr_path,
                                     NULL,
                                     TRUE,
                                     0.2,
                                     0.0);
      }

      gtk_tree_path_free(start_path);
      gtk_tree_path_free(end_path);
      gtk_tree_path_free(curr_path);

    }
#endif
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

  RegUpdateValueInDesign(RegName_p, NewValue);
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

static void Source_RowActivated (GtkTreeView        *treeview,
                                 GtkTreePath        *path,
                                 GtkTreeViewColumn  *col,
                                 gpointer            userdata)
{
  GtkTreeModel *model;
  GtkTreeIter   iter;

  model = gtk_tree_view_get_model(treeview);

  if (gtk_tree_model_get_iter(model, &iter, path)) {
    int LineNo;
    gtk_tree_model_get(model, &iter, 1, &LineNo, -1);

    if (!SourceFileLines[LineNo].bp) {
      /* set breakpoint */

      if (SourceFileLines[LineNo].addr != -1) {
        /* valid address */
        BreakPoint_t *bp_p;

        bp_p = g_malloc(sizeof(BreakPoint_t));

        bp_p->addr = SourceFileLines[LineNo].addr;

        BreakPoint_List_p = g_list_append(BreakPoint_List_p, bp_p);

        SourceFileLines[LineNo].bp = 1;
      }
    }
    else {
      /* remove breakpoint */
      GList *Curr_p = g_list_first(BreakPoint_List_p);

      SourceFileLines[LineNo].bp = 0;

      while (Curr_p) {
        if (((BreakPoint_t *)Curr_p->data)->addr == SourceFileLines[LineNo].addr) {
          g_free(Curr_p->data);
          BreakPoint_List_p = g_list_delete_link(BreakPoint_List_p, Curr_p);
          break;
        }

        Curr_p = g_list_next(Curr_p);
      }
    }

  }
}

static void Source_Init(char *asm_file, char *lineno_file)
{
  FILE *asm_fp;
  FILE *lineno_fp;
  int lineno = 0;
  char linebuf[256];
  char *line_p;

  struct {
    int addr;
    int lineno;
  } lineno_info[1024];
  int max_lineno_info = 0;

  lineno_fp = fopen(lineno_file, "r");
  while (!feof(lineno_fp)) {
    fscanf(lineno_fp, "0x%x:%d\n", &lineno_info[max_lineno_info].addr, &lineno_info[max_lineno_info].lineno);
    max_lineno_info++;
  }
  fclose(lineno_fp);

  asm_fp = fopen(asm_file, "r");

  while (!feof(asm_fp)) {
    lineno++;
    if (fgets(linebuf, sizeof(linebuf), asm_fp)) {

#if 0
      /* Strip trailing blanks and '\n' */
      line_p = &linebuf[strlen(linebuf)];
      while (line_p > linebuf && (*line_p == '\n' || *line_p == ' ' || *line_p == '\t' || *line_p == '\0')) {
        *line_p = '\0';
        line_p--;
      }

      /* Strip leading blanks */
      line_p = &linebuf[0];
      while (*line_p == ' ' || *line_p == '\t') {
        line_p++;
      }
#else
      linebuf[strlen(linebuf) - 1] = '\0';
      line_p = &linebuf[0];
#endif

      SourceFileLines[lineno].bp = 0;
      SourceFileLines[lineno].addr = -1;
      {
        int i;
        for (i = 0; i < max_lineno_info; i++) {
          if (lineno_info[i].lineno == lineno) {
            SourceFileLines[lineno].addr = lineno_info[i].addr;
          }
        }
      }
      SourceFileLines[lineno].str = strdup(linebuf);

      SourceFileLines[lineno].Iter_p = malloc(sizeof(GtkTreeIter));
      gtk_list_store_append(SourceListStore_p, SourceFileLines[lineno].Iter_p);
      gtk_list_store_set(SourceListStore_p, SourceFileLines[lineno].Iter_p,
                         1, lineno, -1);
    }
  }
  SourceFileLinesMax = lineno;

  fclose(asm_fp);
}

static void
Source_DataFunc(GtkTreeViewColumn *col,
                GtkCellRenderer   *renderer,
                GtkTreeModel      *model,
                GtkTreeIter       *iter,
                gpointer           user_data)
{
  int ColumnIndex = (int)user_data;
  int LineNo;

  gtk_tree_model_get(model, iter, 1, &LineNo, -1);

  if (ColumnIndex == 0) {
    gchar buf[16] = "   ";

    if (SourceFileLines[LineNo].bp) {
      buf[0] = 'B';
    }

    if (RegsOfInterest[0].CurrValue == SourceFileLines[LineNo].addr) {
      buf[1] = '-';
      buf[2] = '>';
    }

    g_object_set(renderer, "foreground-set", FALSE, NULL); /* print this normal */
    g_object_set(renderer, "background", "Pink", "background-set", TRUE, NULL);
    g_object_set(renderer, "text", buf, NULL);
  }
  else if (ColumnIndex == 1) {
    gchar buf[16];
    if (SourceFileLines[LineNo].addr != -1) {
      sprintf(buf, "0x%04X", SourceFileLines[LineNo].addr);
    }
    else {
      sprintf(buf, "");
    }
    g_object_set(renderer, "foreground-set", FALSE, NULL); /* print this normal */
    g_object_set(renderer, "background", "Pink", "background-set", TRUE, NULL);
    g_object_set(renderer, "text", buf, NULL);
  }
  else if (ColumnIndex == 2) {
    gchar buf[16];
    sprintf(buf, "%d", LineNo);
    g_object_set(renderer, "foreground-set", FALSE, NULL); /* print this normal */
    g_object_set(renderer, "background", "Gray", "background-set", TRUE, NULL);
    g_object_set(renderer, "text", buf, NULL);
  }
  else if (ColumnIndex == 3) {
    gchar buf[256];
    sprintf(buf, "%s", SourceFileLines[LineNo].str);
    g_object_set(renderer, "foreground-set", FALSE, NULL); /* print this normal */
    g_object_set(renderer, "background", "White", "background-set", TRUE, NULL);
    g_object_set(renderer, "text", buf, NULL);
  }
  else {
    assert(0);
  }
}


static GtkWidget *
CreateSourceViewAndModel(void)
{
  GtkTreeViewColumn   *col;
  GtkCellRenderer     *renderer;
  GtkWidget           *treeview;
  GtkTreeModel        *model;
  gchar                buf[64];
  int                  i;

  treeview =  gtk_tree_view_new();
  SourceTreeView = (GtkTreeView*)treeview;

  gtk_tree_view_set_enable_search(GTK_TREE_VIEW(treeview), FALSE);

  SourceListStore_p = gtk_list_store_new(4,
                                         G_TYPE_INT, G_TYPE_INT,
                                         G_TYPE_INT, G_TYPE_INT);

  SourceTreeModel = model = GTK_TREE_MODEL(SourceListStore_p);

  gtk_tree_view_set_model(GTK_TREE_VIEW(treeview), model);

  /* Marker column */
  renderer = gtk_cell_renderer_text_new ();
  g_object_set_data (G_OBJECT (renderer), "column", GINT_TO_POINTER (0));

  gtk_tree_view_insert_column_with_attributes (GTK_TREE_VIEW (treeview),
                                               -1, "", renderer,
                                               "text", 0,
                                               NULL);

  col = gtk_tree_view_get_column(GTK_TREE_VIEW(treeview), 0);
  gtk_tree_view_column_set_cell_data_func(col, renderer, Source_DataFunc, GINT_TO_POINTER(0), NULL);


  /* LPM address column */
  renderer = gtk_cell_renderer_text_new ();
  g_object_set_data (G_OBJECT (renderer), "column", GINT_TO_POINTER (1));

  gtk_tree_view_insert_column_with_attributes (GTK_TREE_VIEW (treeview),
                                               -1, "Addr", renderer,
                                               "text", 1,
                                               NULL);

  col = gtk_tree_view_get_column(GTK_TREE_VIEW(treeview), 1);
  gtk_tree_view_column_set_cell_data_func(col, renderer, Source_DataFunc, GINT_TO_POINTER(1), NULL);

  /* Lineno column */
  renderer = gtk_cell_renderer_text_new ();
  g_object_set_data (G_OBJECT (renderer), "column", GINT_TO_POINTER (2));

  gtk_tree_view_insert_column_with_attributes (GTK_TREE_VIEW (treeview),
                                               -1, "Line", renderer,
                                               "text", 2,
                                               NULL);

  col = gtk_tree_view_get_column(GTK_TREE_VIEW(treeview), 2);
  gtk_tree_view_column_set_cell_data_func(col, renderer, Source_DataFunc, GINT_TO_POINTER(2), NULL);

  /* Source line column */
  renderer = gtk_cell_renderer_text_new ();
  g_object_set_data (G_OBJECT (renderer), "column", GINT_TO_POINTER (3));

  gtk_tree_view_insert_column_with_attributes (GTK_TREE_VIEW (treeview),
                                               -1, "Source", renderer,
                                               "text", 3,
                                               NULL);

  col = gtk_tree_view_get_column(GTK_TREE_VIEW(treeview), 3);
  gtk_tree_view_column_set_cell_data_func(col, renderer, Source_DataFunc, GINT_TO_POINTER(3), NULL);


  gtk_tree_selection_set_mode(gtk_tree_view_get_selection(GTK_TREE_VIEW(treeview)), GTK_SELECTION_NONE);

  g_signal_connect(treeview, "row-activated", (GCallback) Source_RowActivated, NULL);

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

FuDesc_t BMU_Desc = {
  "BMU",
  3,
  {
    {
      "DEC",
      "testbench.ajardsp_0.bmu_0.inst_pipe_0_r"
    },

    {
      "EXEC",
      "testbench.ajardsp_0.bmu_0.inst_pipe_1_r"
    },

    {
      "WB",
      "testbench.ajardsp_0.bmu_0.inst_pipe_2_r"
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

enum {SYNC_MODE_STEP, SYNC_MODE_RUN, SYNC_MODE_STOP, SYNC_MODE_QUIT} SimSyncMode = SYNC_MODE_STEP;

int SimCyclesLeftToRun = 0;

void WaitForGUI(void)
{
  switch (SimSyncMode) {
  case SYNC_MODE_STOP:
  case SYNC_MODE_STEP:
    SimReadOutRegisters();
    SimReadOutMemory();

    SourceGuiUpdate();

    PipelineGuiUpdate(&PCU_Desc);
    PipelineGuiUpdate(&BMU_Desc);
    PipelineGuiUpdate(&CU_0_Desc);
    PipelineGuiUpdate(&CU_1_Desc);
    PipelineGuiUpdate(&LSU_0_Desc);
    PipelineGuiUpdate(&LSU_1_Desc);


    pthread_cond_wait(&SimSyncCond, &SimSyncCondMutex);
    break;

  case SYNC_MODE_RUN:
    if (--SimCyclesLeftToRun == 0 || BreakPoint_Hit()) {
      SimReadOutRegisters();
      SimReadOutMemory();

      SourceGuiUpdate();

      PipelineGuiUpdate(&PCU_Desc);
      PipelineGuiUpdate(&BMU_Desc);
      PipelineGuiUpdate(&CU_0_Desc);
      PipelineGuiUpdate(&CU_1_Desc);
      PipelineGuiUpdate(&LSU_0_Desc);
      PipelineGuiUpdate(&LSU_1_Desc);

      pthread_cond_wait(&SimSyncCond, &SimSyncCondMutex);
    }
    break;

  case SYNC_MODE_QUIT:
    exit(0);
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

static GtkWidget *CtrlWindow;
static GtkWidget *SourceWindow;
static GtkWidget *SourceScrollWindow;
static GtkWidget *RegWindow;
static GtkWidget *RegScrollWindow;
static GtkWidget *MemWindow;
static GtkWidget *MemScrollWindow;

static char dot_ajardsp_simdebug_file_path[64];

static void PreQuitCallBack(void)
{
  int x, y, w, h;
  FILE *window_pos_fp;

  /* Store window geometry */
  window_pos_fp = fopen(dot_ajardsp_simdebug_file_path, "w");
  if (window_pos_fp) {

    gtk_window_get_position (GTK_WINDOW (CtrlWindow), &x, &y);
    gtk_window_get_size (GTK_WINDOW (CtrlWindow), &w, &h);
    fprintf(window_pos_fp, "%d,%d,%d,%d\n", x, y, w, h);

    gtk_window_get_position (GTK_WINDOW (SourceWindow), &x, &y);
    gtk_window_get_size (GTK_WINDOW (SourceWindow), &w, &h);
    fprintf(window_pos_fp, "%d,%d,%d,%d\n", x, y, w, h);

    gtk_window_get_position (GTK_WINDOW (RegWindow), &x, &y);
    gtk_window_get_size (GTK_WINDOW (RegWindow), &w, &h);
    fprintf(window_pos_fp, "%d,%d,%d,%d\n", x, y, w, h);

    gtk_window_get_position (GTK_WINDOW (MemWindow), &x, &y);
    gtk_window_get_size (GTK_WINDOW (MemWindow), &w, &h);
    fprintf(window_pos_fp, "%d,%d,%d,%d\n", x, y, w, h);

    fclose(window_pos_fp);
  }

  gtk_main_quit();
}

void* GuiMainThread(void* arg_p)
{
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

  char *asm_path;
  char *lineno_path;

  /* init threads */
  gdk_threads_enter();

  gtk_init(NULL, NULL);

  /* Control Window - begin */
  CtrlWindow = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  g_signal_connect(CtrlWindow, "delete_event", PreQuitCallBack, NULL);
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
  gtk_container_add(GTK_CONTAINER(hbox), FunctionalUnitPipelineWidget(&BMU_Desc));
  gtk_container_add(GTK_CONTAINER(hbox), FunctionalUnitPipelineWidget(&CU_0_Desc));
  gtk_container_add(GTK_CONTAINER(hbox), FunctionalUnitPipelineWidget(&CU_1_Desc));
  gtk_container_add(GTK_CONTAINER(hbox), FunctionalUnitPipelineWidget(&LSU_0_Desc));
  gtk_container_add(GTK_CONTAINER(hbox), FunctionalUnitPipelineWidget(&LSU_1_Desc));

  gtk_container_add(GTK_CONTAINER(CtrlWindow), vbox);
  gtk_window_set_title(GTK_WINDOW(CtrlWindow), "AjarDSP debugger (RTL sim)");

  gtk_widget_show_all(CtrlWindow);
  /* Control Window - end */

  /* Source Window - begin */
  asm_path    = getenv("AJARDSP_SIMDEBUG_ASM_PATH");
  lineno_path = getenv("AJARDSP_SIMDEBUG_LINENO_PATH");

  if (asm_path && lineno_path) {
    SourceWindow = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_default_size(GTK_WINDOW(SourceWindow), 320, 600);

    SourceScrollWindow = gtk_scrolled_window_new (NULL, NULL);

    gtk_scrolled_window_set_shadow_type(GTK_SCROLLED_WINDOW(SourceScrollWindow),
                                        GTK_SHADOW_ETCHED_IN);

    gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(SourceScrollWindow),
                                   GTK_POLICY_AUTOMATIC,
                                   GTK_POLICY_ALWAYS);

    g_signal_connect(SourceWindow, "delete_event", PreQuitCallBack, NULL);

    view = CreateSourceViewAndModel();

    gtk_container_add(GTK_CONTAINER(SourceWindow), SourceScrollWindow);
    gtk_container_add(GTK_CONTAINER(SourceScrollWindow), view);

    gtk_window_set_title(GTK_WINDOW(SourceWindow), "Source");

    Source_Init(asm_path, lineno_path);

    gtk_widget_show_all(SourceWindow);
  }
  /* Source Window - end */

  /* Register Window - begin */
  RegWindow = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  RegScrollWindow = gtk_scrolled_window_new (NULL, NULL);

  gtk_scrolled_window_set_shadow_type(GTK_SCROLLED_WINDOW(RegScrollWindow),
                                      GTK_SHADOW_ETCHED_IN);

  gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(RegScrollWindow),
                                 GTK_POLICY_NEVER,
                                 GTK_POLICY_AUTOMATIC);

  g_signal_connect(RegWindow, "delete_event", PreQuitCallBack, NULL);

  view = CreateRegisterViewAndModel();

  gtk_container_add(GTK_CONTAINER(RegScrollWindow), view);
  gtk_container_add(GTK_CONTAINER(RegWindow), RegScrollWindow);
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

  g_signal_connect(MemWindow, "delete_event", PreQuitCallBack, NULL);

  view = CreateMemoryViewAndModel();

  gtk_container_add(GTK_CONTAINER(MemWindow), MemScrollWindow);
  gtk_container_add(GTK_CONTAINER(MemScrollWindow), view);

  gtk_window_set_title(GTK_WINDOW(MemWindow), "Memory");

  gtk_widget_show_all(MemWindow);
  /* Memory Window - end */

  sprintf(dot_ajardsp_simdebug_file_path, "%s/.ajardsp-simdebug", getenv("HOME"));

  /* Restore window geometry */
  {
    int x, y, w, h;
    FILE *window_pos_fp;

    window_pos_fp = fopen(dot_ajardsp_simdebug_file_path, "r");
    if (window_pos_fp) {

      fscanf(window_pos_fp, "%d,%d,%d,%d\n", &x, &y, &w, &h);
      gtk_window_move (GTK_WINDOW (CtrlWindow), x, y);
      gtk_window_resize (GTK_WINDOW (CtrlWindow), w, h);

      fscanf(window_pos_fp, "%d,%d,%d,%d\n", &x, &y, &w, &h);
      gtk_window_move (GTK_WINDOW (SourceWindow), x, y);
      gtk_window_resize (GTK_WINDOW (SourceWindow), w, h);

      fscanf(window_pos_fp, "%d,%d,%d,%d\n", &x, &y, &w, &h);
      gtk_window_move (GTK_WINDOW (RegWindow), x, y);
      gtk_window_resize (GTK_WINDOW (RegWindow), w, h);

      fscanf(window_pos_fp, "%d,%d,%d,%d\n", &x, &y, &w, &h);
      gtk_window_move (GTK_WINDOW (MemWindow), x, y);
      gtk_window_resize (GTK_WINDOW (MemWindow), w, h);

      fclose(window_pos_fp);
    }
  }

  gtk_main();

  SimSyncMode = SYNC_MODE_QUIT;
  pthread_cond_signal(&SimSyncCond);

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
