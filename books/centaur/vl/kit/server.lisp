; VL Verilog Toolkit
; Copyright (C) 2008-2014 Centaur Technology
;
; Contact:
;   Centaur Technology Formal Verification Group
;   7600-C N. Capital of Texas Highway, Suite 300, Austin, TX 78731, USA.
;   http://www.centtech.com/
;
; License: (An MIT/X11-style license)
;
;   Permission is hereby granted, free of charge, to any person obtaining a
;   copy of this software and associated documentation files (the "Software"),
;   to deal in the Software without restriction, including without limitation
;   the rights to use, copy, modify, merge, publish, distribute, sublicense,
;   and/or sell copies of the Software, and to permit persons to whom the
;   Software is furnished to do so, subject to the following conditions:
;
;   The above copyright notice and this permission notice shall be included in
;   all copies or substantial portions of the Software.
;
;   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
;   DEALINGS IN THE SOFTWARE.
;
; Original author: Jared Davis <jared@centtech.com>

(in-package "VL")

; Added by Matt K., May 2015.  Improvement observed when certification used
; the :delay strategy:
; 47.43 sec. vs. 55.41 sec.
(value-triple (set-gc-strategy :delay))

(include-book "shell")
(include-book "../server/top")
(include-book "../util/gc")
(include-book "centaur/getopt/top" :dir :system)
(local (include-book "xdoc/display" :dir :system))

(make-event
 (let ((public-dir (oslib::catpath *browser-dir* "public")))
   `(defoptions vl-server-opts
      :parents (vl-server)
      :short "Options for running @('vl server')."
      :tag :vl-server-opts

      ((help    booleanp
                "Show a brief usage message and exit."
                :rule-classes :type-prescription
                :alias #\h)

       (readme  booleanp
                "Show a more elaborate README and exit."
                :rule-classes :type-prescription)

       (mem     posp
                :alias #\m
                :argname "GB"
                "Default: 6 GB.  How much memory to try to use.  Raising this
                 may improve performance by avoiding garbage collection.  To
                 avoid swapping, keep this below (physical_memory - 2 GB)."
                :default 6
                :rule-classes :type-prescription)

       (port    posp
                :alias #\p
                "Default: 9999.  What port to run on."
                :default 9999
                :rule-classes :type-prescription)

       (root    stringp
                :alias #\r
                "Default: \"./translations\".  Where to find translations.  See the
                 --readme to understand this."
                :default "./translations"
                :rule-classes :type-prescription)

       (public  stringp
                :rule-classes :type-prescription
                ,(cat "Default: \"" public-dir "\".  Where to find the supporting
                'public' directory from the module browser's code.  You should be
                able to ignore this unless you're deploying the module browser to
                a different directory.")
                :default ,public-dir)))))

(defconst *vl-server-help* (str::cat "
vl server:  Runs the VL Server (which supports the Module Browser).

Usage:    vl server [OPTIONS]

Options:" *nls* *nls* *vl-server-opts-usage* *nls*))

(defconsts (*vl-server-readme* state)
  (b* ((topic (xdoc::find-topic 'vl::server (xdoc::get-xdoc-table (w state))))
       ((mv text state) (xdoc::topic-to-text topic nil state)))
    (mv text state)))

(define vl-server ((cmdargs string-listp) &optional (state 'state))
  :parents (kit server)
  :short "The @('vl server') command."

  (b* (((mv errmsg opts extra-args)
        (parse-vl-server-opts cmdargs))
       ((when errmsg)
        (die "~@0~%" errmsg)
        state)
       ((when extra-args)
        (die "Unrecognized arguments: ~x0" extra-args)
        state)

       ((vl-server-opts opts) opts)

       ((when opts.help)
        (vl-cw-ps-seq (vl-print *vl-server-help*))
        (exit-ok)
        state)

       ((when opts.readme)
        (vl-cw-ps-seq (vl-print *vl-server-readme*))
        (exit-ok)
        state)

       (max-mem (* (expt 2 30) opts.mem))
       (1/3-mem (floor max-mem 3))
       (- (acl2::set-max-mem ;; newline to appease cert.pl's scanner
           max-mem))
       (- (set-vl-gc-baseline))
       (- (set-vl-gc-threshold 1/3-mem))

       ((unless (<= opts.port 65535))
        (die "Invalid port ~x0~%" opts.port)
        state)

       ((mv & hostname state) (acl2::getenv$ "HOSTNAME" state))
       (- (cw "Starting VL server on ~s0:~x1~%" hostname opts.port))

       (- (start :port       opts.port
                 :public-dir opts.public
                 :root-dir   opts.root)))
    (cw "Starting VL Shell for the server.~%")
    (vl-shell nil)))



