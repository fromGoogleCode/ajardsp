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

#include "vpi_user.h"
#include "cv_vpi_user.h"

#include "debug.h"


static int CurrentCycles = 0;
static vpiHandle MemVpiHandle;
int MemoryCurr[LDM_SIZE];
int MemoryPrev[LDM_SIZE];
int MemoryAge[LDM_SIZE];

Reg_t RegsOfInterest[] = {
  {"testbench.ajardsp_0.pcu_0.pc_i", "pc", -1, NULL},
  {"testbench.ajardsp_0.pcu_0.retpc_r", "$retpc", -1, NULL},
  {"testbench.ajardsp_0.pred_0.pred_reg_r", "$pred", -1, NULL},
  {"testbench.ajardsp_0.sp_0.sp_r", "$sp", -1, NULL},
  {"testbench.ajardsp_0.curegs_0.satctrl_r", "$satctrl", -1, NULL},
  {"testbench.ajardsp_0.curegs_0.mulsign_r", "$mulsign", -1, NULL},

  {"testbench.ajardsp_0.lsuregs_0.mask_sel_o", "$masksel", -1, NULL},
  {"testbench.ajardsp_0.lsuregs_0.mask_0_o",   "$mask0",   -1, NULL},
  {"testbench.ajardsp_0.lsuregs_0.mask_1_o",   "$mask1",   -1, NULL},
  {"testbench.ajardsp_0.lsuregs_0.mod_sel_o",  "$modsel",  -1, NULL},
  {"testbench.ajardsp_0.lsuregs_0.mod_0_o",    "$mod0",    -1, NULL},
  {"testbench.ajardsp_0.lsuregs_0.mod_1_o",    "$mod1",    -1, NULL},
  {"testbench.ajardsp_0.lsuregs_0.bitrev_o",   "$bitrev",  -1, NULL},

  {"testbench.ajardsp_0.gpio_r",   "$gpio",  -1, NULL},

  {"testbench.ajardsp_0.ptrrf_0.ptr_regs", "$ptr0", 0, NULL},
  {"testbench.ajardsp_0.ptrrf_0.ptr_regs", "$ptr1", 1, NULL},
  {"testbench.ajardsp_0.ptrrf_0.ptr_regs", "$ptr2", 2, NULL},
  {"testbench.ajardsp_0.ptrrf_0.ptr_regs", "$ptr3", 3, NULL},
  {"testbench.ajardsp_0.ptrrf_0.ptr_regs", "$ptr4", 4, NULL},
  {"testbench.ajardsp_0.ptrrf_0.ptr_regs", "$ptr5", 5, NULL},
  {"testbench.ajardsp_0.ptrrf_0.ptr_regs", "$ptr6", 6, NULL},
  {"testbench.ajardsp_0.ptrrf_0.ptr_regs", "$ptr7", 7, NULL},

  {"testbench.ajardsp_0.accrf_share_0.accrf_0.acc_regs_low",  "$acc0l", 0, NULL},
  {"testbench.ajardsp_0.accrf_share_0.accrf_0.acc_regs_high", "$acc0h", 0, NULL},
  {"testbench.ajardsp_0.accrf_share_0.accrf_0.acc_regs_guard", "$acc0g", 0, NULL},
  {"testbench.ajardsp_0.accrf_share_0.accrf_0.acc_regs_low",  "$acc1l", 1, NULL},
  {"testbench.ajardsp_0.accrf_share_0.accrf_0.acc_regs_high", "$acc1h", 1, NULL},
  {"testbench.ajardsp_0.accrf_share_0.accrf_0.acc_regs_guard", "$acc1g", 1, NULL},
  {"testbench.ajardsp_0.accrf_share_0.accrf_0.acc_regs_low",  "$acc2l", 2, NULL},
  {"testbench.ajardsp_0.accrf_share_0.accrf_0.acc_regs_high", "$acc2h", 2, NULL},
  {"testbench.ajardsp_0.accrf_share_0.accrf_0.acc_regs_guard", "$acc2g", 2, NULL},
  {"testbench.ajardsp_0.accrf_share_0.accrf_0.acc_regs_low",  "$acc3l", 3, NULL},
  {"testbench.ajardsp_0.accrf_share_0.accrf_0.acc_regs_high", "$acc3h", 3, NULL},
  {"testbench.ajardsp_0.accrf_share_0.accrf_0.acc_regs_guard", "$acc3g", 3, NULL},
  {"testbench.ajardsp_0.accrf_share_0.accrf_0.acc_regs_low",  "$acc4l", 4, NULL},
  {"testbench.ajardsp_0.accrf_share_0.accrf_0.acc_regs_high", "$acc4h", 4, NULL},
  {"testbench.ajardsp_0.accrf_share_0.accrf_0.acc_regs_guard", "$acc4g", 4, NULL},
  {"testbench.ajardsp_0.accrf_share_0.accrf_0.acc_regs_low",  "$acc5l", 5, NULL},
  {"testbench.ajardsp_0.accrf_share_0.accrf_0.acc_regs_high", "$acc5h", 5, NULL},
  {"testbench.ajardsp_0.accrf_share_0.accrf_0.acc_regs_guard", "$acc5g", 5, NULL},
  {"testbench.ajardsp_0.accrf_share_0.accrf_0.acc_regs_low",  "$acc6l", 6, NULL},
  {"testbench.ajardsp_0.accrf_share_0.accrf_0.acc_regs_high", "$acc6h", 6, NULL},
  {"testbench.ajardsp_0.accrf_share_0.accrf_0.acc_regs_guard", "$acc6g", 6, NULL},
  {"testbench.ajardsp_0.accrf_share_0.accrf_0.acc_regs_low",  "$acc7l", 7, NULL},
  {"testbench.ajardsp_0.accrf_share_0.accrf_0.acc_regs_high", "$acc7h", 7, NULL},
  {"testbench.ajardsp_0.accrf_share_0.accrf_0.acc_regs_guard", "$acc7g", 7, NULL},
};

