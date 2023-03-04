;+
; NAME:
;	statpos
; PURPOSE:
;	Calculate position of average, median and maximum of array
; CATEGORY:
;	Statistics
; CALLING SEQUENCE:
	FUNCTION statpos, Y 	, $
		min 	= min		, $
		max 	= max		, $
		binsize = binsize	, $
		hist	= hist		, $
		fraction= fraction
; INPUTS:	(read-only)
;	A	array		array for which median value is requested
;						A should already represent a histogram
;						If it isn't use one of the histogram
;						keywords
; OPTIONAL INPUT PARAMETERS:
;	min=min
;	max=max
;	binsize=binsize
;					if any one of these keywords is set then
;					array Y is fed to the IDL histogram function
;					with these keywords.
;	fraction=fraction
;					scalar; type: float; default: 0.5
;						sets the fraction used for the median
;						calculation, i.e. finds the position
;						where 'fraction' are lower and 1-fraction
;						are higher.
; OUTPUTS:
;	STATPOS		3 element float array
;		StatPos[0]	position of average ('center of mass')
;		StatPos[1]	position of median
;		StatPos[2]	position of maximum
; INCLUDE:
	@compile_opt.pro		; On error, return to caller
; CALLS:
;	IsType, InitVar
; PROCEDURE:
;	The values returned by StatPos are based on the array index, i.e.
;	0 <= StatPos[i] <= n_elements(A)-1  (i=0,1,2)
;
;	Note that the average calculated here from the histogram depends
;	on the bin size. Use the mean function if that's a problem.
; MODIFICATION HISTORY:
;	MAY-1993, Paul Hick (UCSD/CASS)
;	JUL-2008, Paul Hick (UCSD/CASS; pphick@ucsd.edu)
;		Added keyword 'fraction'
;-

InitVar, fraction, 0.5

mk_hist = IsType(min,/defined) OR IsType(max,/defined) OR IsType(binsize,/defined)

CASE mk_hist OF
0: hist = Y
1: BEGIN
	hist = histogram(Y, min=min, max=max, binsize=binsize, omin=omin, omax=omax)
	InitVar, binsize, (omax-omin)/(n_elements(hist)-1)
END
ENDCASE

n = n_elements(hist)

sum = 0*hist

sum[0] = hist[0]
FOR i=1L,n-1 DO sum[i] = sum[i-1]+hist[i]	; Accumulate
halfway = fraction*sum[n-1]					; Half of total sum

i = (where(sum GT halfway))[0] > 0

CASE i EQ 0 OF
0: halfway = i+0.5*((halfway-sum[i-1])-(sum[i]-halfway))/(sum[i]-sum[i-1])
1: halfway = i
ENDCASE

average = total(hist*findgen(n))/total(hist); Pos of average

i = max(hist,pmax)							; Pos of maximum

A = [average,halfway,pmax]
IF mk_hist THEN A = omin+binsize*(A+0.5*[0,1,1])

RETURN, A  &  END
