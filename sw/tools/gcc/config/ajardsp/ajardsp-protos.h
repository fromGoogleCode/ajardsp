/* This file is part of the AjarDSP GCC configuration.

   Copyright (C) 2010 Markus Lavin.

   Copyright (C) 2006, 2007, 2008, 2009, 2010 Free Software Foundation, Inc.

   This file is free software; you can redistribute it and/or modify it under
   the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 3 of the License, or (at your option)
   any later version.

   This file is distributed in the hope that it will be useful, but WITHOUT
   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
   for more details.

   You should have received a copy of the GNU General Public License
   along with GCC; see the file COPYING3.  If not see
   <http://www.gnu.org/licenses/>. */

#include "target.h"

extern int
symbolic_operand (rtx op, enum machine_mode mode);
extern int
constant_operand (rtx op, enum machine_mode mode);
extern int
zero_register_operand (rtx op, enum machine_mode mode);
extern int
LO_register_operand (rtx op, enum machine_mode mode);
extern int
addr_register_operand (rtx op, enum machine_mode mode);

extern rtx
ajardsp_struct_value_rtx(tree fndecl, int incoming);
rtx
ajardsp_function_value (enum machine_mode mode, tree fndecl);
extern void *ajardsp_function_arg(CUMULATIVE_ARGS *cum, enum machine_mode mode, tree type, int named);
extern void ajardsp_function_arg_advance(CUMULATIVE_ARGS *cum, enum machine_mode mode, tree type, int named);

extern void
ajardsp_prologue(void);
extern void
ajardsp_epilogue(void);

extern void
ajardsp_reorg(void);


extern void
ajardsp_optimization_options (int level, int size ATTRIBUTE_UNUSED);

extern int
ajardsp_absolute_memory_operand (rtx op,
                               enum machine_mode mode ATTRIBUTE_UNUSED);


extern int
legitimate_constant_p (rtx X);

extern int
legitimate_constant_p (rtx X);

extern int
ajardsp_address_cost (rtx x);

extern int
ajardsp_sched_issue_rate(void);

extern int
ajardsp_sched_first_cycle_multipass_dfa_lookahead(void);

extern int
ajardsp_sched_adjust_cost (rtx insn, rtx link, rtx dep_insn, int cost);

extern void
ajardsp_asm_function_prologue (FILE *file, HOST_WIDE_INT size ATTRIBUTE_UNUSED);

extern const char *
ajardsp_asm_output_opcode (FILE *f, const char *ptr);

extern void
ajardsp_asm_output_ascii(FILE *stream, char *ptr, int len);