void RegUpdateValueInDesign(char* RegName_p, int NewValue)
{
  int i;
  for (i = 0; i < sizeof(RegsOfInterest)/sizeof(RegsOfInterest[0]); i++) {
    if(0 == strcmp(RegName_p, RegsOfInterest[i].name)) {
      s_vpi_value val;
      int blen;

      blen = vpi_get(vpiSize, RegsOfInterest[i].obj);
      val.format = vpiObjTypeVal;
      vpi_get_value(RegsOfInterest[i].obj, &val);
      fprintf(stderr, "Value read back from design: %s = 0x%x (format: %d)\n", RegName_p, val.value.vector[0].aval, val.format);

#if 0
      val.format = vpiVectorVal;
      val.value.vector[0].aval = NewValue;
      val.value.vector[0].bval = 0;
#else
      /* This is a workaround for CVER issue (v_vpi3.c:4186) with vpiVectorVal (problem with width) */
      val.format = vpiIntVal;
      val.value.integer = NewValue;
#endif
      fprintf(stderr, "New value set in design: %s = 0x%04x\n", RegName_p, NewValue);
      vpi_put_value(RegsOfInterest[i].obj, &val, NULL, vpiNoDelay);

      val.format = vpiObjTypeVal;
      vpi_get_value(RegsOfInterest[i].obj, &val);
      fprintf(stderr, "Value read back from design: %s = 0x%04x\n", RegName_p, val.value.vector[0].aval);


    }
  }
}

unsigned int SimReadReg(char* RegPath_p)
{
  vpiHandle h;
  s_vpi_value val;

  h = vpi_handle_by_name(RegPath_p, NULL);
  val.format = vpiObjTypeVal;
  vpi_get_value(h, &val);

  return val.value.vector[0].aval;
}


