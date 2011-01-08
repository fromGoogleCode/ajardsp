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

(define_predicate "predicate_operator"
  (match_code "eq,ne"))

(define_predicate "pred_register_operand"
  (match_operand 0 "register_operand")
{
  unsigned int regno;

  regno = REGNO (op);
  return (regno >= FIRST_PSEUDO_REGISTER || (AJARDSP_REGNO_FIRST_PRED <= regno && regno <= AJARDSP_REGNO_LAST_PRED));
})

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
