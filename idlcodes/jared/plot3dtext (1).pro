PRO plot3dtext, pos, labeltext, labeloffset=labeloffset, align=align, _extra=_extra
;+
; NAME:
;	plot3dtext
; PURPOSE:
;	Plots a text string at a 3D location
; CATEGORY:
;	Tricks
; CALLING SEQUENCE:
;	plot3dtext, pos, labeltext, labeloffset=labeloffset
; INPUTS:
;	pos			array[3]; type: int or float
;					rectangular coordinates for positioning string (in data coordinates)
;	labeltext	scalar; type: string
;					label to be plotted
; OPTIONAL INPUT PARAMETERS:
;	labeloffset=labeloffset
;				array[2]; type: int or float
;					adjustment to the position of labeltext in x and y data coordinates
;					This is usually used to manually tweak the position determined with labeldist
;					(depending on the !p.t matrix the computed position can be awkward).
; OUTPUTS:
;	(none)
; INCLUDE:
	@compile_opt.pro		; On error, return to caller
; CALLS:
;	InitVar, coord3to2
; PROCEDURE:
; MODIFICATION HISTORY:
;	APR-2000, Paul Hick (UCSD/CASS; pphick@ucsd.edu)
;-
InitVar, labeloffset, [0,0]

P = coord3to2(pos)

InitVar, align, 0.5
xyouts, P[0]+labeloffset[0], P[1]+labeloffset[1], labeltext, _extra=_extra, align=align

RETURN  &  END
