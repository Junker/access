(cl:defpackage :access-test
  (:use :cl :cl-user :iterate :access :lisp-unit)
  (:shadowing-import-from :alexandria #:ensure-list )
  (:shadowing-import-from :anaphora #:awhen #:aif #:it)
  (:export ))

(in-package :access-test)

(enable-dot-syntax)


(defparameter +al+ `((:one . 1) ("two" . 2) ("three" . 3) (four . 4) (:5 . 5)))
(defparameter +pl+ (list :one 1 "two" 2 "three" 3 'four 4 :5 5))
(defparameter +ht+ (alexandria::plist-hash-table (list "one" 1 "two" 2 "three" 3 "four" 4 "5" 5)
						   :test 'equalp))

(defclass access-test ()
  ((one :accessor one :initarg :one :initform nil)
   (two :accessor two :initarg :two :initform nil)
   (three :accessor three :initarg :three :initform nil)
   (four :initarg :four :initform nil)
   (five :initarg :five :initform nil)
   (pl :initarg :pl :initform +pl+ :accessor pl)))

(defparameter +o+ (make-instance 'access-test :one 1 :two 2 :three 3 :four 4 :five 5))

(define-test access-basic
  (assert-equal 5 (access +al+ 'length))
  (assert-equal 3 (access +al+ 'three))
  (assert-equal 3 (access +pl+ 'three))
  (assert-equal 3 (access +o+ 'three))
  (assert-equal 3 (access +ht+ 'three))
  (assert-equal
   (list "5" "four" "three" "two" "one")
   (access +ht+ 'alexandria:hash-table-keys))
  (assert-equal 3 (accesses +o+ 'pl 'three )))

(define-test test-with-access
  (with-access (one two (my-three three))
      +o+
    (assert-equal 1 one)
    (assert-equal 2 two)
    (assert-equal 3 my-three)
    (setf my-three 33)
    (assert-equal 33 my-three)
    (assert-equal 33 (access +o+ 'three))
    (setf my-three 3)
    ))

(define-test access-and-setting-alist
  (assert-equal 3 (access +al+ 'three) "inited correctly")
  (let ((al (setf (access +al+ 'three) 333)))
    (assert-equal 333 (access al 'three) "first set")
    (setf al (setf (access al 'three) 3))
    
    (assert-equal nil (access al 'sixteen)  "key missing")
    (setf al (setf (access al 'sixteen) 16))
    (assert-equal 16 (access al 'sixteen) "new key set")))

(define-test access-and-setting-plist
  (assert-equal 3 (access +pl+ 'three))

  (let ((pl (setf (access +pl+ 'three) 333)))
    (assert-equal 333 (access pl 'three))
    (assert-equal nil (access pl 'sixteen))
    (setf pl (setf (access pl 'sixteen) 16))
    (assert-equal 16 (access pl 'sixteen))))

(define-test access-and-setting-hashtable
  (assert-equal 3 (access +ht+ 'three))
  (setf (access +ht+ 'three) 333)
  (assert-equal 333 (access +ht+ 'three))
  (assert-equal 333 (access +ht+ "three"))
  (setf (access +ht+ 'three) 3)
  (assert-equal nil (access +ht+ 'sixteen))
  (setf (access +ht+ 'sixteen) 16)
  (assert-equal 16 (access +ht+ 'sixteen))
  (assert-equal 16 (access +ht+ "sixteen"))
  (remhash "sixteen" +ht+))

(define-test access-and-setting-object
  (assert-equal 1 (access +o+ 'one))
  (assert-equal 4 (access +o+ 'four))
  (setf (access +o+ 'four) 444
	(access +o+ 'one) 111)
  (assert-equal 111 (access +o+ 'one))
  (assert-equal 444 (access +o+ 'four))
  (setf (access +o+ 'four) 4
	(access +o+ 'one) 1)
  (assert-equal nil (access +o+ 'nothing))
  (setf (access +o+ 'nothing) 10000)
  (assert-equal nil (access +o+ 'nothing)))

(define-test setting-object-attributes
  (assert-equal 1 (accesses +o+ 'pl :one) +o+ (pl +o+))
  (setf (accesses +o+ 'pl :one) 111)
  (assert-equal 111 (accesses +o+ 'pl :one)  +o+ (pl +o+))
  (setf (accesses +o+ 'pl :one) 1)
  (assert-equal 1 (accesses +o+ 'pl :one)  +o+ (pl +o+))
  
  (assert-equal nil (accesses +o+ 'pl :twenty)  +o+ (pl +o+))
  (setf (accesses +o+ 'pl :twenty) 20)
  (assert-equal 20 (accesses +o+ 'pl :twenty)  +o+ (pl +o+))
  (setf (accesses +o+ 'pl :twenty) nil)
  (assert-equal nil (accesses +o+ 'pl :twenty)  +o+ (pl +o+))
  )


(define-test dot-basic
  (with-dot ()
    (assert-equal 5 +al+.length)
    (assert-equal 3 +al+.three)
    (assert-equal 3 +pl+.three)
    (assert-equal 3 +o+.three)
    (assert-equal 3 +o+.pl.three)))

(define-test dot-set
  (with-dot ()
    (assert-equal 5 +al+.length)
    (assert-equal 3 +al+.three)
    (setf +al+.three 333)
    (assert-equal 333 +al+.three)
    (setf +al+.three 3)
    (assert-equal 3 +o+.pl.three)
    (setf +o+.pl (setf +o+.pl.three 333))
    (assert-equal 333 +o+.pl.three)
    (setf +o+.pl (setf +o+.pl.three 3))
    ))

(define-test dot-basic-reader
  (assert-equal 5 #D+al+.length)
  (assert-equal 3 #D+al+.three)
  (assert-equal 3 #D+pl+.three)
  (assert-equal 3 #D+o+.three)
  (assert-equal 3 #D+o+.pl.three)
  #D(let ((l (list 1 2 3 4 5)))
      (assert-equal 5 l.length)
      (assert-equal 5 +al+.length)
      (assert-equal 3 +al+.three)
      (assert-equal 3 +pl+.three)
      (assert-equal 3 +o+.three)
      (assert-equal 3 +o+.pl.three)))

(define-test dot-iteration
  (with-dot ()
    (iter (for (k v . rest) on (list :pl1 +pl+ :pl2 +pl+) by #'cddr)
	  (when (first-iteration-p)
	    (assert-equal 10 rest.pl2.length)
	    (assert-equal 4 rest.pl2.four))
	  (assert-equal 4 v.four))))
