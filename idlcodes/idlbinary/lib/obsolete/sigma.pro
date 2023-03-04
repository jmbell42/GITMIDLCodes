; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/sigma.pro#1 $

FUNCTION SIGMA,ARRAY,N_PAR,DIMENSION
;+
; NAME:
;	SIGMA
;
; PURPOSE:
;	Calculate the standard deviation value of an array, or calculate the 
;	standard deviation over one dimension of an array as a function of all
;	the other dimensions.
;
; CATEGORY:
;	Statistics.
;
; CALLING SEQUENCE:
;	Result = SIGMA(Array)
;
;	Result = SIGMA(Array, N_Par)
;
;	Result = SIGMA(Array, N_Par, Dimension)
;
; INPUTS:
;	Array:	The input array of any type except string.
;
; OPTIONAL INPUT PARAMETERS:
;	N_Par:	The number of parameters.  The default value is zero.  The 
;		number of degrees of freedom is N_ELEMENTS(Array) - N_Par.  
;		The value of sigma varies as one over the square root of the 
;		number of degrees of freedom.
;
;   Dimension:	The dimension to do standard deviation over.
;
; OUTPUTS:
;	SIGMA returns the standard deviation value of the array when called 
;	with one parameter. 
;
;	If DIMENSION is passed, then the result is an array with all the
;	dimensions of the input array except for the dimension specified,
;	each element of which is the standard deviation of the corresponding
;	vector in the input array.
;
;	For example, if A is an array with dimensions of (3,4,5), then the
;	command:
;
;		B = SIGMA(A,N,1) 
;
;	is equivalent to
;
;		B = FLTARR(3,5)
;		FOR J = 0,4 DO BEGIN
;			FOR I = 0,2 DO BEGIN
;			B(I,J) = SIGMA(A(I,*,J), N)
;			ENDFOR
;		ENDFOR
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	None.
;
; RESTRICTIONS:
;	The dimension specified must be valid for the array passed, 
;	otherwise the input array is returned as the output array.
;
; PROCEDURE:
;	When DIMENSION is passed, then the function SUM is used.
;
; MODIFICATION HISTORY:
;	William Thompson	Applied Research Corporation
;	July, 1986		8201 Corporate Drive
;				Landover, MD  20785
;	DMS, May, 1993		Removed AVG fcn, use new features of TOTAL.
;-
;
ON_ERROR,2                      ;Return to caller if an error occurs
S = SIZE(ARRAY)
IF S(0) EQ 0 THEN BEGIN
   message, 'Variable ARRAY must be an array.', /CONTINUE
   RETURN,ARRAY
ENDIF
IF N_PARAMS(0) EQ 3 THEN BEGIN
	IF ((DIMENSION GE 0) AND (DIMENSION LT S(0))) THEN BEGIN
		m = n_elements(array) / s(dimension+1)
		SIG = SQRT( TOTAL(ARRAY^2,DIMENSION)/m - $
			(TOTAL(ARRAY,DIMENSION)/m)^2 )
		N = S(DIMENSION+1)
	END ELSE BEGIN
		message, 'ARRAY Dimension out of range.', /CONTINUE
		RETURN,ARRAY
	ENDELSE
END ELSE BEGIN
	m = n_elements(array)
	DIFF = ARRAY - TOTAL(array)/m
	SIG = SQRT( TOTAL( DIFF*DIFF )/M)
	N = N_ELEMENTS(ARRAY)
ENDELSE
;
IF N_PARAMS(0) GE 2 THEN SIG = SIG * SQRT( N / ((N - N_PAR) > 1.) )
;
RETURN,SIG
END

