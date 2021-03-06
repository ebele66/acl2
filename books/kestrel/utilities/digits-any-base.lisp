; Representation of Natural Numbers as Digits in Arbitrary Bases
;
; Copyright (C) 2018 Kestrel Institute (http://www.kestrel.edu)
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; Author: Alessandro Coglio (coglio@kestrel.edu)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package "ACL2")

(include-book "centaur/fty/top" :dir :system)
(include-book "std/util/defrule" :dir :system)
(include-book "zp-lists")

(local (include-book "kestrel/utilities/typed-list-theorems" :dir :system))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defxdoc digits-any-base
  :parents (kestrel-utilities)
  :short "Conversions between natural numbers
          and their representations as digits in arbitrary bases."
  :long
  "<p>
   In these utilities, the digits are natural numbers below the base.
   The base (a natural number above 1) is supplied as argument.
   </p>
   <p>
   There are conversions for big-endian and little-endian representations.
   There are conversions to represent natural numbers as lists of digits
   of fixed length, of minimum length, and of minimum non-zero length.
   </p>
   <p>
   The name of some functions in these utilities start with @('dab'),
   which stands for `digits any base'.
   Without this prefix, the names seem too ``general''.
   </p>")

(local (xdoc::set-default-parents digits-any-base))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define dab-basep (x)
  :returns (yes/no booleanp)
  :short "Recognize valid bases for representing natural numbers as digits."
  :long
  "<p>
   The fixing function for this predicate is @(tsee dab-base-fix)
   and the fixtype for this predicate is @('dab-base').
   </p>
   <p>
   Any integer above 1 raised to a positive power is a valid base,
   e.g. binary, octal, and hexadecimal bases.
   </p>"
  (and (natp x)
       (>= x 2))
  ///

  (defrule posp-when-dab-basep
    (implies (dab-basep x)
             (posp x))
    :rule-classes :compound-recognizer)

  (defrule dab-basep-of-expt
    (implies (and (integerp x)
                  (> x 1)
                  (posp n))
             (dab-basep (expt x n)))))

(define dab-base-fix ((x dab-basep))
  :returns (fixed-x dab-basep)
  :short "Fixing function for @(tsee dab-basep)."
  (mbe :logic (max (nfix x) 2)
       :exec x)
  :prepwork ((local (in-theory (enable dab-basep))))
  ///

  (more-returns
   (fixed-x posp
            :name posp-of-dab-base-fix
            :rule-classes :type-prescription))

  (defrule dab-base-fix-when-dab-basep
    (implies (dab-basep x)
             (equal (dab-base-fix x)
                    x))))

(fty::deffixtype dab-base
  :pred dab-basep
  :fix dab-base-fix
  :equiv dab-base-equiv
  :define t
  :forward t
  :topic dab-basep)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define dab-digitp ((base dab-basep) x)
  :returns (yes/no booleanp)
  :short "Recognize valid digits
          for representing natural numbers as digits in the specified base."
  :long
  "<p>
   The fixing function for this predicate is @(tsee dab-digit-fix).
   </p>"
  (and (natp x)
       (< x (dab-base-fix base)))
  :hooks (:fix)
  ///

  (defrule natp-when-dab-digitp
    (implies (dab-digitp base x)
             (natp x))
    :rule-classes :forward-chaining)

  (defrule dab-digitp-of-0
    (dab-digitp base 0)))

(define dab-digit-fix ((base dab-basep) (x (dab-digitp base x)))
  :returns (fixed-x (dab-digitp base fixed-x))
  :short "Fixing function for @(tsee dab-digitp)."
  (mbe :logic (if (dab-digitp base x) x 0)
       :exec x)
  :prepwork ((local (in-theory (enable dab-digitp))))
  :hooks (:fix)
  ///

  (more-returns
   (fixed-x natp
            :name natp-of-dab-digit-fix
            :rule-classes :type-prescription)
   (fixed-x (< fixed-x (dab-base-fix base))
            :name dab-digit-fix-upper-bound
            :rule-classes :linear))

  (defrule dab-digit-fix-when-dab-digitp
    (implies (dab-digitp base x)
             (equal (dab-digit-fix base x)
                    x))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(std::deflist dab-digit-listp (base x)
  (dab-digitp base x)
  :short "Recognize true lists of digits in the specified base."
  :guard (dab-basep base)
  :true-listp t
  ///

  (defrule natp-listp-when-dab-digit-listp
    (implies (dab-digit-listp base x)
             (nat-listp x)))

  (defrule dab-digit-listp-of-dab-base-fix-base
    (equal (dab-digit-listp (dab-base-fix base) x)
           (dab-digit-listp base x)))

  (defrule dab-digit-listp-of-dab-base-fix-base-normalize-const
    (implies  (syntaxp (and (quotep base)
                            (not (dab-basep (cadr base)))))
              (equal (dab-digit-listp base x)
                     (dab-digit-listp (dab-base-fix base) x))))

  (defcong dab-base-equiv equal (dab-digit-listp base x) 1))

(define dab-digit-list-fix ((base dab-basep) (x (dab-digit-listp base x)))
  :returns (fixed-x (dab-digit-listp base fixed-x))
  :short "Fixing function for @(tsee dab-digit-listp)."
  (mbe :logic (cond ((atom x) nil)
                    (t (cons (dab-digit-fix base (car x))
                             (dab-digit-list-fix base (cdr x)))))
       :exec x)
  :hooks (:fix)
  ///

  (more-returns
   (fixed-x nat-listp :name nat-listp-of-dab-digit-list-fix))

  (defrule dab-digit-list-fix-of-list-fix
    (equal (dab-digit-list-fix base (list-fix digits))
           (dab-digit-list-fix base digits)))

  (defrule dab-digit-list-fix-when-dab-digit-listp
    (implies (dab-digit-listp base x)
             (equal (dab-digit-list-fix base x)
                    x)))

  (defrule dab-digit-list-fix-of-nil
    (equal (dab-digit-list-fix base nil)
           nil))

  (defrule dab-digit-list-fix-of-cons
    (equal (dab-digit-list-fix base (cons x y))
           (cons (dab-digit-fix base x)
                 (dab-digit-list-fix base y))))

  (defrule dab-digit-list-fix-of-append
    (equal (dab-digit-list-fix base (append x y))
           (append (dab-digit-list-fix base x)
                   (dab-digit-list-fix base y))))

  (defrule len-of-dab-digit-list-fix
    (equal (len (dab-digit-list-fix base x))
           (len x)))

  (defrule consp-of-dab-digit-list-fix
    (equal (consp (dab-digit-list-fix base x))
           (consp x)))

  (defrule car-of-dab-digit-list-fix
    (implies (consp x)
             (equal (car (dab-digit-list-fix base x))
                    (dab-digit-fix base (car x)))))

  (defrule cdr-of-dab-digit-list-fix
    (implies (consp x)
             (equal (cdr (dab-digit-list-fix base x))
                    (dab-digit-list-fix base (cdr x)))))

  (defrule rev-of-dab-digit-list-fix
    (equal (rev (dab-digit-list-fix base x))
           (dab-digit-list-fix base (rev x)))
    :enable rev)

  (defrule nat-list-fix-of-dab-digit-list-fix
    (equal (nat-list-fix (dab-digit-list-fix base x))
           (dab-digit-list-fix base x))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define digits=>nat-exec ((base dab-basep)
                          (digits (dab-digit-listp base digits))
                          (current-nat natp))
  :returns (final-nat natp :hyp :guard)
  :parents (bendian=>nat lendian=>nat)
  :short "Tail-recursive code for the execution of
          @(tsee bendian=>nat) and @(tsee lendian=>nat)."
  :long
  "<p>
   This interprets the digits in big-endian order.
   Thus, @(tsee bendian=>nat) calls this function on the digits directly,
   while @(tsee lendian=>nat) calls this function on the reversed digits.
   </p>
   <p>
   This definition is used for execution.
   For reasoning, the logic definitions of
   @(tsee bendian=>nat) and @(tsee lendian=>nat) should be used.
   </p>"
  (cond ((endp digits) current-nat)
        (t (digits=>nat-exec base
                             (cdr digits)
                             (+ (* base current-nat)
                                (car digits))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define nat=>digits-exec ((base dab-basep)
                          (nat natp)
                          (current-digits
                           (dab-digit-listp base current-digits)))
  :returns (final-digits (dab-digit-listp base final-digits) :hyp :guard)
  :parents (nat=>bendian* nat=>lendian*)
  :short "Tail-recursive code for the execution of
          @(tsee nat=>bendian*) and @(tsee nat=>lendian*)
          (and, indirectly, of their variants)."
  :long
  "<p>
   This calculates the digits in big-endian order.
   Thus, @(tsee nat=>bendian*) returns the resulting digits directly,
   while @(tsee nat=>lendian*) returns the reversed resulting digits.
   </p>
   <p>
   The fixing of the @('base') divisor of @(tsee floor)
   serves to prove termination.
   </p>
   <p>
   This definition is used for execution.
   For reasoning, the logic definitions of
   @(tsee nat=>bendian*) and @(tsee nat=>lendian*) should be used.
   </p>"
  (cond ((zp nat) current-digits)
        (t (nat=>digits-exec base
                             (floor nat (mbe :logic (dab-base-fix base)
                                             :exec base))
                             (cons (mod nat base) current-digits))))
  :prepwork ((local (include-book "arithmetic-5/top" :dir :system))
             (local (in-theory (enable dab-digitp)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define lendian=>nat ((base dab-basep)
                      (digits (dab-digit-listp base digits)))
  :returns (nat natp)
  :short "Convert a little-endian list of digits to their value."
  (mbe :exec (digits=>nat-exec base (rev digits) 0)
       :logic (cond ((atom digits) 0)
                    (t (+ (dab-digit-fix base (car digits))
                          (* (lendian=>nat base (cdr digits))
                             (dab-base-fix base))))))
  :verify-guards nil ; done below
  :hooks (:fix)
  ///

  (more-returns
   (nat natp
        :rule-classes :type-prescription
        :name lendian=>nat-type-prescription))

  (defrule lendian=>nat-of-dab-digit-list-fix-digits
    (equal (lendian=>nat base (dab-digit-list-fix base digits))
           (lendian=>nat base digits)))

  (defrule lendian=>nat-of-dab-digit-list-fix-digits-normalize-const
    (implies (syntaxp (and (quotep digits)
                           (not (dab-digit-listp base (cadr digits)))))
             (equal (lendian=>nat base digits)
                    (lendian=>nat base (dab-digit-list-fix base digits)))))

  (defrule lendian=>nat-of-list-fix
    (equal (lendian=>nat base (list-fix digits))
           (lendian=>nat base digits)))

  (defruled lendian=>nat-of-append
    (equal (lendian=>nat base (append lodigits hidigits))
           (+ (lendian=>nat base lodigits)
              (* (lendian=>nat base hidigits)
                 (expt (dab-base-fix base) (len lodigits)))))
    :prep-books ((include-book "arithmetic/top" :dir :system)))

  (defruled digits=>nat-exec-to-lendian=>nat
    (implies (and (dab-basep base)
                  (dab-digit-listp base digits)
                  (natp current-nat))
             (equal (digits=>nat-exec base digits current-nat)
                    (+ (lendian=>nat base (rev digits))
                       (* (expt base (len digits)) current-nat))))
    :enable (lendian=>nat-of-append digits=>nat-exec)
    :prep-books ((include-book "arithmetic/top" :dir :system)))

  (verify-guards lendian=>nat
    :hints (("Goal" :in-theory (enable digits=>nat-exec-to-lendian=>nat))))

  (defrule lendian=>nat-of-all-zeros
    (equal (lendian=>nat base (repeat n 0))
           0)
    :enable repeat)

  (defrule lendian=>nat-of-all-zeros-constant
    (implies (and (syntaxp (quotep digits))
                  (equal digits (repeat (len digits) 0)))
             (equal (lendian=>nat base digits) 0))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define nat=>lendian* ((base dab-basep) (nat natp))
  :returns (digits (dab-digit-listp base digits)
                   :hints (("Goal" :in-theory (enable dab-basep dab-digitp))))
  :short "Convert a natural number to
          its minimum-length little-endian list of digits."
  :long
  "<p>
   The resulting list is empty if @('nat') is 0.
   The @('*') in the name of this function can be read as `zero or more'
   (as in typical regular expression notation).
   </p>
   <p>
   See also @(tsee nat=>lendian+) and @(tsee nat=>lendian).
   </p>
   <p>
   The theorem @('len-of-nat=>lendian*-leq-width') is proved
   from a variant of it where @('width') is universally quantified.
   This variant is proved via an induction scheme
   similar to @('nat=>lendian*') but without @('width').
   Base case and induction step are proved individually;
   the induction step uses an arithmetic lemma.
   The @('arithmetic-5') library is needed for several of these proofs.
   There might be a simpler proof that, in particular,
   does not involve introducing a @(tsee defun-sk).
   </p>"
  (mbe :exec (rev (nat=>digits-exec base nat nil))
       :logic (cond ((zp nat) nil)
                    (t (cons (mod nat (dab-base-fix base))
                             (nat=>lendian* base
                                            (floor nat
                                                   (dab-base-fix base)))))))
  :verify-guards nil ; done below
  :prepwork ((local (include-book "arithmetic-5/top" :dir :system)))
  :hooks (:fix)
  ///

  (more-returns
   (digits nat-listp :name natp-listp-of-nat=>lendian*)
   (digits consp
           :hyp (not (zp nat))
           :name consp-of-nat=>lendian*
           :rule-classes :type-prescription))

  (defruled nat=>digits-exec-to-nat=>lendian*
    (implies (and (dab-basep base)
                  (natp nat)
                  (dab-digit-listp base current-digits))
             (equal (nat=>digits-exec base nat current-digits)
                    (append (rev (nat=>lendian* base nat))
                            current-digits)))
    :enable (nat=>digits-exec dab-basep dab-digitp)
    :prep-books ((include-book "arithmetic-5/top" :dir :system)))

  (defrule nat=>lendian*-of-0
    (equal (nat=>lendian* base 0)
           nil))

  (defrule expt-of-len-of-nat=>lendian*-is-upper-bound
    (implies (and (natp nat)
                  (dab-basep base))
             (< nat (expt base (len (nat=>lendian* base nat)))))
    :rule-classes :linear
    :prep-books ((include-book "arithmetic-5/top" :dir :system)))

  (verify-guards nat=>lendian*
    :hints (("Goal" :in-theory (enable nat=>digits-exec-to-nat=>lendian*))))

  (defruled len-of-nat=>lendian*-leq-width
    (implies (and (natp nat)
                  (dab-basep base)
                  (natp width))
             (equal (<= (len (nat=>lendian* base nat))
                        width)
                    (< nat
                       (expt base width))))
    :rule-classes ((:rewrite
                    :corollary
                    (implies (and (natp nat)
                                  (dab-basep base)
                                  (natp width))
                             (equal (> (len (nat=>lendian* base nat))
                                       width)
                                    (>= nat
                                        (expt base width))))
                    :hints (("Goal" :in-theory '(not)))))

    :prep-lemmas

    ((defun-sk univ-quant-width (base nat)
       (forall width
               (implies (natp width)
                        (equal (<= (len (nat=>lendian* base nat))
                                   width)
                               (< nat
                                  (expt base width)))))
       :rewrite :direct)

     (local (include-book "arithmetic-5/top" :dir :system))

     (defun induction-scheme (base nat)
       (if (zp nat)
           0
         (induction-scheme base (floor nat (dab-base-fix base)))))

     (defrule prove-the-base-case
       (implies (zp nat)
                (implies (and (natp nat)
                              (dab-basep base))
                         (univ-quant-width base nat))))

     (defruled arithmetic-lemma
       (implies (and (not (zp x))
                     (not (zp base)))
                (equal (expt base (1- x))
                       (floor (expt base x) base))))

     (defrule prove-the-induction-step
       (implies (and (not (zp nat))
                     (univ-quant-width base (floor nat base)))
                (implies (and (natp nat)
                              (dab-basep base))
                         (univ-quant-width base nat)))
       :disable (univ-quant-width univ-quant-width-necc)
       :expand ((univ-quant-width base nat)
                (nat=>lendian* base nat))
       :use ((:instance univ-quant-width-necc
              (nat (floor nat base))
              (width (1- (univ-quant-width-witness base nat))))
             (:instance arithmetic-lemma
              (x (univ-quant-width-witness base nat)))))

     (defrule prove-the-variant
       (implies (and (natp nat)
                     (dab-basep base))
                (univ-quant-width base nat))
       :induct (induction-scheme base nat)
       :hints ('(:use (prove-the-base-case prove-the-induction-step)))
       :prep-lemmas ((set-minimal-arithmetic-5-theory)))))

  (defruled nat=>lendian*-of-digit-+-base-*-nat
    (implies (and (dab-basep base)
                  (dab-digitp base x)
                  (natp y))
             (equal (nat=>lendian* base (+ x (* base y)))
                    (if (equal y 0)
                        (if (equal x 0)
                            nil
                          (list x))
                      (cons x (nat=>lendian* base y)))))
    :enable dab-digitp
    :prep-books ((include-book "arithmetic-5/top" :dir :system))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define nat=>lendian+ ((base dab-basep) (nat natp))
  :returns (digits (dab-digit-listp base digits))
  :short "Convert a natural number to
          its non-empty minimum-length little-endian list of digits."
  :long
  "<p>
   The resulting list is never empty; it is @('(0)') if @('nat') is 0.
   The @('+') in the name of this function can be read as `one or more'
   (as in typical regular expression notation).
   </p>
   <p>
   See also @(tsee nat=>lendian*) and @(tsee nat=>lendian).
   </p>"
  (b* ((digits (nat=>lendian* base nat)))
    (or digits (list 0)))
  :hooks (:fix)
  ///

  (more-returns
   (digits nat-listp :name nat-listp-of-nat=>lendian+))

  (defrule nat=>lendian+-of-0
    (equal (nat=>lendian+ base 0)
           (list 0))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define nat=>lendian ((base dab-basep) (width natp) (nat natp))
  :guard (< nat (expt base width))
  :returns (digits (dab-digit-listp base digits))
  :short "Convert a natural number to
          its little-endian list of digits of specified length."
  :long
  "<p>
   The number must be representable in the specified number of digits.
   The resulting list starts with zero or more 0s.
   </p>
   <p>
   See also @(tsee nat=>lendian*) and @(tsee nat=>lendian+).
   </p>"
  (b* ((width (mbe :logic (nfix width)
                   :exec width))
       (nat (mbe :logic (mod (nfix nat) (expt (dab-base-fix base) width))
                 :exec nat))
       (digits (nat=>lendian* base nat))
       (zeros (repeat (- width (len digits)) 0)))
    (append digits zeros))
  :guard-hints (("Goal" :in-theory (enable len-of-nat=>lendian*-leq-width)))
  :prepwork ((local (include-book "arithmetic-5/top" :dir :system))
             (local (include-book "std/typed-lists/top" :dir :system)))
  :hooks (:fix)
  ///

  (more-returns
   (digits nat-listp :name nat-listp-of-nat=>lendian)
   (digits consp
           :hyp (not (zp width))
           :name consp-of-nat=>lendian
           :rule-classes :type-prescription))

  (defrule nat=>lendian-of-mod
    (implies (and (dab-basep base)
                  (natp width)
                  (natp nat)
                  (equal expt-base-width (expt base width)))
             (equal (nat=>lendian base width (mod nat expt-base-width))
                    (nat=>lendian base width nat))))

  (defrule len-of-nat=>lendian
    (equal (len (nat=>lendian base width nat))
           (nfix width))
    :enable nat=>lendian
    :use (:instance len-of-nat=>lendian*-leq-width
          (nat (mod nat (expt (dab-base-fix base) width)))
          (base (dab-base-fix base)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define bendian=>nat ((base dab-basep)
                      (digits (dab-digit-listp base digits)))
  :returns (nat natp)
  :short "Convert a big-endian list of digits to their value."
  (mbe :exec (digits=>nat-exec base digits 0)
       :logic (lendian=>nat base (rev digits)))
  :guard-hints (("Goal" :in-theory (enable digits=>nat-exec-to-lendian=>nat)))
  :hooks (:fix)
  ///

  (defrule bendian=>nat-of-dab-digit-list-fix-digits
    (equal (bendian=>nat base (dab-digit-list-fix base digits))
           (bendian=>nat base digits))
    :enable rev-of-dab-digit-list-fix)

  (defrule bendian=>nat-of-dab-digit-list-fix-digits-normalize-const
    (implies (syntaxp (and (quotep digits)
                           (not (dab-digit-listp base (cadr digits)))))
             (equal (bendian=>nat base digits)
                    (bendian=>nat base (dab-digit-list-fix base digits))))
    :enable rev-of-dab-digit-list-fix)

  (defrule bendian=>nat-of-list-fix
    (equal (bendian=>nat base (list-fix digits))
           (bendian=>nat base digits)))

  (defruled bendian=>nat-of-append
    (equal (bendian=>nat base (append hidigits lodigits))
           (+ (* (bendian=>nat base hidigits)
                 (expt (dab-base-fix base) (len lodigits)))
              (bendian=>nat base lodigits)))
    :enable lendian=>nat-of-append)

  (defrule bendian=>nat-of-all-zeros
    (equal (bendian=>nat base (repeat n 0))
           0))

  (defrule bendian=>nat-of-all-zeros-constant
    (implies (and (syntaxp (quotep digits))
                  (equal digits (repeat (len digits) 0)))
             (equal (bendian=>nat base digits) 0)))

  (defruled lendian=>nat-as-bendian=>nat
    (equal (lendian=>nat base digits)
           (bendian=>nat base (rev digits))))

  (theory-invariant (incompatible (:rewrite lendian=>nat-as-bendian=>nat)
                                  (:definition bendian=>nat))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define nat=>bendian* ((base dab-basep) (nat natp))
  :returns (digits (dab-digit-listp base digits))
  :short "Convert a natural number to
          its minimum-length big-endian list of digits."
  :long
  "<p>
   The resulting list is empty if @('nat') is 0.
   The @('*') in the name of this function can be read as `zero or more'
   (as in typical regular expression notation).
   </p>
   <p>
   See also @(tsee nat=>bendian+) and @(tsee nat=>bendian).
   </p>"
  (mbe :exec (nat=>digits-exec base nat nil)
       :logic (rev (nat=>lendian* base nat)))
  :guard-hints (("Goal"
                 :in-theory (enable nat=>digits-exec-to-nat=>lendian*)))
  :hooks (:fix)
  ///

  (more-returns
   (digits nat-listp :name natp-listp-of-nat=>bendian*)
   (digits consp
           :hyp (not (zp nat))
           :name consp-of-nat=>bendian*
           :rule-classes :type-prescription))

  (defrule nat=>bendian*-of-0
    (equal (nat=>bendian* base 0)
           nil))

  (defrule expt-of-len-of-nat=>bendian*-is-upper-bound
    (implies (and (natp nat)
                  (dab-basep base))
             (< nat (expt base (len (nat=>bendian* base nat)))))
    :rule-classes :linear)

  (defruled len-of-nat=>bendian*-leq-width
    (implies (and (natp nat)
                  (dab-basep base)
                  (natp width))
             (equal (<= (len (nat=>bendian* base nat))
                        width)
                    (< nat
                       (expt base width))))
    :enable len-of-nat=>lendian*-leq-width
    :rule-classes ((:rewrite
                    :corollary
                    (implies (and (natp nat)
                                  (dab-basep base)
                                  (natp width))
                             (equal (> (len (nat=>bendian* base nat))
                                       width)
                                    (>= nat
                                        (expt base width))))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define nat=>bendian+ ((base dab-basep) (nat natp))
  :returns (digits (dab-digit-listp base digits))
  :short "Convert a natural number to
          its non-empty minimum-length big-endian list of digits."
  :long
  "<p>
   The resulting list is never empty; it is @('(0)') if @('nat') is 0.
   The @('+') in the name of this function can be read as `one or more'
   (as in typical regular expression notation).
   </p>
   <p>
   See also @(tsee nat=>bendian*) and @(tsee nat=>bendian).
   </p>"
  (b* ((digits (nat=>bendian* base nat)))
    (or digits (list 0)))
  :hooks (:fix)
  ///

  (more-returns
   (digits nat-listp :name nat-listp-of-nat=>bendian+))

  (defrule nat=>bendian+-of-0
    (equal (nat=>bendian+ base 0)
           (list 0))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define nat=>bendian ((base dab-basep) (width natp) (nat natp))
  :guard (< nat (expt base width))
  :returns (digits (dab-digit-listp base digits))
  :short "Convert a natural number to
          its big-endian list of digits of specified length."
  :long
  "<p>
   The number must be representable in the specified number of digits.
   The resulting list starts with zero or more 0s.
   </p>
   <p>
   See also @(tsee nat=>bendian*) and @(tsee nat=>bendian+).
   </p>"
  (rev (nat=>lendian base width nat))
  :hooks (:fix)
  ///

  (more-returns
   (digits nat-listp :name nat-listp-of-nat=>bendian)
   (digits consp
           :hyp (not (zp width))
           :name consp-of-nat=>bendian
           :rule-classes :type-prescription))

  (defrule nat=>bendian-of-mod
    (implies (and (dab-basep base)
                  (natp width)
                  (natp nat)
                  (equal expt-base-width (expt base width)))
             (equal (nat=>bendian base width (mod nat expt-base-width))
                    (nat=>bendian base width nat)))
    :prep-books ((include-book "arithmetic-5/top" :dir :system)))

  (defrule len-of-nat=>bendian
    (equal (len (nat=>bendian base width nat))
           (nfix width))
    :enable nat=>bendian
    :use (:instance len-of-nat=>bendian*-leq-width
          (nat (mod nat (expt (dab-base-fix base) width)))
          (base (dab-base-fix base)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defsection nat=>digits=>nat-inversion-theorems
  :short "Theorems about converting natural numbers to digits and back."
  :long
  "<p>
   @(tsee lendian=>nat) is left inverse of
   @(tsee nat=>lendian*), @(tsee nat=>lendian+), and @(tsee nat=>lendian),
   over natural numbers.
   </p>
   <p>
   @(tsee bendian=>nat) is left inverse of
   @(tsee nat=>bendian*), @(tsee nat=>bendian+), and @(tsee nat=>bendian),
   over natural numbers.
   </p>
   <p>
   That is, converting a natural number to digits
   (whether zero or more, one or more, or of given width),
   and then converting the digits to a number,
   yields the starting natural number.
   </p>"

  (defrule lendian=>nat-of-nat=>lendian*
    (equal (lendian=>nat base (nat=>lendian* base nat))
           (nfix nat))
    :enable (nat=>lendian* lendian=>nat dab-digit-fix dab-digitp)
    :prep-books ((include-book "arithmetic-5/top" :dir :system)))

  (defrule lendian=>nat-of-nat=>lendian+
    (equal (lendian=>nat base (nat=>lendian+ base nat))
           (nfix nat))
    :enable nat=>lendian+)

  (defrule lendian=>nat-of-nat=>lendian
    (implies (< (nfix nat)
                (expt (dab-base-fix base)
                      (nfix width)))
             (equal (lendian=>nat base (nat=>lendian base width nat))
                    (nfix nat)))
    :enable (nat=>lendian lendian=>nat-of-append)
    :prep-books ((include-book "arithmetic-5/top" :dir :system)))

  (defrule bendian=>nat-of-nat=>bendian*
    (equal (bendian=>nat base (nat=>bendian* base nat))
           (nfix nat))
    :enable (nat=>bendian* bendian=>nat))

  (defrule bendian=>nat-of-nat=>bendian+
    (equal (bendian=>nat base (nat=>bendian+ base nat))
           (nfix nat))
    :enable nat=>bendian+)

  (defrule bendian=>nat-of-nat=>bendian
    (implies (< (nfix nat)
                (expt (dab-base-fix base)
                      (nfix width)))
             (equal (bendian=>nat base (nat=>bendian base width nat))
                    (nfix nat)))
    :enable (nat=>bendian bendian=>nat)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defsection nat=>digits-injectivity-theorems
  :short "Theorems about the injectivity of
          the conversions from natural numbers to digits."
  :long
  "<p>
   The conversions from natural numbers to digits
   are injective over natural numbers.
   These are simple consequences of the
   <see topic='@(url nat=>digits=>nat-inversion-theorems)'>theorems about
   converting natural numbers to digits and back</see>.
   </p>"

  (defrule nat=>lendian*-injectivity
    (equal (equal (nat=>lendian* base nat1)
                  (nat=>lendian* base nat2))
           (equal (nfix nat1)
                  (nfix nat2)))
    :use ((:instance lendian=>nat-of-nat=>lendian* (nat nat1))
          (:instance lendian=>nat-of-nat=>lendian* (nat nat2))
          (:instance nat=>lendian*-nat-equiv-congruence-on-nat
           (nat nat1) (nat-equiv nat2)))
    :disable (lendian=>nat-of-nat=>lendian*
              nat=>lendian*-nat-equiv-congruence-on-nat))

  (defrule nat=>lendian+-injectivity
    (equal (equal (nat=>lendian+ base nat1)
                  (nat=>lendian+ base nat2))
           (equal (nfix nat1)
                  (nfix nat2)))
    :use ((:instance lendian=>nat-of-nat=>lendian+ (nat nat1))
          (:instance lendian=>nat-of-nat=>lendian+ (nat nat2))
          (:instance nat=>lendian+-nat-equiv-congruence-on-nat
           (nat nat1) (nat-equiv nat2)))
    :disable (lendian=>nat-of-nat=>lendian+
              nat=>lendian+-nat-equiv-congruence-on-nat))

  (defrule nat=>lendian-injectivity
    (implies (and (< (nfix nat1)
                     (expt (dab-base-fix base)
                           (nfix width)))
                  (< (nfix nat2)
                     (expt (dab-base-fix base)
                           (nfix width))))
             (equal (equal (nat=>lendian base width nat1)
                           (nat=>lendian base width nat2))
                    (equal (nfix nat1)
                           (nfix nat2))))
    :use ((:instance lendian=>nat-of-nat=>lendian (nat nat1))
          (:instance lendian=>nat-of-nat=>lendian (nat nat2))
          (:instance nat=>lendian-nat-equiv-congruence-on-nat
           (nat nat1) (nat-equiv nat2)))
    :disable (lendian=>nat-of-nat=>lendian
              nat=>lendian-nat-equiv-congruence-on-nat))

  (defrule nat=>bendian*-injectivity
    (equal (equal (nat=>bendian* base nat1)
                  (nat=>bendian* base nat2))
           (equal (nfix nat1)
                  (nfix nat2)))
    :use ((:instance bendian=>nat-of-nat=>bendian* (nat nat1))
          (:instance bendian=>nat-of-nat=>bendian* (nat nat2))
          (:instance nat=>bendian*-nat-equiv-congruence-on-nat
           (nat nat1) (nat-equiv nat2)))
    :disable (bendian=>nat-of-nat=>bendian*
              nat=>bendian*-nat-equiv-congruence-on-nat))

  (defrule nat=>bendian+-injectivity
    (equal (equal (nat=>bendian+ base nat1)
                  (nat=>bendian+ base nat2))
           (equal (nfix nat1)
                  (nfix nat2)))
    :use ((:instance bendian=>nat-of-nat=>bendian+ (nat nat1))
          (:instance bendian=>nat-of-nat=>bendian+ (nat nat2))
          (:instance nat=>bendian+-nat-equiv-congruence-on-nat
           (nat nat1) (nat-equiv nat2)))
    :disable (bendian=>nat-of-nat=>bendian+
              nat=>bendian+-nat-equiv-congruence-on-nat))

  (defrule nat=>bendian-injectivity
    (implies (and (< (nfix nat1)
                     (expt (dab-base-fix base)
                           (nfix width)))
                  (< (nfix nat2)
                     (expt (dab-base-fix base)
                           (nfix width))))
             (equal (equal (nat=>bendian base width nat1)
                           (nat=>bendian base width nat2))
                    (equal (nfix nat1)
                           (nfix nat2))))
    :use ((:instance bendian=>nat-of-nat=>bendian (nat nat1))
          (:instance bendian=>nat-of-nat=>bendian (nat nat2))
          (:instance nat=>bendian-nat-equiv-congruence-on-nat
           (nat nat1) (nat-equiv nat2)))
    :disable (bendian=>nat-of-nat=>bendian
              nat=>bendian-nat-equiv-congruence-on-nat)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define trim-bendian* ((digits nat-listp))
  :returns (trimmed-digits nat-listp)
  :short "Remove all the most significant zero digits
          from a big-endian representation."
  :long
  "<p>
   This produces a minimal-length representation with the same value.
   </p>
   <p>
   This operation does not depend on a base.
   It maps lists of natural numbers to lists of natural numbers,
   where the natural numbers may be digit in any suitable base.
   </p>
   <p>
   See also @(tsee trim-bendian+).
   </p>"
  (cond ((endp digits) nil)
        ((zp (car digits)) (trim-bendian* (cdr digits)))
        (t (mbe :logic (nat-list-fix digits) :exec digits)))
  :hooks (:fix)
  ///

  (defrule trim-bendian*-of-list-fix
    (equal (trim-bendian* (list-fix digits))
           (trim-bendian* digits))
    :enable nat-list-fix)

  (defrule trim-bendian*-when-zp-listp
    (implies (zp-listp digits)
             (equal (trim-bendian* digits)
                    nil)))

  (defrule bendian=>nat-of-trim-bendian*
    (equal (bendian=>nat base (trim-bendian* digits))
           (bendian=>nat base digits))
    :enable (bendian=>nat lendian=>nat))

  (defrule len-of-trim-bendian*-upper-bound
    (<= (len (trim-bendian* digits))
        (len digits))
    :rule-classes :linear)

  (defrule append-of-repeat-and-trim-bendian*
    (equal (append (repeat (- (len digits)
                              (len (trim-bendian* digits)))
                           0)
                   (trim-bendian* digits))
           (nat-list-fix digits))
    :enable nat-list-fix))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define trim-lendian* ((digits nat-listp))
  :returns (trimmed-digits nat-listp)
  :short "Remove all the most significant zero digits
          from a little-endian representation."
  :long
  "<p>
   This produces a minimal-length representation with the same value.
   </p>
   <p>
   This operation does not depend on a base.
   It maps lists of natural numbers to lists of natural numbers,
   where the natural numbers may be digit in any suitable base.
   </p>
   <p>
   See also @(tsee trim-lendian+).
   </p>"
  (rev (trim-bendian* (rev digits)))
  :hooks (:fix)
  ///

  (defrule trim-lendian*-of-list-fix
    (equal (trim-lendian* (list-fix digits))
           (trim-lendian* digits)))

  (defrule trim-lendian*-when-zp-listp
    (implies (zp-listp digits)
             (equal (trim-lendian* digits)
                    nil)))

  (defrule lendian=>nat-of-trim-lendian*
    (equal (lendian=>nat base (trim-lendian* digits))
           (lendian=>nat base digits))
    :enable lendian=>nat-as-bendian=>nat)

  (defrule len-of-trim-lendian*-upper-bound
    (<= (len (trim-lendian* digits))
        (len digits))
    :rule-classes :linear)

  (defrule append-of-repeat-and-trim-lendian*
    (equal (append (trim-lendian* digits)
                   (repeat (- (len digits)
                              (len (trim-lendian* digits)))
                           0))
           (nat-list-fix digits))
    :use (:instance
          apply-rev-to-both-sides-of-append-of-repeat-and-trim-bendian*
          (digits (rev digits)))

    :prep-lemmas
    ((defruled
       apply-rev-to-both-sides-of-append-of-repeat-and-trim-bendian*
       (equal (rev (append (repeat (- (len digits)
                                      (len (trim-bendian* digits)))
                                   0)
                           (trim-bendian* digits)))
              (rev (nat-list-fix digits))))))

  (defruled trim-lendian*-of-cons
    (implies (and (natp digit)
                  (nat-listp digits))
             (equal (trim-lendian* (cons digit digits))
                    (if (zp-listp digits)
                        (if (zp digit)
                            nil
                          (list digit))
                      (cons digit (trim-lendian* digits)))))
    :enable (trim-bendian* zp-listp)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define trim-bendian+ ((digits nat-listp))
  :returns (trimmed-digits nat-listp)
  :short "Remove all the most significant zero digits
          from a big-endian representation,
          but leave one zero if all the digits are zero."
  :long
  "<p>
   This produces a minimal-length non-empty representation with the same value.
   </p>
   <p>
   This operation does not depend on a base.
   It maps lists of natural numbers to lists of natural numbers,
   where the natural numbers may be digit in any suitable base.
   </p>
   <p>
   See also @(tsee trim-bendian*).
   </p>"
  (b* ((digits (trim-bendian* digits)))
    (or digits (list 0)))
  :hooks (:fix)
  ///

  (defrule trim-bendian+-of-list-fix
    (equal (trim-bendian+ (list-fix digits))
           (trim-bendian+ digits)))

  (defrule trim-bendian+-when-zp-listp
    (implies (zp-listp digits)
             (equal (trim-bendian+ digits)
                    (list 0))))

  (defrule bendian=>nat-of-trim-bendian+
    (equal (bendian=>nat base (trim-bendian+ digits))
           (bendian=>nat base digits))
    :use bendian=>nat-of-trim-bendian*
    :disable bendian=>nat-of-trim-bendian*))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define trim-lendian+ ((digits nat-listp))
  :returns (trimmed-digits nat-listp)
  :short "Remove all the most significant zero digits
          from a little-endian representation,
          but leave one zero if all the digits are zero."
  :long
  "<p>
   This produces a minimal-length non-empty representation with the same value.
   </p>
   <p>
   This operation does not depend on a base.
   It maps lists of natural numbers to lists of natural numbers,
   where the natural numbers may be digit in any suitable base.
   </p>
   <p>
   See also @(tsee trim-lendian*).
   </p>"
  (b* ((digits (trim-lendian* digits)))
    (or digits (list 0)))
  :hooks (:fix)
  ///

  (defrule trim-lendian+-of-list-fix
    (equal (trim-lendian+ (list-fix digits))
           (trim-lendian+ digits)))

  (defrule trim-lendian+-when-zp-listp
    (implies (zp-listp digits)
             (equal (trim-lendian+ digits)
                    (list 0))))

  (defrule lendian=>nat-of-trim-lendian+
    (equal (lendian=>nat base (trim-lendian+ digits))
           (lendian=>nat base digits))
    :use lendian=>nat-of-trim-lendian*
    :disable lendian=>nat-of-trim-lendian*))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defsection digits=>nat=>digits-inversion-theorems
  :short "Theorems about converting digits to natural numbers and back."
  :long
  "<p>
   @(tsee lendian=>nat) is right inverse of
   @(tsee nat=>lendian*), @(tsee nat=>lendian+), and @(tsee nat=>lendian),
   over digits without superfluous zeros in the most significant positions.
   </p>
   <p>
   @(tsee bendian=>nat) is right inverse of
   @(tsee nat=>bendian*), @(tsee nat=>bendian+), and @(tsee nat=>bendian),
   over digits without superfluous zeros in the most significant positions.
   </p>
   <p>
   That is, converting digits to a natural number,
   and then converting the number to digits,
   yields the original digits,
   but without superfluous zeros in the most significant positions.
   We remove those superfluous zeros, in the right hand sides of the equalities,
   via the trimming functions, as appropriate.
   </p>"

  (defrule nat=>lendian*-of-lendian=>nat
    (equal (nat=>lendian* base (lendian=>nat base digits))
           (trim-lendian* (dab-digit-list-fix base digits)))
    :use (:instance lemma
          (base (dab-base-fix base))
          (digits (dab-digit-list-fix (dab-base-fix base) digits)))

    :prep-lemmas
    ((defruled lemma
       (implies (and (dab-basep base)
                     (dab-digit-listp base digits))
                (equal (nat=>lendian* base (lendian=>nat base digits))
                       (trim-lendian* (dab-digit-list-fix base digits))))
       :enable (lendian=>nat
                nat=>lendian*
                trim-lendian*-of-cons
                nat=>lendian*-of-digit-+-base-*-nat))))

  (defrule nat=>lendian+-of-lendian=>nat
    (equal (nat=>lendian+ base (lendian=>nat base digits))
           (trim-lendian+ (dab-digit-list-fix base digits)))
    :enable (lendian=>nat
             nat=>lendian+
             trim-lendian+))

  (defrule nat=>lendian-of-lendian=>nat
    (equal (nat=>lendian base (len digits) (lendian=>nat base digits))
           (dab-digit-list-fix base digits))
    :enable nat=>lendian
    :use ((:instance lemma (base (dab-base-fix base)))
          (:instance append-of-repeat-and-trim-lendian*
           (digits (dab-digit-list-fix (dab-base-fix base) digits))))

    :prep-lemmas
    ((defrule lemma
       (implies (dab-basep base)
                (equal (mod (lendian=>nat base digits)
                            (expt base (len digits)))
                       (lendian=>nat base digits)))
       :use ((:instance expt-of-len-of-nat=>lendian*-is-upper-bound
              (nat (lendian=>nat base digits)))
             (:instance len-of-trim-lendian*-upper-bound
              (digits (dab-digit-list-fix base digits))))
       :prep-books ((include-book "arithmetic-5/top" :dir :system)))))

  (defrule nat=>bendian*-of-bendian=>nat
    (equal (nat=>bendian* base (bendian=>nat base digits))
           (trim-bendian* (dab-digit-list-fix base digits)))
    :enable (nat=>bendian* bendian=>nat trim-lendian*))

  (defrule nat=>bendian+-of-bendian=>nat
    (equal (nat=>bendian+ base (bendian=>nat base digits))
           (trim-bendian+ (dab-digit-list-fix base digits)))
    :enable (nat=>bendian+ trim-bendian+))

  (defrule nat=>bendian-of-bendian=>nat
    (equal (nat=>bendian base (len digits) (bendian=>nat base digits))
           (dab-digit-list-fix base digits))
    :enable (nat=>bendian bendian=>nat)
    :use (:instance nat=>lendian-of-lendian=>nat (digits (rev digits)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defsection digits=>nat-injectivity-theorems
  :short "Theorems about the injectivity of
          the conversions from digits to natural numbers."
  :long
  "<p>
   The conversions from digits to natural numbers are injective
   over digits without superfluous zeros in the most significant positions.
   These are simple consequences of the
   <see topic='@(url digits=>nat=>digits-inversion-theorems)'>theorems about
   converting digits to natural numbers and back</see>.
   The absence of suprfluous digits can be expressed by saying that
   the digits, fixed with @(tsee dab-digit-list-fix),
   are invariant under @(tsee trim-lendian*) or @(tsee trim-lendian+).
   </p>
   <p>
   Another formulation of the inejctivity theorems is that
   the conversions from digits to natural numbers are injective
   over lists of digits of the same length.
   </p>
   <p>
   Note that each formulation of the injectivity theorem
   is proved via a ``corresponding'' inversion theorem.
   </p>"

  (defrule lendian=>nat-injectivity*
    (implies (and (equal (trim-lendian* (dab-digit-list-fix base digits1))
                         digits1)
                  (equal (trim-lendian* (dab-digit-list-fix base digits2))
                         digits2))
             (equal (equal (lendian=>nat base digits1)
                           (lendian=>nat base digits2))
                    (equal digits1 digits2)))
    :use ((:instance nat=>lendian*-of-lendian=>nat (digits digits1))
          (:instance nat=>lendian*-of-lendian=>nat (digits digits2)))
    :disable nat=>lendian*-of-lendian=>nat)

  (defrule lendian=>nat-injectivity+
    (implies (and (equal (trim-lendian+ (dab-digit-list-fix base digits1))
                         digits1)
                  (equal (trim-lendian+ (dab-digit-list-fix base digits2))
                         digits2))
             (equal (equal (lendian=>nat base digits1)
                           (lendian=>nat base digits2))
                    (equal digits1 digits2)))
    :use ((:instance nat=>lendian+-of-lendian=>nat (digits digits1))
          (:instance nat=>lendian+-of-lendian=>nat (digits digits2)))
    :disable nat=>lendian+-of-lendian=>nat)

  (defrule lendian=>nat-injectivity
    (implies (equal (len digits1)
                    (len digits2))
             (equal (equal (lendian=>nat base digits1)
                           (lendian=>nat base digits2))
                    (equal (dab-digit-list-fix base digits1)
                           (dab-digit-list-fix base digits2))))
    :use ((:instance nat=>lendian-of-lendian=>nat (digits digits1))
          (:instance nat=>lendian-of-lendian=>nat (digits digits2))
          (:instance lendian=>nat-of-dab-digit-list-fix-digits (digits
                                                                digits1))
          (:instance lendian=>nat-of-dab-digit-list-fix-digits (digits
                                                                digits2)))
    :disable (nat=>lendian-of-lendian=>nat
              lendian=>nat-of-dab-digit-list-fix-digits))

  (defrule bendian=>nat-injectivity*
    (implies (and (equal (trim-bendian* (dab-digit-list-fix base digits1))
                         digits1)
                  (equal (trim-bendian* (dab-digit-list-fix base digits2))
                         digits2))
             (equal (equal (bendian=>nat base digits1)
                           (bendian=>nat base digits2))
                    (equal digits1 digits2)))
    :use ((:instance nat=>bendian*-of-bendian=>nat (digits digits1))
          (:instance nat=>bendian*-of-bendian=>nat (digits digits2)))
    :disable nat=>bendian*-of-bendian=>nat)

  (defrule bendian=>nat-injectivity+
    (implies (and (equal (trim-bendian+ (dab-digit-list-fix base digits1))
                         digits1)
                  (equal (trim-bendian+ (dab-digit-list-fix base digits2))
                         digits2))
             (equal (equal (bendian=>nat base digits1)
                           (bendian=>nat base digits2))
                    (equal digits1 digits2)))
    :use ((:instance nat=>bendian+-of-bendian=>nat (digits digits1))
          (:instance nat=>bendian+-of-bendian=>nat (digits digits2)))
    :disable nat=>bendian+-of-bendian=>nat)

  (defrule bendian=>nat-injectivity
    (implies (equal (len digits1)
                    (len digits2))
             (equal (equal (bendian=>nat base digits1)
                           (bendian=>nat base digits2))
                    (equal (dab-digit-list-fix base digits1)
                           (dab-digit-list-fix base digits2))))
    :use ((:instance nat=>bendian-of-bendian=>nat (digits digits1))
          (:instance nat=>bendian-of-bendian=>nat (digits digits2))
          (:instance bendian=>nat-of-dab-digit-list-fix-digits (digits
                                                                digits1))
          (:instance bendian=>nat-of-dab-digit-list-fix-digits (digits
                                                                digits2)))
    :disable (nat=>bendian-of-bendian=>nat
              bendian=>nat-of-dab-digit-list-fix-digits)))
