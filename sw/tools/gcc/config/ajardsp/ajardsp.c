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

#include "config.h"
#include "system.h"
#include "coretypes.h"
#include "tm.h"
#include "rtl.h"
#include "tree.h"
#include "tm_p.h"
#include "regs.h"
#include "hard-reg-set.h"
#include "real.h"
#include "insn-config.h"
#include "conditions.h"
#include "output.h"
#include "insn-codes.h"
#include "insn-attr.h"
#include "flags.h"
#include "except.h"
#include "function.h"
#include "recog.h"
#include "expr.h"
#include "optabs.h"
#include "toplev.h"
#include "basic-block.h"
#include "ggc.h"
#include "target.h"
#include "target-def.h"
#include "langhooks.h"
#include "cgraph.h"
#include "df.h"


#include "tree-pass.h"

/* ------------------------------------------------------------------------------*
 *                              Floating point support                           *
 * ------------------------------------------------------------------------------*/

static void
decode_ajardsp_float (const struct real_format *fmt, REAL_VALUE_TYPE *r,
                      const long *buf)
{
  unsigned long image = buf[0] & 0xffff;
  bool sign = (image >> 15) & 1;
  int exp = (image >> 8) & 0xef;

  memset (r, 0, sizeof (*r));
  image <<= (HOST_BITS_PER_LONG - 8 - 1);
  image &= ~SIG_MSB;

  r->cl = rvc_normal;
  r->sign = sign;
  SET_REAL_EXP (r, exp - 63 + 1);
  r->sig[SIGSZ-1] = image | SIG_MSB;
}

static void
encode_ajardsp_float (const struct real_format *fmt, long *buf,
                      const REAL_VALUE_TYPE *r)
{
  unsigned long image, sig, exp;
  unsigned long sign = r->sign;

  image = sign << 15;
  /* r->sig stores the significand with the implicit leading 1 present */
  sig = (r->sig[SIGSZ-1] >> (HOST_BITS_PER_LONG - 8 - 1)) & 0xff;

  switch (r->cl)
    {
    case rvc_zero:
      break;

    case rvc_inf:
      /* not supported */
      break;

    case rvc_nan:
      /* not supported */
      break;

    case rvc_normal:
      /* Recall that IEEE numbers are interpreted as 1.F x 2**exp,
	 whereas the intermediate representation is 0.F x 2**exp.
	 Which means we're off by one.  */

      exp = REAL_EXP (r) + 63 - 1;

      image |= exp << 8;
      image |= sig;
      break;

    default:
      gcc_unreachable ();
    }

  buf[0] = image;
}

const struct real_format ajardsp_single_format =
  {
    encode_ajardsp_float,
    decode_ajardsp_float,
    2,
    9,  /* includes implicit 1 */
    9,  /* includes implicit 1 */
    -125,
    129,
    15,
    15,
    true,
    false,
    false,
    false,
    false,
    true,
    false,
    false
  };


/* ------------------------------------------------------------------------------*
 *                              Nop insertion pass                               *
 * ------------------------------------------------------------------------------*/

static bool
gate_insert_nop (void)
{
  return TARGET_INSERT_NOPS;
}

static void
insert_nop_bb_scan(rtx insn, int cycle, int cycles_left, unsigned int regno, rtx src_insn)
{
  basic_block bb;
  edge e;
  edge_iterator ei;
  rtx start_of_bundle = insn;

  if (insn == NULL)
    return;

  bb = BLOCK_FOR_INSN (insn);

  do
    {
      if (NONDEBUG_INSN_P (insn) && recog_memoized(insn) >= 0 && src_insn != insn)
        {
          if (GET_MODE (insn) == TImode)
            {
              cycle++;
              cycles_left--;
              start_of_bundle = insn;
            }

          if (regno_use_in(regno, PATTERN(insn)) && cycle < insn_latency(src_insn, insn))
            {
              rtx nop;
              int nnops;
              int i;

              nnops = insn_latency(src_insn, insn) - cycle;

              if (dump_file)
                {
                  fprintf(dump_file, "Must insert %d nop(s) between UID: %d and UID: %d for REG: %s)\n",
                          nnops, INSN_UID(src_insn), INSN_UID(insn), reg_names[regno]);
                }

              for (i = 0; i < nnops; i++)
                {
                  rtx nop_insn;
                  nop = gen_nop();
                  nop_insn = emit_insn_before(nop, start_of_bundle);
                  PUT_MODE(nop_insn, TImode);
                  recog_memoized(nop_insn);
                  cycle++;
                  cycles_left--;
                }
            }

          if (cycles_left > 0)
            {
              if (insn == BB_END(bb))
                {
                  FOR_EACH_EDGE (e, ei, bb->succs)
                    {
                      insert_nop_bb_scan(BB_HEAD(e->dest), cycle, cycles_left, regno, src_insn);
                    }
                  break;
                }
            }
          else
            {
              return;
            }
        }
    }
  while (insn = NEXT_INSN(insn));
}

static int
insert_nop(void)
{
  basic_block bb;
  rtx insn;

  dfa_start();  /* needed for *_latency() calls */

  FOR_ALL_BB (bb)
  {
    FOR_BB_INSNS (bb, insn)
      {
#if 0
        if (NONDEBUG_INSN_P (insn) && GET_CODE(PATTERN(insn)) == SET && GET_CODE(SET_DEST(PATTERN(insn))) == REG
            && recog_memoized(insn) >= 0)
          {
            if (dump_file)
              {
                fprintf(dump_file, "Begin scan for insn UID: %d (set to REG: %s)\n",
                        INSN_UID(insn), reg_names[REGNO(SET_DEST(PATTERN(insn)))]);
              }

            insert_nop_bb_scan(insn, 0, maximal_insn_latency(insn), REGNO(SET_DEST(PATTERN(insn))), insn);

          }
#else
        if (NONDEBUG_INSN_P (insn) && recog_memoized(insn) >= 0)
          {
            if (single_set(insn))
              {
                if (GET_CODE(PATTERN(insn)) == SET && GET_CODE(SET_DEST(PATTERN(insn))) == REG)
                  {
                    insert_nop_bb_scan(insn, 0, maximal_insn_latency(insn), REGNO(SET_DEST(PATTERN(insn))), insn);
                  }
              }
            else if (multiple_sets(insn))
              {
                /* open the parallel and for each set do the insert_nop_bb_scan() */
                fprintf(stderr, "multiple_sets()\n");
                debug_rtx(insn);
              }
          }
#endif
      }
  }

  dfa_finish();

  return 0;
}

