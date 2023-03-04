; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/student_t.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.

function student_t , a1, DF
;+
; NAME:
;	STUDENT_T
;
; PURPOSE:
;	STUDENT_T returns the cutoff value v such that
;
;		Probability(X > v) = a1
;
;	where X is a random variable from the Student t's distribution with
;	DF degrees of freedom.
;
; CATEGORY:
;	Statistics.
;
; CALLING SEQUENCE:
;	Result = STUDENT_T(A, DF)
;
; INPUT:
;	A1:	The probability for which a cutoff is desired.
;	DF:	The degrees of freedom
;
; OUTPUT: 
;	The cutoff value if a is beween 0 and 1 inclusively. Otherwise, -1.
;-
a = a1 
if (a gt 1 or a lt 0) then return,-1  

if ( a gt .5) THEN adjust =1 ELSE BEGIN
   adjust = 0
   a = 1.0 -a
ENDELSE

if a1 eq 0 THEN return, 1.e12
if a1 eq 1 THEn return,-1.e12

case 1 of
 DF EQ 1: UP = 100 > (100 * .005/a1)
 DF EQ 2: UP = 10 > (10 *.005/a1)
 DF GT 2 and  DF LE 5: UP= 5 > (5*.005/a1)
 DF GT 5 and DF LE 14: UP = 4 > (4 *.005/a1)
 ELSE: UP = 3 > (3 *.005/a1)				
ENDCASE

 while student1_t(UP, DF) LT a DO BEGIN
      Below = UP
      UP = 2*UP
 ENDWHILE
x = pd_bisection([a,DF],'student1_t',Up,0)

if (adjust) THEN  return, -x   $
ELSE return,x
end
