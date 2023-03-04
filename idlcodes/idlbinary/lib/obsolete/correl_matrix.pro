; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/correl_matrix.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.


function correl_matrix,X
;+
; NAME:
;	CORREL_MATRIX
;
; PURPOSE: 
;	To compute correlation coefficients of pairs of columns of X.
;
; CATEGORY:
;	Statistics.
;
; CALLING SEQUENCE:
;	Result = CORREL_MATRIX(X)
;
; INPUTS: 
;	X:	Matrix of experimental data.  X(i,j) = the value of the ith
;		variable in the jth observation.
;
; OUTPUT:
;	CORREL_MATRIX returns a matrix M, where M(i,j) = the simple Pearson
;	correlation coefficient between the ith and jth variable. 
;-
 N = size(X)
 C = N(1)
 N = N(2)

if N LT 2 THEN BEGIN
  print,       $
     'correl_matrix - need more than one pair of observations'
  return,-1
ENDIF
 X = float(X)
 M = Fltarr(C,C) + 1
 VarXI = X - (X # Replicate(1.0/N,N)) # Replicate(1.0,N)
 SS = VarXI^2 # Replicate(1.0,N) 
 SS = sqrt(SS # SS)
 M = (VarXI # transpose(VarXI))/SS
 return,M
 END
       