void nop_delay_slots(void)
{
  rtx insn;
  insn = get_insns();

  do
    {
      if ((JUMP_P(insn) || CALL_P(insn)) && get_attr_dslots(insn) != DSLOTS_0)
        {
          int nnops = 0;
          int i;

          for (i = 0; i < nnops; i++)
            {
              rtx nop_insn;
              rtx nop;
              nop = gen_nop();
              nop_insn = emit_insn_after(nop, insn);
              PUT_MODE(nop_insn, TImode);
              recog_memoized(nop_insn);
            }
        }
    }
  while (insn = NEXT_INSN(insn));
}

struct rtl_opt_pass pass_insert_nop =
{
 {
  RTL_PASS,
  "insert_nop",                         /* name */
  gate_insert_nop,                      /* gate */
  insert_nop,                           /* execute */
  NULL,                                 /* sub */
  NULL,                                 /* next */
  0,                                    /* static_pass_number */
  TV_NONE,                              /* tv_id */
  0,                                    /* properties_required */
  0,                                    /* properties_provided */
  0,                                    /* properties_destroyed */
  0,                                    /* todo_flags_start */
  TODO_dump_func,                       /* todo_flags_finish */
 }
};

static struct register_pass_info pass_info_insert_nop = {
  .pass = &pass_insert_nop,
  .reference_pass_name = "sched2",
  .ref_pass_instance_number = 0,
  .pos_op = PASS_POS_INSERT_AFTER,
};

/* ------------------------------------------------------------------------------*
 *                      Registers and their usage conventions                    *
 * ------------------------------------------------------------------------------*/

static int
is_index_reg(int REGN)
{
  return 0;
}

static int
is_base_reg(int REGN)
{
  if (AJARDSP_REGNO_FIRST_PTR <= REGN && REGN <= AJARDSP_REGNO_LAST_PTR) {
    return 1;
  }
  if (REGN == STACK_POINTER_REGNUM || REGN == HARD_FRAME_POINTER_REGNUM)
    return 1;

  return 0;
}

static int
is_arg_reg(int REGN)
{
  if((AJARDSP_REGNO_FIRST_PTR <= REGN && REGN < AJARDSP_REGNO_FIRST_PTR + 4) ||
     (AJARDSP_REGNO_FIRST_ACC <= REGN && REGN < AJARDSP_REGNO_FIRST_ACC + 4))
    return 1;
  return 0;
}

static int
is_return_val_reg(int REGN)
{
  if((REGN==AJARDSP_REGNO_FIRST_PTR) || (REGN==AJARDSP_REGNO_FIRST_ACC))
    return 1;
  return 0;
}

static int
non_strict_index_reg(int REGN)
{
  return 0;
}

static int
non_strict_base_reg(int regn)
{
  if(is_base_reg(regn))
    return 1;
  if(regn>=FIRST_PSEUDO_REGISTER)
    return 1;
  return 0;
}

static int
is_caller_saved_reg(int REGN)
{
  if((0 <= REGN && REGN <= 3) || (8 <= REGN && REGN <= 15))
    return 1;
  return 0;
}

static int
is_callee_saved_reg(int REGN)
{
  if((4 <= REGN && REGN <= 7) || (16 <= REGN && REGN <= 23))
    return 1;
  return 0;
}

static int
is_general_reg(int REGN)
{
  if(REGN<FIRST_PSEUDO_REGISTER)
    return 1;
  return 0;
}

static int
is_data_reg_low_part(int REGN)
{
  if ((AJARDSP_REGNO_FIRST_ACC <= REGN && REGN <= AJARDSP_REGNO_LAST_ACC))
    {
      if((REGN % 2) == 0)
        {
          return 1;
        }
    }
  return 0;
}


/* ------------------------------------------------------------------------------*
 *                      Assembly Output Format                                   *
 * ------------------------------------------------------------------------------*/

void
ajardsp_asm_internal_label(FILE *stream, const char *prefix, unsigned int labelno)
{
  fprintf(stream,"%s%d:",prefix,labelno);
  return;
}

void
ajardsp_asm_globalize_label(FILE *stream, const char *name)
{
  //  fprintf(stream,".global %s\n",name);
  return;
}

void
asm_output_align(FILE *STREAM, int POWER)
{
  int num,i;
  num=1;
  for(i=0;i<POWER;i++)
    {
      num=num*2;
    }
  fprintf (STREAM, "\t.align %d\n",POWER);
}

void
asm_output_skip(FILE  *STREAM,int NBYTES)
{
  fprintf(STREAM,"\t.skip\t%u\n", NBYTES);
}


/* From final.c :
   % followed by a letter and some digits
   outputs an operand in a special way depending on the letter.
   Letters `acln' are implemented directly.
   Other letters are passed to `output_operand' so that
   the PRINT_OPERAND macro can define them.  */

