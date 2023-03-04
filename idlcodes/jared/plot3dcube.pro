PRO plot3dcube, r0, r1, _extra=_extra, tiplen=tiplen, tipwid=tipwid, color=color,		$
	labeltext=labeltext, labeldist=labeldist, labeloffset=labeloffset
;+
; NAME:
;	plot3dcube
; PURPOSE:
;	Plot 3D cube with optional label
; CATEGORY:
; CALLING SEQUENCE:
;	plot3dcube, r0, r1 [, linestyle=linestyle, thick=thick,	$
;		labeltext=labeltext, labeldist=labeldist, labeloffset=labeloffset, charsize=charsize, charthick=chartick]
; INPUTS:
;	r0, r1		array[3]; type: int of float
;					rectangular coordinates for begin and end point of line (in data coordinates)
; OPTIONAL INPUT PARAMETERS:
;	linestyle=linestyle, thick=thick
;					IDL keywords passed to plots, /t3d command for drawing line
;	tiplen=tiplen, tipwid=tipwid, color=color
;					keywords passed to arrow3d. If either tiplen or tipwid is set then arrow3d is called
;					to add a 3D arrow point to the end of the line (at r1 side)
;	labeltext=labeltext
;				scalar; type: string
;					label to plotted near axis (usually near the end r1)
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
;	plot3dtext, InitVar, IsType
; PROCEDURE:
; MODIFICATION HISTORY:
;	APR-2000, Paul Hick (UCSD/CASS; pphick@ucsd.edu)
;-
xunit = [1,0,0]
yunit = [0,1,0]
zunit = [0,0,1]

dr = r1-r0

r  = r0
plots, [	[r],					$
 			[r+dr* xunit],			$
 			[r+dr*(xunit+yunit)],	$
 			[r+dr*       yunit ],	$
 			[r] ], /t3d, _extra=_extra

r	= r0+dr*zunit
plots, [	[r],					$
 			[r+dr*xunit],			$
 			[r+dr*xunit+dr*yunit],	$
 			[r			+dr*yunit],	$
 			[r] ], /t3d, _extra=_extra

r = r0
plots, [ [r], [r+dr*zunit] ], /t3d, _extra=_extra
r = r0+dr*xunit
plots, [ [r], [r+dr*zunit] ], /t3d, _extra=_extra
r = r0+dr*yunit
plots, [ [r], [r+dr*zunit] ], /t3d, _extra=_extra
r = r0+dr*(xunit+yunit)
plots, [ [r], [r+dr*zunit] ], /t3d, _extra=_extra


InitVar, labeldist, 0

IF IsType(labeltext, /defined) THEN BEGIN
	P = r1-r0
	P = P/sqrt(total(P*P))
	plot3dtext, r1+labeldist*P, labeltext, labeloffset=labeloffset, _extra=_extra
ENDIF

RETURN  &  END
