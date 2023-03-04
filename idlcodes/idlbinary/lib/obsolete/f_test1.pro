; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/f_test1.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.


function f_test1 , X,DFN,DFD
;+
; NAME:
;     F_TEST1
;
; PURPOSE:
;	F_test1 returns the probabilty of an observed value greater than X
;	from an F distribution with DFN and DFD numerator and denominator 
;	degrees of freedom.
;
; CATEGORY:
;	Statistics.
;
; CALLING SEQUENCE:
;     Result = F_TEST1(X, DFN, DFD)
;
; INPUT:
;	X:	cutoff
;
;	DFN:	numerator degrees of freedom
;
;	DFD:	denominator degrees of freedom
;
; OUTPUT: 
;	The probability of a value greater than X. 
;-
 if X le 0 THEN return,1
 return, 1 - betai( DFD/(DFD+DFN*X),DFD/2.0,DFN/2.0)

END