void
print_operand(FILE *STREAM,rtx X,char CODE)
{
  rtx op;
  switch(CODE)
    {
    case 0:/* Generally, if there is no code after % character, then
              it is considered as register operand. But, for safe case,
              at this place also, I am taking care of all other operands.*/
      if(GET_CODE(X) == REG)
        {
          if (GET_MODE(X) == BImode || GET_MODE(X) == QImode || GET_MODE(X) == QFmode)
            {
              fprintf(STREAM,"%s",reg_names[XINT(X,0)]);
            }
          else if (GET_MODE(X) == HImode)
            {
              /* Note that we only print the first five (e.g. $acc3) characthers
                 of register name if HImode (skip [lh]) */
              int i;
              char* accstr;
              accstr = reg_names[XINT(X,0)];
              for (i = 0; i < 5 && accstr[i]; i++)
                {
                  fprintf(STREAM,"%c", accstr[i]);
                }
            }
          else
            {
              gcc_unreachable();
            }
          break;
        }
      else if(GET_CODE(X) == MEM)
        {
          op=XEXP(X,0);
          PRINT_OPERAND_ADDRESS(STREAM,op);
        }
      else if(GET_CODE(X)==CONST_INT)
        {
          fprintf(STREAM,"%d",XINT(X,0));
        }
      else if(CONSTANT_ADDRESS_P(X))
        {
          PRINT_OPERAND_ADDRESS(STREAM,X);
        }
      else if(COMPARISON_P(X))
        {
          fprintf(STREAM, "%s", rtx_name[GET_CODE(X)]);
        }
      else if(LEGITIMATE_CONSTANT_P(X))
        {
          if(GET_CODE(X)==LABEL_REF)
            {
              ASM_OUTPUT_LABELREF(STREAM,XSTR(X,0));
            }
          else
            {
#if 0
              op=XEXP(X,0);
              PRINT_OPERAND(STREAM,op,0);
#endif
              printf("FIXME: %s:%d\n", __FILE__, __LINE__);
              printf("#Legitimate address");

            }
        }
      else
        {
          printf("other case"
                 " in CODE = 0");
        }
      break;
    case 'm':
      if(GET_CODE(X) != MEM)
        {
          printf("Invalid operand : Not a memory operand");
          return;
        }
      op=XEXP(X,0);
      PRINT_OPERAND_ADDRESS(STREAM,op);
      break;
    case 's':
      if(GET_CODE(X)==SYMBOL_REF)
        {
          output_addr_const(STREAM,X);
        }
      else
        {
          printf("Other than symbol ref not allowed");
        }
      break;
    case 'd':
      if(GET_CODE(X)==CONST_INT)
        {
          fprintf(STREAM,"%d",XINT(X,0));
        }
      else {
        gcc_unreachable();
      }
      break;

    case 'D':
      if(GET_CODE(X)==CONST_INT)
        {
          fprintf(STREAM,"%d",-XINT(X,0));
        }
      else {
        gcc_unreachable();
      }
      break;

    case 'X':
      if (GET_CODE(X) == REG)
        {
          /* Note that we only print the first two characthers of register name (skip [lh]) */
          fprintf(STREAM,"%c%c",reg_names[XINT(X,0)][0], reg_names[XINT(X,0)][1]);
        }
      else
        {
          gcc_unreachable();
        }
      break;

    case 'J':
      /* cond_exec */
      gcc_assert(GET_CODE(X) == EQ || GET_CODE(X) == NE);
      fprintf(STREAM, "if (%s%s)", GET_CODE(X) == EQ ? "" : "!", reg_names[REGNO(XEXP(X, 0))]);
      break;

    default:
      printf("In print operand default");
    }
}


void
print_operand_address(FILE *STREAM,rtx X)
{
  rtx op1,op2,temp;
  int num;

  if (GET_CODE(X) == MEM)
    {
      X = XEXP(X,0);
    }

  switch(GET_CODE(X))
    {
    case SUBREG:
      /*As in case of register indirect mode, where address
        of operand is present in subreg.*/
      fprintf(STREAM,"%s",reg_names[REGNO(XEXP(X,0))]);
      break;
    case REG:
      /*As in case of register indirect mode, address of operand
        in memory is persent in register REGNO(X).*/
      fprintf(STREAM,"%s",      reg_names[REGNO(X)]);
      break;
    case PLUS:
      /*The address can be in base displacement or base - index
        form of addressing.*/
      op1 = XEXP(X,0);
      op2 = XEXP(X,1);
      if((GET_CODE(op1) == CONST_INT || GET_CODE(op1) == SYMBOL_REF) &&
         (GET_CODE(op2) == REG || GET_CODE(op2) == SUBREG))
        /*base displacement*/
        {
          if(GET_CODE(op1) == SYMBOL_REF)
            {
              fprintf(STREAM,"%s, #%s",
                      ((GET_CODE(op2)==REG)
                       ?reg_names[REGNO(op2)]
                       :reg_names[REGNO(XEXP(op2,0))]), XSTR((op1),0));


            }
          else
            {
              fprintf(STREAM,"%s, %d",
                      ((GET_CODE(op2)==REG)
                       ?reg_names[REGNO(op2)]
                       :reg_names[REGNO(XEXP(op2,0))]),  INTVAL(op1));
            }
        }
      else if ((GET_CODE(op2) == CONST_INT || GET_CODE(op2) == SYMBOL_REF) &&
               (GET_CODE(op1) == REG || GET_CODE(op1) == SUBREG))
        /*base displacement*/
        {
          if(GET_CODE(op2) == SYMBOL_REF)
            {
              fprintf(STREAM,"%s, #%s",
                      ((GET_CODE(op1) == REG)
                       ?reg_names[REGNO(op1)]
                       :reg_names[REGNO(XEXP(op1,0))]), XSTR((op2),0));
            }
          else
            {
              fprintf(STREAM,"%s, %d",
                      ((GET_CODE(op1) == REG)
                       ?reg_names[REGNO(op1)]
                       :reg_names[REGNO(XEXP(op1,0))]), INTVAL(op2));
            }
        }
      else
        {
	  fprintf(stderr, "CONST_INT  = %08x\n", CONST_INT) ;
	  fprintf(stderr, "SYMBOL_REF = %08x\n", SYMBOL_REF) ;
	  fprintf(stderr, "SUBREG     = %08x\n", SUBREG) ;
	  fprintf(stderr, "REG        = %08x\n", REG) ;
	  fprintf(stderr, "PC         = %08x\n", PC) ;
	  fprintf(stderr, "CONST      = %08x\n", CONST) ;
	  fprintf(stderr, "GET_CODE(op1) = %08x GET_CODE(op2) = %08x\n", GET_CODE(op1), GET_CODE(op2)) ;
          debug_rtx(X);
          gcc_unreachable();
        }
      break;
    default:
      gcc_unreachable();
      if(CONSTANT_ADDRESS_P(X))
        {
          output_addr_const(STREAM,X);
        }
      else
        fprintf(STREAM,"Coming in default part of"
                " print_operand_address");
      break;
    }
}

