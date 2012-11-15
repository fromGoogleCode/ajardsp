;; This file is part of the AjarDSP GCC configuration.
;;
;; Copyright (C) 2010 Markus Lavin.
;;
;; Copyright (C) 2006, 2007, 2008, 2009, 2010 Free Software Foundation, Inc.
;;
;; This file is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 3 of the License, or (at your option)
;; any later version.
;;
;; This file is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
;; for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GCC; see the file COPYING3.  If not see
;; <http://www.gnu.org/licenses/>.

(include "constraints.md")
(include "predicates.md")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Definition of constants
;;=======================

(define_constants
  [
   (PTR0_REGNUM        0)
   (PTR1_REGNUM        1)
   (PTR2_REGNUM        2)
   (PTR3_REGNUM        3)
   (PTR4_REGNUM        4)
   (PTR5_REGNUM        5)
   (PTR6_REGNUM        6)
   (PTR7_REGNUM        7)

   (ACC0L_REGNUM       8)
   (ACC0H_REGNUM       9)
   (ACC1L_REGNUM       10)
   (ACC1H_REGNUM       11)
   (ACC2L_REGNUM       12)
   (ACC2H_REGNUM       13)
   (ACC3L_REGNUM       14)
   (ACC3H_REGNUM       15)
   (ACC4L_REGNUM       16)
   (ACC4H_REGNUM       17)
   (ACC5L_REGNUM       18)
   (ACC5H_REGNUM       19)
   (ACC6L_REGNUM       20)
   (ACC6H_REGNUM       21)
   (ACC7L_REGNUM       22)
   (ACC7H_REGNUM       23)

   (PRED0_REGNUM       24)
   (PRED1_REGNUM       25)
   (PRED2_REGNUM       26)
   (PRED3_REGNUM       27)

   (SP_REGNUM          28)
   (RETPC_REGNUM       29)

   (UNSPEC_HWLOPP_INIT 1024)
  ]
)

;; Predication.  True iff this instruction can be predicated.
(define_attr "predicable" "no,yes" (const_string "yes"))

;; General predication pattern
(define_cond_exec
  [(match_operator 0 "predicate_operator"
		   [(match_operand:BI 1 "pred_register_operand" "z")
		    (const_int 0)])]
  ""
  "%J0")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Definition of instruction attributes
;;====================================

(define_attr "itype" "bmu,cu,cu_cmp,cu_fp,lsu,lsu_spec,lsu_all,pcu"
  (const_string "pcu"))

(define_attr "isize" "1,2"
  (const_string "2"))

(define_attr "dslots" "0,2"
  (const_string "0"))

