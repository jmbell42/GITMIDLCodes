; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/multicompare.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.


function testmeans, A
SX = size(A)
if SX(0) eq 1 THEN CNum = 0 else CNum = SX(2) - 1
for i = long(0), CNum do BEGIN
here = where(A(*,i) NE 0,count)
if count NE 2 THEN return,0
ENDFOR
return,1
END
  





 pro multicompare, X, Contrast, a, ST,One_Way = One, Unequal_One_Way = Unequal,$
            Two_Way = Two, Interactions_Two_Way  = $
            Interactions,LSD = LS, Bonferroni=Bon,Scheffe = Sch, Tukey = Tuk,$
            Missing = M, Block=B, TInteraction = IN
;+
; NAME: 
;	MULTICOMPARE
;
; PURPOSE:
;	Multicompare gives the user access to a variety of procedures for 
;	making many inferences from a single experimental data set. These
;	procedures are designed to guard against experimentwise errors 
;	resulting from the increased probabilty of at least one inferential
;	error when many inferences are made. 
;
; CATEGORY: 
;	Statistics.
;
; CALLING SEQUENCE:
;	MULTICOMPARE, X, Contrast, A, St
;
; INPUTS: 
;	X:	2 or 3-dimensional array of experimental data values.
;
;     Contrast:	An array, dimensioned (CL,C), where:
;		CL = the number of treatments
;		   = the number of columns of X
;		and 
;		C = the number of contrasts or inferences to be tested.
;		Contrast, B(i,j) = the coefficient of the mean of the ith 
;		treatment in the jth contrast.
;
;	A:	Experimentwise significance level desired. 
; 
; OUTPUT:
;	St:	An array, dimensioned (2,C), where C is the number
;		of contrasts to test. ST(0,j) = the absolute value
;		of the test statistic. ST(1,j) = the lower
;		limit of the rejection region - i.e.,
;		if ST(0,j) > ST(1,j) reject the null hypothesis for
;		the jth contrast at the a*100% significance level.
;
; KEYWORD PARAMETERS:
;	Type of design structure. Options are:
;      ONE_WAY:	If set,  1-way anova.
;
; UNEQUAL_ONE_WAY:  If set,  1-way ANOVA with unequal sample sizes.
;
;      TWO_WAY:	If set,  2-way ANOVA.
;
; INTERACTIONS_TWO_WAY:	If set, 2-way ANOVA with interactions.
;	One and only one of the above options may be set.
;
;	Options for multicomparison testing:
;
;	LSD:	Fisher's LSD procedure. LSD is a post-hoc test of any
;		contrasts of the treatment means.  It should only be used if
;		the F-test for equal means rejects the null hypothesis at
;		the A*100% significance level. LSD has an experimentwise
;		error rate approximately equal to 5%.
;
;   BONFERRONI:	Bonferroni's method. This method should be selected
;		instead of LSD if the F-test is not significant.
;                                      
;        
;      SCHEFFE:	Scheffe's procedure.  Use Sheffe's procedure to make any
;		number of unplanned comparisons - that is, to data snoop.
;		Experimentwise error rate is A*100%.              
;
;	TUKEY:	Tukey`s procedure. Tukey's procedure is often more sensitive
;		than Sheffe's but in the general case it requires equal sample
;		sizes. Pairwise testing of means is allowed with unequal 
;		sample sizes, but if the disparity is too great, Sheffe's 
;		method is more sensitive.  The experimentwise error rate, A,
;		must be between 0 and 0.1.
;
;	BLOCK:	a flag which ,if set, signals that comparisons
;		should be done on block means instead of treatment means.
;		Alternatively, input transpose(X) for the experimental data
;		array.
;
;      MISSING:	Placeholding value for missing data.  If not set, then assume
;		no missing data.
;
; TINTERACTION:	A flag, if set, to signal that contrasts are for interaction
;		effects. The user should not set both keywords BLOCK and
;		TINTERACTION.
;-
On_Error,2

;  Ascertain design structure
 ONE_WAY = 0 & ONE_WAY_UNEQUAL=1 & TWO_WAY = 2 & TWO_WAY_INTERACTION = 3

 keyset = [keyword_set(One), keyword_set(Unequal), $
            keyword_set(Two),keyword_set(Interactions)]
 T  = where(keyset,nkey)

 if nkey NE 1 THEN BEGIN
    print, $
         'multicompare - must specify one and only type of '
    print,'               of design structure'
    goto,DONE
 ENDIF

 T = T(0)      ; T = selected design structure


; Ascertain test type
 LSD = 0 & BONFERRONI = 1 & Scheffe = 2 & TUKEY = 3

 keyset = [keyword_set(LS), keyword_set(Bon), $
           keyword_set(Sch),keyword_set(TUK)]
 MT  = where(keyset,nkey)

 if nkey NE 1 THEN BEGIN
    print,'multicompare - must specify one and only one type'
   print, '               of multiple comparison test'
   goto,DONE
 ENDIF

 MT = MT(0)    ; M = selected test type


If N_Params(0) LT 3 THEN BEGIN
  print,"multicompare- need more parameters."
  goto, done
ENDIF


if (a GT 1.0 OR a LT 0) THEN BEGIN
    print,        $
     'multicompare- significance level a must lie between 0 and 1'
    goto, DONE
 ENDIF ELSE if MT EQ TUKEY and a GT .1 THEN BEGIN
      print, "multicompare - experiment-wise error rate must be"  
      print, "               no greater than .1 for Tukey's test"
      goto,done
     ENDIF

 X1 = float(X)
 SX = size(X1)

 if (SX(0) NE 2 AND T ne TWO_WAY_INTERACTIONS) OR   $
    (SX(0) ne 3 and T eq TWO_WAY_INTERACTIONS) THEN BEGIN
    print,      $
     'multicompare- data array has wrong number of dimensions'
    goto,done
 ENDIF

if (KEYWORD_SET(B) NE 0) THEN    $ 
                        ;transpose to test block means
  if (T NE TWO_WAY_INTERACTIONS) THEN      $
       X1 = transpose(X1)        $
  ELSE BEGIN
       SX = size(X1)
       X1 = fltarr(SX(3),SX(2),SX(1))
       for i = 0l,SX(1) -1 do $
         for j = 0l,SX(3) -1 do $
            X1(j,*,i) = float(X(i,*,J))
  ENDELSE


 SX =size(X1)
 SC = size(Contrast)
 C = SX(1)
 CN = SC(1)
  




; If testing interactions, reform array and perform 1-way testing

if KEYWORD_SET(IN) THEN BEGIN
 if KEYWORD_SET(B) THEN BEGIN
  print,   $
    "multicompare - keywords Block and Interaction should not both be set."
  goto,done
 ENDIF 

 if (T EQ TWO_WAY_INTERACTIONS) THEN $
   if (SX(0) NE 3) THEN BEGIN
    print, 'multicompare- wrong number of dimensions.' 
    goto,DONE
   ENDIF ELSE BEGIN                ;reform array for one-way anova
   X1 = Fltarr(C*SX(3),SX(2))
   for i = 0,SX(3) -1 DO $
    for j = 0,C-1 DO $
     X1(C * i +j,*) = float(X(j,*,i))
   SX = size(X1)
   C  = SX(1)
   T = ONE_WAY
  ENDELSE     $ 
 ELSE BEGIN
   print,    $
 "multicompare- to compare interaction effects, keyword structure"
  print,"                      must be set to TWO_WAY_INTERACTIONS "
   goto, done
 ENDELSE
ENDIF
 
 
 if ( SC(0) EQ 1) THEN CNUM = 1 else CNUM = SC(2)

 if (C NE CN) THEN BEGIN
   print,         $
   'multicompare- data and contrast arrays must have same number of columns'
   goto,DONE
 ENDIF

 if testcontrast(Contrast) EQ 0 THEN BEGIN
  print,'multicompare- Contrast array contains equations whose coefficients'
  print,'              do not sum to 0'
  return
 ENDIF
 
 D=1
 if T NE TWO_WAY_INTERACTIONS THEN  R=SX(2) ELSE BEGIN
    R=SX(3) 
    D=SX(2)    
 ENDELSE                                  ;Compute number of rows


 ; replace missing data with 0
 if ( T EQ ONE_WAY_UNEQUAL and N_ELEMENTS(M) NE 0) THEN BEGIN

     Pairwise,X1,M,YR,YC, nogood, good
     CN = where(YC NE 0,NYC)
     RN = where(YR NE 0,NYR)
     if NYC LT 2 OR NYR LT 2 THEN BEGIN
       print,"multicompare, too many missing entries"
      return 
    ENDIF

     YC = float(YC)

        ; compute sqd dev of columns from their means
     Mean =  (X1 # Replicate(1.,R)) /YC  
     Mean = MEAN # replicate(1.0, R)
     sigma = fltarr(C,R)
     sigma(good) = (X1(good) - Mean(good))^2
     sigma = sigma # Replicate(1.0,R)

 ENDIF ELSE    BEGIN

         YC = float(R)
        if (T EQ TWO_WAY_INTERACTIONS) THEN BEGIN    

          YC = YC * D
          X2 = X1
          X1= reform(X1,C,YC)
  
        ; Compute sum squared deviations of columns from their means 
          Mean =  (X1 # replicate(1.0,YC))/YC
          sigma = (X1 -  MEAN # replicate(1.0, YC))^2 
          sigma = sigma # replicate(1.0,YC)

        ;Pre-process three dimensional are by converting to a two
        ; dimensional array whose entries are sums of repetitions

        X1 = fltarr(C,R)
        for i = float(0),R-1 Do   $
        for j=0,C-1 DO        $
          X1(j,i) = Total(X2(j,*,i)) 
                          
      ENDIF ELSE BEGIN
       Mean = (X1 # replicate(1.0, YC))/YC
       sigma = (X1 -  MEAN # replicate(1.0, YC))^2 
       sigma = sigma # replicate(1.0,YC)
      ENDELSE
  ENDELSE




if ( T EQ ONE_WAY_UNEQUAL AND N_ELEMENTS(M) ne 0) THEN         $
               sigma =sqrt( total(sigma)/(Total(YC)-C))           $
ELSE sigma =sqrt( total(sigma)/(C*YC-C)) 


Means = (X1#replicate(1.0,R))/YC      ;compute column means
ST = fltarr(2,CNUM)

if CNUM GE 2 THEN ST(0,*) = ABS(MEANS # Contrast)  $
 ELSE   ST(0) = ABS(Total(Contrast * Means))

CASE MT of
        ; compute test statistic for all examples
        ; based on contrasts
 TUKEY: BEGIN
         If T EQ ONE_WAY_UNEQUAL AND   $
          testmeans(Contrast) EQ 0 THEN BEGIN
          print, 'Multicompare- TUKEY test can only handle'
          print, '              missing data when comparing means'
          goto,done
         ENDIF

        if CNUM GE 2 THEN BEGIN 
          if ( T NE ONE_WAY_UNEQUAL OR N_ELEMENTS(M) eq 0) THEN  BEGIN
            Test_Stat =Replicate(1.0,C)   $
                       #ABS(Contrast)/sqrt(YC)   
            ST(1,*) =  sigma * Test_Stat
          ENDIF ELSE BEGIN

            for i = 0l,CNUM - 1 DO   $
             ST(1,i) = min (YC(where(Contrast(*,i) NE 0)))
            ST(1,*) =2.0* sigma / sqrt(ST(1,*))
          ENDELSE
       ENDIF ELSE BEGIN
           if T EQ ONE_WAY_UNEQUAL THEN $
            YC1 =  min(YC(where(Contrast ne 0))) $
           else YC1 = YC
           ST(1) = sigma*Total(ABS(Contrast)/sqrt(YC1))
         ENDELSE
  END
 
ELSE: BEGIN
    if CNUM GE 2 THEN BEGIN 
      ;compute test statistic for all examples based on contrasts
    if ( T NE ONE_WAY_UNEQUAL or N_ELEMENTS(M) eq 0) THEN       $
     Test_Stat =Replicate(1.0/YC,C)# Contrast^2   $
    ELSE Test_Stat = 1./YC # Contrast^2
    ST(1,*) = sigma * (sqrt(Test_Stat))
    ENDIF ELSE  $
      ST(1) = sigma*(sqrt(Total(Contrast^2/YC)))
    END
ENDCASE


 if( N_ELEMENTS(YC) EQ 1) then v = YC*C-C else v = total(YC) -C

 case MT of
  
      LSD       : tav = student_t (a/2.,v)
      BONFERRONI:BEGIN
                   tav = student_t(a/(CNUM*2),v)
                   END
      SCHEFFE    : Begin
                     tav =F_test(a,C-1,v)  
                     tav=sqrt((C-1)*tav) 
                     END
       TUKEY:    if C ne 2 THEN $
                  tav = .5 * studrange(1.0 - a,v,C)   $
                else tav = sqrt(2)*student_t(a/2.,v)/2.
              
       ELSE: BEGIN
            print,"multicompare- unknown Test selected"
            goto,DONE
            END
 ENDCASE



ST(1,*) = tav*ST(1,*)   


DONE:
RETURN
END   