void
ajardsp_asm_output_ascii(FILE *stream, char *ptr, int len)
{
  int i;

  for (i = 0; i < len; i++)
    {
      fprintf(stream, "\t.word\t%d\n", ptr[i]);
    }
}

void
asm_generate_internal_label(char *STRING,char *PREFIX,int NUM)
{
  sprintf(STRING,"%s%d", PREFIX,NUM);
}
void
asm_output_local(FILE *STREAM,char *NAME,int SIZE,int ROUNDED)
{
  fprintf(STREAM,"\t.reserve ");
  assemble_name (STREAM, NAME);
  fprintf (STREAM, ",%u,\"bss\"\n", SIZE);
}

void
asm_output_common(FILE *STREAM,char *NAME,int SIZE,int ROUNDED)
{
  int i;

  fprintf(STREAM, ".data\n") ; // NAK
  assemble_name(STREAM,NAME);
  fprintf(STREAM, ":\n");
  fprintf(STREAM, ".skip %d\n", SIZE/UNITS_PER_WORD) ;
/*
  for(i=0;i< SIZE/UNITS_PER_WORD;i++)
    {
      fprintf(STREAM, "\t.word\t0\n");
    }

  fprintf(STREAM,"\n");
*/
}

bool
ajardsp_assemble_integer(rtx x ATTRIBUTE_UNUSED,
                       unsigned int size ATTRIBUTE_UNUSED,
                       int aligned_p ATTRIBUTE_UNUSED)
{
  const char *op = integer_asm_op (size, aligned_p);
  return op && (assemble_integer_with_op (op, x), true);
}


int
asm_output_symbol_ref(FILE *stream, rtx sym)
{
  fprintf(stream,"#");
  assemble_name(stream, XSTR((sym),0));
}

void
function_profiler(FILE*asm_file,int labelno)
{
}

int
hard_regno_mode_ok (int REGN, enum machine_mode MODE)
{
  if (MODE == BImode && 24 <= REGN && REGN <= 27)
    {
      return 1;
    }

  if(GET_MODE_CLASS(MODE) == MODE_FLOAT)
    {
      if (MODE == QFmode && (AJARDSP_REGNO_FIRST_PTR <= REGN && REGN <= AJARDSP_REGNO_LAST_ACC))
        {
          return 1;
        }
    }

  if(GET_MODE_CLASS(MODE) == MODE_INT) {
    if (MODE == QImode && (AJARDSP_REGNO_FIRST_PTR <= REGN && REGN <= AJARDSP_REGNO_LAST_ACC)) {
      return 1;
    }
    if (MODE == HImode && is_data_reg_low_part(REGN)) {
      return 1;
    }

    if (MODE == QImode &&  (REGN == STACK_POINTER_REGNUM || REGN == HARD_FRAME_POINTER_REGNUM)) {
      return 1;
    }

  }

  return 0;
}

int
modes_tieable_p(enum machine_mode MODE1, enum machine_mode MODE2)
{
  if((MODE1 == MODE2)
     || (GET_MODE_SIZE(MODE1) <= GET_MODE_SIZE(MODE2)
         && GET_MODE_CLASS(MODE1) == GET_MODE_CLASS(MODE2)))
    return 1;
  return 0;
}

enum reg_class
regno_reg_class(int REGN)
{
  if(is_callee_saved_reg(REGN))
    return CALLEE_SAVED_REGS;
  if(is_caller_saved_reg(REGN))
    return CALLER_SAVED_REGS;
  if(is_base_reg(REGN))
    return ALL_PTR_REGS;  /* TODO: this should really be ALL_PTR_REGS with the current definition of is_base_reg() */
  if(AJARDSP_REGNO_FIRST_PTR <= (REGN) && (REGN) <= AJARDSP_REGNO_LAST_PTR)
    return PTR_REGS;
  if(AJARDSP_REGNO_FIRST_ACC <= (REGN) && (REGN) <= AJARDSP_REGNO_FIRST_ACC + 7)
    return ACC_REGS_0_3;
  if(AJARDSP_REGNO_FIRST_ACC <= (REGN) && (REGN) <= AJARDSP_REGNO_LAST_ACC)
    return ACC_REGS;
  if(is_general_reg(REGN))
    return GENERAL_REGS;
  if (AJARDSP_REGNO_FIRST_PRED <= (REGN) && (REGN) <= AJARDSP_REGNO_LAST_PRED)
    return PRED_REGS;
  if (AJARDSP_REGNO_FIRST_SPEC <= (REGN) && (REGN) <= AJARDSP_REGNO_LAST_SPEC)
    return SPEC_REGS;

  return NO_REGS;
}

int
ajardsp_regno_ok_for_base_p (int REGN)
{
  if(is_base_reg(REGN)
     || (REGN >= FIRST_PSEUDO_REGISTER
         && is_base_reg(reg_renumber[REGN])))
    return 1;
  return 0;
}

int
regno_ok_for_index_p (int REGN)
{
  if(is_index_reg(REGN)
     || (REGN >= FIRST_PSEUDO_REGISTER
         && is_index_reg(reg_renumber[REGN])))
    return 1;
  return 0;
}

/* ------------------------------------------------------------------------------*
 *                      Activation Record and Calling Conventions                *
 * ------------------------------------------------------------------------------*/

int ajardsp_callee_saved_stack_usage(void)
{
  int i;
  int sum;

  sum = 0;

  for(i=0;i<FIRST_PSEUDO_REGISTER;i++) {
    if(df_regs_ever_live_p(i) && !call_used_regs[i] && !fixed_regs[i]) {
      if (AJARDSP_REGNO_FIRST_PTR <= i && i <= AJARDSP_REGNO_LAST_PTR) {
        sum += 1;
      }
      else if (AJARDSP_REGNO_FIRST_ACC <= i && i <= AJARDSP_REGNO_LAST_ACC) {
        sum += 2;
      }
      else {
        gcc_unreachable();
      }
    }
  }

  printf("%s: sum = %d\n", __FUNCTION__, sum);
  return sum;
}


