(import
  (scheme base)
  (scheme write)
  (srfi 230))

(define b (make-atomic-fxbox 42))

(write (atomic-fxbox-ref b))
(newline)

(atomic-fxbox+/fetch! b 1)
(atomic-fxbox+/fetch! b 1)
(atomic-fxbox+/fetch! b 1)
(write (atomic-fxbox-ref b))
(newline)
