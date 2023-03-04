; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/friedman.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.


function friedman_compute_rank, x , SortD
list = where( sortD EQ x,count)
return, list(0) + (count-1)/2.0
END
         
  
pro Friedman, Data, Rank, F, Prob, DF, Names=names, List_Name=Ln,$
              NoPrint=NP
;+ 
; NAME:
;      FRIEDMAN
;
; PURPOSE:
;	Perform a two-way analysis of variance with k treatments and b 
;	blocks to test the hypothesis that all treatments have the same
;	distribution versus the alternative that at least two treatment 
;	distributions differ in location. No assumptions are needed about 
;	the underlying probability distributions.
;        
; CATEGORY:
;	Statistics.
;
; CALLING SEQUENCE:
;	FRIEDMAN, Data [, Rank, F, Prob, Df]
;
; INPUTS:
;	Data:	two dimensional array. Data(i,j) = the observation from the
;		ith treatment and jth block.
;
; KEYWORDS:
;	NAMES:	vector of names for the populations to be used in the output.
;
;    LIST_NAME:	name of output file. Default is to the screen.
;
;      NOPRINT:	a flag, if set, to suppress output to the screen or a file.    
;
; OUTPUT:
;	Table written to the screen showing rank sum for each treatment.
;	Also, the Friedman test statistic and it is probability assuming a 
;	chi-square distribution are written to the screen.
;
; OPTIONAL OUTPUT PARAMETERS:
;	Rank:	1-dim array of rank sums.  Rank(i) = sum of ranks of 
;		population i.
;
;	F:	Friedman test statistic.
;
;	Prob:	probability of F, assuming a chi-square distribution.
;
;	DF:	degrees of freedom of chi-square distribution.
;		
; RESTRICTIONS:
;	No missing data
;
; COMMON BLOCKS:
;	None.
;
; PROCEDURE:   
;	For each block, the observations for the k treatments are ranked. 
;	Let Ri = rank sum for ith treatment, RRi = Ri/b and Let R = average 
;	of all ranks =(k+1)/2. Let RRi = Ri/ni.  The rank sum analogue to the
;	standard sum of squares is:
;		SS =b* sum((RRi -R)^2).
;	The Friedman statistic F = 12/(k(k+1)) * V and has approximately the
;	chi-square distribution if each sample size exceeds 4.
;-




On_Error,2
SD= size(Data)

if( N_Elements( Ln) NE 0) THEN openw,unit,/get,Ln else unit=-1


if ( SD(0) NE 2) THEN BEGIN
   printf,unit, 'friedman- Data array has wrong dimension'
   goto, DONE
ENDIF

C=SD(1)
R= SD(2)

Rank = Fltarr(C) ;

m = 2*max(abs(Data)) + 1
if ( m LT 1.0e30/R) THEN BEGIN         ; fast sort
  Temp = Replicate(m,C) # (findgen(R))
  SortD = Data + Temp   
  SortD = SortD(sort(sortD))              ; sort data by rows
ENDIF ELSE BEGIN
  m=0              ;we wont use m since it may cause overflow

SortD = Data
  for i = 0L,R-1 DO SortD(i*C:(i+1)*C-1)=            $
                            Data(sort(Data(*,i)),i) 
ENDELSE


for i = 0L,C-1 DO BEGIN               ; Compute rank sums

   Rank(i) = 0
   
   for j = 0L,R-1  DO BEGIN
           x = data(i,j) + j*m
           x = friedman_compute_rank(x,SortD(j*C:(j+1)*C-1))
           Rank(i) = Rank(i) + x +1
next:
        ENDFOR
ENDFOR


F =12.0/(float(R)*C*(C+1.)) * Total(Rank^2) - 3*float(R)*(C+1.)




 SN =Size(Names)
 if (SN(1) EQ 0) THEN BEGIN
     I = INDGEN(C)
     Names=['treatment'+StrTrim(I,2)]  
 ENDIF ELSE          		$
   if ( SN(1) LT C) THEN BEGIN
     I = Indgen(C)
     printf,unit,'sign_test- missing names'
     Names=[Names, 'treatment'+StrTrim(I(SN(1):C-1),2)]
  ENDIF


  DF = C-1
  Prob = 1 - chi_sqr1(F,DF)
  if(NOT KEYWORD_SET(NP)) THEN BEGIN  
  printf,unit, " Table of Rank Sums:"
  printf,unit, " Friedman Test"
  printf,unit, " "
  printf,unit, "    Treatment        count     Rank Sum"
  for i= 0L,C-1 do                       $
     printf,unit,              $
        format='(A13,5x,I8,5X,G15.7)',Names(i),R,Rank(i)
  printf,unit, " "
  printf,unit,          $
     format = '( " The Friedman F  statistic = ",G15.5)',F
  printf,unit,           $
 format='(" probability =",G15.7," degrees of freedom =",I15)',$
          Prob,DF
ENDIF

DONE:
   if ( unit NE -1) THEN Free_Lun,unit

    RETURN
    END
