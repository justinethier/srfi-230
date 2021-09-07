
(define-library (230)
  (include-c-header "<stdatomic.h>")
  (export 
;  memory-order
  memory-order?
  make-atomic-flag
  atomic-flag?
  atomic-flag-test-and-set!
  atomic-flag-clear!
  make-atomic-box
  atomic-box?
  atomic-box-ref
  atomic-box-set!
;  atomic-box-swap!
;  atomic-box-compare-and-swap!
  make-atomic-fxbox
  atomic-fxbox?
  atomic-fxbox-ref
;  atomic-fxbox-set!
;  atomic-fxbox-swap!
;  atomic-fxbox-compare-and-swap!
  atomic-fxbox+/fetch!
  atomic-fxbox-/fetch!
  atomic-fxbox-and/fetch!
  atomic-fxbox-ior/fetch!
  atomic-fxbox-xor/fetch!
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

    (define-c %atomic-flag-init
      "(void *data, int argc, closure _, object k)"
      " atomic_flag f = ATOMIC_FLAG_INIT;
        atomic_flag *flag = malloc(sizeof(atomic_flag));
        make_c_opaque(opq, flag); 
        opaque_collect_ptr(&opq) = 1; // Allow GC to free() memory
        *flag = f;
        return_closcall1(data, k, &opq); ")

    (define-c %atomic-flag-tas
      "(void *data, int argc, closure _, object k, object opq)"
      " atomic_flag *flag = opaque_ptr(opq);
        _Bool b = atomic_flag_test_and_set(flag);
        return_closcall1(data, k, b ? boolean_t : boolean_f);")

    (define-c %atomic-flag-clear
      "(void *data, int argc, closure _, object k, object opq)"
      " atomic_flag *flag = opaque_ptr(opq);
        atomic_flag_clear(flag);
        return_closcall1(data, k, boolean_f);")

    (define-record-type atomic-flag
      (%make-atomic-flag content)
      atomic-flag?
      (content atomic-flag-content atomic-flag-set-content!))

    (define (make-atomic-flag)
      (define b (%make-atomic-flag (%atomic-flag-init)))
      (Cyc-minor-gc)
      b)

    (define (atomic-flag-check flag)
      (unless (atomic-flag? flag)
        (error "Expected atomic flag but received" flag)))

    (define (atomic-flag-test-and-set! flag . o)
      (atomic-flag-check flag)
      (%atomic-flag-tas (atomic-flag-content flag)))

    (define (atomic-flag-clear! flag . o)
      (atomic-flag-check flag)
      (%atomic-flag-clear (atomic-flag-content flag)))

    ;; Atomic boxes

    (define-c %atomic-box-init
      "(void *data, int argc, closure _, object k, object pair, object value)"
      " pair_type *p = (pair_type*)pair;
        atomic_init((uintptr_t *)&(p->pair_car), (uintptr_t)value);
        //v->elements[2] = (object)ptr;
        return_closcall1(data, k, pair); ")

    (define-c %atomic-box-load
      "(void *data, int argc, closure _, object k, object pair)"
      " pair_type *p = (pair_type*)pair;
        uintptr_t c = atomic_load((uintptr_t *)(&(p->pair_car)));
        return_closcall1(data, k, (object)c); ")

;; TODO: need a write barrier
;;       see Cyc_set_car_cps() in runtime.c
    (define-c %atomic-box-store
      "(void *data, int argc, closure _, object k, object pair, object value)"
      " pair_type *p = (pair_type*)pair;
        atomic_store((uintptr_t *)(&(p->pair_car)), (uintptr_t)value);
        return_closcall1(data, k, boolean_f); ")

    ;; TODO: atomic_exchange

    ;; TODO: atomic_compare_exchange_strong, used to implement CAS
    ;;; take care that *expected may be overwritten

    (define-record-type atomic-box
      (%make-atomic-box content)
      atomic-box?
      (content atomic-box-content atomic-box-set-content!))

    (define (make-atomic-box c)
      (define b (%make-atomic-box (list #f)))
      ;; TODO: force c onto heap now?
      (%atomic-box-init (atomic-box-content b) c) 
      (Cyc-minor-gc) ;; Force b onto heap
      b)

    (define (atomic-box-check box)
      (unless (atomic-box? box)
        (error "Expected atomic box but received" box)))

    (define (atomic-box-ref box . o)
      (atomic-box-check box)
      (%atomic-box-load (atomic-box-content box)))

    (define (atomic-box-set! box obj . o)
      (atomic-box-check box)
      (%atomic-box-store (atomic-box-content box) obj))

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

    ;; store native ints in a C opaque, otherwise GC could think they are pointers
    (define-c %atomic-fxbox-init
      "(void *data, int argc, closure _, object k, object opq, object value)"
      " Cyc_check_fixnum(data, value);
        atomic_uintptr_t p;
        atomic_init(&p, (uintptr_t)obj_obj2int(value));
        opaque_ptr(opq) = (object)p;
        return_closcall1(data, k, opq); ")

    (define-c %empty-opaque
      "(void *data, int argc, closure _, object k)"
      " make_c_opaque(opq, NULL);
        return_closcall1(data, k, &opq); ")

    (define-c %atomic-fxbox-load
      "(void *data, int argc, closure _, object k, object opq)"
      " uintptr_t c = atomic_load((uintptr_t *)(&(opaque_ptr(opq))));
        return_closcall1(data, k, obj_int2obj(c)); ")

    (define-syntax fx-num-op
      (er-macro-transformer
        (lambda (expr rename compare)
          (let* ((scm-fnc (cadr expr))
                 (fnc (caddr expr))
                 (op-str (cadddr expr))
                 (args "(void* data, int argc, closure _, object k, object opq, object m)")
                 (body
                   (string-append
                     " uintptr_t c = " op-str "((uintptr_t *)(&(opaque_ptr(opq))), (uintptr_t)obj_obj2int(m));\n"
                     " return_closcall1(data, k, (object)c); ")))
            `(begin 
               (define-c ,fnc ,args ,body)
               (define (,scm-fnc box n . o)
                 (atomic-fxbox-check box)
                 (,fnc (atomic-fxbox-content box) n))
)))))

    ;(define-c %atomic-fxbox-fetch-add
    ;  "(void *data, int argc, closure _, object k, object opq, object m)"
    ;  " uintptr_t c = atomic_fetch_add((uintptr_t *)(&(opaque_ptr(opq))), (uintptr_t)obj_obj2int(m));
    ;    return_closcall1(data, k, (object)c); ")

    ;(define (atomic-fxbox+/fetch! box n . o)
    ;  (atomic-fxbox-check box)
    ;  (%atomic-fxbox-fetch-add (atomic-fxbox-content box) n))

    (fx-num-op atomic-fxbox+/fetch!    %atomic-fxbox-fetch-add  "atomic_fetch_add")
    (fx-num-op atomic-fxbox-/fetch!    %atomic-fxbox-/fetch!    "atomic_fetch_sub")
    (fx-num-op atomic-fxbox-and/fetch! %atomic-fxbox-and/fetch! "atomic_fetch_and")
    (fx-num-op atomic-fxbox-ior/fetch! %atomic-fxbox-ior/fetch! "atomic_fetch_or")
    (fx-num-op atomic-fxbox-xor/fetch! %atomic-fxbox-xor/fetch! "atomic_fetch_xor")

    (define-record-type atomic-fxbox
      (%make-atomic-fxbox content)
      atomic-fxbox?
      (content atomic-fxbox-content atomic-fxbox-set-content!))

    (define (make-atomic-fxbox c)
      (define b (%make-atomic-fxbox (%empty-opaque)))
      (Cyc-minor-gc) ;; Force b onto heap
      (%atomic-fxbox-init (atomic-fxbox-content b) c) 
      b)

    (define (atomic-fxbox-check box)
      (unless (atomic-fxbox? box)
        (error "Expected atomic fxbox but received" box)))

    (define (atomic-fxbox-ref box . o)
      (atomic-fxbox-check box)
      (%atomic-fxbox-load (atomic-fxbox-content box)))

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
;
;    ;; Memory synchronization
;
;    (define (atomic-fence . o)
;      (lock-guard (if #f #f)))
  ))
