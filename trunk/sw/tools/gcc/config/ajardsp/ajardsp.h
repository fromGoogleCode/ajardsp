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


extern const struct real_format ajardsp_single_format;

/* ------------------------------------------------------------------------------*
 *                      Data Sizes, Layout and Memory                            *
 * ------------------------------------------------------------------------------*/
#define BITS_BIG_ENDIAN 0

#define BYTES_BIG_ENDIAN 0

#define WORDS_BIG_ENDIAN 0

#define BITS_PER_UNIT 16

#define UNITS_PER_WORD 1

#define PARM_BOUNDARY 16

#define STACK_BOUNDARY 16

#define FUNCTION_BOUNDARY 16

#define BIGGEST_ALIGNMENT 16

#define STRICT_ALIGNMENT 0

#define MOVE_MAX 1

#define Pmode QImode

#define FUNCTION_MODE HImode

#define SLOW_BYTE_ACCESS 0

#define CASE_VECTOR_MODE QImode

#define LONG_TYPE_SIZE 32

#define SIZE_TYPE "unsigned int"

#define PTRDIFF_TYPE "int"

#define FLOAT_TYPE_SIZE 16
#define DOUBLE_TYPE_SIZE 16
#define LONG_DOUBLE_TYPE_SIZE 16
//#define POINTER_SIZE 16

/* ------------------------------------------------------------------------------*
 *                      Registers and their usage conventions                    *
 * ------------------------------------------------------------------------------*/

#define FIRST_PSEUDO_REGISTER 30

#define AJARDSP_REGNO_FIRST_PTR   0
#define AJARDSP_REGNO_BEF_LAST_PTR    6
#define AJARDSP_REGNO_LAST_PTR    7
#define AJARDSP_REGNO_FIRST_ACC   8
#define AJARDSP_REGNO_LAST_ACC   23
#define AJARDSP_REGNO_FIRST_PRED 24
#define AJARDSP_REGNO_LAST_PRED  27
#define AJARDSP_REGNO_FIRST_SPEC 28
#define AJARDSP_REGNO_LAST_SPEC  29

#define AJARDSP_REGNO_SP         28
#define AJARDSP_REGNO_RETPC      29

#define REGISTER_NAMES                                  \
{                                                       \
  "$ptr0",  "$ptr1",  "$ptr2",  "$ptr3",  /* 0  - 3 */  \
  "$ptr4",  "$ptr5",  "$ptr6",  "$ptr7",  /* 4  - 7 */  \
  "$acc0l", "$acc0h", "$acc1l", "$acc1h", /* 8  - 11 */ \
  "$acc2l", "$acc2h", "$acc3l", "$acc3h", /* 12 - 15 */ \
  "$acc4l", "$acc4h", "$acc5l", "$acc5h", /* 16 - 19 */ \
  "$acc6l", "$acc6h", "$acc7l", "$acc7h", /* 20 - 23 */ \
  "$pred0", "$pred1", "$pred2", "$pred3", /* 24 - 27 */ \
  "$sp",    "$retpc"                      /* 28 - 29 */ \
}

#define FIXED_REGISTERS                         \
{0,0,0,0, /* $ptr0  - $ptr3 */                  \
 0,0,0,1, /* $ptr4  - $ptr7 */                  \
 0,0,0,0, /* $acc0l - $acc1h */                 \
 0,0,0,0, /* $acc2l - $acc3h */                 \
 0,0,0,0, /* $acc4l - $acc5h */                 \
 0,0,0,0, /* $acc6l - $acc7h */                 \
 1,0,0,0, /* $pred0 - $pred3 */                 \
 1,1      /* $sp, $retpc */                     \
}

#define CALL_USED_REGISTERS                     \
{1,1,1,1, /* $ptr0  - $ptr3 */                  \
 0,0,0,1, /* $ptr4  - $ptr7 */                  \
 1,1,1,1, /* $acc0l - $acc1h */                 \
 1,1,1,1, /* $acc2l - $acc3h */                 \
 0,0,0,0, /* $acc4l - $acc5h */                 \
 0,0,0,0, /* $acc6l - $acc7h */                 \
 1,1,1,1, /* $pred0 - $pred3 */                 \
 1,1      /* $sp, $retpc */                     \
}

enum reg_class                                  \
{                                               \
        NO_REGS,                                \
        CALLER_SAVED_REGS,                      \
        CALLEE_SAVED_REGS,                      \
        ACC_REGS_LOW_PART,                      \
        ACC_REGS_HIGH_PART,                     \
        ACC_REGS_0_3,                           \
        ACC_REGS,                               \
        PTR_REGS,                               \
        PRED_REGS,                              \
        SPEC_REGS,                              \
        ALL_PTR_REGS,                           \
        GENERAL_REGS,                           \
        ALL_REGS,                               \
	ACC_PTR,				\
	LIM_REG_CLASSES
};