;; This dummy pattern is needed for some reason (to avoid empty data structures)
(define_insn "dummy_pattern"
        [(reg:QI 0)]
        "1"
        "This stmnt should not be emitted!"
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Function prologue and epilogue (special)
;;========================================

(define_expand "prologue"
  [(clobber (const_int 0))]
  "!TARGET_DIS_PROEPILOGUE"
  {
     ajardsp_prologue();
     DONE;
  })

(define_expand "epilogue"
  [(clobber (const_int 0))]
  "!TARGET_DIS_PROEPILOGUE"
  {
     ajardsp_epilogue();
     DONE;
  })

;; Every callee-saved register is marked as used by the return insn to keep
;; the flow pass from deleting epilogue insns (they would otherwise appear
;; as dead register stores).
(define_insn "ajardsp_return"
        [(return)
	 (use (reg:QI RETPC_REGNUM))
         (use (reg:QI PTR4_REGNUM))
         (use (reg:QI PTR5_REGNUM))
         (use (reg:QI PTR6_REGNUM))
         (use (reg:QI PTR7_REGNUM))
         (use (reg:QI ACC4L_REGNUM))
         (use (reg:QI ACC4H_REGNUM))
         (use (reg:QI ACC5L_REGNUM))
         (use (reg:QI ACC5H_REGNUM))
         (use (reg:QI ACC6L_REGNUM))
         (use (reg:QI ACC6H_REGNUM))
         (use (reg:QI ACC7L_REGNUM))
         (use (reg:QI ACC7H_REGNUM))
         ]
        ""
        "rets"
[(set_attr "itype" "pcu")
 (set_attr "dslots" "2")])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;movqi/movhi expanders
;;=====================

(define_expand "movqi"
        [(set (match_operand:QI 0 "nonimmediate_operand" "")
              (match_operand:QI 1 "general_operand" "")
        )]
        ""
        {
          if(0 && GET_CODE(operands[1])==CONST_INT && INTVAL(operands[1])==0)
          {
            emit_insn(gen_move_zero(operands[0],gen_rtx_REG(QImode,0)));
            DONE;
          }
          else
          if(GET_CODE(operands[0])==MEM && GET_CODE(operands[1])!=REG)
          {

            if(can_create_pseudo_p())
            {
                operands[1]=force_reg(QImode,operands[1]);
            }
          }
        }
)

(define_expand "movhi"
        [(set (match_operand:HI 0 "nonimmediate_operand" "")
              (match_operand:HI 1 "general_operand" "")
        )]
        ""
        {

          if(GET_CODE(operands[0]) == REG && GET_CODE(operands[1]) == CONST_INT)
          {
    	    rtx lo_int = gen_rtx_CONST_INT(QImode, trunc_int_for_mode(INTVAL(operands[1]) & 0xffff, QImode));
	    rtx hi_int = gen_rtx_CONST_INT(QImode, trunc_int_for_mode((INTVAL(operands[1]) >> 16) & 0xffff, QImode));

	    rtx lo_reg = simplify_gen_subreg (QImode, operands[0], HImode, 0);
	    rtx hi_reg = simplify_gen_subreg (QImode, operands[0], HImode, 1);

	    emit_move_insn(lo_reg, lo_int);
	    emit_move_insn(hi_reg, hi_int);

            DONE;
          }

          if(GET_CODE(operands[0])==MEM && GET_CODE(operands[1])!=REG)
          {

            if(can_create_pseudo_p())
            {
                operands[1]=force_reg(HImode,operands[1]);
            }
          }
        }
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Load patterns (from memory and constants)
;;=========================================

(define_insn "*ld_qi"
  [(set (match_operand:QI 0 "register_operand" "=r,r")
        (match_operand:QI 1 "memory_operand" "Qr,m"))]
  ""
  "@
   ld16 %1, %0
   ldoff16 %a1, %0"
  [(set_attr "itype" "lsu,lsu")
   (set_attr "isize" "1,2")])

(define_insn "*ld_inc_qi"
  [(set (match_operand:QI 0 "register_operand" "=d")
        (mem:QI (post_inc (match_operand:QI 1 "addr_register_operand" "b"))))]
  ""
  "ldinc16 %a1, %0"
  [(set_attr "itype" "lsu")
   (set_attr "isize" "1")])

(define_insn "*ld_hi"
  [(set (match_operand:HI 0 "register_operand" "=d,d")
        (match_operand:HI 1 "memory_operand" "Qr,m"))]
  ""
  "@
   ld32 %1, %0
   ldoff32 %a1, %0"
  [(set_attr "itype" "lsu,lsu")
   (set_attr "isize" "1,2")])

;;Constant loads

(define_insn "*ld_imm_qi"
  [(set (match_operand:QI 0 "register_operand" "=r,r")
        (match_operand:QI 1 "const_int_operand" "i,Iu16"))]
  ""
  "@
   ldimm16 %c1, %0
   ldimm16 %c1, %0"
  [(set_attr "itype" "lsu")
   (set_attr "isize" "2")])

(define_insn "*ld_zero_qi"
  [(set (match_operand:QI 0 "register_operand" "=d")
        (const_int 0))]
  ""
  "sub16 %0, %0"
  [(set_attr "itype" "cu")
   (set_attr "isize" "1")])

(define_insn "*ld_zero_hi"
  [(set (match_operand:HI 0 "register_operand" "=d")
        (const_int 0))]
  ""
  "sub32 %0, %0, %0"
  [(set_attr "itype" "cu")
   (set_attr "isize" "1")])

(define_insn "*symbolic_address_load"
  [(set (match_operand:QI 0 "register_operand" "=r")
        (match_operand:QI 1 "symbolic_operand" ""))]
  ""
  "ldimm16 %s1, %0"
  [(set_attr "itype" "lsu")
   (set_attr "isize" "2")])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Store patterns (to memory)
;;====================================

(define_insn "*st_qi"
  [(set (match_operand:QI 0 "memory_operand" "=Qr,m")
        (match_operand:QI 1 "register_operand" "r,r"))]
  ""
  "@
   st16 %1, %0
   stoff16 %1, %a0"
  [(set_attr "itype" "lsu_all,lsu_all")  ;;FIXME: should _only_ be lsu_all if second operand is a $ptr register
   (set_attr "isize" "1,2")])

(define_insn "*store_word_hi"
  [(set (match_operand:HI 0 "memory_operand" "=Qr,m")
        (match_operand:HI 1 "register_operand" "r,r"))]
  ""
  "@
   st32 %1, %0
   stoff32 %1, %a0"
  [(set_attr "itype" "lsu,lsu")
   (set_attr "isize" "1,2")])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Move patterns (register to register)
;;====================================

(define_insn "*mv_qi"
  [(set (match_operand:QI 0 "register_operand" "=r,q,r,q")
        (match_operand:QI 1 "register_operand" "r,r,q,0")
        )]
  ""
  "@
   mv16 %1, %0
   mvts16 %1, %0
   mvfs16 %1, %0
   dummy"
  [(set_attr "itype" "lsu,lsu_spec,lsu_spec,lsu")
   (set_attr "isize" "1,2,2,1")])

(define_insn "*mv_hi"
  [(set (match_operand:HI 0 "register_operand" "=d")
        (match_operand:HI 1 "register_operand" "d")
        )]
  ""
  "and32 %1, %1, %0"
  [(set_attr "itype" "bmu")
   (set_attr "isize" "2")])

(define_insn "swap_spec_qi"
  [(parallel
    [(set (match_operand:QI 0 "register_operand" "=r,q")
	  (match_operand:QI 1 "register_operand" "=q,r"))
     (set (match_dup 1)
	  (match_dup 0))]
    )]
  ""
  "@
   mvfs16 %1, %0 | mvts16 %0, %1
   mvfs16 %0, %1 | mvts16 %1, %0"
  [(set_attr "itype" "lsu_all,lsu_all")
   (set_attr "isize" "2,2")])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Push/pop stack operations
;;=========================

(define_insn "pushqi1"
  [(set (mem:QI (pre_dec (reg:QI SP_REGNUM)))
        (match_operand:QI 0 "register_operand" "r,q"))]
  ""
  "@
   push16 %0
   push16 %0"
  [(set_attr "itype" "lsu,lsu_spec")
   (set_attr "isize" "1,1")])

(define_insn "pushhi1"
  [(set (mem:HI (pre_dec (reg:QI SP_REGNUM)))
        (match_operand:HI 0 "register_operand" "r"))]
  ""
  "push32 %0"
  [(set_attr "itype" "lsu")
   (set_attr "isize" "1")])

(define_insn "popqi1"
  [(set (match_operand:QI 0 "register_operand" "=r,q")
        (mem:QI (post_inc (reg:QI SP_REGNUM))))]
  ""
  "@
   pop16 %0
   pop16 %0"
  [(set_attr "itype" "lsu,lsu_spec")
   (set_attr "isize" "1,1")])

(define_insn "pophi1"
  [(set (match_operand:HI 0 "register_operand" "=r")
        (mem:HI (post_inc (reg:QI SP_REGNUM))))]
  ""
  "pop32 %0"
  [(set_attr "itype" "lsu")
   (set_attr "isize" "1")])


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Arithmatic and logical operations
;;===================================

(define_insn "addqi3"
  [(set (match_operand:QI 0 "register_operand" "=d,b")
        (plus:QI (match_operand:QI 1 "register_operand" "0,0")
                 (match_operand:QI 2 "nonmemory_operand" "d,Is16"))
        )]
  ""
  "@
   add16 %2, %0
   addptr16 %2, %0"
  [(set_attr "itype" "cu,lsu")
   (set_attr "isize" "1,2")])

(define_insn "addhi3"
  [(set (match_operand:HI 0 "register_operand" "=d")
        (plus:HI (match_operand:HI 1 "register_operand" "d")
                 (match_operand:HI 2 "nonmemory_operand" "d"))
        )]
  ""
  "add32 %1, %2, %0"
  [(set_attr "itype" "cu")
   (set_attr "isize" "1")])

(define_insn "absqi2"
        [(set (match_operand:QI 0 "register_operand" "=y")
              (abs:QI (match_operand:QI 1 "register_operand" "d")))]
        ""
        "absh %1, %0"
[(set_attr "itype" "cu")])

(define_insn "abshi2"
        [(set (match_operand:HI 0 "register_operand" "=d")
              (abs:HI (match_operand:HI 1 "register_operand" "d")))]
        ""
        "abs %1, %0"
[(set_attr "itype" "cu")])



(define_insn "andqi3"
        [(set (match_operand:QI 0 "register_operand" "=d")
              (and:QI (match_operand:QI 1 "register_operand" "d")
                      (match_operand:QI 2 "register_operand" "d"))
         )]
        ""
        "and16 %2, %1, %0"
[(set_attr "itype" "bmu")])

;; NAK 2012-11-14 Added half int-single int multiplication
(define_insn "mulhisi3"
        [(set (match_operand:SI 0 "register_operand" "=d")
              (mult:SI (match_operand:HI 1 "register_operand" "d")
                       (match_operand:HI 2 "register_operand" "d"))
         )]
        ""
        "mpy16 %2, %1, %0"
[(set_attr "itype" "cu")])

(define_insn "andhi3"
        [(set (match_operand:HI 0 "register_operand" "=d")
              (and:HI (match_operand:HI 1 "register_operand" "d")
                      (match_operand:HI 2 "register_operand" "d"))
         )]
        ""
        "and32 %2, %1, %0"
[(set_attr "itype" "bmu")])


(define_insn "mulqihi3"
        [(set (match_operand:HI 0 "register_operand" "=d")
              (mult:HI (sign_extend:HI (match_operand:QI 1 "register_operand" "D"))
                       (sign_extend:HI (match_operand:QI 2 "register_operand" "D")))
         )]
        ""
        "mpy16 %2, %1, %0"
[(set_attr "itype" "cu")])

(define_insn "*mac_qi"
  [(set (match_operand:HI 0 "register_operand" "=d")
        (plus:HI (mult:HI (sign_extend:HI (match_operand:QI 2 "register_operand" "D"))
                          (sign_extend:HI (match_operand:QI 3 "register_operand" "D")))
                 (match_operand:HI 1 "register_operand" "0")
              ))]
        ""
        "mac16 %2, %3, %0"
[(set_attr "itype" "cu")])

(define_insn "negqi2"
        [(set (match_operand:QI 0 "register_operand" "=y")
              (neg:QI (match_operand:QI 1 "register_operand" "d"))
         )]
        ""
        "negh %1, %0"
[(set_attr "itype" "cu")])

(define_insn "neghi2"
        [(set (match_operand:HI 0 "register_operand" "=d")
              (neg:HI (match_operand:HI 1 "register_operand" "d"))
         )]
        ""
        "neg %1, %0"
[(set_attr "itype" "cu")])

(define_insn "one_cmplqi2"
        [(set (match_operand:QI 0 "register_operand" "=d")
              (not:QI (match_operand:QI 1 "register_operand" "d")))]
        ""
        "not16 %1, %0"
[(set_attr "itype" "bmu")])

(define_insn "one_cmplhi2"
        [(set (match_operand:HI 0 "register_operand" "=d")
              (not:HI (match_operand:HI 1 "register_operand" "d")))]
        ""
        "not32 %1, %0"
[(set_attr "itype" "bmu")])

(define_insn "iorqi3"
        [(set (match_operand:QI 0 "register_operand" "=d")
              (ior:QI (match_operand:QI 1 "register_operand" "d")
                      (match_operand:QI 2 "nonmemory_operand" "d")))]
        ""
        "or16 %2, %1, %0"
[(set_attr "itype" "bmu")])

(define_insn "iorhi3"
        [(set (match_operand:HI 0 "register_operand" "=d")
              (ior:HI (match_operand:HI 1 "register_operand" "d")
                       (match_operand:HI 2 "register_operand" "d"))
         )]
        ""
        "or32 %2, %1, %0"
[(set_attr "itype" "bmu")])


(define_insn "xorqi3"
        [(set (match_operand:QI 0 "register_operand" "=d")
              (xor:QI (match_operand:QI 1 "register_operand" "d")
                       (match_operand:QI 2 "nonmemory_operand" "d"))
         )]
        ""
        "xor16 %2, %1, %0"
[(set_attr "itype" "bmu")])

(define_insn "xorhi3"
        [(set (match_operand:HI 0 "register_operand" "=d")
              (xor:HI (match_operand:HI 1 "register_operand" "d")
                      (match_operand:HI 2 "register_operand" "d"))
         )]
        ""
        "xor32 %2, %1, %0"
[(set_attr "itype" "bmu")])

(define_insn "subqi3"
  [(set (match_operand:QI 0 "register_operand" "=d")
        (minus:QI (match_operand:QI 1 "register_operand" "0")
                  (match_operand:QI 2 "register_operand" "d"))
        )]
  ""
  "sub16 %2, %0"
  [(set_attr "itype" "cu")
   (set_attr "isize" "1")])

(define_insn "subhi3"
  [(set (match_operand:HI 0 "register_operand" "=d")
        (minus:HI (match_operand:HI 1 "register_operand" "d")
                  (match_operand:HI 2 "register_operand" "d"))
        )]
  ""
  "sub32 %1, %2, %0"
  [(set_attr "itype" "cu")
   (set_attr "isize" "1")])

(define_insn "ashlqi3"
        [(set (match_operand:QI 0 "register_operand" "=d")
              (ashift:QI (match_operand:QI 1 "register_operand" "d")
                       (match_operand:QI 2 "register_operand" "d"))
         )]
        ""
        "shiftll16 %1, %2, %0"
[(set_attr "itype" "bmu")])

(define_insn "ashrqi3"
        [(set (match_operand:QI 0 "register_operand" "=d")
              (ashiftrt:QI (match_operand:QI 1 "register_operand" "d")
                       (match_operand:QI 2 "register_operand" "d"))
         )]
        ""
        "shiftra16 %1, %2, %0"
[(set_attr "itype" "bmu")])

(define_insn "lshrqi3"
        [(set (match_operand:QI 0 "register_operand" "=d")
              (lshiftrt:QI (match_operand:QI 1 "register_operand" "d")
                       (match_operand:QI 2 "register_operand" "d"))
         )]
        ""
        "shiftrl16 %1, %2, %0"
[(set_attr "itype" "bmu")])

;; 32-bit shifts

(define_insn "ashlhi3"
        [(set (match_operand:HI 0 "register_operand" "=d")
              (ashift:HI (match_operand:HI 1 "register_operand" "d")
                       (match_operand:QI 2 "register_operand" "d"))
         )]
        ""
        "shiftll32 %1, %2, %0"
[(set_attr "itype" "bmu")])

(define_insn "ashrhi3"
        [(set (match_operand:HI 0 "register_operand" "=d")
              (ashiftrt:HI (match_operand:HI 1 "register_operand" "d")
                       (match_operand:QI 2 "register_operand" "d"))
         )]
        ""
        "shiftra32 %1, %2, %0"
[(set_attr "itype" "bmu")])

(define_insn "lshrhi3"
        [(set (match_operand:HI 0 "register_operand" "=d")
              (lshiftrt:HI (match_operand:HI 1 "register_operand" "d")
                       (match_operand:QI 2 "register_operand" "d"))
         )]
        ""
        "shiftrl32 %1, %2, %0"
[(set_attr "itype" "bmu")])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Floating point
;;===============

(define_insn "addqf3"
  [(set (match_operand:QF 0 "register_operand" "=d")
        (plus:QF (match_operand:QF 1 "register_operand" "d")
                 (match_operand:QF 2 "register_operand" "d"))
        )]
  ""
  "fpadd %1, %2, %0"
  [(set_attr "itype" "cu_fp")
   (set_attr "isize" "2")])

(define_insn "mulqf3"
  [(set (match_operand:QF 0 "register_operand" "=d")
        (mult:QF (match_operand:QF 1 "register_operand" "d")
                 (match_operand:QF 2 "register_operand" "d"))
        )]
  ""
  "fpmul %1, %2, %0"
  [(set_attr "itype" "cu_fp")
   (set_attr "isize" "2")])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Function calls
;;===============

(define_insn "call"
        [(call (match_operand:HI 0 "memory_operand" "m")
               (match_operand:QI 1 "immediate_operand" "i"))
        ]
        ""
        "call %m0"
[(set_attr "itype" "pcu")
 (set_attr "dslots" "2")])

(define_insn "call_value"
        [(set (match_operand:QI 0 "register_operand" "=r")
              (call (match_operand:HI 1 "memory_operand" "m")
                    (match_operand:QI 2 "immediate_operand" "i")))
        ]
        ""
        "call %1"
[(set_attr "itype" "pcu")
 (set_attr "dslots" "2")])

(define_insn "*call_value_hi"
        [(set (match_operand:HI 0 "register_operand" "=r")
              (call (match_operand:HI 1 "memory_operand" "m")
                    (match_operand:QI 2 "immediate_operand" "i")))
        ]
        ""
        "call %1"
[(set_attr "itype" "pcu")
 (set_attr "dslots" "2")])


(define_insn "*call_sym"
        [(call (mem:HI (match_operand:HI 0 "symbolic_operand" "S"))
               (match_operand:QI 1 "immediate_operand" "i"))
        ]
        ""
        "call %s0"
[(set_attr "itype" "pcu")
 (set_attr "dslots" "2")])

(define_insn "*call_value_sym"
        [(set (match_operand:QI 0 "register_operand" "=r")
              (call (mem:HI (match_operand:HI 1 "symbolic_operand" "S"))
                    (match_operand:QI 2 "immediate_operand" "i")))
        ]
        ""
        "call %s1"
[(set_attr "itype" "pcu")
 (set_attr "dslots" "2")])

(define_insn "*call_value_hi_sym"
        [(set (match_operand:HI 0 "register_operand" "=r")
              (call (mem:HI (match_operand:HI 1 "symbolic_operand" "S"))
                    (match_operand:QI 2 "immediate_operand" "i")))
        ]
        ""
        "call %s1"
[(set_attr "itype" "pcu")
 (set_attr "dslots" "2")])


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Loop instructions
;;========================================

;;  Hardware loop

;; NOTE: Not using doloop_begin since nobody else is !!!

; operand 0 is the loop count pseudo register
; operand 1 is the number of loop iterations or 0 if it is unknown
; operand 2 is the maximum number of loop iterations
; operand 3 is the number of levels of enclosed loops
; operand 4 is the label to jump to at the top of the loop

(define_expand "doloop_end"
  [(parallel [(set (pc) (if_then_else
                          (ne (match_operand:QI 0 "" "")
                              (const_int 1))
                          (label_ref (match_operand 4 "" ""))
                          (pc)))
              (set (match_dup 0)
                   (plus:QI (match_dup 0)
                            (const_int -1)))
              (use (match_operand 1 "" ""))
              (use (match_operand 2 "" ""))
              (use (match_operand 3 "" ""))
              ])]
  "TARGET_HWLOOP"
  {
   if (GET_CODE(operands[1]) != CONST_INT || operands[1] == const0_rtx || INTVAL (operands[3]) > 1)
      FAIL;
  }
)

(define_insn "doloop_end_internal"
  [(parallel [(set (pc) (if_then_else
                          (ne (match_operand:QI 0 "" "")
                              (const_int 1))
                          (label_ref (match_operand 4 "" ""))
                          (pc)))
              (set (match_dup 0)
                   (plus:QI (match_dup 0)
                            (const_int -1)))
              (use (match_operand 1 "" ""))
              (use (match_operand 2 "" ""))
              (use (match_operand 3 "" ""))
              ])]
  "TARGET_HWLOOP"
  ""
  [(set_attr "itype" "pcu")]
)

(define_insn "block_repeat"
  [(unspec [(match_operand:QI 0 "" "") (match_operand:QI 1 "" "")] UNSPEC_HWLOPP_INIT)]
  "TARGET_HWLOOP"
  {
    static char str[64];
    sprintf(str, \"mv \t%d, brc1   bkrep \t#%%l1\", INTVAL(operands[0]));
    return str;
  }

  [(set_attr "itype" "pcu")]
)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Conditional code and branch instructions
;;========================================

(define_code_iterator cond_code [lt ltu eq ge geu gt gtu le leu ne])

(define_insn "jump"
        [(set (pc) (label_ref (match_operand 0 "" "")))]
        ""
        {
                return "bra #%l0";
        }
[(set_attr "itype" "pcu")
 (set_attr "dslots" "2")])

(define_insn "indirect_jump"
        [(set (pc) (match_operand:QI 0 "register_operand" ""))]
        ""
        "bra %0"
[(set_attr "itype" "pcu")])

(define_insn "nop"
  [(const_int 0)]
  ""
  "nop"
[(set_attr "itype" "pcu")])

;;;;;
;;;;;
;;;;;

(define_insn "mycmpqi"
  [(set (match_operand:BI 0 "pred_register_operand" "=z")
        (match_operator 1 "comparison_operator"
                        [(match_operand:QI 2 "register_operand" "d")
                         (match_operand:QI 3 "nonmemory_operand" "d")]))]
  ""
  "cmp16%1 %2, %3, %0"
  [(set_attr "itype" "cu_cmp")
   (set_attr "isize" "2")
   (set_attr "predicable" "no")])

(define_insn "mybranch"
  [(set (pc)
        (if_then_else (ne:BI (match_operand:BI 0 "pred_register_operand" "z")
                             (const_int 0))
                      (label_ref (match_operand 1 "" ""))
                      (pc)))]
  ""
  "if (%0) bra #%l1"
[(set_attr "itype" "pcu")
 (set_attr "dslots" "2")
 (set_attr "predicable" "no")])



(define_expand "cbranchqi4"
  [(set (pc)
        (if_then_else (match_operator 0 "comparison_operator"
                                      [(match_operand:QI 1 "register_operand" "")
                                       (match_operand:QI 2 "nonmemory_operand" "")])
                      (label_ref (match_operand 3 "" ""))
                      (pc)))]
  ""
  {
   rtx predbit = gen_reg_rtx(BImode);
   /* Compare instruction takes the comparison operator and its two operands. It
      produces a predicate register of BImode .*/

   emit_insn(gen_mycmpqi(predbit, operands[0], operands[1], operands[2]));
   
   /* NAK 2012-11-13 Added NOPs between compare and conditional branch */
   emit_insn(gen_nop());
   emit_insn(gen_nop());

   /* Branch instruction takes two operands, a predicate register and a
      destination label */

   emit_jump_insn(gen_mybranch(predbit, operands[3]));

   DONE;
  }
)

(define_expand "cstoreqi4"
  [(set (match_operand:QI 0 "register_operand" "")
        (match_operator 1 "comparison_operator"
                        [(match_operand:QI 2 "register_operand" "")
                         (match_operand:QI 3 "nonmemory_operand" "")]))]
  ""
  {
   rtx predbit = gen_reg_rtx(BImode);

   emit_insn(gen_mycmpqi(predbit, operands[1], operands[2], operands[3]));

   emit_insn (gen_rtx_COND_EXEC (VOIDmode,
				 gen_rtx_EQ (BImode, predbit, const0_rtx),
				 gen_rtx_SET (QImode, operands[0], const1_rtx)));

   emit_insn (gen_rtx_COND_EXEC (VOIDmode,
				 gen_rtx_NE (BImode, predbit, const0_rtx),
				 gen_rtx_SET (QImode, operands[0], const0_rtx)));

   DONE;
  }
)

(define_expand "cstorebi4"
  [(set (match_operand:BI 0 "pred_register_operand" "")
        (match_operator 1 "comparison_operator"
                        [(match_operand:QI 2 "register_operand" "")
                         (match_operand:QI 3 "nonmemory_operand" "")]))]
  ""
  {
   /* Compare instruction takes the comparison operator and its two operands. It
      produces a predicate register of BImode .*/

   emit_insn(gen_mycmpqi(operands[0], operands[1], operands[2], operands[3]));

   DONE;
  }
)

;; zero_extendbisi2

(define_insn "zero_extendbiqi2"
  [(set (match_operand:QI 0 "register_operand" "=d")
	(zero_extend:QI (match_operand:BI 1 "pred_register_operand" "z")))]
  ""
  "zero_extendbiqi2"
  )


(define_insn "extendbiqi2"
  [(set (match_operand:QI 0 "register_operand" "=d")
	(sign_extend:QI (match_operand:BI 1 "pred_register_operand" "z")))]
  ""
  "sign_extendbiqi2"
  )



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;DFA model of pipeline and functional units
;;==========================================

(automata_option "v")  ;; generate debuginfo in ajardsp.dfa

(define_automaton "ajardsp")

;; Define available cpu units.
(define_cpu_unit "bmu" "ajardsp")
(define_cpu_unit "pcu" "ajardsp")
(define_cpu_unit "lsu0" "ajardsp")
(define_cpu_unit "lsu1" "ajardsp")
(define_cpu_unit "cu0" "ajardsp")
(define_cpu_unit "cu1" "ajardsp")

(define_cpu_unit "bus_spec" "ajardsp")

(define_cpu_unit "islot0" "ajardsp")
(define_cpu_unit "islot1" "ajardsp")
(define_cpu_unit "islot2" "ajardsp")
(define_cpu_unit "islot3" "ajardsp")

;; Define reservations for issue slots
(define_reservation "one_islot" "(islot0|islot1|islot2|islot3)")
(define_reservation "two_islots" "((islot0+(islot1|islot2|islot3))|(islot1+(islot0|islot2|islot3))|(islot2+(islot0|islot1|islot3))|(islot3+(islot0|islot1|islot2)))")

;; Define reservations for instruction types.
(define_insn_reservation "bmu_16"  2 (and (eq_attr "itype" "bmu") (eq_attr "isize"  "1"))
  "one_islot+bmu")
(define_insn_reservation "cu_16"   2 (and (eq_attr "itype"  "cu") (eq_attr "isize"  "1"))
  "one_islot+(cu0|cu1)")
(define_insn_reservation "lsu_16"  1 (and (eq_attr "itype" "lsu") (eq_attr "isize"  "1"))
  "one_islot+(lsu0|lsu1)")
(define_insn_reservation "pcu_16"  1 (and (eq_attr "itype" "pcu") (eq_attr "isize"  "1"))
  "one_islot+pcu")

(define_insn_reservation "bmu_32" 2 (and (eq_attr "itype" "bmu") (eq_attr "isize"  "2"))
  "two_islots+bmu")
(define_insn_reservation "cu_32"  2 (and (eq_attr "itype"  "cu") (eq_attr "isize"  "2"))
  "two_islots+(cu0|cu1)")
(define_insn_reservation "cu_cmp_32"  2 (and (eq_attr "itype"  "cu_cmp") (eq_attr "isize"  "2"))
  "two_islots+(cu0|cu1)")  ;; cmp to PCU latency is the problem, to CU/LSU/BMU should be one cycle faster
(define_insn_reservation "cu_fp_32"  4 (and (eq_attr "itype"  "cu_fp") (eq_attr "isize"  "2"))
  "two_islots+(cu0|cu1)")
(define_insn_reservation "lsu_32" 1 (and (eq_attr "itype" "lsu") (eq_attr "isize"  "2"))
  "two_islots+(lsu0|lsu1)")
(define_insn_reservation "pcu_32" 1 (and (eq_attr "itype" "pcu") (eq_attr "isize"  "2"))
  "two_islots+pcu")

(define_insn_reservation "lsu_16_spec"  2 (and (eq_attr "itype" "lsu_spec") (eq_attr "isize"  "1"))
  "one_islot+(lsu0|lsu1)+bus_spec")
(define_insn_reservation "lsu_32_spec" 2 (and (eq_attr "itype" "lsu_spec") (eq_attr "isize"  "2"))
  "two_islots+(lsu0|lsu1)+bus_spec")

(define_insn_reservation "lsu_16_all" 2 (and (eq_attr "itype" "lsu_all") (eq_attr "isize"  "1"))
  "one_islot+lsu0+lsu1+bus_spec")
(define_insn_reservation "lsu_32_all" 2 (and (eq_attr "itype" "lsu_all") (eq_attr "isize"  "2"))
  "two_islots+lsu0+lsu1+bus_spec")


;;    (define_bypass number out_insn_names in_insn_names [guard])  ;; Define latencies for the pred bits. I.e. 1 for CU and BMU use, 2 for PCU use and 2 for LSU mem writes while 1 for remaining LSUs.


;; Local variables:
;; mode:emacs-lisp
;; comment-start: ";; "
;; eval: (set-syntax-table (copy-sequence (syntax-table)))
;; eval: (modify-syntax-entry ?[ "(]")
;; eval: (modify-syntax-entry ?] ")[")
;; eval: (modify-syntax-entry ?{ "(}")
;; eval: (modify-syntax-entry ?} "){")
;; eval: (setq indent-tabs-mode t)
;; End:
