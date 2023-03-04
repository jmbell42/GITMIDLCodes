; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/testcontrast.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.


function testcontrast, A, unit
;testcontrast tests that the array A consists
;of contrasts-- ie the sum of each row is zero.
;input: 
;     A = two-dimensional array
;output:
;    return 1 if A consists of contrasts and
;           0, if rows dont sum to 0
;           -1, if 0 contrast or wrong dimensions
 
 if(N_ELEMENTS(unit) eq 0) THEN unit = -1
 SC = size(A)
 if (SC(0) NE 2 and SC(0) NE 1) THEN BEGIN
  printf,unit, 'testcontrast--- contrast array must be one or two-dimensional'
  return,-1
 END

 C = SC(1)
 if( SC(0) EQ 2) THEN BEGIN
  T = Replicate(1.0,C) # A
  Here = where(T NE 0,count)
  if count NE 0 THEN $
   return,0          $
  ELSE BEGIN
   T = Replicate(1.0,C) # A^2
   Here = where(T EQ 0,count)

   if count NE 0 THEN BEGIN
    printf,unit, 'testcontrast--- invalid 0 contrast'
    return,-1
   ENDIF else return,1

  ENDELSE
 ENDIF
  
  if Total(A) NE 0 THEN return,0
  if Total(A^2) EQ 0 THEN BEGIN
    printf,unit, 'testcontrast--- invalid 0 contrast'
    return,-1
  ENDIF

 return,1

END

