int
starting_frame_offset (void)
{
  return 0;
}

int
initial_frame_pointer_offset (int DEPTH)
{
  int size;
  size = get_frame_size();
  return size;
}

int registers_to_be_saved(void)
{
  int i,num;
  for(i=0,num=0;i<FIRST_PSEUDO_REGISTER;i++)
    {
      if(df_regs_ever_live_p(i) && !call_used_regs[i] && !fixed_regs[i])
        num++;
    }
  return num;
}

int
initial_elimination_offset(int from, int to)
{
  if(from == FRAME_POINTER_REGNUM && to == STACK_POINTER_REGNUM)
    {
      return (get_frame_size());
    }
  else if(from == FRAME_POINTER_REGNUM && to == HARD_FRAME_POINTER_REGNUM)
    {
      return -(3+registers_to_be_saved())*4;
    }
  else if(from == ARG_POINTER_REGNUM && to == STACK_POINTER_REGNUM)
    {
      return ((3+registers_to_be_saved())*4+get_frame_size());
    }
  else if(from == ARG_POINTER_REGNUM && to == HARD_FRAME_POINTER_REGNUM)
    {
      return 0;
    }
  else if(from == HARD_FRAME_POINTER_REGNUM && to == STACK_POINTER_REGNUM)
    {
      return ((3+registers_to_be_saved())*4+get_frame_size());
    }
  else
    printf("\nIt should not come here... Trying to eliminate non-eliminable register!\n");
  return 0;
}

rtx
ajardsp_struct_value_rtx(tree fndecl, int incoming)
{
  return gen_rtx_REG(Pmode, 2);
}

rtx
ajardsp_function_value (enum machine_mode mode, tree fndecl)
{
  if (fndecl) {
    /*    debug_tree(TREE_TYPE(TREE_TYPE(fndecl)));
          gcc_unreachable(); */
    switch (TREE_CODE(TREE_TYPE(TREE_TYPE(fndecl)))) {

    case INTEGER_TYPE:
      /* printf("%s: INTEGER_TYPE\n", __FUNCTION__); */
      return gen_rtx_REG(mode, AJARDSP_REGNO_FIRST_ACC + (mode == QImode ? 1 : 0));

    case POINTER_TYPE:
      /* printf("%s: POINTER_TYPE\n", __FUNCTION__); */
      return gen_rtx_REG(mode, AJARDSP_REGNO_FIRST_PTR);

    default:
      debug_tree(fndecl);
      gcc_unreachable();
      return NULL_RTX;
    }
  }
  else {  /* LIBCALL */
    return gen_rtx_REG(mode, AJARDSP_REGNO_FIRST_ACC);
  }
}

void *ajardsp_function_arg(CUMULATIVE_ARGS *cum, enum machine_mode mode, tree type, int named)
{
  if (type == NULL) {
    printf("%s: tree type is NULL, type not known, probably a library function... what to do??? revert to stack passing for now\n", __FUNCTION__);
    return NULL_RTX;
  }
#if 0
  printf("function_arg: tree_type: %s\n", tree_code_name[(int) TREE_CODE(type)]);
#endif

#if 1
  switch (TREE_CODE(type)) {
  case INTEGER_TYPE:
    return (cum->a_regs < 4) ? gen_rtx_REG(mode, AJARDSP_REGNO_FIRST_ACC + cum->a_regs*2 + (mode == QImode ? 1 : 0)) : NULL_RTX;
    break;
  case POINTER_TYPE:
    return (cum->r_regs < 4) ? gen_rtx_REG(mode, AJARDSP_REGNO_FIRST_PTR + cum->r_regs) : NULL_RTX;
    break;
  default:
    return NULL_RTX;
    break;
  }
#endif
  return NULL_RTX;
}

void ajardsp_function_arg_advance(CUMULATIVE_ARGS *cum, enum machine_mode mode,
                                tree type, int named)
{
  if (type == NULL) {
    printf("%s: tree type is NULL, type not known, probably a library function... what to do??? doing nothing\n", __FUNCTION__);
    return;
  }

#if 0
  printf("function_arg_advance: tree_type: %s\n", tree_code_name[(int) TREE_CODE(type)]);
  printf("cum.r_regs: %d\ncum.a_regs: %d\n", cum->r_regs, cum->a_regs);
#endif

  switch (TREE_CODE(type)) {
  case INTEGER_TYPE:
    cum->a_regs++;
    break;
  case POINTER_TYPE:
    cum->r_regs++;
    break;
  default:
    break;
  }
}

/* ------------------------------------------------------------------------------*
 *                      Addressing Mode information                              *
 * ------------------------------------------------------------------------------*/

int
constant_address_p (rtx X)
{
  return (CONSTANT_P(X) &&
          GET_CODE(X)!=CONST_DOUBLE
          && GET_CODE(X)!=CONST_VECTOR);
}

/*This function corresponds to the macro GO_IF_LEGITIMATE_ADDRESS. There are
 * two varients of this macro: one when the registers used may or may not be
 * hard registers, and second when the registers must be LEGITIMATE HARD
 * REGISTERS. This function checks if the address is legitimate or not.*/
int
legitimate_address_strict(enum machine_mode MODE,rtx X)
{
  rtx op1,op2;

  if(GET_CODE(X)==REG && is_base_reg(REGNO(X)))
    return 1;
  if(GET_CODE(X)==PLUS)
    {
      op1=XEXP(X,0);
      op2=XEXP(X,1);
      if(GET_CODE(op1)==REG && CONSTANT_ADDRESS_P(op2) && is_base_reg(REGNO(op1)))
        {
            return 1;
        }
      if(GET_CODE(op2)==REG && CONSTANT_ADDRESS_P(op1) && is_base_reg(REGNO(op2)))
        {
            return 1;
        }
    }
  return 0;

}

