; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/chi_sqr.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.


function chi_sqr, a,DF 
;+
; NAME:
;	CHI_SQR
;
; PURPOSE: 
;	CHI_SQR returns the cutoff value v such that
;
;		Probability(X > v) = a
;
;	where X is a random variable from the chi_sqr distribution with 
;	v degrees of freedom. 
;
; CATEGORY:
;	Statistics.
; 
; CALLING SEQUENCE:
;	Result = CHI_SQR(A, DF)
;
; INPUT:
;	A:	probability
;	DF:	degrees of freedom
;
; OUTPUT:
;	If a is between 0 and 1, then the cutoff value is returned.
;	Otherwise, -1 is returned to indicate an error.
;-
if (a gt 1 or a lt 0) then return,-1  
if a eq 0 THEN return, 1.e12
if a eq 1 THEn return,0

if DF lt 0 THEN BEGIN
  print,'chi_sqr-- degrees of freedom must be nonegative'
  return, -1
ENDIF
case 1 of
 DF EQ 1: UP=300.0 
 DF EQ 2: UP =100.0 
 DF GT 2 and  DF LE 5: UP=30.0
 DF GT 5 and DF LE 14: UP = 20.0
 ELSE: UP = 12.0
ENDCASE

Below=0

 while chi_sqr1(UP,DF) LT 1- a DO BEGIN
      Below = UP
      UP = 2*UP
 ENDWHILE

 
return, pd_bisection([1-a,DF],'chi_sqr1',Up,Below)
end

