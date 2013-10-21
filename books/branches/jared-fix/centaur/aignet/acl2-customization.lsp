; AIGNET - And-Inverter Graph Networks
; Copyright (C) 2013 Centaur Technology
;
; Contact:
;   Centaur Technology Formal Verification Group
;   7600-C N. Capital of Texas Highway, Suite 300, Austin, TX 78731, USA.
;   http://www.centtech.com/
;
; This program is free software; you can redistribute it and/or modify it under
; the terms of the GNU General Public License as published by the Free Software
; Foundation; either version 2 of the License, or (at your option) any later
; version.  This program is distributed in the hope that it will be useful but
; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
; more details.  You should have received a copy of the GNU General Public
; License along with this program; if not, write to the Free Software
; Foundation, Inc., 51 Franklin Street, Suite 500, Boston, MA 02110-1335, USA.
;
; Original author: Sol Swords <sswords@centtech.com>

(ld "package.lsp")
(in-package "AIGNET")

(set-inhibit-output-lst '(proof-tree warning))
(set-gag-mode :goals)
(set-deferred-ttag-notes t state)

(defmacro why (rule)
  ;; BOZO eventually improve this to handle other rule-classes and 
  ;; such automatically.  That is, look up the name of the rule, etc.
  `(ACL2::er-progn
    (ACL2::brr t)
    (ACL2::monitor '(:rewrite ,rule) ''(:eval :go t))))