int
legitimate_address_non_strict(enum machine_mode MODE,rtx X)
{
  rtx op1,op2;

  if(GET_CODE(X)==REG && non_strict_base_reg(REGNO(X)))
    return 1;
  if(GET_CODE(X)==PLUS)
    {
      op1=XEXP(X,0);
      op2=XEXP(X,1);
      if(GET_CODE(op1)==REG && CONSTANT_ADDRESS_P(op2) && non_strict_base_reg(REGNO(op1)))
        return 1;
      if(GET_CODE(op2)==REG && CONSTANT_ADDRESS_P(op1) && non_strict_base_reg(REGNO(op2)))
        return 1;
    }
  return 0;
}

int
reg_ok_for_base_strict_p(rtx x)
{
  if(is_base_reg(REGNO(x)))
    return 1;
  return 0;
}

int
reg_ok_for_base_non_strict_p(rtx x)
{
  if(non_strict_base_reg(REGNO(x)))
    return 1;
  return 0;
}

int
reg_ok_for_index_strict_p(rtx x)
{
  if(is_index_reg(REGNO(x)))
    return 1;
  return 0;
}

int
reg_ok_for_index_non_strict_p(rtx x)
{
  if(non_strict_index_reg(REGNO(x)))
    return 1;
  return 0;
}

rtx
legitimize_address(rtx X,rtx OLDX, enum machine_mode MODE)
{
  rtx op1,op2,op;
  op=NULL;
  if(memory_address_p(MODE,X))
    return X;
  if(GET_CODE(X)==MEM && can_create_pseudo_p())
    op = force_reg(MODE,X);
  else if(GET_CODE(X)==PLUS && can_create_pseudo_p())
    {
      op1=XEXP(X,0);
      op2=XEXP(X,1);
      if(GET_CODE(op1)==REG && !CONSTANT_ADDRESS_P(op2))
        {
          op=force_reg(MODE,X);
        }
      else if(GET_CODE(op2)==REG && !CONSTANT_ADDRESS_P(op1))
        {
          op=force_reg(MODE,X);
        }
    }
  if(op!=NULL && memory_address_p(MODE,op))
    return op;
  return X;
}

int
legitimate_constant_p (rtx X)
{
  return (GET_CODE(X)!= CONST_DOUBLE);
}


void
initialize_trampoline(void)
{
  return;
}

/* address cost taken directly from ARM!! This needs to be adjusted, however
   seems to make IVOPTS do the right thing (not splitting IVs for unrolled loops) */

int
ajardsp_address_cost (rtx x)
{
  enum rtx_code c  = GET_CODE (x);

  if (c == PRE_INC || c == PRE_DEC || c == POST_INC || c == POST_DEC)
    return 0;
  if (c == MEM || c == LABEL_REF || c == SYMBOL_REF)
    return 10;

  if (c == PLUS || c == MINUS)
    {
      if (GET_CODE (XEXP (x, 0)) == CONST_INT)
        return 2;

      if (ARITHMETIC_P (XEXP (x, 0)) || ARITHMETIC_P (XEXP (x, 1)))
        return 3;

      return 4;
    }

  return 6;
}

/* ------------------------------------------------------------------------------*
 *                      Instruction bundling (VLIW packing)                      *
 * ------------------------------------------------------------------------------*/

int ajardsp_sched_issue_rate(void)
{
  return 4;
}

int ajardsp_sched_first_cycle_multipass_dfa_lookahead(void)
{
  return 16;  /* Why 16 ??? */
}

/* Push/pop operations pose a problem in that the the pre_dec/post_inc gives
   true data dependencies between two consecutive push (or pop) instructions.
   The hardware correctly executes two push (pop) instructions in the same cycle
   so this hook is used to adust the dependency cost to zero for these cases.
   It significantly improves scheduling of prologues/epilogues.
*/

int ajardsp_sched_adjust_cost (rtx insn, rtx link, rtx dep_insn, int cost)
{

  if (REG_NOTE_KIND (link) == REG_DEP_TRUE)
    {

      if (recog_memoized (insn) == CODE_FOR_popqi1 ||
          recog_memoized (insn) == CODE_FOR_pophi1)
        {
          if (recog_memoized (dep_insn) == CODE_FOR_popqi1 ||
              recog_memoized (dep_insn) == CODE_FOR_pophi1)
            {
              return 0;
            }
        }

      if (recog_memoized (insn) == CODE_FOR_pushqi1 ||
          recog_memoized (insn) == CODE_FOR_pushhi1)
        {
          if (recog_memoized (dep_insn) == CODE_FOR_pushqi1 ||
              recog_memoized (dep_insn) == CODE_FOR_pushhi1)
            {
              return 0;
            }
        }

    }

  return cost;
}

static int ajardsp_curr_insn_start_issue_group = 0;

void
ajardsp_asm_function_prologue (FILE *file, HOST_WIDE_INT size ATTRIBUTE_UNUSED)
{
}

void
ajardsp_final_prescan_insn (rtx insn, rtx *opvec,
                          int noperands ATTRIBUTE_UNUSED)
{
  if (TARGET_VLIW_PACK)
    {
      if (GET_MODE (insn) == TImode ||
          GET_CODE(PATTERN(insn)) == UNSPEC)
        {
          ajardsp_curr_insn_start_issue_group =  1;
        }
      else
        {
          ajardsp_curr_insn_start_issue_group =  0;
        }
    }
}

const char *
ajardsp_asm_output_opcode (FILE *f, const char *ptr)
{
  int insn_width = 8;

  if (TARGET_VLIW_PACK) {
    if (ajardsp_curr_insn_start_issue_group) {
      fprintf(f, "  ");
    }
    else {
      fprintf(f, "| ");
    }
  }
#if 0
  while (*ptr && *ptr != ' ')
    {
      fprintf(f, "%c", *ptr);
      ptr++;
      insn_width--;
    }

  while (insn_width > 0)
    {
      fprintf(f, " ");
      insn_width--;
    }
#endif
  return ptr;
}

/* ------------------------------------------------------------------------------*
 *                      Instruction-pattern predicates                           *
 * ------------------------------------------------------------------------------*/

