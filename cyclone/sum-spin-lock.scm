(import (scheme base)
	(scheme write)
	(srfi 18)
	(230))

(define *flag* (make-atomic-flag))
(define *counter* 0)

(define (spin-lock flag)
  (let loop ()
    (if (atomic-flag-test-and-set! flag)
        (loop))))
;    while( flag.test_and_set() );

(define (spin-unlock flag)
  (atomic-flag-clear! flag))

(define (task)
  (do ((i 0 (+ i 1)))
      ((= i 1000))

    (spin-lock *flag*)
    (set! *counter* (+ *counter* 1))
    (spin-unlock *flag*)
    
    ))

(define threads (make-vector 10))

(do ((i 0 (+ i 1)))
    ((= i 10))
  (let ((thread (make-thread task)))
    (vector-set! threads i thread)
    (thread-start! thread)))

(do ((i 0 (+ i 1)))
    ((= i 10))
  (thread-join! (vector-ref threads i)))

(display *counter*)
(newline)