void SimReadOutRegisters(void)
{
  char s1[1024];
  int blen;
  int i;

  for (i = 0; i < sizeof(RegsOfInterest)/sizeof(RegsOfInterest[0]); i++) {
    s_vpi_value val;
    blen = vpi_get(vpiSize, RegsOfInterest[i].obj);
    val.format = vpiObjTypeVal;
    vpi_get_value(RegsOfInterest[i].obj, &val);

    RegsOfInterest[i].PrevValue = RegsOfInterest[i].CurrValue;
    RegsOfInterest[i].CurrValue = val.value.vector[0].aval;

    vpi_printf("%s:%s:0x%04X\n", RegsOfInterest[i].path, RegsOfInterest[i].name, RegsOfInterest[i].CurrValue);

    RegisterGuiUpdate(&RegsOfInterest[i]);
  }

}

void SimReadOutMemory(void)
{
  int i;

  for (i = 0; i < LDM_SIZE; i++) {
    s_vpi_value val;
    vpiHandle MemElementVpiHandle;

    MemElementVpiHandle = vpi_handle_by_index(MemVpiHandle, i);
    val.format = vpiObjTypeVal;
    vpi_get_value(MemElementVpiHandle, &val);

    MemoryPrev[i] = MemoryCurr[i];
    MemoryCurr[i] = val.value.vector[0].aval;
    if (MemoryCurr[i] != MemoryPrev[i]) {
      MemoryAge[i] = 0;
    }
    else {
      MemoryAge[i]++;
    }
    if (MemoryAge[i] < 2) {
      MemoryGuiUpdate(i, MemoryCurr[i]);
    }
  }
}

void UpdateMemoryInDesign(int Address, int NewValue)
{
  s_vpi_value val;
  vpiHandle MemElementVpiHandle;

  MemoryCurr[Address] = NewValue;

  MemElementVpiHandle = vpi_handle_by_index(MemVpiHandle, Address);
  val.format = vpiObjTypeVal;
  vpi_get_value(MemElementVpiHandle, &val);

  val.format = vpiIntVal;
  val.value.integer = NewValue;
  vpi_put_value(MemElementVpiHandle, &val, NULL, vpiNoDelay);
}

vpiHandle rstHandle;

int ClkNegEdgeCallBack(p_cb_data cbp)
{
 s_vpi_value ClkVal;
 s_vpi_value RstVal;
 s_vpi_time tim;

 RstVal.format = vpiObjTypeVal;
 vpi_get_value(rstHandle, &RstVal);

 ClkVal.format = vpiObjTypeVal;
 vpi_get_value(cbp->obj, &ClkVal);

 if (RstVal.format == vpiScalarVal && RstVal.value.scalar == vpi0 &&
     ClkVal.format == vpiScalarVal && ClkVal.value.scalar == vpi0) {

   vpi_printf("ClkNegEdgeCallBack\n");

   UpdateCycleCount(CurrentCycles++);

   WaitForGUI();
 }

 return 0;
}

