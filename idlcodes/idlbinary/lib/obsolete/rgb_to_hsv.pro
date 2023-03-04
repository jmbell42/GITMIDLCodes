; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/rgb_to_hsv.pro#1 $
;
; Copyright (c) 1989-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

pro rgb_to_hsv, red, green, blue, h, s, v
;+
; NAME:
;	RGB_TO_HSV
;
; PURPOSE:
;	Convert from the RGB (Red, Green, Blue) color system to the
;	HSV (Hue, Saturation, Value) color system.
;
;	Note that this procedure has essentially been replaced by
;	the much quicker built-in routine COLOR_CONVERT.
;
; CATEGORY:
;	Graphics, color systems.
;
; CALLING SEQUENCE:
;	RGB_TO_HSV, Red, Green, Blue, H, S, V
;
; INPUTS:
;	Red:	Red color value(s), may be scalar or vector.  RGB values
;		are in the range 0 to 255.
;
;	Green:	Green color value(s), must have the same number of elements
;		as Red.
;
;	Blue:	Blue color value(s), must have the same number of elements
;		as Red and Green.
;
; OUTPUTS:
;	H:	Hue output.  This vector has the same number of elements as 
;		Red.  Hue is in the range of [0,360).  H is 0 (should really 
;		be undefined) if S (Saturation) is 0.0, 
;		i.e., red == green == blue.
;
;	S:	Saturation output, in the range of [0,1].
;
;	V:	Value output, in the range of [0,1].
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	None.
;
; RESTRICTIONS:
;	Red, Green, and Blue should be scaled into the range 0 to 255.
;
; PROCEDURE:
;	Taken from Foley & Van Dam, Fundamentals of Interactive Computer
;	Graphics, 1982. Pg 615.
;
; MODIFICATION HISTORY:
;	DMS, Aug, 1989.
;	DMS, 	Changed to use COLOR_CONVERT (Which really makes
;		this procedure obsolete.)
;-

on_error,2                              ;Return to caller if an error occurs
color_convert, red, green, blue, h, s, v, /RGB_HSV
end


