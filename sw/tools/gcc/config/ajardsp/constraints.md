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

;;
;; Unsigned immediate integer values
;;

 (define_constraint "Iu05"
  "Imm integer value [0,31]"
  (and (match_code "const_int")
       (match_test "IN_RANGE(ival, 0, 31)")))

 (define_constraint "Iu16"
  "Imm integer value [0,65535]"
  (and (match_code "const_int")
       (match_test "IN_RANGE(ival, 0, 65535)")))

;;
;; Signed immediate integer values
;;

 (define_constraint "Is16"
  "Imm integer value [-32768,32767]"
  (and (match_code "const_int")
       (match_test "IN_RANGE(ival, -32768, 32767)")))

;;
;; Register classes
;;

 (define_register_constraint "b" "PTR_REGS"
   "Pointer register ($ptr0 - $ptr7)")

 (define_register_constraint "q" "SPEC_REGS"
   "Special register ($sp,$retpc)")

 (define_register_constraint "d" "ACC_REGS"
   "Accumulator register ($acc0l - $acc7h)")

(define_register_constraint "x" "ACC_REGS_LOW_PART"
  "Data register ($acc0l - $acc7l)")

(define_register_constraint "y" "ACC_REGS_HIGH_PART"
  "Data register ($acc0h - $acc7h)")

(define_register_constraint "D" "ACC_REGS_0_3"
  "Data register ($acc0l - $acc3h)")

(define_register_constraint "z" "PRED_REGS"
  "Predicate register ($pred0 - $pred3)")

(define_register_constraint "c" "NONPRED_REGS"
  "All registers except predicate registers")


;;
;; Memory addresses and symbols
;;

(define_constraint "a"
 "See if this is an absolute address in memory"
  (and (match_code "mem")
       (match_test "ajardsp_absolute_memory_operand(op,mode) == 1")))

(define_constraint "S"
 "Symbol-ref"
 (match_test "GET_CODE (op) == SYMBOL_REF"))

(define_memory_constraint "Qr"
  "A memory address where the complete address is in one register"
  (and (match_code "mem")
       (match_test "GET_CODE(XEXP(op,0)) == REG")))


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
