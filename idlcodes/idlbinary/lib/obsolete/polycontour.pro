; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/polycontour.pro#1 $
;
; Copyright (c) 1989-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

pro polycontour, filename, color_index=color_index, pattern = pat, $
	DELETE_FILE=delfile
;+
; NAME:
;	POLYCONTOUR
;
; PURPOSE:
;	Fill the contours defined by a path file created by CONTOUR.
;	This routine has been obsoleted by the FILL option to CONTOUR,
;	and should NOT be used.
;
; CATEGORY:
;	Graphics.
;
; CALLING SEQUENCE:
;	POLYCONTOUR, Filename [, COLOR_INDEX = color_index]
;
; INPUTS:
;    Filename:	The name of a file containing contour paths.  This
;		file must have been created by using the CONTOUR
;		procedure:  CONTOUR, PATH=Filename, ...
;
; KEYWORD PARAMETERS:
; COLOR_INDEX:	An array of color indices for the filled contours.  Element 
;		i contains the color of contour level number i-1.  Element 
;		0 contains the background color.  There must be one more 
;		color index than the number of levels.
;
; DELETE_FILE:	If present and non-zero, Filename will be deleted after
;		POLYCONTOUR is finished with it.
;
;     PATTERN:	An optional array of patterns with the dimensions
;		(NX, NY, NPATTERN).
;
; OUTPUTS:
;	The contours are filled on the display using normalized
;	coordinates and the POLYFILL procedure.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	A filled contour plot is drawn to the current display.
;
; RESTRICTIONS:
;	This routine will NOT draw open contours.  To eliminate open
;	contours in your dataset, surround the original array with a 1-element
;	border on all sides.  The border should be set to a value less than
;	or equal to the minimum data array value.  
;
;	For example, if A is an (N,M) array enter:
;
;		B = REPLICATE(MIN(A), N+2, M+2)	;Make background
;		B(1,1) = A			;Insert original data
;		CONTOUR, B, PATH=Filename ...	;Create the contour file.
;
; PROCEDURE:
;	The contour file is scaned to find the starting byte of each contour's
;	path.  Then POLYCONTOUR sorts the contour levels and reads each 
;	record, filling its path.  High contours are draw in increasing 
;	order, then Low contours are drawn in decreasing order.
;
; EXAMPLE:
;	Create a 8 by 8 array of random numbers, place it into a 10 by 10
;	array to eliminate open contours, polycontour it, then overdraw 
;	the contour lines.  Enter:
;
;		B = FLTARR(10,10)		;Create a big array of 0's.
;		B(1,1) = RANDOMU(seed, 8,8)	;Insert random numbers.
;		CONTOUR, b, /SPLINE, PATH = 'path.dat' ;Make the path file.
;		POLYCONTOUR, 'path.dat'		;Fill the contours.
;		CONTOUR, b, /SPLINE, /NOERASE	;Overplot lines & labels.
;
;	Suggestion:  Use TEK_COLOR to load a color table suitable
;		     for viewing this display.
;
; MODIFICATION HISTORY:
;	DMS, AB, January, 1989.
;	DMS,     April, 1993.  Made it obsolete.
;-

COMMON POLYCONTOUR_MSG, count


if n_elements(count) eq 0 then begin
	count = 1
	message, 'is obsolete, use CONTOUR, /FILL', /INFO
	endif

on_error,2                      ;Return to caller if an error occurs
header = {contour_header,$
	type : 0B, $
	high_low : 0B, $
	level : 0, $
	num : 0L, $
	value : 0.0 }

max = 0
if n_elements(color_index) eq 0 then color_index = indgen(25)+1
asize = 100		;# of elements in our arrays
n = 0
cval = intarr(asize)	;Contour index
cstart = lonarr(asize)	;Starting byte of record
openr, unit, filename, /GET_LUN, DELETE=keyword_set(delfile)
while (not eof(unit)) do begin	;First pass
	a = fstat(unit)		;File position
	readu,unit,header	;Read header
	if (header.type eq 0) then $
		message, 'Warning: Unclosed contour ignored.', /CONT $
	else begin

	if n eq asize then begin	;Expand our arrays?
		cval = [cval,cval]	;Yes, double them
		cstart = [cstart,cstart]
		asize = 2 * asize
		endif
		;Color to draw
	c = fix(header.level)
	max = max > c
	if header.high_low eq 0 then  c = 200 - c ;low contour
	cval(n) = c			;Contour index
	cstart(n) = a.cur_ptr		;Position	
	n = n + 1
	endelse
     xyarr = fltarr(header.num,2)	;Define point to skip
     readu,unit,xyarr
    endwhile

cval = cval(0:n-1)			;Truncate
cstart = cstart(0:n-1)
order = sort(cval)			;Subscripts of order
for i=0,n-1 do begin			;Draw each contour
 	j = order(i)			;Index of record
	point_lun,unit,cstart(j)
	readu,unit,header		;Reread header
	if header.num le 2 then goto, skip ;A polygon?
	xyarr = fltarr(header.num, 2)	;Define points
	readu,unit,xyarr		;Read points
	col = cval(j)			;Drawing color
	if col ge 100 then col = 199-col ;Drawing index = 1 less than orig
	col = color_index(col+1)

	if n_elements(pat) ne 0 then begin
		s = size(pat)
		if s(0) ne 3 then message, 'Pattern array not 3d.'
		polyfill,/NORMAL, pattern=pat(*,*, i mod s(3)), $
			transpose(xyarr)
	endif else $
	  polyfill, /NORMAL, color= col,transpose(xyarr) ;Fill contour
skip:
	endfor
free_lun, unit			;Done
end











