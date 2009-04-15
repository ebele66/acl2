#|-*-Lisp-*-=================================================================|#
#|                                                                           |#
#| coi: Computational Object Inference                                       |#
#|                                                                           |#
#|===========================================================================|#
(in-package "ACL2")

(ld "Makefile.acl2")

;(include-book "syn-pkg" :dir :syntax)
;(include-book "bag-pkg" :dir :bags)
;(include-book "symbol-fns-exports" :dir :symbol-fns)

;(include-book "list-exports" :dir :lists)
;(ld "list-exports.lsp" :dir :lists) ;trying... -ews

;(include-book "alist-pkg" :dir :alists)

(ld "record-exports.lsp")

(defpkg "REC" ;(remove-duplicates-eql ;no longer necessary due to change in ACL2
               `(,@ACL2::*acl2-exports*
                 ,@ACL2::*common-lisp-symbols-from-main-lisp-package*
                 ,@ACL2::*record-exports*
                 ACL2::acl2->rcd ACL2::rcd->acl2
                 ACL2::s-aux ACL2::g-aux
                 ACL2::ifrp ACL2::rcdp
                 ACL2::<<
                 )
;               )
               )


;; (defpkg "GR" nil)

;; (defpkg "PATH" (remove-duplicates-eql
;; 		`(SYN::defignore
;; 		  SYN::defignored
;; 		  SYN::defirrelevant
;; 		  ,@ACL2::*record-exports*
;; 		  ,@LIST::*exports*
;; 		  ,@ACL2::*acl2-exports*
;; 		  ,@ACL2::*common-lisp-symbols-from-main-lisp-package*
;;                   )))

