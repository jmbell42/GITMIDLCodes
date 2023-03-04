; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/regression.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.


pro printoutr,TName,BName,SST,SSE,R,C,unit

if N_Elements( TName) EQ 0 THEN TName='Regression'
if N_Elements( BName) EQ 0 THEN BName='Residual'
printf,unit, " "
printf,unit,  " "
printf,unit,'                                ANALYSIS OF VARIANCE
printf,unit," "
printf,unit,'    SOURCE        SUM OF SQUARES      DF       MEAN SQUARE       F       p'
      printf,unit,'*******************************************************************************'
 
MSSE = SSE/(R-C-1)
DFE = R-C-1

MT = SST/(C)

 if MSSE NE 0 THEN FT = MT/MSSE else FT = 1.0e30
printf,unit,               $
Format='(A10,7X,G15.7,3X,I5,3X,G15.7,1X,G11.5,3X,F6.4)',    $
       TName,SST,C,MT,FT, 1-F_Test1(FT,C,DFE)

printf,unit,Format='(A10,7X,G15.4,3X,I5,3X,G15.4)',   $
 BName,SSe,DFe,MSSe

RETURN
END 




pro regression, X1, Y1, W1, A0, COEFF, Resid, YFit, sigma, $
                FTest, R, RMul, ChiSqr, VarNames = VarName,$
                   ListName = LN,NoPrint=NP, Missing =M,   $
                                           Unit = unit
