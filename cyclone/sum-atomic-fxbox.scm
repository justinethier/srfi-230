(import (scheme base)
	(scheme write)
	(srfi 18)
	(230))

(define *atomic-counter* (make-atomic-fxbox 0))
(define *counter* 0)

(define (task)
  (do ((i 0 (+ i 1)))
      ((= i 1000))
    (atomic-fxbox+/fetch! *atomic-counter* 1)
    (set! *counter* (+ *counter* 1))))

(define threads (make-vector 10))

(do ((i 0 (+ i 1)))
    ((= i 10))
  (let ((thread (make-thread task)))
    (vector-set! threads i thread)
    (thread-start! thread)))

(do ((i 0 (+ i 1)))
    ((= i 10))
  (thread-join! (vector-ref threads i)))

(display (atomic-fxbox-ref *atomic-counter*))
(newline)
(display *counter*)
(newline)
