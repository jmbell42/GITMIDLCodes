PRO plot3darc, center, nn1, nn2, arcbegin, arclength, degrees=degrees,	$
	color=color, fill=fill, tiplen=tiplen, tipwid=tipwid, 		$
	labeltext=labeltext, labelradius=labelradius, labeloffset=labeloffset, _extra=_extra,	$
	circle=circle
;+
; NAME:
;	plot3darc
; PURPOSE:
;	Plot an arc in a 3d geometry (with optional label)
; CATEGORY:
;	Tricks
; CALLING SEQUENCE:
;	plot3darc, center, nn1, nn2 [, arcbegin, arclength, degrees=degrees,	$
;		color=color, tiplen=tiplen, tipwid=tipwid, 		$
;		labeltext=labeltext, labelradius=labelradius, labeloffset=labeloffset]
; INPUTS:
;	center		array[3]; type: int or float
;					Cartesian coordinates of center of arc
;	nn1, nn2	array[3]; type: int or float
;					Cartesian coordinates defining plane in which arc is to be drawn
;		The arc is drawn in one of two ways:
;		1.	if arcbegin and arclength both specified:
;			nn1 is intepreted as 'x-axis', nn2 as y-axis; the arc is drawn by connecting points
;				center+(nn1*cos(angle)+nn2*sin(angle)) where angle covers [arcbegin,arcbegin+arclength]
;				In this case n1 and n2 usually will be two perpendicular vectors
;		2.	if either arcbegin or arclength not specified
;				nn1 and nn2 are connected by arc
; OPTIONAL INPUT PARAMETERS:
;	arcbegin	scalar; type: int or float
;					phase angle for the starting point of the arc in the [nn1,nn2] plane
;	arclength	scalar; type: int or float
;					length of the arc
;	/degrees	if set, arcbegin and arclength are assumed to be in radians
;
;	color=color	if set, the area between the center and the arc is shaded with the specfied color
;
;	tiplen=tiplen			keyword passed to arrow3d
;	tipwid=tipwid			keyword passed to arrow3d
;				if one of these keywords is set the end point of the arc (at nn2) receives an
;				3D arrow point
;
;	labeltext=labeltext
;				scalar; type: string
;					string to plotted somewhere near the arc. The following three keywords are only used
;					if labeltext is provided:
;	labelradius=labelradius
;				scalar; type: int or float
;					as a first approximation the string is plotted near the middle of the arc
;					between nn1 and nn1 at a distance of labelradius times the radius of the arc.
;					Usually labelradius is somewhat greater than one.
;	labeloffset=labeloffset
;				array[2]; type: int or float
;					adjustment to the position of labeltext in x and y data coordinates
;					This is usually to manually tweak the position determined with labelradius
;					(depending on the !p.t matrix the computed position can be awkward).
; OUTPUTS:
;	circle=circle
;				array[3,361]; type: float
;					3D-coordinates of point along arc. If this keyword is present
;					then nothing is plotted.
; INCLUDE:
	@compile_opt.pro				; On error, return to caller
; CALLS:
;	InitVar, arrow3d, vectorproduct, ToRadians, SuperArray, plot3dtext, gridgen
;	IsType
; SEE ALSO:
;	setup3d
; RESTRICTIONS:
;	A proper !p.t matrix must be set up (e.g. with setup3d)
; PROCEDURE:
; MODIFICATION HISTORY:
;	AUG-1999, Paul Hick (UCSD/CASS; pphick@ucsd.edu)
;-
InitVar, fill, /key
InitVar, labelradius, 1.0

IF IsType(arcbegin, /undefined) AND IsType(arclength, /undefined) THEN BEGIN
	aa = total(nn1*nn1)
	ll = total(nn2*nn2)

	n1 = nn1/sqrt(aa)
	n2 = nn2/sqrt(ll)

	rpd = 1.0
	arcbegin  = 0.0
	arclength = acos(total(n1*n2))

	n2 = vectorproduct(vectorproduct(n1,n2,/unit),n1)

	n1 = nn1
	n2 = n2*sqrt(aa + (ll-aa)/sin(arclength)^2)
ENDIF ELSE BEGIN
	n1 = nn1
	n2 = nn2
	rpd = ToRadians(degrees=degrees)
ENDELSE

n = 361
zero2one = gridgen(n, /one)

tmp = (arcbegin+arclength*zero2one)*rpd

arc = n1#cos(tmp)+n2#sin(tmp)

circle = SuperArray(center,n,/trail)+arc

IF NOT arg_present(circle) THEN BEGIN

	; First execute polyfill calls (there is one in arrow3d also).

	IF fill AND IsType(color, /defined) THEN polyfill,  [ [center], [circle] ], color=color, /t3d

	IF IsType(tiplen, /defined) OR IsType(tipwid, /defined) THEN	$
		arrow3d, center+arc[*,n-6], center+arc[*,n-1], tiplen=tiplen, tipwid=tipwid, _extra=_extra

	plots, circle, /t3d, _extra=_extra, color=color

	IF IsType(labeltext, /defined) THEN	$
		plot3dtext, center+labelradius*arc[*,n/2], labeltext, labeloffset=labeloffset, _extra=_extra

ENDIF

RETURN  &  END
