; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/equal_variance.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.


 pro equal_variance, X1, FC, DF, P, One_Way = One,  $
                     Unequal_One_Way = Unequal,$
                     Two_Way = Two, Interactions_Two_Way  = $
                     Interactions, Hartley = Hart, Bartlett = Bart, $
                     Box = Bx, Levene = Lev, Missing =M,      $
                     Group_No = gn, Block = B,  TInteraction=IN
;+
; NAME:
;	EQUAL_VARIANCE
;
; PURPOSE: 
;	To test treatments, blocks and interactions, as applicable, for 
;	variance equality before performing an anova test.
; 
; CATEGORY:
;	Statisitics.
;
; CALLING SEQUENCE:
;	EQUAL_VARIANCE, X [, FC, DF, P]
;
; INPUTS:  
;	X:	two or three dimensional array of experimental data.
;
; KEYWORDS: 
;	BLOCK:	a flag, if set by user, to test homogeneity of block 
;		variances. Default is treatment variances.  Block should 
;		only be set when either the keyword TWO_WAY or 
;		INTERACTIONS_TWO_WAY is set.
;
; TINTERACTION:	a flag, if set by the user, to test homogeneity of variance
;		for all treatment/block combinations.
;
; Type of design structure. Options are
;      ONE_WAY:	if set,  1-way anova.
;
; UNEQUAL_ONE_WAY:  if set,  1-way ANOVA with unequal sample sizes.
;
; TWO_WAY:	if set,  2-way ANOVA.
;
; INTERACTIONS_TWO_WAY:  if set,  2-way ANOVA with interactions.
;
; One and only one of the above options may be set.
; Type of test to be used to test variance equality.
; Options are:
;              
;      HARTLEY:	Hartley's F-Max test. Sample sizes should be equal and data
;		nearly normally distributed.
;
;     BARTLETT:	Bartlett's test for nearly normally distributed data and not
;		necessarily equal sample sizes.
;
;	BOX:	Box's test. Robust for large data sets, data not necessarily
;		normally distributed.
;    
;	LEVENE:	Levene's test.              
;
; One and only one test may be selected.
;
;      MISSING:	place holder for missing data or undefined if no data is 
;		missing.
;
;     GROUP_NO:	number of groups to use in Box test.
;
; OUTPUT:     
;	FC:	value of statistic computed by each test.  If Bartlett's is 
;		selected, FC has chi square distribution.  Otherwise, FC has 
;		F distribution.
;
;	DF:	degrees of freedom. 
;		Hartley: DF = [max sample size -1, number of treatments],
;		Bartlett: DF = number of treatments,
;		Box,Levene: DF =[numertor DF,denominator DF]
;
;	P:	probability of FC or something greater for Barlett's, Box's 
;		and Levene's Test.  P = -1 for Hartley's.
;
; PROCEDURE:
;	Milliken and Johnson, "Analysis of Messy Data", Van Nostrand, 
;	Reinhold, 1984, pp. 18-22.
;-
 On_Error,2
 
 SX = size(X1)

          ;Ascertain design structure.
 ONE_WAY = 0 & ONE_WAY_UNEQUAL=1 & TWO_WAY = 2 & TWO_WAY_INTERACTIONS =3
 keyset = [keyword_set(One), keyword_set(Unequal), $
           keyword_set(Two),keyword_set(Interactions)]
 T  = where(keyset,nkey)     

 if nkey NE 1 THEN BEGIN
   print,'equal_variance - must specify one and only one type'
   print, '                of design structure'
  return
 ENDIF

 T = T(0)               ;T = selected design structure

 if((T EQ TWO_WAY_INTERACTIONS) AND  (SX(0) NE 3) OR $
     ( T NE TWO_WAY_INTERACTIONS AND (SX(0) NE 2))) THEN BEGIN
      print, 'Anova- wrong number of dimensions' 
      return
 ENDIF


         ; Ascertain test type
 Hartley = 0 & Bartlett = 1 & Box = 2 & Levene = 3
 keyset = [keyword_set(Hart), keyword_set(Bart), $
           keyword_set(Bx),keyword_set(Lev)]
 VT  = where(keyset,nkey)

 if nkey NE 1 THEN $
    print, $
      'equal_variance - must specify one and only test type'

 VT = VT(0)             ; VT = selected test type

 X = float(X1)
 
 SX=Size(X)        
 C=SX(1)      ; Compute number of columns       
 D= 1         ; Default # of replications
 



 if( T EQ TWO_WAY_INTERACTIONS) THEN R = SX(3) else R = SX(2)

                                 ;Compute number of rows


 if R LT 2 OR C LT 2 THEN BEGIN
   print,'equal_variance- data array needs more rows or columns'
   return
 ENDIF

 if KEYWORD_SET(B) THEN $
  if T EQ TWO_WAY THEN BEGIN
    X = transpose(X)
    C = R
    R = SX(1)
 ENDIF ELSE if T EQ ONE_WAY or T EQ ONE_WAY_UNEQUAL THEN BEGIN
    print, 'equal_variance- Block test only done with'
    print, '                two_way design structures'
    return
 ENDIF

