; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/sign_test.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.


function gaussint1,x
; gaussinit1 returns the probabilty of obtaining x or something
; more extreme.

  if x le 0 then return,gaussint(x)          $
 else return,1 - gaussint(X)

end 


pro sign_test,Data, Diff,Prob,Names=Names,List_Name=Ln,   $
              Missing=M,NoPrint=NP
;+ 
; NAME:
;	SIGN_TEST
;
; PURPOSE:
;	To test the null hypothesis that two populations have the same 
;	distribution -i.e. F(x) = G(x) against the alternative that their 
;	distributions differ in location- i.e F(x) = G(x+a).Sign_test 
;	pairwise tests the populations in Data.
;  
; CATEGORY:
;	Statistics.
;
; CALLING SEQUENCE:
;	SIGN_TEST, Data, [Diff,Prob,Names=Names]
;
; INPUTS:
;	Data:	Two-dimensional array. Data(i,j) = the jth observation from
;		the ith population.
;
; KEYWORDS:  
;	NAMES:	Vector of user supplied names for the populations to be 
;		used in the output.
;
;    LIST_NAME:	Name of output file. Default is to the screen.
;
;      MISSING:	Value used as a place holder for missing data.  Pairwise 
;		handling of missing data.
;           
;      NOPRINT:	Flag, if set, to suppress output to the screen.
;
; OUTPUT:
;	Table written to the screen showing for each pair of populations 
;	the number of positive differences in observations.  Also, table of 
; 	probabilties for each population pair giving the two-tailed 
;	significance of the results in the first table.
;
;OPTIONAL OUTPUT PARAMETERS: 
;	Diff:	Two-dimensional array of positive differences.
;		Diff(i,j) = number of observations in population
;		i greater than the corresponding observation in population j.
;
;	Prob:	Two-dimensional array. Prob(i,j) = probability of 
;		Diff(i,j) or something more extreme.
;                          
;RESTRICTIONS:
;      All populations have the same sample size.
;
;COMMON BLOCKS: 
;     None.
;
;PROCEDURE:
;	For each pair of populations, the diffence between corresponding
;	observations is computed and a count is made of the positive and
;	negative differences.  The probability of the count is computed
;	under the assumption that the distributions are the same - i.e.
;	the probability of a negative difference = the probability of a 
;	positive difference = .5.  For sample size > 25, the binomial 
;	distribution is approximated with a normal distribution for computing
;	Prob.
;-


On_Error,2
SD= size(Data)

if( N_Elements( Ln) NE 0) THEN openw,unit,/get,Ln else unit=-1

if ( SD(0) NE 2) THEN BEGIN
   printf,unit, 'sign_test- Data array has wrong dimension'
   goto, DONE
ENDIF


C=SD(1)
R= SD(2)



Diff = Fltarr(C,C) 
Prob = Diff +1.0

 for i = 0l,C-2 DO  BEGIN

   D1 = Replicate(1.0,C-i-1) # Data(i,*)  ;compute differences
   Temp = Data(i+1:*,*) - D1

   if (N_Elements(M) NE 0) THEN BEGIN   ; Handle missing data
     here = where( Data(i+1:*,*) EQ M, count) 
   if count  NE 0 THEN Temp(here)=0
   here = where(D1 EQ M,count)
   if count NE 0 THEN  Temp( here) = 0
   ENDIF

   here = where (Temp NE 0,count)
   if ( count NE 0) THEN BEGIN    
     Temp1 = Temp
     Temp1 ( here) = 1   ; If diff =0 then discard observation
     PopSize = Temp1 # Replicate(1,R)   
                  ; compute number of observation per column



     here = where(Temp LE 0, count)     ;count positives
     if (count ne 0) THEN  $
        Temp(here) = 0                 
     here = where(Temp NE 0,count)
     if ( count NE 0) THEN $
     Temp(here) = 1
     PosNo = Temp # Replicate(1,R)     



     Diff(i+1:*,i) = PosNo


     for j =long(i+1),C-1 DO BEGIN
         k=j-i-1
        if Popsize(k) eq 0 THEN BEGIN
           printf,unit,"sign_test- Data are all the same or missing"
           printf,unit,"           for columns ",i, " and ",j
           Diff(i,j) = -1 & Diff(j,i) = -1
           Prob(i,j) = -1 & Prob(j,i) =-1
        ENDIF ELSE $
        if PopSize(k) GT 25 THEN      $       
                          ;approximate binomial with normal
           Prob(j,i) =2*      $
                 Gaussint1((2*Diff(j,i)-       $
                    PopSize(k))/sqrt(PopSize(k)))  $

         else if Diff(j,i) GT PopSize(k)/2 THEN   $          
                 prob(j,i) =      $
                    2*binomial(Diff(j,i),PopSize(k) ,.5)     $
         else if Diff(j,i) eq PopSize(k)/2 THEN       $ 
             prob(j,i) = 1           $
             else  prob(j,i) =        $
                   2*(1- binomial(Diff(j,i)+1,PopSize(k),.5))
   
      ENDFOR


     Diff(i,i+1:*) = PopSize - Diff(i+1:*,i)
     Prob(i,i+1:*) = Prob(i+1:*,i)


 ENDIF ELSE BEGIN
        printf,unit,'sign_test- all data are missing for column ',i
        printf,unit,'           or data the same in all columns after column',i
        printf,unit," "
        Diff(i+1:*,i) = -1 & Diff(i,i+1:*) = -1
        Prob(i,i+1:*) = -1 & Prob(i+1:*,i) = -1
        ENDELSE
ENDFOR

 SN =Size(Names)
 if (SN(1) EQ 0) THEN BEGIN
     I = INDGEN(C)
     Names=['pop'+StrTrim(I,2)]  
 ENDIF ELSE          		$
   if ( SN(1) LT C) THEN BEGIN
     I = Indgen(C)
     printf,unit,'sign_test- missing names'
     Names=[Names, 'pop'+StrTrim(I(SN(1):C-1),2)]
  ENDIF



if( Not keyword_set(NP)) THEN BEGIN

  printf,unit, " Table of Count Differences"
  printf,unit, " "
  printf,unit, format ='(8X,16(A8,2x))', Names

  for i= 0,C-1 do                       $
     printf,unit, format='(A8,16(I8,2X))',Names(i),Diff(*,i)
 printf,unit, " "
 printf,unit, "Table of Probabilities:"
 printf,unit," "
 printf,unit, format ='(8X,16(A10,2x))', Names

 for i= 0,C-1 do                      $
     printf,unit, format='(A8,16(G10.5,2X))',Names(i),  $
                Prob(*,i)
 ENDIF


DONE:
   if ( unit NE -1) THEN Free_Lun,unit
   RETURN
   END