;+
; NAME:
;	REGRESSION
;
; PURPOSE:
;	To augment and display the output of the library function Regress.
;	Additional output includes an anova table to test the hypothesis
;	that all coefficients are zero.A regression table is printed to the
;	screen or user specified file displaying the Coefficients, their
;	standard deviations, and  the T statistic to test for each coefficient
;	the hypothesis that it is zero.
;
; CATEGORY:
;	Statistics.
;
; CALLING SEQUENCE:
;   REGRESSION, X, Y, W,A0, COEFF, Resid, YFit, sigma, FTest, R, RMul, ChiSqr
;
; INPUTS:
;	X:	Array of independent variable data.  X must be dimensioned
;		(NTerms, NPoints) where there are Nterms coefficients to be
;		found and NPoints of sample data.  Y = column vector of NPoints
;		dependent variable values.
;
; OPTIONAL INPUTS:
;	W:	vector of weights for each equation.  For instrumental 
;		weighing, set w(i) = 1/Variance(Y(i)), for statistical 
;		weighting, w(i) = 1./Y(i) 
;
; KEYWORDS:
;     VARNAMES:	A vector of names for the independent variables to be used
;		in the output.
;                        
;      NOPRINT:	A flag to suppress printing out regression statistics.
;		The default is to print.
;       
;    LIST_NAME:	Name of output file.  Default is to the screen.
;
;      MISSING:	Missing data value.  If undefined, assume no missing data.
;		Listwise handling of missing data.
;
; OUTPUTS:
;	Anova table and regression summary written to the screen or to user
;	specified file.
;
; OPTIONAL OUTPUT PARAMETERS:
;	A0:	Constant term.
;
;	Coeff:	Vector of coefficients. Coeff has NTerm elements.
;
;	Resid:	Vector of residuals - i.e. Y - YFit.
;
; 	Yfit:	Array of calculated values of Y, Npoints 
;
;	Sigma:	Vector of standard deviations for coefficients.
;
;	Ftest:	Value of F for test of fit.
;
;	Rmul:	Multiple linear correlation coefficient.
;
;	R:	Vector of linear correlation coefficient.
;
;	ChiSqr:	Reduced weighted chi square for fit.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	None.
;
; RESTRICTIONS:
;	None.
;
; PROCEDURE: 
;	See documentation for REGRESS in the User's Library.
;-
; On_Error,2
 X = X1
 Y = Y1
 SY = size(Y)

 if N_Elements(unit) EQ 0 THEN            $     
   if  N_Elements(LN)  THEN openw,unit,/get,ln else unit = -1

 X = float(X)  
  
 if (SY(0) lt 2) THEN         BEGIN
     B = Y
 ENDIF ELSE B = transpose(Y)  

 SA = size(X)
 SY = Size(B)

 IF ((SA(0) eq 2) AND (SY(1) NE SA(2))) OR  $
    ((SA(0) eq 1) and (Sy(1) NE SA(1))) THEN  BEGIN
  printf,unit, 'regression - Incompatible arrays.'
  goto,done
 ENDIF

 
 if N_Elements(M) THEN BEGIN

    if SA(0) eq 1 THEN BEGIN 

     here = where(X ne M, count)
     if count ne 0 THEN BEGIN
        X = X(here)
        Y = Y(here)
     ENDIF

     here = where(Y ne M, count)
     if count ne 0 THEN BEGIN
        X= X(here)
        Y = Y(here)
     ENDIF

  ENDIF  ELSE BEGIN
    X = listwise([x,Y],M,rownum,rows,here)          ; removes 
                                    ;cases with missing data
    X = X(0:SA(1)-1,*)
    B = B(here)
 ENDELSE
    SA = size(X)
    SY = Size(B)
 ENDIF

  if sa(0) eq 2 THEN siza = SA(2) else siza= SA(1)


 if (siza LT 2) THEN BEGIN
    printf,unit,"regression- need more than 1 observation
    goto, DONE
 ENDIF



 if SA(0) EQ 1 THEN  BEGIN
    if N_elements(W1) ne 0 THEN W = W1
    coeff=SimpRegress(X,B,W,YFit,A0,sigma,FTest,R,RMul,  $
                        Chisqr) 

 ENDIF ELSE  BEGIN
  if N_Elements(W1) EQ 0 THEN W=fltarr(siza)+1 else W = w1
  coeff = Regress1(X,B,W,Yfit,A0,sigma,FTest,R,RMul,Chisqr   )
  if N_ELEMENTS(coeff) eq 1 then  $
     if coeff eq 1.e+30  THEN BEGIN
        printf, unit, "Regression---Halting, correlation matrix is singular"
        goto,done
  ENDIF
     
  sigma = sigma * sqrt(Chisqr)
 ENDELSE


 if N_Elements(NP) EQ 0 THEN BEGIN
  printf,unit,'Regression: Correlation Coeff =',RMul 



  if SA(0) eq 1 THEN VARNUM = 1 else VarNum = SA(1)
  if SA(0) eq 1 then points = SA(1) else points = SA(2)

   NC=Size(VarName)
   if (NC(1) NE 0 ) THEN BEGIN        ; set dependent
                                      ; variable names
     if  (NC(1) LT VarNum) THEN BEGIN
       printf,unit,'regression-missing Variable names'
       I=Indgen(varNum)
       VarName=[VarName,'Var'+STRTRIM(I(NC(1):VarNum-1),2)]
     ENDIF
   ENDIF ELSE VarName='Var'+ STRTrim(INDgen(VarNum),2)


   printf,unit," "
   printf,unit,"  VARIABLE       COEFFICIENT            STDDEV                  T       P  "
   printf,unit,format='(A10,3X,G15.7)','Constant',A0
 
   For i =0L,VarNum-1 DO             $


      printf,unit,format=     $
               '(A10,3X,G15.7,3x,G15.7,4x,G15.7,3x,F6.4 )',  $
             VarName(i), coeff(i), sigma(i),     $
             coeff(i)/sigma(i), $
             2.0*(1-student1_t(abs(coeff(i)/sigma(i)),       $
             points-VarNum-1))

   
   Resid = B - YFit
   if SA(1) NE 1 THEN ChiSqr = Total(Resid^2 * W)
   Mean = Total(B)/points
   SST = Total(W*(B - Mean)^2) - ChiSqr
   printoutr,TName,BName,SSt,ChiSqr,Points,VarNum,unit
   ChiSqr = ChiSqr/(Points - VarNum -1) 
   FTEST =  SST/VarNum/ChiSqr
 ENDIF

 DONE:
 if (N_Elements(LN) NE 0) THEN Free_LUN,unit
 return
 end  
