; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/wilcoxon.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.


pro Wilcoxon,Data, Rank,Prob,Names=Names,List_Name=Ln,    $
                  Missing=M,Tail =T,NoPrint=NP 
;+ 
; NAME:
;	WILCOXON
;
; PURPOSE:
;	Test the null hypothesis that two populations have the same 
;	distribution -i.e. F(x) = G(x) against the alternative that their 
;	distributions differ in location- i.e F(x) = G(x+a).
;	Wilcox pairwise tests the populations in Data.  It is preferable 
;	to the sign_test for non-binary data, since it uses the ranking of
;	data differences and not just the sign.
;
; CATEGORY:
;	Statistics.
;
; CALLING SEQUENCE:
;	WILCOXON, Data
;
; INPUTS:
;	Data:	Two-dimensional array. Data(i,j) = the jth observation from 
;		the ith population.
;
; KEYWORDS:  
;	NAMES:	Vector of user supplied names for the populations to be 
;		used in the output.
;
;    LIST_NAME:	Name of output file.  The default is to the screen.
;
;      MISSING:	Value used as a place holder for missing data.
;		Pairwise handling of missing data.
;
;	TAIL:	If set, tail specifies the type of test.  If Tail = 1 then a 
;		one-tailed test is performed.  Likewise, Tail = 2 specifies 
;		a two-tailed test.  The default is the two-tailed test.
;
;      NOPRINT:	A flag, if set, to suppress output to the screen or a file.
;           
; OUTPUT:
;	Table written to the screen showing for each pair of populations the
;	total of the rankings.  Also, table of probabilities for each 
;	population pair giving the significance of the results in the first
;	table. These probabilities are based on normal approximations.  For
;	small sample sizes (less than 26), consult a table for the Wilcox 
;	Test in any general text on statistics.
;
; OPTIONAL OUTPUT PARAMETERS:
;	Rank:	Two-dimensional array of ranking sums.
;		Rank(i,j) = sum of ranks of population i where observations
;		in i are ranked with those in population j.
;
;	Prob:	Two-dimensional array. Prob(i,j) = probability of Rank(i,j) 
;		or something more extreme. -1 is returned for small 
;		(less than 26) populations.
;                          
; RESTRICTIONS: 
;	All populations have the same sample size.
;
; COMMON BLOCKS:
;	None.
;
; PROCEDURE:
;	For each pair of populations,  differences between corresponding
;	observations are computed and the absolute values of the differences
;	are ranked.  Ranks of positive differences are summed and likewise,
;	those of the negative ones.  The probability of the sums is computed
;	under the assumption that the distributions are the same.  These 
;	probabilities are approximated with an approximately normal test
;	statistic for populations greater than 25.
;-




On_Error,2
SD= size(Data)

if( N_Elements( Ln) NE 0) THEN openw,unit,/get,Ln else unit=-1

if ( SD(0) NE 2) THEN BEGIN
   printf,unit, 'wilcoxon- Data array has wrong dimension'
   goto, DONE
ENDIF

 if(N_Elements(T) EQ 0) THEN T=2   $
 else if (T GT 2) OR  (T LT 1) $
      THEN T =2

C=SD(1)
R= SD(2)

Rank = Fltarr(C,C) 
Prob =  Rank +1.0
for  i =1l,C/2 DO  BEGIN             ;cycle through populations

   D1 = Shift(Data,i,0)
   Temp = Data - D1                  ; compute differences

   if (N_Elements(M) NE 0) THEN BEGIN  ; Handle missing data
     here = where(Data EQ M,count)
    if count  NE 0 THEN    BEGIN
      Temp( here) = 0
      Temp( where(D1 EQ M)) = 0
    ENDIF
   ENDIF
   

   for j = 0l, C-1 DO BEGIN             ;compute rankings
     k = (j + (C-i)) mod C
     accept =0
     SortT =Temp(j, sort(abs(Temp(j,*))))
                                    ;sort absolute values
                                         ; of differences
     pos = where(SortT NE 0,countp)    ; discard equal
                                       ; observation

    if countp eq 0 THEN BEGIN
         Rank(k,j) = 0 & Rank(j,k) = 0
         prob(k,j)=  1 & prob(j,k) =1
    ENDIF else BEGIN
        SortT = SortT(pos)
                                ; if all equal, accept NUll 
        			; hypotheses
        PopSize = N_Elements(SortT)	
        Pos =float( where(sortT GT 0,countp))
                                   ; get rankings of positive
        Neg =float( where (sortT LT 0,countn))
                                   ; of negative
        Repeats =where ( abs(sortT) EQ abs(shift(sortT,-1)),count)
                                   ;look for repetitions to average

        if count NE 0 THEN BEGIN
          here = 0

          while ( here LT count-1) DO BEGIN
            diff = abs(SortT(Repeats(here)))
            set1= where( abs(SortT) EQ diff,count2)
            if countp NE 0 THEN    $
              posr = where(SortT(pos) EQ diff,count3)  $
                         ELSE count3 = 0
            ave = repeats(here) + (count2-1.0)/2.0
            if count3 NE 0 THEN Pos(posr) = ave

            if countn NE 0 THEN posr =            $
                    where (SortT(neg) EQ -diff,count3) $
              ELSE count3 = 0

            if count3 NE 0 THEN Neg(posr) = ave
            here = here + count2 -1

       ENDWHILE
      ENDIF

      if countp NE 0 THEN  Rank(j,k) =      $
             Total(Pos+1) ELSE RANK(j,k) = 0
      if countn NE 0 THEN  Rank(k,j) =      $
                      Total(Neg+1) ELSE RANK(k,j) = 0
       Z = (Rank(k,j) - (PopSize * (PopSize+1)/4.))/       $
           sqrt(popsize*(popsize+1.)*(2*popsize+1.)/24.)
      if popsize gt 25 THEN  Prob(j,k) =( 1 - Gaussint(abs(Z))) $
         else Prob(j,k) = -1
       if T EQ 2 and popsize gt 25 THEN $
               Prob(j,k) = 2*Prob(j,k)
       Prob(k,j) = Prob(j,k) 
    ENDELSE
   ENDFOR
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

 If NOT KEYWORD_SET(NP) THEN    BEGIN
  printf,unit, "Wilcoxon"  
  printf,unit, " Table of Rank Sums"
  printf,unit, " "
  printf,unit, format ='(8X,16(A15,2x))', Names
 
  for i= 0l,C-1 do                       $
     printf,unit, format='(A8,16(G15.5,2X))',   $
                          Names(i),Rank(*,i)
 printf,unit, " "
 printf,unit, "Table of Probabilities:"
 if (T EQ 2) THEN       $
   printf,unit, "Two- Tailed" $
 else printf,unit, "One-Tailed"

 printf,unit," "
 printf,unit, format ='(8X,16(A15,2x))', Names
 for i= 0,C-1 do                      $
     printf,unit, format='(A8,16(G15.5,2X))',     $
            Names(i),Prob(*,i)
 ENDIF


DONE:
   if ( unit NE -1) THEN Free_Lun,unit
    RETURN
    END