int StartOfSimulationCallBack(struct t_cb_data *cbp)
{
 int isiz;
 vpiHandle topiter, topiref;
 p_cb_data ClkCBp;
 p_vpi_time timp;
 p_vpi_value valp;
 vpiHandle clkHandle;

#if 1
 /* Start the GTK GUI */
 StartGUI();
#endif

 rstHandle = vpi_handle_by_name("testbench.rst", NULL);
 if (rstHandle == NULL) {
   exit(1);
 }


 clkHandle = vpi_handle_by_name("testbench.clk", NULL);
 if (clkHandle == NULL) {
   exit(1);
 }

 ClkCBp = (p_cb_data) malloc(sizeof(s_cb_data));
 ClkCBp->reason = cbValueChange;
 ClkCBp->cb_rtn = ClkNegEdgeCallBack;

 ClkCBp->obj = clkHandle;
 timp = (p_vpi_time) malloc(sizeof(s_vpi_time));
 timp->type = vpiSuppressTime;
 ClkCBp->time = timp;
 valp = (p_vpi_value) malloc(sizeof(s_vpi_value));
 valp->format = vpiScalarVal;
 valp->value.scalar = vpi0;
 ClkCBp->value = valp;
 ClkCBp->index = 0;

 vpi_register_cb(ClkCBp);

 {
   int i;
   vpiHandle TmpVpiHandle;

   for (i = 0; i < sizeof(RegsOfInterest)/sizeof(RegsOfInterest[0]); i++) {

     TmpVpiHandle = vpi_handle_by_name(RegsOfInterest[i].path, NULL);
     if (TmpVpiHandle == NULL) {
       vpi_printf("ERR: Unable to find %s\n", RegsOfInterest[i].path);
       exit(1);
     }
     if (RegsOfInterest[i].index >= 0) {
       TmpVpiHandle = vpi_handle_by_index(TmpVpiHandle, RegsOfInterest[i].index);
       if (TmpVpiHandle == NULL) {
         vpi_printf("ERR: Unable to find %s, index %d\n", RegsOfInterest[i].path, RegsOfInterest[i].index);
         exit(1);
       }

       RegsOfInterest[i].obj = TmpVpiHandle;
     }
     else {
       RegsOfInterest[i].obj = TmpVpiHandle;
     }
   }

   RegInitializeRegisters(RegsOfInterest, sizeof(RegsOfInterest)/sizeof(RegsOfInterest[0]));
   MemInitializeMemory(LDM_SIZE);

   MemVpiHandle = vpi_handle_by_name("testbench.ajardsp_0.dmem_0.dmem", NULL);
 }

}

int my_error_handler(struct t_cb_data *cbp)
{
 struct t_vpi_error_info einfotab;
 struct t_vpi_error_info *einfop;
 char s1[128];

 einfop = &einfotab;
 vpi_chk_error(einfop);

 if (einfop->state == vpiCompile) strcpy(s1, "vpiCompile");
 else if (einfop->state == vpiPLI) strcpy(s1, "vpiPLI");
 else if (einfop->state == vpiRun) strcpy(s1, "vpiRun");
 else strcpy(s1, "**unknown**");

 vpi_printf("**ERR(%s) %s (level %d) at **%s(%d):\n  %s\n",
  einfop->code, s1, einfop->level, einfop->file, einfop->line,
  einfop->message);

 /* if serious error give up */
 if (einfop->level == vpiError || einfop->level == vpiSystem
  || einfop->level == vpiInternal)
  {
   vpi_printf("**FATAL: encountered error - giving up\n");
   vpi_sim_control(vpiFinish, 0);
  }
 return(0);
}

void vpi_bootstrap(void)
{
 vpiHandle href, href2;
 struct t_cb_data *ecbp, *cbp;
 struct t_cb_data cbrec;

 /* notice cb records must be in global storage */
 ecbp = &cbrec;
 ecbp->reason = cbError;
 ecbp->cb_rtn = my_error_handler;
 ecbp->obj = NULL;
 ecbp->time = NULL;
 ecbp->value = NULL;
 ecbp->user_data = NULL;

 /* probably should check for error here */
 if ((href = vpi_register_cb(ecbp)) == NULL)
  vpi_printf("**ERR: PLI 2.0 can not register error handler callback.\n");

 cbp = &cbrec;
 cbp->reason = cbStartOfSimulation;
 cbp->cb_rtn = StartOfSimulationCallBack;
 cbp->obj = NULL;
 cbp->time = NULL;
 cbp->value = NULL;
 cbp->user_data = NULL;

 /* probably should check for error here */
 if ((href2 = vpi_register_cb(cbp)) == NULL)
  vpi_printf(
   "**ERR: PLI 2.0 can not register start of sim setup callback.\n");
 /* if not registered will be no call backs */
}

void (*vlog_startup_routines[])() = {
    vpi_bootstrap,
    0
};
