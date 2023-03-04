; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/runs_test.pro#1 $
;
;  Copyright (c) 1993-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.

pro runs_test, Sequence1, RunNo, Prob,BinNo,Z,  $
     List_Name = Ln
;+ 
; NAME:
;	RUNS_TEST
;
; PURPOSE:
;	To test for nonrandomness in a sequence of 0 and 1's by
;	counting the number of runs and computing its probabilty.
;
; CATEGORY:
;	Statistics.
;
; CALLING SEQUENCE:
;	RUNS_TEST, Sequence1, RunNo, Prob, BinNo, Z, LIST_NAME = Ln
;
; INPUTS:
;    Sequence1:	The vector of 0's and 1's.
;           
; OPTIONAL OUTPUT PARAMETERS:
;	RunNo:	Total number of rums.
;                            
;	Prob:	probabilty of total number of runs, if number of 0's and 
;		number of 1's both exceeds 10.Otherwise, undefined and -1 is
;		returned in Prob.
;
;	BinNo:	[ number of 0's, number of 1's]
;
;	Z:	Approximately normal test statistic computed when number \
;		of 0' and number of 1's both exceed 10.
;                                                           
; RESTRICTIONS:
;	None.
;
; COMMON BLOCKS:
;	None.
;
; PROCEDURE:
;	If either the number of 0's or the number of 1's does not exceed 10,
;	then the probability must be looked up in a table. Otherwise, it is
;	estimated with the normal distribution. Any nonbinary values are 
;	removed from the sequence.
;-



On_Error,2

if N_ELEMENTS(sequence1) eq 0 THEN BEGIN
   print, "runs_test- Sequence is undefined."
   goto,done
ENDIF

sequence = sequence1
temp = where( Sequence EQ  0 OR Sequence EQ 1,countNB)


if (countNB NE 0) THEN BEGIN
     Seq = Sequence
     Sequence = Sequence(temp)             ;remove nonbinaries
ENDIF ELSE BEGIN
      print, " runs_test-Too many missing data values."
      goto,done
ENDELSE

SD= size(Sequence)



C=SD(1)

h0 = where( Sequence EQ 0,y0)         ;count 0's and runs of 0

if y0 ne 0 then $
 temp = where(H0 + 1 NE Shift(h0,-1),n0) $
else n0 = 0

y1 = SD(1) - y0                       ;count 1's and runs of 1

if(Sequence(SD(1)-1) NE Sequence(0)) THEN $
   n1 = n0      $
ELSE if Sequence(0) EQ 1 then n1 = n0 + 1 $
ELSE n1 = n0-1

R = n0 + n1
RunNo=R
BinNo = [y0,y1]

if y0 eq 0 or y1 eq 0 THEN BEGIN
   Prob = 0
   Z    = 1.e12
   print, 'runs_test- all sequence values are the same'
   goto, DONE
ENDIF


E = 2.0*y0*y1/(y0 + y1) + 1.0
V = 2.0*y0*y1*(2.0*y1*y0 - y0 -y1)/        $
              ((y0 + y1 -1.0)*(y1+y0)^2)
Z = (R-E)/sqrt(V)
if (y0 LE 10 or y1 LE 10) THEN $
   Prob = -1 $
else Prob =1- gaussint(abs(Z))                   

DONE:
RETURN
END