; Pre-process three dimensional array by converting to a
; two dimensional array with R*C columns and D rows.


 if(T EQ TWO_WAY_INTERACTIONS) THEN BEGIN    

     D = SX(2)
     if KEYWORD_SET(IN) THEN BEGIN
      X = Fltarr(R*C,D)
      for i = 0L,R*C-1  DO X( i,*) = X1(i mod C,*,i / C) 
      X = float(x)
      C=R*C

      R=D
    ENDIF ELSE BEGIN 
        T = ONE_WAY
        if KEYWORD_SET(B) THEN BEGIN
          X = reform(X,C*D,R)
          X = transpose(X)
          temp = C*D
          C = R
          R = temp
        ENDIF ELSE BEGIN
          X = reform(X,C,R*D)
          R = R*D
          D = 1
        ENDELSE
   ENDELSE
 ENDIF


if (N_Elements(M) NE 0) THEN BEGIN
   if (T EQ TWO_WAY) THEN BEGIN
       print,            $
        "equal_variance- two_way anova without interactions"
       print,"                can't have missing data."
       return
    ENDIF

    Pairwise,X,M,YR,YC,NotGood, good               
                                 ; replace missing data by 0,return
                                 ;vectors YR,YC of row,column sizes
     if(N_Elements(NotGood) EQ 0) THEN M=0
       CN = where(YC NE 0,NYC)
       RN = where(YR NE 0,NYR)
       CN1 = where(YC lt 2, NYC1)
       RN1 = where(YR lt 2,NYR1)

     if NYC LT 2  OR $
        NYC1  NE 0 THEN BEGIN
       print,"equal_variances, too many missing entries"
      return 
    ENDIF
  ENDIF ELSE M=0
   
 if (VT EQ BARTLETT OR VT EQ HARTLEY ) THEN BEGIN    
                      
    ;compute column variances
 if (M EQ 0) THEN BEGIN
    Mean = (X # replicate(1.0, R))/R
    Var = (X -  MEAN # replicate(1.0, R))^2 
    Var =  Var # replicate(1.0,R)
    Var = Var / (R-1)

;    if (T EQ TWO_WAY) THEN BEGIN       ;add on row variances 
;       Mean = (replicate(1.0, C) # X)/C
;       RVAR = (X -  replicate(1.0, C) # MEAN)^2 
;       RVAR = Replicate(1.0,C) # RVAR
;      RVar = RVar /(C-1)
;       Var = [Var, transpose(RVar)]
;      ENDIF
 
 ENDIF ELSE BEGIN

        Mean =  (X # Replicate(1.,R)) /YC  
        Mean = MEAN # replicate(1.0, R)
        VAR = fltarr(C,R)
        VAR(good) = (X(good) - Mean(good))^2
        VAR = VAR # Replicate(1.0,R)
        YC  = YC - 1
        Var = Var/YC

     ENDELSE

  here = where(VAR eq 0, count)
  if count ne 0 THEN BEGIN
     print, 'equal_variance- cannot handle populations with '
     print, '                0 variance'
     return
  ENDIF

 ENDIF



 case VT of
 
 HARTLEY : BEGIN
              FC = max(Var)/min(Var) 
              if (M EQ 0) THEN DF = [R-1,C] else DF = [max(YC),C] 
              P = -1
             END
 BARTLETT: BEGIN
             if M NE 0   THEN v = Total(YC) ELSE BEGIN
               v = R*C-C
               YC = replicate (R-1,C)
               CN  = replicate(1.0,C)
             ENDELSE
             t1 = N_Elements(Var) -1.0
             CC = 1. + 1.0/(3*t1) *  $
                                       (Total(1./YC(CN)) - 1./v)
             s2 = Total(YC*Var)/v
             FC = 1/CC * (v * Alog(s2) - Total(YC* Alog(Var)))
             DF = t1
             P  = 1. - chi_sqr1(FC,DF)

             END

 BOX:     BEGIN
            if n_elements(gn) EQ 0 THEN gn = 2

            if gn gt R then BEGIN
               print, "equal_variance- group size is too large"
               return
            ENDIF

            group = fix(gn * randomu(seed,C,R))    
                                        ; break columns into groups
            if (M NE 0) THEN group(NotGood) = -1     
            Var =  Fltarr (C,gn)
            for i = 0L,gn-1 DO BEGIN    
                               ;compute group variances for columns
              tempgroup = X
              ngri = where ( group ne i)
              tempgroup(ngri) = 0
              gri = where(group eq i)
              tempgroup (gri) =1
              ysize = tempgroup # Replicate(1,R)
              ysize1 = ysize
              y = where(ysize ne 0,count)
              if count GT 0 then BEGIN
                ysize(y) = 1./ysize(y) 
                ysize1(y) = ysize1(y) -1
               ENDIF
 
                tempgroup(gri) = X(gri)
                Var1 = (tempgroup*tempgroup) # Replicate (1.,R) -$
                         (tempgroup # Replicate(1.,R))^2 * ysize

                y = where(ysize1 ne 0,count)
                if count NE 0 THEN ysize1(y) = 1/ysize1(y)
                Var1 = Var1 * ysize1
                Var(*,i) = Var1        
                               ;append variances for ith group
            ENDFOR          
            
            DF = [C-1,C*gn-C]
           not0 = where (var ne 0,count)
           if count NE 0 THEN var(not0) = alog(var(not0))
           FC = 1
           anova,var,FCTest = FC, ONE_WAY=1  ,/No_Printout
           P = 1 - f_test1(FC, C-1, C*gn-C)
            END

LEVENE :  BEGIN
            if ( M EQ 0) THEN BEGIN
                YC = Replicate (R-1,C)
                ysize = 1./YC
            ENDIF  else begin
                y = where(YC NE 0,count)
                ysize = YC 
               if count GT 0 then ysize(y) = 1./ysize(y)
                
             ENDELSE
       
            Dev= ABS(X - ((X # Replicate (1.,R))*ysize) #     $
                                           Replicate(1.,R))
            if (M NE 0) THEN BEGIN
               Dev(NotGood) = -1
               tot = total(YC)
            ENDIF ELSE tot = R*C   

            DF = [C-1,tot-C]
            FC=1
           if ( M NE 0) THEN      $
               anova,Dev,FCTest = FC,      $
            Unequal_ONE_WAY=1,Missing=-1,  /No_Print $
           ELSE  anova,FCTest = FC,Dev,ONE_WAY=1, $
                      /No_Print          
            P = 1 - f_test1(FC, C-1, tot-1)
            END
            
     
 ELSE :
 ENDCASE

RETURN
END 
