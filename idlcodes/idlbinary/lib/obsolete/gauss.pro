; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/gauss.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.


function gauss, a ;
;+
; NAME: 
;	GAUSS 
;
; PURPOSE: 
;	Gauss returns the cutoff value v such that
;
;		Probability(X > v) = a,
;
;	where X is a standard gaussian random variable.
; 
; CATEGORY:
;	Statistics.
;
; CALLING SEQUENCE: 
;	Result = GAUSS(A)
;
; INPUT:
;	A:	The probability for which a cutoff is desired.
;
; OUTPUT: 
;	The cutoff value if a is beween 0 and 1 inclusively. Otherwise, -1.
;-

if (a gt 1 or a lt 0) then return,-1  
if a eq 0 THEN return, 1.e12
if a eq 1 THEN return,-1.e12

if (a gt .5) THEN BEGIN
  a = 1-a
  adjust = 1
ENDIF ELSE adjust = 0 

BELOW = 0
UP    = 1.0

while gaussint(UP) LT 1.0 - a DO BEGIN
 Below = UP
 UP = 2*UP
ENDWHILE

x = pd_bisection([1.0-a],'gaussint',Up,Below)
if adjust THEN BEGIN
  a = 1 - a
  return, -x
ENDIF ELSE return,x
end

