; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/spearman.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.


 pro  compute_ave, Data,SortT,R, count
 ; returns a ranking of Data with ties averaged
 ; in SorT. On input sortT = sort(data). On output,
 ; sortt(i) = the ranking of the value in data(i).

     temp = Data(SortT)
     temp1 = sortT
     for i = 0,R-1 DO temp1(sortT(i)) = i +1
     sortT = temp1


   Repeats =  where (temp EQ shift(temp,-1),count) 
                          ; look for repetitions to average
      
      if count NE 0 THEN BEGIN
        here = 0
        
        while ( here LT count) DO BEGIN

            first =temp(Repeats(here))
            set1= where( Data EQ first, count2)
            ave = repeats(here) + (count2 - 1.)/2.0
            SortT(set1) = ave 
            here = here + count2 -1
            
       ENDWHILE
      ENDIF
return
end


pro spearman, Data1, CorMatrix,Names=Names,List_Name=Ln,   $
            Missing=M ,NoPrint = NP
;+ 
; NAME:
;	SPEARMAN
;
; PURPOSE:
;	To compute the correlation matrix where Spearman's correlation 
;	coefficient is computed between pairs of ranked variables. No 
;	assumptions are made about the probabilty distribution of the 
;	variable values.
;
; CATEGORY:
;	Statistics.
;
; CALLING SEQUENCE:
;	SPEARMAN, Data, CorMatrix
;
; INPUTS:
;	Data:	Two-dimensional array. Data(i,j) = the jth value of the ith
;		variable.
;
; KEYWORDS:
;	NAMES:	Vector of user supplied names for the variables to be used in
;		the output.
;
;    LIST_NAME:	Name of output file.  Default is to the screen.
;
;      MISSING:	Value used as a place holder for missing data.  Pairwise 
;		handling of missing data.
;
;     NOPRINT:	A flag, if set, to suppress output to the screen.
;           
; OUTPUT:
;       Correlation matrix written to the screen
;
; OPTIONAL OUTPUT PARAMETERS:
;    CORMATRIX:	Two-dimensional correlation array.  CorMatrix(i,j) = spearman
;		correlation coeffiecient computed for variables i and j.
;                          
; RESTRICTIONS:
;	None.
;
; COMMON BLOCKS:
;	None.
;
; PROCEDURE:
;	Variables are pairwised ranked with ties averaged.  Correlation 
;	coefficient is computed using the rankings.
;-            




On_Error,2
Data = Data1
SD= size(Data)
MissNo = 0

if( N_Elements( Ln) NE 0) THEN openw,unit,/get,Ln else unit=-1

if ( SD(0) NE 2) THEN BEGIN
   printf,unit, 'spearman- Data array has wrong dimension'
   goto, DONE
ENDIF


C=SD(1)
R= SD(2)

CorMatrix = Fltarr(C,C) +1
SortMatrix  = Data
if C mod 2 NE 0 THEN C1 = C+1 else C1 = C 

here = where( Data GE 1.0e30 , num)
if num NE 0 THEN BEGIN
  print,unit, ' spearman - data values too large = inf'
  goto,done
ENDIF


if( N_Elements(M) NE 0) THEN BEGIN         ; put missing data 
                                           ; where it wont
                                           ; affect sort
   here = where(Data EQ M,missNo)
   if (missNo NE 0) THEN Data(here) = 1.0e30
ENDIF ELSE missNo = 0



TN = 0                              ;TN = total number of ties
for i = 0,C-1 Do BEGIN               ;Rank each population

   Sort11 =float( sort(Data(i,*)))
   compute_ave, Data(i,*), Sort11, R, TieNo      ; handle ties
   TN = Tn + TieNO
   SortMatrix(i,*) = sort11
 ENDFOR

if TieNo EQ 0 and MissNo EQ 0 THEN BEGIN    ;handle simple case
   CorMatrix = 1 - (4*R +2.)/(R - 1.)   $
              + (12.0/(R * (R^2 - 1.)))    $
                         * (SortMatrix # transpose(SortMatrix))

ENDIF ELSE   $
  
  for i = 1,C1/2 DO BEGIN           ;cycle through populations
      for j = 0,C-1 DO BEGIN
       Pop = R
       k = (j + (C-i)) mod C
 
       Sort11 = SortMatrix(j,*)
       Sort22 = SortMatrix(k,*)    

       if missNo NE 0 THEN  BEGIN    
          here = where ( Data(j,*) EQ 1.0e30,count1)
          if count1 NE 0 THEN BEGIN
             Pop = Pop - count1
             tot_miss = here
             Sort2 = Data(k,*)
             Sort2(here) = 1.0e30
             Sort22 = sort(Sort2)
             compute_ave,Sort2 ,Sort22,R
           ENDIF

          here = where ( Data(k,*) EQ 1.0e30 and Data(j,*) NE $
                 1.e30, count)
          if count NE 0 THEN BEGIN
             Pop = Pop - count
             if count1  EQ 0 then   $
               tot_miss = here else  $
                tot_miss = [tot_miss,here]
             Sort1 = Data(j,*)
             Sort1(here) = 1.0e30
             Sort11 = sort(Sort1)
             compute_ave, Sort1, Sort11, R
           END
        if (Pop NE R) THEN BEGIN
           Sort11(tot_miss) = 0
           Sort22 (tot_miss) = 0
        ENDIF
     ENDIF      
       temp = Pop * Total(Sort11 ^2) - (Total(Sort11))^2 
       temp1 =Pop * Total(Sort22 ^2) - (Total(Sort22))^2
       temp = sqrt(temp * temp1)
       CorMatrix(j,k) = (Pop*Total(Sort11*Sort22) -     $
                        Total(Sort11) *Total(Sort22)) /temp
       CorMatrix(k,j) = CorMatrix(j,k)
    ENDFOR
  ENDFOR
 



  


   

 SN =Size(Names)
 if (SN(1) EQ 0) THEN BEGIN
     I = INDGEN(C)
     Names=['Var'+StrTrim(I,2)]  
 ENDIF ELSE          		$
   if ( SN(1) LT C) THEN BEGIN
     I = Indgen(C)
     printf,unit,'spearman- missing names'
     Names=[Names, 'var'+StrTrim(I(SN(1):C-1),2)]
  ENDIF



  if(N_Elements(NP) EQ 0) THEN BEGIN
    printf,unit, " Correlation Matrix"
    printf,unit, " "
    printf,unit, format ='(10X,16(A8,2x))', Names
   for i= 0,C-1 do                       $
     printf,unit, format='(A8,2X,16(f8.5,2X))',Names(i), CorMatrix(*,i)
  ENDIF

DONE:
   if ( unit NE -1) THEN Free_Lun,unit
    RETURN
    END
