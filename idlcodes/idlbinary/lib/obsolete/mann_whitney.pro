; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/mann_whitney.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.


function mann_whitney_compute_rank, x , SortD
list = where( sortD EQ x,count)
return, list(0) + (count-1)/2.0
END


pro mann_whitney, Pop, U0, U1,n1,n2,Z,Prob, Missing=M
;+ 
; NAME:
;	MANN_WHITNEY
;
; PURPOSE:
;	To test the null hypothesis that two populations have the same
;	distribution -i.e. F(x) = G(x) against the alternative that their
;	distributions differ in location, i.e F(x) = G(x+a).  MANN_WHITNEY 
;	is a rank test that does not assume equal population sizes.
;
; CATEGORY:
;	Statistics.
;
; CALLING SEQUENCE:
;	MANN_WHITNEY, Pop [, U0, U1, N1, N2, Z, Prob, MISSING = M]
;
; INPUTS:
;	Pop:	Array dimensioned (2,Maxsize).  Pop(i,j) = jth observation
;		from ith population, i = 0, 1.
;  
; KEYWORDS: 
;      MISSING:	Value used as a place holder for missing data.  Pairwise
;		handling of missing data.
;
; OPTIONAL OUTPUT PARAMETERS:
;	U0:	MANN_WHITNEY statistic for Population 0.
;	U1:	MANN_WHITNEY statistic for Population 1.     
;	N1:	Size of sample from Pop(0,*)
;	N2:	Size of sample from Pop(1,*)
;	Z:	Test statistic,almost normal, to be used
;		when sample sizes exceed 10. Otherwise, Z=0.
;	Prob:	Probablity of Z or something more extreme.
;		Undefined for small sample sizes.
;
; RESTRICTIONS: 
;	All populations have the same sample size.
;
; COMMON BLOCKS:
;	None.
;
;PROCEDURE:  
;	The Mann_Whitney statistics Ua may be computed by ordering all 
;	observations according to their magnitude and counting the number
;	of observations in the first sample that precede each observation
;	in the second. Ub may be computed likewise. Very large or very small
;	values of UA or UB indicate seperation in the data and suggest 
;	rejection of the null hypothesis. 
;-             





On_Error,2
SD= size(Pop)

unit =-1
if ( SD(0) NE 2) THEN BEGIN
   printf,unit, 'mann_whitney- Data array has wrong dimension'
   goto, DONE
ENDIF

C=SD(1)
R= SD(2)

if (C LT 2) THEN BEGIN
printf,unit,'mann_whitney- need more than 1 population'
goto,done
ENDIF

if (C GT 2) THEN print,             $
       'mann_whitney- we only compare first two populations'

Pop1 =Pop(0,*)
Pop2 = Pop(1,*)
 
if N_Elements(M) NE 0 THEN BEGIN
   here1 = where(Pop1 NE M, count)

   if count ne 0 THEN $
      Pop1 = Pop1 (here1) $
   else BEGIN
     print, " Too many missing values"
     return
   ENDELSE

   here2 = where(Pop2 NE M, count)
   if count ne 0 THEN $
    Pop2 = Pop2( where (Pop2 NE M)) $
   ELSE BEGIN
    print, "Too many missing values"
    return
   ENDELSE
ENDIF

n1 = N_Elements(Pop1)
n2 = N_Elements(Pop2)

Merge = [Pop1,Pop2]
SortT = Merge( sort(Merge))

U0 = 0
for i = 0l,n1-1 DO U0 = U0 + mann_whitney_compute_rank(Pop1(i), SortT) + 1
 
U1 = 0
for i = 0l,n2-1 DO U1 = U1 + mann_whitney_compute_rank(Pop2(i), SortT) + 1

U0 = n1 * n2 + n1 * (n1 + 1)/2. - U0
U1 = n1 * n2 + n2 * (n2 +1)/2. - U1

if (n1 LE 10 or n2 LE 10) THEN  BEGIN
 print,"mann_whitney- find probability of Z from table"
 Prob = -1 
 Z=0
ENDIF else  BEGIN
      E = n1*n2/2.
      V = n1*n2*(n1 + n2 +1)/12.
      Z = (U0-E)/sqrt(V)
      Prob = 1 - gaussint(abs(z))
ENDElSE

done:
return
end
