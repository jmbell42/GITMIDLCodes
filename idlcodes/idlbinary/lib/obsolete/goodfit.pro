; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/goodfit.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.



Function Stdev1,D,Freq
; Stdev returns the sample standard deviation, where
; D contains the sampled values and Freq their frequency.
FT=Total(Freq)
D2=Total(D*Freq) / FT
Return, SQRT(Total(freq*(D - D2)^2)/(FT-1))
END    ;Function Stdev



Pro goodfit, Freq,A, B,ChiSqr, Prob,DF,Distr=D
;+
; NAME:
;       GOODFIT
;
; PURPOSE:
;	Test that a set of data has a given distibution.  User can select
;	built-in distribution through the keyword DISTR or supply own 
;	expected values.
;
; CATEGORY:
;	Statistics.
;
; CALLING SEQUENCE:
;	GOODFIT, Freq, [A, B, ChiSqr, Prob, DF, DISTR=D]
;
; INPUTS: 
;     Freq:	Vector of value or range frequencies.
;          
; OPTIONAL INPUTS:
;     A:	Vector of observed values or left endpoints for interval data.
;		Should have same length as F.  A must be present if user
;		selects built-in distributions.                
;
;     B:	Vector of right hand endpoints.
;                            
;
; OPTIONAL OUTPUT PARAMETERS:
;	ChiSqr:	The chi square statistic to test for the goodness of fit of
;		the data to the distribution.
;
;	Prob:	The probability of ChiSqr or somethinG larger from a chi 
;		square distribution.
;  
;	DF:	Degrees of freedom. User must specify chi
;		square degrees of freedom for user supplied
;		distribution. Compute DF to be s-1-t,
;		where s = N_Elements(A) and t is the number
;		of parameters that must be estimated to
;		derive expected frequencies.
;
; KEYWORDS: 
;	Distr:	the type of distribution for which the data is to be tested.
;		If Distr = "G", then GOODFIT tests for a Gaussian distribution.
;		To supply distribution, set Distr to the vector of expected
;		frequencies, say, EF.  EF(i) = the frequency expected for the
;		observation with observed frequency Freq(i).
;
; RESTRICTIONS:
;	None.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECT:
;	None.
;
; PROCEDURE:
;	Compute expected frequencies EXP(i).
;	Chi_Sqr = SUM((Freq(i)-ExpV(i))^2/ExpV(i)^2)
;	has the chi sqr distribution.
;-
On_Error,2
SF= SIZE(Freq)


if(KEYWORD_SET(D) eq 0) THEN BEGIN
   print,"Goodfit- key word Distr must be set"
   Return
 ENDIF ELSE if (N_ELEMENTS(D) gt 1) THEN BEGIN
              Expv = D
              Distr = "U"
             ENDIF $
           ELSE Distr = D
 
 if Distr NE "U" THEN  BEGIN
   SA= Size(A)
   if((SA(0) NE 1) OR (SF(0) NE 1) OR (SF(1) NE SA(1))) THEN BEGIN
     print, "GoodFit- incompatible vectors"
    Return
   ENDIF
 ENDIF



Case Distr of


"G": BEGIN

     if(N_Elements(B) EQ 0) THEN BEGIN
     print,"GoodFit- interval right endpoints undefined"
     RETURN
     ENDIF


     D=((A+B)/2.0)
     FT=Total(Freq)

     if(FT LE 1) THEN BEGIN
        print,"GoodFit-must have more than 1 observed value" 
        return
     END
   
     mean=Total(D*Freq)/FT
     sigma=StDev1(D,Freq)
     A1=(A-mean)/sigma
     B1 = (B-mean)/sigma
     ExpV=FltArr(SA(1))
     for i=0,SA(1)-1 DO                       $
       Expv(i) = (Gaussint(B1(i))-Gaussint(A1(i)))*FT
   
     DF=SA(1)-2
     END

 "U": BEGIN

    if(N_Elements(Distr) EQ 0) THEN BEGIN
        print,"GoodFit- expected values undefined"
        RETURN
     ENDIF

     if (N_Elements(DF) EQ 0 ) THEN BEGIN
      print, "goodfit- must specify degrees of freedom"
      Return
     ENDIF

     SE=Size(EXPV)
     if(SE(0) NE 1) OR (SE(1) NE SF(1)) THEN BEGIN
       print, "GoodFit- incompatible arrays"
       Return
     ENDIF     
     END

  
 ELSE: BEGIN
       print,"Unknown value for Key word Distr"
       Return
       END

 ENDCASE

 SS=float(Freq-Expv)
 ChiSqr = Total(SS*SS/Expv)
 Prob = 1 - chi_sqr1(ChiSqr,DF)
 print, "ChiSqr = ",ChiSqr, " with  ",DF,             $
   " degrees of freedom"
 print, "Probability of ChiSqr=",Prob

 Return
 END

   



