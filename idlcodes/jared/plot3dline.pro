PRO plot3dline, r0, r1, _extra=_extra, tiplen=tiplen, tipwid=tipwid, color=color,		$
	labeltext=labeltext, labeldist=labeldist, labeloffset=labeloffset
;+
; NAME:
;	plot3dline
; PURPOSE:
;	Plot line ('axis') in 3D with optional label
; CATEGORY:
;	Tricks
; CALLING SEQUENCE:
;	plot3dline, r0, r1 [, linestyle=linestyle, thick=thick,	$
;		labeltext=labeltext, labeldist=labeldist, labeloffset=labeloffset, charsize=charsize, charthick=chartick]
; INPUTS:
;	r0, r1		array[3]; type: int or float
;					rectangular coordinates for begin and end point of line (in data coordinates)
; OPTIONAL INPUT PARAMETERS:
;	tiplen=tiplen, tipwid=tipwid, color=color
;					keywords passed to arrow3d. If either tiplen or tipwid is set then arrow3d is called
;					to add a 3D arrow point to the end of the line (at r1 side)
;	labeltext=labeltext
;				scalar; type: string
;					label to be plotted near axis (usually near the end r1)
;
;	There are two keywords to determine label placement:
;
;	labeldist=labeldist
;				scalar; type: int or float
;					labeldist is a distance (in data coordinates) along the line from r0 to r1 where the label
;					is placed. Since this placement sometime looks messy when a strange 3D transformation
;					is in effect, labeloffset
;	labeloffset=labeloffset
;				array[2]; type: int or float
;					adjustment to the position of labeltext in x and y data coordinates
;					This is usually used to manually tweak the position determined with labeldist
;					(depending on the !p.t matrix the computed position can be awkward).
; INCLUDE:
	@compile_opt.pro		; On error, return to caller
; CALLS:
;	InitVar, IsType, arrow3d, plot3dtext
; PROCEDURE:
; MODIFICATION HISTORY:
;	AUG-1999, Paul Hick (UCSD/CASS; pphick@ucsd.edu)
;-
InitVar, labeldist, 0

CASE IsType(tiplen, /defined) or IsType(tipwid, /defined) OF
0: plots, [ [r0], [r1] ], /t3d, _extra=_extra, color=color
1: arrow3d, r0, r1, tiplen=tiplen, tipwid=tipwid, _extra=_extra, color=color
ENDCASE

IF IsType(labeltext, /defined) THEN BEGIN
	P = r1-r0
	P = P/sqrt(total(P*P))
	plot3dtext, r1+labeldist*P, labeltext, labeloffset=labeloffset, _extra=_extra
ENDIF

RETURN  &  END
