; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/contingent.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.


Pro   MakeTable, A,Table,ColNames,RowNames,R,C,RT,CT,unit

  printf,unit,Format='(A15,$)',"               "     

  for i=0L,C-1 DO                 $
   printf,unit,Format='(A11,$)',ColNames(i) 

   printf,unit,"    Total"
  

   printf,unit,Format='(A15,$)',"               "     
  for j=1L,C*11+1 do printf,unit,Format='(A1,$)',"_"
  printf,unit," "

  for i=0L,R-1 do Begin
    printf,unit,Format ='(A5,$)',"     "
    for j=0L,C DO  printf,unit,Format='(A11,$)',"          |"
    printf,unit," "
    printf,unit,Format ='(A2,$)',"  "
    printf,unit,Format='(A10,A3,A1,$)',RowNames(i),"   ","|"
    for j= 0L,C-1 DO printf,unit,Format='(F10.2,A1,$)',    $
                                        A(j,i),"|"
    printf,unit,Format='(F8.2)',RT(i)
    printf,unit,Format ='(A16,$)',"               |"
    for j= 0L,C-1 DO printf,unit,Format='(A1,F8.3,A1,A1,$)',$
                                       "(",Table(j,i),")","|"
    printf,unit," "
    printf,unit,Format='(A15,$)',"               "     
    for j=1L,C*11+1 do printf,unit,Format='(A1,$)', "_"
    printf,unit," "
  ENDFOR
  
  printf,unit,Format='(A3,A10,A2,$)',"  ","Total","  "
  for i = 0L,C-1 Do  printf,unit,Format='(F10.2,A1,$)',    $
                          CT(i)," "
  printf,unit,Format='(F10.2)',Total(CT)
 
  printf,unit,"  "
  

  RETURN
  END
      

 


 PRO Contingent, X, ChiSqr, Prob, DF, ColNames= ColNames, RowNames=RowNames,$
         List_Name= LN
;+
;
; NAME:
;	CONTINGENT
;
; PURPOSE:
;	Construct a two-way contingency table from the count data in X and 
;	test for independence between two factors represented by the rows 
;	and columns of X.
;
; CATEGORY:
;	Statistics.
;
; CALLING SEQUENCE:
;	Contingent, X, ChiSqr, Prob, DF
; 
; INPUTS: 
;	X:	input array of count data. X(i,j) is the number
;		of observations at level i and j of the column
;		and row factors respectively.
;
; OUTPUT:
;	Contingency table writtem to the screen.
;
; OPTIONAL OUTPUT PARAMETERS:      
;	ChiSqr:	the statistic to test for factor independence.
;
;	Prob:	the probability of ChiSqr or something larger from a chi 
;		square distribution.
;
;	DF:	degrees of freedom
;
; KEYWORDS:
;     COLNAMES:	vector of names to label table columns.
;
;     ROWNAMES:	vector of names to label table rows.
;
;    LIST_NAME:	name of output file. default is to the screen.
;                          
; RESTRICTIONS:
;	None.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	None.
;
; PROCEDURE:
;	Calculation of standard formulas to compute ChiSqr.
;-

On_Error,2
SX=Size(X)             ; Get Dimensions

if ( N_Elements(LN) NE 0) THEN openw,unit,/Get,LN    $
ELSE unit = -1


if(SX(0) NE 2) THEN BEGIN
 printf,unit,            $
          'Contingent- Need 2- dimensional array for Table'
 goto, DONE
ENDIF

 sn = where(X LT 0,count)

if count gt 0 THEN BEGIN
  printf,unit,'Contingent- Data should be positive.'
  goto,DONE
ENDIF
 
 C=SX(1)                ; # of Columns
 R=SX(2)                ; # of Rows

 SC= N_Elements(ColNames)
 SR= N_Elements(RowNames)

 if ( SC EQ 0) THEN BEGIN
   ColNames = ['Col1']
   SC = SC + 1
 ENDIF

 if ( SC LT C) THEN  $
   for i = SC,C-1 DO                    $
 ColNames = [ColNames,'Col' + StrTrim( i+1,2)]

 if ( SR EQ 0) THEN BEGIN
   RowNames = ['Row1']
   SR = SR + 1
 ENDIF

 if ( SR LT R) THEN  $
   for i = SR,R-1 DO           $
     RowNames = [RowNames,'Row' + StrTrim( i+1,2)]

 GrandTotal=Total(X)
 ColTotal = X#(FltArr(R)+1)
 RowTotal =  (FltArr(C)+1)#X
 if GrandTotal ne 0 then $
   Table=ColTotal#RowTotal/GrandTotal $
 else  $
   message,' Must Halt since counts are all 0'

 DF=(r-1)*(c-1)
 X2=X-Table

 ChiSqr= Total((X2*X2)/Table)
 Prob = 1 -chi_sqr1(ChiSqr,DF)

 MakeTable,X,Table,ColNames,RowNames,R,C,RowTotal,ColTotal,$
unit

 printf,unit," "
 printf, unit,format =     $
       '("ChiSqr=",G15.8, "   Probability =",G15.8)',  $
 ChiSqr, Prob

 DONE:
 if (unit NE -1) THEN Free_Lun,unit

 RETURN
 END

 


 


