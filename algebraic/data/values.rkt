#lang algebraic/racket/base

(require algebraic/class/applicative
         algebraic/class/functor
         algebraic/class/monad)

(provide (all-defined-out))

(define-syntax ValuesFunctor
  (instance Functor
    [fmap (flip call-with-values)]))

(define-syntax ValuesApplicative
  (instance Applicative
    extends (ValuesFunctor)
    [pure id]
    [liftA2 (λ (f x~ y~) (fmap (fmap (>>* f) x~) y~))]))

(define-syntax ValuesMonad
  (instance Monad
    extends (ValuesApplicative)
    [return pure]
    [>>= call-with-values]
    [>>M (λ (x~ y~) (x~) (y~))]))

;;; -----------------------------------------------------------------------------

(module+ test
  (require rackunit
           algebraic/data/list)

  (instantiate || ValuesMonad)

  (test-case "ValuesFunctor"
    (check equal? (fmap list (λ () (id 1 2 3 4))) '(1 2 3 4))
    (check equal? (fmap (.. (>> map add1) list) (λ () (id 1 2 3 4)))
           '(2 3 4 5)))

  (with-instances ([list- ListFunctor]
                   [values- ValuesFunctor])
    (check equal? (list-fmap add1 (values-fmap list (λ () (id 1 2 3 4))))
           '(2 3 4 5)))

  (test-case "ValuesApplicative"
    (check = (pure 1) 1)
    (check equal? (liftA2 list
                          (λ () (pure 1 2))
                          (λ () (pure 3 4)))
           '(1 2 3 4))
    (check = (<*> (λ () (pure add1))
                  (λ () (pure 2)))
           3)
    (check = (<*> (λ () add1) (λ () 2)) 3))

  (test-case "ValuesMonad"
    (check equal? (>>= (λ () (return 1 2)) list) '(1 2))
    (check equal? (do xs <- (λ () (return 1 2))
                      (return xs))
           '(1 2))
    (check equal? (do (x . xs) <- (λ () (return 4 5 6))
                      (return (list x xs)))
           '(4 (5 6)))
    (check equal? (do xs <- (λ () (return 7 8))
                      (return xs))
           '(7 8))
    (check equal? (do (x . xs) <- (λ () (return 9 10 11))
                      (λ () (return 12 13 14))
                      (return (λ () (list x xs))))
           '(9 (10 11)))
    (check = (do let x 12 (+ x 13)) 25)
    (check = (do let-values xs (return 14 15 16) ($ + xs)) 45)))
