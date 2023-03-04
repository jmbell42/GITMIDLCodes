; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/partial2_cor.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.


function partial2_cor,X,Y,C
;+NODOCUMENT
; NAME: 
;     PARTIAL_COR2
;
; PURPOSE:
;	Compute the partial correlation coefficient between X and Y after
;	both have been adjusted for the variables in C
;
; CATEGORY:
;	Statistics.
;
; CALLING SEQUENCE: 
;	Result = PARTIAL_COR(X,Y,C)
;
; INPUTS:
;	X:	Column vector of R independent data values.
;
;	Y:	Column vector of R dependent data values.
;  
;	C:	Two-dimensional array with each column
;		containing data values corresponding to
;		an independent variable. Each column has
;		length R.
;
; OUTPUT:
;       The partial correlation coefficient.
;-
SC = size(C)
CNum = SC(1)

if CNum EQ 1 THEN BEGIN
  P1 = Correlate(X,Y)
  P2 = Correlate(X,C)
  P3 = Correlate(Y,C)

ENDIF ELSE BEGIN
  P1 = partial_cor(X,Y,C(0:CNum-2,*))
  P2 = partial_cor(X,C(CNum-1,*),C(0:CNum-2,*))
  P3 = partial_cor(Y,C(CNum-1,*),C(0:CNum-2,*))
  ENDELSE

if ( P2 NE 1 and P3 NE 1) THEN          $
return, (P1 - P2 * P3)/sqrt((1-P2^2) * (1 - P3^2)) $
else return,0
END
