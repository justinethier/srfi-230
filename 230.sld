
(define-library (230)
  (include-c-header "<stdatomic.h>")
  (export 
;  memory-order
  memory-order?
;  make-atomic-flag
;  atomic-flag?
;  atomic-flag-test-and-set!
;  atomic-flag-clear!
;  make-atomic-box
;  atomic-box?
;  atomic-box-ref
;  atomic-box-set!
;  atomic-box-swap!
;  atomic-box-compare-and-swap!
  make-atomic-fxbox
  atomic-fxbox?
  atomic-fxbox-ref
;  atomic-fxbox-set!
;  atomic-fxbox-swap!
;  atomic-fxbox-compare-and-swap!
  atomic-fxbox+/fetch!
;  atomic-fxbox-/fetch!
;  atomic-fxbox-and/fetch!
;  atomic-fxbox-ior/fetch!
;  atomic-fxbox-xor/fetch!
;  atomic-fence
)
  (import (scheme base)
;  (scheme case-lambda)
  (srfi 18)
;  (srfi 143)
    )
  (begin

    ;; Internals

;    (define lock (make-mutex))
;
;    (define-syntax lock-guard
;      (syntax-rules ()
;	((lock-guard . body)
;	 (dynamic-wind
;	   (lambda ()
;	     (guard
;		 (c
;		  ((abandoned-mutex-exception? c)
;		   #f))
;	       (mutex-lock! lock)))
;	   (lambda () . body)
;	   (lambda ()
;	     (mutex-unlock! lock))))))
;
;    ;; Memory orders
;
;    ;; Note: On an R6RS system, the following syntax and procedure would be
;    ;; implemented as an enumeration type.
;
;    (define-syntax memory-order
;      (syntax-rules ()
;	((memory-order symbol) 'symbol)))
;
    (define (memory-order? obj)
      (and (memq
	    obj
	    '(relaxed acquire release acquire-release sequentially-consistent))
	   #t))
;
;    ;; Atomic flags

;    (define-c atomic-flag-init
;      "(void *data, int argc, closure _, object k, object box)"
;      " 
;        atomic_flag flag = ATOMIC_FLAG_INIT;
;        // TODO: validate v and size
;        vector v = (vector)box;
;        v->elements[2] = (object) flag;
;        return_closcall1(data, k, box); ")
;
;    (define-record-type atomic-flag
;      (%make-atomic-flag content)
;      atomic-flag?
;      (content atomic-flag-content atomic-flag-set-content!))
;
;    (define (make-atomic-flag)
;      (%make-atomic-flag (atomic-flag-init)))

;    (define (atomic-flag-test-and-set! flag . o)
;      (lock-guard
;       (let ((prev (atomic-flag-content flag)))
;	 (atomic-flag-set-content! flag #t)
;	 prev)))
;
;    (define (atomic-flag-clear! flag . o)
;      (lock-guard
;       (atomic-flag-set-content! flag #f)))
;
;    ;; Atomic boxes
;
;    (define-record-type atomic-box
;      (make-atomic-box content)
;      atomic-box?
;      (content atomic-box-content atomic-box-set-content!))
;
;    (define (atomic-box-ref box . o)
;      (lock-guard
;       (atomic-box-content box)))
;
;    (define (atomic-box-set! box obj . o)
;      (lock-guard
;       (atomic-box-set-content! box obj)))
;
;    (define (atomic-box-swap! box obj . o)
;      (lock-guard
;       (let ((prev (atomic-box-content box)))
;	 (atomic-box-set-content! box obj)
;	 prev)))
;
;    (define (atomic-box-compare-and-swap! box expected desired . o)
;      (lock-guard
;       (let ((actual (atomic-box-content box)))
;	 (when (eq? expected actual)
;	   (atomic-box-set-content! box desired))
;	 actual)))

    ;; Atomic fixnum boxes

    (define-c atomic-init
      "(void *data, int argc, closure _, object k, object box, object value)"
      " Cyc_check_fixnum(data, value);
        atomic_uintptr_t a;
        // TODO: validate v and size
        vector v = (vector)box;
        v->elements[2] = (object) a;
        atomic_init((uintptr_t *)(&(v->elements[2])), (uintptr_t)obj_obj2int(value));
        return_closcall1(data, k, box); ")

    (define-c atomic-load
      "(void *data, int argc, closure _, object k, object a)"
      " vector v = (vector) a;
        // TODO: validate v and size
        uintptr_t c = atomic_load((uintptr_t *)(&(v->elements[2])));
        return_closcall1(data, k, obj_int2obj(c)); ")

    (define-c atomic-fetch-add
      "(void *data, int argc, closure _, object k, object a, object m)"
      " vector v = (vector) a;
        // TODO: validate v and size
        uintptr_t c = atomic_fetch_add((uintptr_t *)(&(v->elements[2])), (uintptr_t)obj_obj2int(m));
        return_closcall1(data, k, (object)c); ")

    (define-record-type atomic-fxbox
      (%make-atomic-fxbox content)
      atomic-fxbox?
      (content atomic-fxbox-content atomic-fxbox-set-content!))

    (define (make-atomic-fxbox c)
      (define b (%make-atomic-fxbox #f))
      (Cyc-minor-gc) ;; Force b onto heap
      (atomic-init b c) 
      b)

    (define (atomic-fxbox-ref box . o)
      (atomic-load box))

    (define (atomic-fxbox+/fetch! box n . o)
      (atomic-fetch-add box n))

;    (define (atomic-fxbox-ref box . o)
;      (lock-guard
;       (atomic-fxbox-content box)))

;    (define (atomic-fxbox-set! box obj . o)
;      (lock-guard
;       (atomic-fxbox-set-content! box obj)))
;
;    (define (atomic-fxbox-swap! box obj . o)
;      (lock-guard
;       (let ((prev (atomic-fxbox-content box)))
;	 (atomic-fxbox-set-content! box obj)
;	 prev)))
;
;    (define (atomic-fxbox-compare-and-swap! box expected desired . o)
;      (lock-guard
;       (let ((actual (atomic-fxbox-content box)))
;	 (when (fx=? expected actual)
;	   (atomic-fxbox-set-content! box desired))
;	 actual)))
;
;    (define (atomic-fxbox+/fetch! box n . o)
;      (lock-guard
;       (let ((prev (atomic-fxbox-content box)))
;	 (atomic-fxbox-set-content! box (fx+ n prev))
;	 prev)))
;
;    (define (atomic-fxbox-/fetch! box n . o)
;      (lock-guard
;       (let ((prev (atomic-fxbox-content box)))
;	 (atomic-fxbox-set-content! box (fx- n prev))
;	 prev)))
;
;    (define (atomic-fxbox-and/fetch! box n . o)
;      (lock-guard
;       (let ((prev (atomic-fxbox-content box)))
;	 (atomic-fxbox-set-content! box (fxand n prev))
;	 prev)))
;
;    (define (atomic-fxbox-ior/fetch! box n . o)
;      (lock-guard
;       (let ((prev (atomic-fxbox-content box)))
;	 (atomic-fxbox-set-content! box (fxior n prev))
;	 prev)))
;
;    (define (atomic-fxbox-xor/fetch! box n . o)
;      (lock-guard
;       (let ((prev (atomic-fxbox-content box)))
;	 (atomic-fxbox-set-content! box (fxxor n prev))
;	 prev)))
;
;    ;; Memory synchronization
;
;    (define (atomic-fence . o)
;      (lock-guard (if #f #f)))
  ))