#define N_REG_CLASSES LIM_REG_CLASSES

#define REG_CLASS_NAMES                         \
{                                               \
        "NO_REGS",                              \
        "CALLER_SAVED_REGS",                    \
        "CALLEE_SAVED_REGS",                    \
        "ACC_REGS_LOW_PART",                    \
        "ACC_REGS_HIGH_PART",                   \
        "ACC_REGS_0_3"                          \
        "ACC_REGS",                             \
        "PTR_REGS",                             \
        "PRED_REGS",                            \
        "SPEC_REGS",                            \
        "ALL_PTR_REGS",                         \
        "GEN_REGS",                             \
        "ALL_REGS",                             \
	"ACC_PTR"                          \
}

#define REG_CLASS_CONTENTS                      \
{                                               \
    {0x00000000},   /* NO_REGS */               \
    {0x0000ff0f},   /* CALLER_SAVED_REGS */     \
    {0x00ff00f0},   /* CALLEE_SAVED_REGS */     \
    {0x00555500},   /* ACC_REGS_LOW_PART */     \
    {0x00aaaa00},   /* ACC_REGS_HIGH_PART */    \
    {0x0000ff00},   /* ACC_REGS_0_3 */          \
    {0x00ffff00},   /* ACC_REGS */              \
    {0x000000ff},   /* PTR_REGS */              \
    {0x0f000000},   /* PRED_REGS */             \
    {0x30000000},   /* SPEC_REGS */             \
    {0x100000ff},   /* ALL_PTR_REGS */          \
    {0x0fffffff},   /* GENERAL_REGS */          \
    {0x3fffffff},   /* ALL_REGS */              \
    {0x00ffffff}    /* ACC and PTR */           \
}

