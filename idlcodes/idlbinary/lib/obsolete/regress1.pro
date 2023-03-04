; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/regress1.pro#1 $
;
;  Copyright (c) 1993-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.

FUNCTION REGRESS1,X,Y,W,YFIT,A0,SIGMA,FTEST,R,RMUL,CHISQ

;+
; NAME:
;	REGRESS1
;
; PURPOSE:
;	Multiple linear regression fit.
;	Fit the function:
;	Y(i) = A0 + A(0)*X(0,i) + A(1)*X(1,i) + ... + 
;		A(Nterms-1)*X(Nterms-1,i)
;
; CATEGORY:
;	G2 - Correlation and regression analysis.
;
; CALLING SEQUENCE:
;	Result = REGRESS(X, Y, W, YFIT, A0, SIGMA, FTEST, R, RMUL, CHISQ)
;
; INPUTS:
;	X:	array of independent variable data.  X must 
;		be dimensioned (Nterms, Npoints) where there are Nterms 
;		coefficients to be found (independent variables) and 
;		Npoints of samples.
;
;	Y:	vector of dependent variable points, must have Npoints 
;		elements.
;
;       W:	vector of weights for each equation, must be a Npoints 
;		elements vector.  For instrumental weighting 
;		w(i) = 1/standard_deviation(Y(i)), for statistical 
;		weighting w(i) = 1./Y(i).   For no weighting set w(i)=1,
;		and also set the RELATIVE_WEIGHT keyword.
;
; OUTPUTS:
;	Function result = coefficients = vector of 
;	Nterms elements.  Returned as a column vector.
;
; OPTIONAL OUTPUT PARAMETERS:
;	Yfit:	array of calculated values of Y, Npoints elements.
;
;	A0:	Constant term.
;
;	Sigma:	Vector of standard deviations for coefficients.
;
;	Ftest:	value of F for test of fit.
;
;	Rmul:	multiple linear correlation coefficient.
;
;	R:	Vector of linear correlation coefficient.
;
;	Chisq:	Reduced weighted chi squared.
;
; KEYWORDS:
;RELATIVE_WEIGHT: if this keyword is non-zero, the input weights
;		(W vector) are assumed to be relative values, and not based
;		on known uncertainties in the Y vector.    This is the case for
;		no weighting W(*) = 1.
;
; PROCEDURE:
;	Adapted from the program REGRES, Page 172, Bevington, Data Reduction
;	and Error Analysis for the Physical Sciences, 1969.
;
; MODIFICATION HISTORY:
;	Written, DMS, RSI, September, 1982.
;	Added RELATIVE_WEIGHT keyword, W. Landsman, August 1991
;-
;
On_error,2              ;Return to caller if an error occurs 
SY = SIZE(Y)            ;Get dimensions of x and y.  
SX = SIZE(X)
IF (N_ELEMENTS(W) NE SY(1)) OR (SX(0) NE 2) OR (SY(1) NE SX(2)) THEN $
  message, 'Incompatible arrays.'
;
NTERM = SX(1)           ;# OF TERMS
NPTS = SY(1)            ;# OF OBSERVATIONS
;
SW = TOTAL(W)           ;SUM OF WEIGHTS
YMEAN = TOTAL(Y*W)/SW   ;Y MEAN
XMEAN = (X * (REPLICATE(1.,NTERM) # W)) # REPLICATE(1./SW,NPTS)
WMEAN = SW/NPTS
WW = W/WMEAN
;
NFREE = NPTS-1          ;DEGS OF FREEDOM
SIGMAY = SQRT(TOTAL(WW * (Y-YMEAN)^2)/NFREE) ;W*(Y(I)-YMEAN)
XX = X- XMEAN # REPLICATE(1.,NPTS)      ;X(J,I) - XMEAN(I)
WX = REPLICATE(1.,NTERM) # WW * XX      ;W(I)*(X(J,I)-XMEAN(I))
SIGMAX = SQRT( XX*WX # REPLICATE(1./NFREE,NPTS)) ;W(I)*(X(J,I)-XM)*(X(K,I)-XM)
R = WX #(Y - YMEAN) / (SIGMAX * SIGMAY * NFREE)


WW1 = WX # TRANSPOSE(XX)
d = determ(WW1)
if d eq 0 THEN return, 1.e+30
if d lt 1.e-13 THEN BEGIN 
  print,"regression-- Determinant of correlation matrix less than 1.e-13."
  print,"             Hit control C to terminate."
ENDIF

ARRAY = INVERT((WX # TRANSPOSE(XX))/(NFREE * SIGMAX #SIGMAX))
A = (R # ARRAY)*(SIGMAY/SIGMAX)         ;GET COEFFICIENTS
YFIT = A # X                            ;COMPUTE FIT
A0 = YMEAN - TOTAL(A*XMEAN)             ;CONSTANT TERM
YFIT = YFIT + A0                        ;ADD IT IN
FREEN = NPTS-NTERM-1 > 1                ;DEGS OF FREEDOM, AT LEAST 1.

CHISQ = TOTAL(WW*(Y-YFIT)^2)*WMEAN/FREEN ;WEIGHTED CHI SQUARED
IF KEYWORD_SET(relative_weight) then varnce = chisq $
                                else varnce = 1./wmean
sigma = sqrt(array(indgen(nterm)*(nterm+1))*varnce/(nfree*sigmax^2)) ;Error term
RMUL = TOTAL(A*R*SIGMAX/SIGMAY)         ;MULTIPLE LIN REG COEFF
IF RMUL LT 1. THEN FTEST = RMUL/NTERM / ((1.-RMUL)/FREEN) ELSE FTEST=1.E6
RMUL = SQRT(RMUL)
RETURN,A
END