int
symbolic_operand (rtx op, enum machine_mode mode)
{
  if(GET_CODE(op) == CONST || GET_CODE(op) == SYMBOL_REF || GET_CODE(op) == LABEL_REF)
    {
      return 1;
    }
  return 0;
}
int
constant_operand (rtx op, enum machine_mode mode)
{
  if(GET_CODE(op)!=CONST_INT)
    return 0;
  if(INTVAL(op) <=0xff)
    {
      return 1;
    }
  return 0;
}

int
zero_register_operand (rtx op, enum machine_mode mode)
{
  if(GET_CODE(op)!=REG)
    return 0;
  if(REGNO(op) == 0)
    {
      return 1;
    }
  return 0;
}

int
LO_register_operand (rtx op, enum machine_mode mode)
{
  if(GET_CODE(op)!=REG)
    return 0;
  if(REGNO(op) == 26)
    {
      return 1;
    }
  return 0;
}

int
addr_register_operand (rtx op, enum machine_mode mode)
{
  if (GET_MODE (op) != mode && mode != QImode)
    return 0;
  if(GET_CODE(op)!=REG)
    return 0;
  if(AJARDSP_REGNO_FIRST_PTR <= REGNO(op) && REGNO(op) <= AJARDSP_REGNO_LAST_PTR)
    return 1;
  if (REGNO(op) >=FIRST_PSEUDO_REGISTER)
    return 1;

  return 0;
}

/* ------------------------------------------------------------------------------*
 *                      Function entry (prologue) and exit (epilogue)            *
 * ------------------------------------------------------------------------------*/

void
ajardsp_prologue(void)
{
  int i;

  emit_insn(gen_pushqi1(hard_frame_pointer_rtx));
  emit_move_insn(hard_frame_pointer_rtx, stack_pointer_rtx);

  if (1 || !leaf_function_p())
    {
      emit_insn(gen_pushqi1(gen_rtx_REG(QImode, AJARDSP_REGNO_RETPC)));
    }

  if (get_frame_size() > 0)
    {
      emit_insn(gen_rtx_SET(QImode, hard_frame_pointer_rtx,
                            plus_constant(hard_frame_pointer_rtx, -(get_frame_size()  + 2 /* retpc */))));
      emit_insn(gen_swap_spec_qi(stack_pointer_rtx, hard_frame_pointer_rtx));
      emit_insn(gen_nop()) ;
      emit_insn(gen_pushqi1(hard_frame_pointer_rtx));  /* stack pointer before locals */
    }

  for(i=0;i<FIRST_PSEUDO_REGISTER;i++)
    {
      if(df_regs_ever_live_p(i) && !call_used_regs[i] && !fixed_regs[i])
        {
          if (AJARDSP_REGNO_FIRST_PTR <= i && i <= AJARDSP_REGNO_LAST_PTR) {
            emit_insn(gen_pushqi1(gen_rtx_REG(QImode,i)));
          }
          else if (AJARDSP_REGNO_FIRST_ACC <= i && i <= AJARDSP_REGNO_LAST_ACC) {
            //              emit_insn(gen_pushhi1(gen_rtx_REG(HImode,i)));
            // TODO FIXME
            emit_insn(gen_pushqi1(gen_rtx_REG(QImode,i)));
          }
          else {
            gcc_unreachable();
          }
        }
    }
}

void
ajardsp_epilogue(void)
{
  int i;

  for(i=FIRST_PSEUDO_REGISTER-1; i >= 0; i--) /*Restore all the callee-registers from stack frame*/
    {
      if(df_regs_ever_live_p(i) && !call_used_regs[i] && !fixed_regs[i])
        {
          if (AJARDSP_REGNO_FIRST_PTR <= i && i <= AJARDSP_REGNO_LAST_PTR) {
            emit_insn(gen_popqi1(gen_rtx_REG(QImode,i)));
          }
          else if (AJARDSP_REGNO_FIRST_ACC <= i && i <= AJARDSP_REGNO_LAST_ACC) {
            //              emit_insn(gen_pophi1(gen_rtx_REG(HImode,i)));
            // TODO FIXME
            emit_insn(gen_popqi1(gen_rtx_REG(QImode,i)));
          }
          else {
            gcc_unreachable();
          }
        }
    }

  if (get_frame_size() > 0)
    {
      emit_insn(gen_popqi1(stack_pointer_rtx));
    }

  if (1 || !leaf_function_p())
    {
      emit_insn(gen_popqi1(gen_rtx_REG(QImode, AJARDSP_REGNO_RETPC)));
    }

  emit_insn(gen_popqi1(hard_frame_pointer_rtx));

  /*Jump instruction*/
  emit_jump_insn(gen_ajardsp_return());
}

/* ------------------------------------------------------------------------------*
 *                      Machine dependent reorg (hwloop opt)                     *
 * ------------------------------------------------------------------------------*/

struct ajardsp_doloop_end_info
{
  rtx pattern;
  rtx cmp;
  rtx inc;
  rtx reg;
  rtx inc_src;
  rtx lab_ref;
  rtx niter;
};

static int ajardsp_parse_doloop_end_pattern(rtx insn, struct ajardsp_doloop_end_info *info)
{
  rtx pattern;
  rtx cmp;
  rtx inc;
  rtx reg;
  rtx inc_src;
  rtx lab_ref;
  rtx niter;

  pattern = PATTERN (insn);
  if (pattern == NULL_RTX)
    return 0;

  if (GET_CODE (pattern) != PARALLEL)
    return 0;

  cmp = XVECEXP (pattern, 0, 0);
  if (cmp == NULL_RTX)
    return 0;

  inc = XVECEXP (pattern, 0, 1);
  if (inc == NULL_RTX)
    return 0;

  if (GET_CODE (inc) != SET)
    return 0;

  niter = XEXP(XVECEXP (pattern, 0, 2), 0);
  if (niter == NULL_RTX)
    return 0;

  reg = SET_DEST (inc);
  if (reg == NULL_RTX || ! REG_P (reg))
    return 0;

  inc_src = SET_SRC (inc);
  if (inc_src == NULL_RTX)
    return 0;

  if (GET_CODE (inc_src) != PLUS
      || XEXP (inc_src, 0) != reg
      || XEXP (inc_src, 1) != constm1_rtx)
    return 0;

  if (GET_CODE (cmp) != SET
      || SET_DEST (cmp) != pc_rtx
      || GET_CODE (SET_SRC (cmp)) != IF_THEN_ELSE
      || GET_CODE (XEXP (SET_SRC (cmp), 1)) != LABEL_REF
      || XEXP (SET_SRC (cmp), 2) != pc_rtx)
    return 0;

  lab_ref = XEXP (SET_SRC (cmp), 1);

  info->pattern = pattern;
  info->cmp = cmp;
  info->inc = inc;
  info->reg = reg;
  info->inc_src = inc_src;
  info->lab_ref = lab_ref;
  info->niter = niter;

  return 1;
}