#define TARGET_CLASS_LIKELY_SPILLED_P(a) \
        a == NO_REGS? 0 :                                \
        a == CALLER_SAVED_REGS ? 1 :                     \
        a == CALLEE_SAVED_REGS ? 1 :                      \
        a == ACC_REGS_LOW_PART ? 1 :                      \
        a == ACC_REGS_HIGH_PART ? 1 :                     \
        a == ACC_REGS_0_3 ? 1  :                           \
        a == ACC_REGS ? 1  :                               \
        a == PTR_REGS ? 1  :                               \
        a == PRED_REGS ? 0  :                              \
        a == (SPEC_REGS ? 1  :                              \
        a == ALL_PTR_REGS ? 1 :                           \
        a == GENERAL_REGS ? 1 :                           \
        a == ALL_REGS ? 1 :                               \
	a == ACC_PTR ? 1 : 1

#define REGNO_REG_CLASS(REGNO) \
regno_reg_class(REGNO)

#define BASE_REG_CLASS \
ALL_PTR_REGS

#define INDEX_REG_CLASS \
NO_REGS

/* Number of consecutive hard registers required to hold
 * value of given mode, starting from register REGNO. */
#define HARD_REGNO_NREGS(REGNO, MODE) \
((GET_MODE_SIZE (MODE) + UNITS_PER_WORD - 1)  \
               / UNITS_PER_WORD)

/* The following macro returns 1 if a  value of mode MODE can be held in
 * register REGNO. If the mode is  double, it checks for register number
 * and allows only if register has  even number, else returns 0. This is
 * because for double  values, register with even number  is paired with
 * the succeeding  odd numbered  register. For  single integer  mode, it
 * allows all registers.*/
#define HARD_REGNO_MODE_OK(REGN, MODE) \
hard_regno_mode_ok (REGN, MODE)

/* This  macro defines  if object  of mode2  can be  moved in  object of
 * mode1. If the modes are same or they belong to same class (eg. int or
 * float) and mode2 has size less than mode1, then we allow the move.*/
#define MODES_TIEABLE_P(MODE1, MODE2) \
modes_tieable_p (MODE1,MODE2)

/* Currently we assume any register can be used as base register. But in
 * later levels,  we will define  the registers acording  to appropriate
 * register class.*/
#define REGNO_OK_FOR_BASE_P(REGNO)\
ajardsp_regno_ok_for_base_p (REGNO)

/* AjarDSP does not support indexed addressing mode. */
#define REGNO_OK_FOR_INDEX_P(REGNO)\
0

#define PREFERRED_RELOAD_CLASS(X, CLASS) \
CLASS

/* This is closely  related to the macro  HARD_REGNO_NREGS. It specifies
 * the maximum number  of consecutive registers of  class CLASS required
 * for  holding  a  value of  mode  MODE.  In  fact,  the value  of  the
 * macro CLASS_MAX_NREGS  (class, mode) should  be the maximum  value of
 * HARD_REGNO_NREGS  (regno, mode)  for all  regno values  in the  class
 * CLASS. */
#define CLASS_MAX_NREGS(CLASS, MODE) \
((GET_MODE_SIZE(MODE)+UNITS_PER_WORD-1)/UNITS_PER_WORD)

/* ------------------------------------------------------------------------------*
 *                      Activation Record and Calling Conventions                *
 * ------------------------------------------------------------------------------*/

/* Stack layout
                      |                                 |
   direction of  |    |    CALLER'S ACTIVATION RECORD   |
     growth of   |    +---------------------------------+  <-- Previous SP   we should probably pass by push instead
      stack      |    |   Parameters passed on stack    |
                 |    |  (Accessible from frame pointer.|
                \|/   |  Direction of growth is opposite|
                 V    |   to direction of stack growth) | <-- Current AP = HFP
                      +---------------------------------+
                      |     old retpc (pushed by hw)    |
                      +---------------------------------+
                      |     old SP (pushed by callee)   |
                      +---------------------------------+
                      |     old FP (pushed by callee)   | <-- Current FP
                      +---------------------------------+
                      |       Local variables           |
                      |(Direction of growth of frame is |
                      | same as direction of growth of  |
                      |            stack)               |
                      +---------------------------------+
                      |                                 |
                      |  Callee saved registers being   |
                      |   used in the callee function   |
                      |                                 | <-- Current SP
                      +---------------------------------+
                      |                                 |

  SP points to last element pushed.
  FP points to the location where the old FP is stored, i.e. not pointing directly at the local variables.

*/

#define PUSH_ARGS 1

#define PUSH_ROUNDING(BYTES) (BYTES)

#define STACK_GROWS_DOWNWARD 1

#define FRAME_GROWS_DOWNWARD 1

#define ARGS_GROWS_DOWNWARD 0

#define STARTING_FRAME_OFFSET \
starting_frame_offset ()

#define STACK_POINTER_OFFSET \
0

#define FIRST_PARM_OFFSET(FUN)\
0

#define STACK_POINTER_REGNUM  AJARDSP_REGNO_SP

#define HARD_FRAME_POINTER_REGNUM AJARDSP_REGNO_LAST_PTR

#define ARG_POINTER_REGNUM AJARDSP_REGNO_BEF_LAST_PTR

#define FRAME_POINTER_REGNUM AJARDSP_REGNO_LAST_PTR

#define ELIMINABLE_REGS \
{{ARG_POINTER_REGNUM,      HARD_FRAME_POINTER_REGNUM}, \
 {FRAME_POINTER_REGNUM,        STACK_POINTER_REGNUM}, \
 {HARD_FRAME_POINTER_REGNUM, STACK_POINTER_REGNUM} \
}
/*Recomputes new offsets, after eliminating.*/
#define INITIAL_ELIMINATION_OFFSET(FROM, TO, VAR) \
(VAR) = initial_elimination_offset(FROM, TO)

#define ACCUMULATE_OUTGOING_ARGS \
0

/* Function pops none of its arguments, so it is caller's responsibility
 * to pop off the parameters. */
#define RETURN_POPS_ARGS(FUN, TYPE, SIZE) \
0

#define FUNCTION_ARG_REGNO_P(r) /* Irrelevant in this level */ \
0

#define FUNCTION_ARG(CUM, MODE, TYPE, NAMED) \
ajardsp_function_arg(&CUM, MODE, TYPE, NAMED)

#define FUNCTION_ARG_REGNO_P(r) /* Irrelevant in this level */ \
0

struct cum_args {int r_regs; int a_regs;};

#define CUMULATIVE_ARGS struct cum_args

#define INIT_CUMULATIVE_ARGS(CUM, FNTYPE, LIBNAME, FNDECL, NAMED_ARGS)    \
{\
(CUM).r_regs = 0; (CUM).a_regs = 0; \
}

#define FUNCTION_ARG_ADVANCE(CUM, MODE, TYPE, NAMED) \
ajardsp_function_arg_advance(&CUM, MODE, TYPE, NAMED)

#define FUNCTION_VALUE(valtype, func)\
ajardsp_function_value(TYPE_MODE(valtype), func)

#define LIBCALL_VALUE(MODE) \
ajardsp_function_value(MODE, NULL)

#define FUNCTION_VALUE_REGNO_P(REGN) \
((REGN) == AJARDSP_REGNO_FIRST_PTR || (REGN) == AJARDSP_REGNO_FIRST_ACC)


/* ------------------------------------------------------------------------------*
 *                      Addressing Mode information                              *
 * ------------------------------------------------------------------------------*/

#define HAVE_PRE_DECREMENT  1
#define HAVE_POST_INCREMENT 1

/* To validate use of labels as symbolic references or numeric addresses */
#define CONSTANT_ADDRESS_P(X) \
constant_address_p(X)

/* Since we don't have base indexed mode, we do not need more than one
 * register for any address. */
#define MAX_REGS_PER_ADDRESS \
1

/* This macro is  used to validate an  address used in an  insn by using
 * the constraints specified  in the template in the  md (describing the
 * addressing) mode and the constraints on the register classes. This is
 * implemented by transferring control  to appropriate code fragments in
 * source of generated compiler.*/

#ifdef REG_OK_STRICT
#define GO_IF_LEGITIMATE_ADDRESS(mode,x,label) \
{\
if (legitimate_address_strict(mode,x))\
        goto label;\
}
#else
#define GO_IF_LEGITIMATE_ADDRESS(mode,x,label) \
{\
        if (legitimate_address_non_strict(mode,x))\
                        goto label;\
}
#endif

#ifdef REG_OK_STRICT
#define REG_OK_FOR_BASE_P(x) \
reg_ok_for_base_strict_p(x)
#else
#define REG_OK_FOR_BASE_P(x)  \
reg_ok_for_base_non_strict_p(x)
#endif

#ifdef REG_OK_STRICT
#define REG_OK_FOR_INDEX_P(x) \
reg_ok_for_index_strict_p(x)
#else
#define REG_OK_FOR_INDEX_P(x) \
reg_ok_for_index_non_strict_p(x)
#endif

#define GO_IF_MODE_DEPENDENT_ADDRESS(addr,label)

/* ------------------------------------------------------------------------------*
 *                      Assembly Output Format                                   *
 * ------------------------------------------------------------------------------*/

#define ASM_OUTPUT_ALIGN(STREAM, POWER)                                   \
         asm_output_align(STREAM, POWER)

#define ASM_OUTPUT_SKIP(STREAM, NBYTES)                                   \
         asm_output_skip(STREAM, NBYTES)

#define ASM_OUTPUT_ASCII(STREAM, PTR, LEN)                                \
ajardsp_asm_output_ascii(STREAM, PTR, LEN)

#define PRINT_OPERAND(STREAM, X, CODE)                                    \
         print_operand(STREAM, X, CODE)

#define PRINT_OPERAND_ADDRESS(STREAM, X)                                  \
         print_operand_address(STREAM, X)

#define ASM_GENERATE_INTERNAL_LABEL(STRING, PREFIX, NUM)                  \
        asm_generate_internal_label(STRING, PREFIX, NUM)

#define ASM_OUTPUT_LOCAL(STREAM, NAME, SIZE, ROUNDED)                     \
         asm_output_local(STREAM, NAME, SIZE, ROUNDED)

#define ASM_OUTPUT_COMMON(STREAM, NAME, SIZE, ROUNDED)                    \
         asm_output_common(STREAM, NAME, SIZE, ROUNDED)

#define ASM_OUTPUT_SYMBOL_REF(stream, sym)                                \
        asm_output_symbol_ref(stream, sym)

#define FUNCTION_PROFILER(file,lab) \
function_profiler(file,lab)

#define ASM_APP_ON                                                        \
""
#define ASM_APP_OFF                                                       \
""

extern int target_flags;

#define READONLY_DATA_SECTION_ASM_OP                                      \
".data"

#define TEXT_SECTION_ASM_OP                                               \
".code"

#define DATA_SECTION_ASM_OP                                               \
".data"

#define ASM_OUTPUT_LABELREF(stream, name) \
        fprintf(stream,"%s",name)

#define ASM_OUTPUT_EXTERNAL(stream, decl, name) \
//        fprintf(stream,".extern %s\n",name)

/* ------------------------------------------------------------------------------*
 *                      Misc
 * ------------------------------------------------------------------------------*/

#define OPTIMIZATION_OPTIONS(LEVEL,SIZE) \
ajardsp_optimization_options ((LEVEL), (SIZE))


#define NO_FUNCTION_CSE 1

#define DEFAULT_SIGNED_CHAR \
0

/* Value is 1 if truncating an integer of INPREC bits to OUTPREC bits
   is done just by pretending it is already truncated. */
#define TRULY_NOOP_TRUNCATION(OUTPREC, INPREC) \
1


#define TARGET_CPU_CPP_BUILTINS()\
do                                            \
  {                                           \
      builtin_define_std ("ajardsp");           \
      builtin_assert ("cpu=ajardsp");           \
  }                                           \
  while (0)

/* This macro has been defined to eliminate call to __main function from `main'. */
#define HAS_INIT_SECTION

#define TRAMPOLINE_SIZE 32

#define LEGITIMATE_CONSTANT_P(x) \
legitimate_constant_p(x)

#define ASM_OUTPUT_OPCODE(stream,ptr) \
ptr = ajardsp_asm_output_opcode(stream,ptr)

#define FINAL_PRESCAN_INSN(insn,opvec,noperands) \
ajardsp_final_prescan_insn(insn, opvec, noperands)
