; Copyright (C) 2000, 2001, 2002 RiskMap srl
;
; This file is part of QuantLib, a free-software/open-source library
; for financial quantitative analysts and developers - http://quantlib.org/
;
; QuantLib is free software developed by the QuantLib Group; you can
; redistribute it and/or modify it under the terms of the QuantLib License;
; either version 1.0, or (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; QuantLib License for more details.
;
; You should have received a copy of the QuantLib License along with this
; program; if not, please email ferdinando@ametrano.net
;
; The QuantLib License is also available at http://quantlib.org/license.html
; The members of the QuantLib Group are listed in the QuantLib License
;
; $Id$


; common utility functions
(define (range i j)
  (if (= i j)
      '()
      (cons i (range (+ i 1) j))))
(define (flatmap proc seq)
  (foldr append '() (map proc seq)))
(define (foldr op initial sequence)
  (if (null? sequence)
      initial
      (op (car sequence)
          (foldr op initial (cdr sequence)))))
(define (sorted? l less-than?)
  (if (null? l)
      #t
      (let ((first (car l))
            (rest (cdr l)))
        (if (null? rest)
            #t
            (let ((second (car rest)))
              (if (less-than? first second)
                  (sorted? rest less-than?)
                  #f))))))


; make a grid
(define (grid-step xmin xmax N)
  (/ (- xmax xmin) (- N 1)))
(define (grid xmin xmax N)
  (let ((h (grid-step xmin xmax N)))
    (define (loop i accum)
      (if (= i N)
          (reverse accum)
          (loop (+ i 1) (cons (+ xmin (* h i)) accum))))
    (loop 0 '())))

; norm of a discretized function
(define (norm f h)
  (define (sum f)
    (apply + f))
  (define (integral f h)
    (let ((first (car f))
          (last (list-ref f (- (length f) 1))))
      (sqrt (* h (- (sum f) (* 0.5 first) (* 0.5 last))))))
  (let ((f^2 (map (lambda (x) (* x x)) f)))
    (integral f^2 h)))


; bind a set of names to the elements of a list
(define-macro let-at-once
  (lambda (binding . body)
    (let ((vars (car binding))
          (vals (cadr binding)))
      `(call-with-values
         (lambda () (apply values ,vals))
         (lambda ,vars ,@body)))))

; bind a set of parameters to each test case
(define-macro for-each-case
  (lambda (bindings . body)
    (let ((vars (car bindings))
          (cases (cadr bindings))
          (test-case (gensym)))
      `(for-each
        (lambda (,test-case)
          (let-at-once (,vars ,test-case)
            ,@body))
        ,cases))))

; get a number of test cases by building all possible
; combinations of sets of parameters
(define (combinations l . ls)
  (define (add-one x ls)
    (map (lambda (l) (cons x l)) ls))
  (define (add-all l ls)
    (flatmap (lambda (x) (add-one x ls)) l))
  (if (null? ls)
      (map list l)
      (add-all l (apply combinations ls))))

; bind a set of parameters to all possible combinations
(define-macro for-each-combination
  (lambda (bind-sets . body)
    (let ((vars (map car bind-sets))
          (sets (map cadr bind-sets))
          (combo (gensym)))
      `(for-each 
        (lambda (,combo)
          (let-at-once (,vars ,combo)
            ,@body))
        (combinations ,@sets)))))