void
ajardsp_reorg(void)
{
  rtx insn;
  struct ajardsp_doloop_end_info info;
  basic_block bb;

  nop_delay_slots();

  insn = get_insns();

  if (!TARGET_HWLOOP)
    return;

  FOR_EACH_BB (bb)
  {
    rtx tail = BB_END (bb);

    while (GET_CODE (tail) == NOTE)
      tail = PREV_INSN (tail);

    if (INSN_P (tail) && recog_memoized (tail) == CODE_FOR_doloop_end_internal)
      {
        rtx loop_head;

        loop_head = BB_HEAD (BRANCH_EDGE (bb)->dest);

        if (ajardsp_parse_doloop_end_pattern(tail, &info))
          {
            rtx loop_last_insn_label;
            rtx tmp_insn;
            rtx hwloop_insn;

            loop_last_insn_label = gen_label_rtx();

            if (TARGET_VLIW_PACK)
              {
                tmp_insn = prev_real_insn(tail);
                while (GET_MODE(tmp_insn) != TImode)
                  tmp_insn = prev_real_insn(tmp_insn);
              }
            else
              {
                tmp_insn = prev_real_insn(tail);
              }

            emit_label_before(loop_last_insn_label, tmp_insn);

            LABEL_NUSES(loop_last_insn_label)++;
            hwloop_insn = gen_block_repeat(info.niter, gen_rtx_LABEL_REF(Pmode, loop_last_insn_label));
            emit_insn_before(hwloop_insn, loop_head);
            PUT_MODE(hwloop_insn, TImode);
          }
      }
  }
}

/* ------------------------------------------------------------------------------*
 *                      Misc                                                     *
 * ------------------------------------------------------------------------------*/

void
ajardsp_optimization_options (int level, int size ATTRIBUTE_UNUSED)
{
  register_pass (&pass_info_insert_nop);

  target_flags |= MASK_INSERT_NOPS;

  if (level > 2)
    {
      target_flags |= MASK_VLIW_PACK;
      //      target_flags |= MASK_HWLOOP;
    }
}

/* Copy-paste from picochip */
int
ajardsp_absolute_memory_operand (rtx op,
                               enum machine_mode mode ATTRIBUTE_UNUSED)
{

  if (MEM == GET_CODE (op))
    {
      rtx address = XEXP (op, 0);

      /* Symbols are valid absolute addresses. */
      if (SYMBOL_REF == GET_CODE (address))
        return 1;

      /* Constant offsets to symbols are valid absolute addresses. */
      if (CONST == GET_CODE (address) &&
          PLUS == GET_CODE (XEXP (address, 0)) &&
          SYMBOL_REF == GET_CODE (XEXP (XEXP (address, 0), 0)) &&
          CONST_INT == GET_CODE (XEXP (XEXP (address, 0), 1)))
        return 1;

    }
  else
    return 0;

  /* Symbols are valid absolute addresses. */
  if (SYMBOL_REF == GET_CODE (XEXP (op, 0)))
    return 1;


  return 0;

}



#undef TARGET_STRUCT_VALUE_RTX
#define TARGET_STRUCT_VALUE_RTX                 \
  ajardsp_struct_value_rtx

#undef TARGET_ASM_GLOBALIZE_LABEL
#define TARGET_ASM_GLOBALIZE_LABEL              \
  ajardsp_asm_globalize_label

#undef TARGET_ASM_INTERNAL_LABEL
#define TARGET_ASM_INTERNAL_LABEL               \
  ajardsp_asm_internal_label

#undef  TARGET_ADDRESS_COST
#define TARGET_ADDRESS_COST                     \
  ajardsp_address_cost

#undef TARGET_SCHED_ISSUE_RATE
#define TARGET_SCHED_ISSUE_RATE                 \
  ajardsp_sched_issue_rate

#undef TARGET_SCHED_FIRST_CYCLE_MULTIPASS_DFA_LOOKAHEAD
#define TARGET_SCHED_FIRST_CYCLE_MULTIPASS_DFA_LOOKAHEAD        \
  ajardsp_sched_first_cycle_multipass_dfa_lookahead

#undef TARGET_SCHED_ADJUST_COST
#define TARGET_SCHED_ADJUST_COST                \
  ajardsp_sched_adjust_cost


#undef TARGET_MACHINE_DEPENDENT_REORG
#define TARGET_MACHINE_DEPENDENT_REORG          \
  ajardsp_reorg

#undef  TARGET_ASM_FUNCTION_PROLOGUE
#define TARGET_ASM_FUNCTION_PROLOGUE            \
  ajardsp_asm_function_prologue

#undef TARGET_ASM_BYTE_OP
#define TARGET_ASM_BYTE_OP                      \
  "\t.word\t"

#undef TARGET_ASM_ALIGNED_HI_OP
#define TARGET_ASM_ALIGNED_HI_OP                \
  "\t.dword\t"

#undef TARGET_ASM_UNALIGNED_HI_OP
#define TARGET_ASM_UNALIGNED_HI_OP              \
  "\t.dword\t"

#undef TARGET_ASM_INTEGER
#define TARGET_ASM_INTEGER                      \
  ajardsp_assemble_integer

struct gcc_target targetm = TARGET_INITIALIZER;


