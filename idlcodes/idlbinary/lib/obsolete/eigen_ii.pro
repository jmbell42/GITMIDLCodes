; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/eigen_ii.pro#1 $
;
; Copyright (c) 1993-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

;+
; NAME:
;       EIGEN_II
;
; PURPOSE:
;       This function computes the eigenvectors of an N by N 
;       real, nonsymmetric matrix. The result is an array of 
;       complex type with a column dimension equal to the 
;       number of eigenvalues and a row dimension equal to N.
;
; CATEGORY:
;       Numerical Linear Algebra.
;
; CALLING SEQUENCE:
;       Result = EIGEN_II(A, Eval)
;
; INPUTS:
;           A:  An N by N matrix real, nonsymmetric matrix.
;        Eval:  An n-element complex vector of eigenvalues.    
;
; KEYWORD PARAMETERS:
;      Double:  If set to a non-zero value, computations are done in
;               double precision arithmetic.
;               NOTE: Since IDL lacks a double-precision complex 
;                     data type, computations are done internally
;                     in double-precision and the result is truncated
;                     to single-precision complex.
;       Itmax:  The number of iterations performed in the computation
;               of each eigenvector. The default value is 4.
;
; EXAMPLE:
; 1) A real, nonsymmetric matrix with real eigenvalues/eigenvectors.
;       Define an N by N real, nonsymmetric array.
;         a = [[  7.3, 0.2, -3.7], $
;              [-11.5, 1.0,  5.5], $
;              [ 17.7, 1.8, -9.3]]
;       Transpose the array into IDL column (matrix) format.
;         at = transpose(a)
;       Compute the eigenvalues of a.
;         eval = NR_HQR(NR_ELMHES(at))
;       Print the eigenvalues.
;         print, eval
;       Compute the eigenvectors of a.
;         evec = EIGEN_II(at, eval)
;       Print the eigenvectors.
;         print, evec(0,*), evec(1,*), evec(2,*)
;       Check the accuracy of each eigenvalue/eigenvector (lamda/x) 
;       pair using the mathematical definition of an eigenvector;
;       Ax - (lambda)x = 0
;         print, (evec(0,*) # a) - (eval(0) * evec(0,*))
;         print, (evec(1,*) # a) - (eval(1) * evec(1,*))
;         print, (evec(2,*) # a) - (eval(2) * evec(2,*)) 
; 2) A real, nonsymmetric matrix with complex eigenvalues/eigenvectors.
;       Define an N by N real, nonsymmetric array.
;       a = [[ 0.0, 1.0], $
;            [-1.0, 0.0]]
;       Transpose the array into IDL column (matrix) format.
;         at = transpose(a)
;       Compute the eigenvalues of a.
;         eval = NR_HQR(NR_ELMHES(at))
;       Print the eigenvalues.
;         print, eval
;       Compute the eigenvectors of a.
;         evec = EIGEN_II(at, eval, /double)
;       Print the eigenvectors.
;         print, evec(0,*), evec(1,*)
;       Check the accuracy of each eigenvalue/eigenvector (lamda/x)
;       pair using the mathematical definition of an eigenvector;
;       Ax - (lambda)x = 0
;         print, (evec(0,*) # a) - (eval(0) * evec(0,*))
;         print, (evec(1,*) # a) - (eval(1) * evec(1,*))
;
; PROCEDURE:
;       EIGEN_II.PRO computes the set of eigenvectors that correspond
;       to a given set of eigenvalues using Inverse Subspace Iteration.
;       The eigenvectors are computed up to a scale factor and are of
;       Euclidean length.
;       The functions NR_ELMHES and NR_HQR may be used to find the  
;       eigenvalues of an N by N matrix real, nonsymmetric matrix.
;
; REFERENCE:
;       Numerical Recipes, The Art of Scientific Computing (Second Edition)
;       Cambridge University Press
;       ISBN 0-521-43108-5
;
; MODIFICATION HISTORY:
;           Written by:  GGS, RSI, December 1993
;-

function eigen_ii, a, eval, double = double, itmax = itmax

  on_error, 2  ;return to caller if error occurs.

  dim = size(a)
  if dim(1) ne dim(2) then stop, $
    ' EIGEN_II: A is not square.'

; Set default values for keyword parameters.
  if keyword_set(double) eq 0 then double =  0
  if keyword_set(itmax)  eq 0 then itmax  =  4

  enum = n_elements(eval)            ;Number of eigenvalues.
  evec = complexarr(enum, dim(1))    ;Eigenvector storage array.
  diag = indgen(dim(1)) * (dim(1)+1) ;Diagonal indices of a. 

  for k = 0, enum - 1 do begin
    alud = a  ;Create a new copy of alud for next eigenvalue computation.

;   Complex eigenvalue ?
    if imaginary(eval(k)) ne 0 then begin
      alud = complex(alud)
      alud(diag) = alud(diag) - eval(k)
      re = float(alud)
      im = imaginary(alud)
      comp = [[ re, im], $
              [-im, re]]
      b = replicate(1.0, 2*dim(1))
      b = b / sqrt(total(b^2, 1))
      ludc, comp, index, double = double, /column
      it = 0
      while it lt itmax do begin
        x = lusol(comp, index, b, double = double, /column)
        b = x / sqrt(total(x^2, 1))  ;Normalize eigenvector.
        it = it + 1
      endwhile
      evec(k, *) = complex(b(0:dim(1)-1), b(dim(1):*))

    endif else begin
;   Real eigenvalue !
      alud(diag) = alud(diag) - float(eval(k))
      b = replicate(1.0, dim(1))
      b = b / sqrt(total(b^2, 1))
      ludc, alud, index, double = double, /column
      it = 0
      while it lt itmax do begin
        x = lusol(alud, index, b, double = double, /column)
        b = x / sqrt(total(x^2, 1))  ;Normalize eigenvector.
        it = it + 1
      endwhile
      evec(k, *) = complex(b, 0.0)
    endelse
  endfor
  return, evec
end

