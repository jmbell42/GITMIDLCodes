; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/partial_cor.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.


 function  partial_cor,X,Y,C
;+
; NAME: 
;     PARTIAL_COR
;
; PURPOSE:
;	Compute the partial correlation coefficient between
;	X and Y after both have been adjusted for the variables in C.
;
; CATEGORY:
;	Statistics.
;
; CALLING SEQUENCE: 
;	Result = PARTIAL_COR(X,Y,C)
;
; INPUTS:
;	X:	column vector of R independent data values.
;	Y:	column vector of R dependent data values.
;
;	C:	two dimensional array with each column containing data
;		values corresponding to an independent variable.  Each column
;		has length R.
;
; OUTPUT:
;	The partial correlation coefficient.
;-
 
SC = size(C)
CNum = SC(1)
W = Replicate(1.0,SC(2))

if CNum EQ 1 THEN BEGIN
  P1 = Correlate(X,Y)
  P2 = Correlate(X,C)
  P3 = Correlate(Y,C)
 if ( P2 NE 1 and P3 NE 1) THEN          $
    return, (P1 - P2 * P3)/sqrt((1-P2^2) * (1 - P3^2)) $
  else return,0
ENDIF ELSE BEGIN
  Y1 = transpose(Y)
  Coef = Regress(C,Y1,W,YFit,A0,s,f,r,P1)
   D = [C,X]
  Coef = Regress(D,Y1,W,YFit,A0,s,f,r,P2)
  P1 = 1 - P1^2
  P2 = 1 - P2^2 
  if P1 EQ 0 THEN return,0
 return,sqrt((P1-P2)/P1)
 
ENDELSE

end
