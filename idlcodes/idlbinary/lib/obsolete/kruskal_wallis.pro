; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/kruskal_wallis.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.



         
  
pro kruskal_wallis, Data, Rank, H,Prob, df, Pop,    $
          names=names, List_Name=Ln, Missing=M , NoPrint =NP
;+ 
; NAME:
;	KRUSKAL_WALLIS
;
; PURPOSE:
;	To perform a one-way analysis of variance on k treatments to test
;	the hypothesis that all treatments have the same distribution 
;	versus the alternative that at least two treatments differ in 
;	location.  No assumptions are needed about the underlying probability
;	distributions.
;        
; CATEGORY:
;	Statistics.
;
; CALLING SEQUENCE:
;	KRUSKAL_WALLIS, Data [,Rank, H, Prob, df, Pop    $
;         names=names, List_Name=Ln, Missing=M , NoPrint =NP]
;
; INPUTS:
;	Data:	Two-dimensional array. Data(i,j) =the jth   $
;		observation from the ith treatment;
;
; KEYWORDS:  
;	NAMES:	vector of names for the treatments to be used in the output.
;
;    LIST_NAME:	Name of output file.  Default is to the screen.
;
;      MISSING:	value used as a place holder for missing data.  Pairwise
;		handling of missing data.
;
;      NOPRINT:	flag, if set, to suppress ouput to the screen or a file.
;
; OUTPUT:
;	Table written to the screen showing rank sum for each treatment.
;	Also, the kruskal_wallis test statistic and it is probability 
;	assuming a chi-square distribution are written to the screen.
;
; OPTIONAL OUTPUT PARAMETERS:
;	Rank:	1-dim array of rank sums.
;		Rank(i) = sum of ranks of treatment i
;
;	H:	kruskal_wallis test statistic.
;
;	Prob:	probability of H assuming a chi-square distribution.
;
;	DF:	degrees of freedom of chi-square distribution.
;
;	POP:	1-dim array of treatment sizes
;
; RESTRICTIONS:
;	None.
;
; COMMON BLOCKS:
;	None.
;
; PROCEDURE:   
;	The samples from the k treatments are pooled and their members are
;	ranked. Let Ri = rank sum for ith treatment and let ni = the sample
;	size. Let R = the average of all ranks =(n+1)/2 where n = sum(ni).
;	Let RRi = Ri/ni. The rank sum analogue to the standard sum of squares
;	is:
;		SS = sum(ni(RRi -R))^2.
;	The Kruskal-Wallis statistic H = 12/(n(n+1)) * V and has approximately
;	the chi-square distribution if each sample size exceeds 4.
;-




On_Error,2
SD = size(Data)

if( N_Elements( Ln) NE 0) THEN openw,unit,/get,Ln else unit=-1


if ( SD(0) NE 2) THEN BEGIN
 printf,unit, 'kruskal-wallis- Data array has wrong dimension'
   goto, DONE
ENDIF

C=SD(1)
R= SD(2)

Rank = Fltarr(C) ;
Pop  = Lonarr(C);

SortI = sort(Data)   
SortD =Data(SortI)              ; sort data
 

Miss = N_Elements (M)
if (Miss NE 0) THEN BEGIN            ; discard bad data
 notM = where( SortD NE M, count)

 if count NE 0 THEN SortD = SortD(notM) $
 else BEGIN 
     printf,unit,'kruskal_wallis- Too many missing values'
     return
 ENDELSE

 SortI = SortI(NotM) 

ENDIF

size = N_elements(SortI)-1

start = 0l
stop  = 0l

while start le size DO BEGIN    ;compute rank, average ties
       if start lt size then     $

         while (sortd(start) eq sortd(stop)) DO BEGIN
                                      ;how many of same rank
           stop =stop +1     
           if stop gt size THEN goto, fine      
        ENDWHILE $
  
       ELSE  stop = stop+1
       
       fine: 
             IND = SortI(start:stop-1) mod C
             size1 = stop - start - 1
             ranki = start + size1/2.0
             for i = 0l, size1 DO BEGIN
              Rank(IND(i)) = Rank(IND(i))+ ranki +1        
              Pop(IND(i))  = Pop(IND(i)) + 1
              ENDFOR

             start = stop
       ENDWHILE    
        


n = Total(float(Pop))
here = where(Pop ne 0, countC)

if countC ne 0 THEN $
 H =12.0/(n*(n+1.)) * Total(Rank(here)^2/Pop(here)) - 3*(n+1) $
else H = 0

If CountC ne C THEN BEGIN
     here1 = where (Pop eq 0, count)
     printf, unit, "The following rows are empty and discarded"
     printf, unit, here1
ENDIF

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


  DF = CountC-1
 Prob = 1 - chi_sqr1(H,df)

if(NOT KEYWORD_SET(NP)) THEN BEGIN  
  printf,unit, " Table of Rank Sums:"
  printf,unit, " Kruskal-Wallis H Test"
  printf,unit, " "
  printf,unit, "   Treatment        count     Rank Sum"
  for i= 0l,C-1 do                       $
     printf,unit, format ='(A13,5x,I8,5X,G15.7)',         $
                                 Names(i),Pop(i),Rank(i)
  printf,unit, " "
  printf,unit,           $
    format = '( " The Kruskal-Wallis H statistic = ",G15.7)',H

 printf, unit,format =      $
 '(" probability =", G10.4, " degrees of freedom = ",I5)',  $
            Prob,DF
ENDIF

DONE:
   if ( unit NE -1) THEN Free_Lun,unit

    RETURN
    END


















