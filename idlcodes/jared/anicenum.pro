FUNCTION anicenum, x, upper=upper, digits=digits, astring=astring
;+
; NAME:
;	anicenum
; PURPOSE:
;	Returns a 'nice' round number close to the input value
; CATEGORY:
;	Tricks
; CALLING SEQUENCE:
;	R = anicenum(x [,/upper])
; INPUTS:
;	x			scalar; type: float
;					input floating value
; OPTIONAL INPUT PARAMETERS:
;	/upper		if set the input value is rounded up
; OUTPUTS:
;	R			scalar; type: float
;					'nice' value
; INCLUDE:
	@compile_opt.pro		; On error, return to caller
; PROCEDURE:
;	Trivial
; MODIFICATION HISTORY:
;	JUL-2001, Paul Hick (UCSD/CASS)
;	AUG-2003, Paul Hick (UCSD/CASS; pphick@ucsd.edu)
;		Added digits and astring keyword
;-

InitVar, upper  , /key
InitVar, astring, /key

y0 = abs(x)
y1 = alog10(y0)
p1 = floor(y1)
y1 = 10^(y1-p1)			; 1 <= y1 < 10

CASE IsType(digits, /defined) OF

0: BEGIN

	yTest = [0.,1.,1.5,2.,5.,10.]
	nTest = n_elements(yTest)

	CASE upper OF
	0: BEGIN
		n = nTest-1
		WHILE n GE     0 AND yTest[n] GT y1 DO n = n-1
	END
	1: BEGIN
		n = 0
		WHILE n LE nTest-1 AND yTest[n] LT y1 DO n = n+1
	END
	ENDCASE

	r = (2*(x GE 0)-1)*yTest[n]*(10^float(p1))
END

1: BEGIN

	fmt = '(F'+strcompress(digits+3,/rem)+'.'+strcompress(digits-1,/rem)+')'
	reads, string(y1, format=fmt), r, format=fmt 
	r = (2*(x GE 0)-1)*r*(10^float(p1))

END

ENDCASE

IF astring THEN BEGIN
	r = strcompress(r, /rem)
	WHILE strmid(r,strlen(r)-1) EQ '0' DO r = strmid(r,0,strlen(r)-1)
	IF strmid(r,strlen(r)-1) EQ '.' THEN r = strmid(r,0,strlen(r)-1)
ENDIF

RETURN, r  &  END
