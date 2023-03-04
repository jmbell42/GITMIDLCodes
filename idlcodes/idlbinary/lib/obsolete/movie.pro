; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/movie.pro#1 $
;
; Copyright (c) 1988-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

pro movie, images, rate, order = order	;Image is an (n,m,k) images to show as fast
				;as we can.  !Order is set to 1 and restored.
;+
; NAME:
;	MOVIE
;
; PURPOSE:
;	Show a cyclic sequence of images stored in a 3D array.
;
; CATEGORY:
;	Image display.
;
; CALLING SEQUENCE:
;	MOVIE, Images [, Rate]
;
; INPUTS:
;      Images:	A 3D (n, m, nframes) byte array of image data, consisting of
;		nframes images, each of size n by m.  This array should be
;		stored with the top row first, (order = 1) for maximum 
;		efficiency.
;
; OPTIONAL INPUT PARAMETERS:
;	Rate:	Initial animation rate, in APPROXIMATE frames per second.  If 
;		omitted, the inter-frame delay is set to 0.01 second.
;
; KEYWORD PARAMETERS:
;	ORDER:	The ordering of images in the array.  Set Order to 0 for 
;		images ordered bottom up, or 1 for images ordered top down 
;		(the default).
;
; OUTPUTS:
;	No explicit outputs.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	The animation is displayed in the lower left corner of the currently
;	selected window.
;
; RESTRICTIONS:
;	SunView:
;	As SunView has no zoom or pan, we have to write each image to
;	the display.  This restricts the maximum animation rate.  Experience 
;	has shown that you can count on a rate of approximately 10 
;	frames per second with 192 by 192-byte images.  This speed varies 
;	according to the type of computer, amount of physical memory, and 
;	number of frames in the array.
;
;	The amount of available memory also restricts the maximum amount
;	of data	that can be displayed in  a loop.
;
;	X Windows users (Motif and OPEN LOOK) should use the XINTERANIMATE 
;	routine from the Widget Library for better results.
;
; PROCEDURE:
;	Straightforward.
;
; MODIFICATION HISTORY:
;	DMS, Nov, 1988.
;-
on_error,2                      ;Return to caller if an error occurs
old_order = !order
s = size(images)
if n_elements(rate) ne 0 then delay = 1./rate else delay = 0.01
if s(0) ne 3 then message, "Images must be a 3d array."

		;Default order is top down cause its faster.
if n_elements(order) ne 0 then !order = order else !order = 1

print,"S for slower, F for faster, Q to quit."
i = 0
while 1 do case strupcase(get_kbrd(0)) of
'':	begin
		tv,images(*,*,i)
		wait,delay
		i = i + 1
		if i eq s(3) then i = 0
	endcase
'S':	delay = delay * 1.5
'F':	delay = delay / 1.5
'Q':	begin
	!order=old_order		;Restore order.
	return
	endcase
else:

endcase
end

