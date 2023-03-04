; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/f_test.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.


function f_test, a,DFN,DFD
;+
; NAME:
;     F_TEST
;
; PURPOSE:
;	F_TEST returns the cutoff value v such that:
;
;		Probability(X > v) = a
;
;	where X is a random variable from the F distribution with DFN and DFD
;	numerator and denominator degrees of freedom.
;
; CATEGORY:
;	Statistics.
;
; CALLING SEQUENCE:
;     Result = F_TEST(A, DFN, DFD)
;
; INPUT:
;	A:	probability
;
;	DFN:	numerator degrees of freedom
;
;	DFD:	denominator degrees of freedom
;
; OUTPUT: 
;	If A is between 0 and 1, then the cutoff value is returned. 
;	Otherwise, -1 is returned to indicate an error.
;-
if (a gt 1 or a lt 0) then return,-1  

case 1 of
 DFD EQ 1: UP=300.0 
 DFD EQ 2: UP =100.0 
 DFD GT 2 and  DFD LE 5: UP=30.0
 DFD GT 5 and DFD LE 14: UP = 20.0
 ELSE: UP = 12.0
ENDCASE

Below=0

 while f_test1(UP,DFN,DFD) LT 1- a DO BEGIN
      Below = UP
      UP = 2*UP
 ENDWHILE

 
return, pd_bisection([1-a,DFN,DFD],'f_test1',Up,Below)
end

