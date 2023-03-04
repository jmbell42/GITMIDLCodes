; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/hsv_to_rgb.pro#1 $
;
; Copyright (c) 1989-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

pro hsv_to_rgb, h, s, v, red, green, blue
;+
; NAME:
;	HSV_TO_RGB
;
; PURPOSE:
;	Convert from the HSV (Hue, Saturation, Value) color system to
;	the RGB (Red, Green, Blue) color system.
;
; CATEGORY:
;	Graphics, color systems.
;
; CALLING SEQUENCE:
;	HSV_TO_RGB, H, S, V, Red, Green, Blue
;
; INPUTS:
;	H:	The hue variable.  This value may be either vector or scalar.
;		Values for hue range from 0 to 360.  H is 0 if S (saturation) 
;		is 0.0.
;
;	S:	The saturation variable.  This variable should be the same 
;		size as H.  Valid values range from 0 to 1.
;
;	V:	The value variable.  This variable should be the same size
;		as H.  Valid values range from 0 to 1.
;
; KEYWORD PARAMETERS:
;	None.
;
; OUTPUTS:
;	Red:	The returned red color value(s). This returned variable has 
;		the same size as H.  RGB values are short integers in the
;		range 0 to 255.
;
;	Green:	The green color value(s).
;  
;	Blue:	The blue color value(s).
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	None.
;
; RESTRICTIONS:
;	H must be in the range 0 to 360.  S and V must be in the range
;	0 to 1.0.
;
; PROCEDURE:
;	Taken from Foley & Van Dam, Fundamentals of Interactive Computer
;	Graphics, 1982, page 616.
;
; MODIFICATION HISTORY:
;	DMS, Aug, 1989.
;-
on_error,2                      ;Return to caller if an error occurs
n = n_elements(h)
red = intarr(n) & green = intarr(n) & blue = intarr(n)
hh = [h]		;Make into vectors
ss = [s]
vv = reform([v], n)		;Must be 1D
s0 = where(ss eq 0.0, count)
if count ne 0 then begin	;Monochromatic case
	q = v(s0) * 255.	;gray value
	red(s0) = q
	green(s0) = q
	blue(s0) = q
	endif
s0 = where(hh eq 360., count)
if count ne 0 then hh(s0) = 0.0

s0 = where(ss ne 0.0, count)
if count ne 0 then begin
	hh = float(hh) / 60.
	hi = fix(hh)		;floor
	f = hh - hi		;remainder
	p = vv * (1.0 -ss)
	q = vv * (1.0-ss*f)
	t = vv*(1.0-(ss*(1.-f)))

	;       0   1   2   3
	tmp = [[p],[q],[t],[vv]] * 255.
	rindex = [3,1,0,0,2,3]
	gindex = [2,3,3,1,0,0]
	bindex = [0,0,2,3,3,1]
	hi=hi(s0)
	red(s0) = tmp(s0,rindex(hi))
	green(s0) = tmp(s0,gindex(hi))
	blue(s0) = tmp(s0,bindex(hi))
	endif
end
