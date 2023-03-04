; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/xanimate.pro#1 $
;
; Copyright (c) 1990-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

pro xanimate, set = set, image = image, frame = frame, order = order, $
	close = close, title = title, window = window, rate
;+
; NAME:
;	XANIMATE
;
; PURPOSE:
;	Display an animated sequence of images using Xwindows Pixmaps,
;	or the SunView display.
;
; CATEGORY:
;	Image display.
;
; CALLING SEQUENCE:
;	To initialize:
;	XANIMATE, SET = [Sizex, Sizey, Nframes, Show_Window]
;
;	To load a single image:
;	XANIMATE, IMAGE = Image, FRAME = Frame_Index
;
;	To load a single image that is already displayed in an existing window:
;	XANIMATE, FRAME = Frame_Index, WINDOW = [ Window [, X0, Y0, Sx, Sy]]
;	(This technique is much faster than reading back from the window.)
;
;	To display the animation after all the images have been loaded:
;	XANIMATE [, Rate]
;	To stop the display, hit any key.
;
;	To close and deallocate the pixmap/buffer:
;	XANIMATE, /CLOSE
;
; OPTIONAL INPUT PARAMETERS:
;	Rate:	The basic display rate in frames per second.  The default 
;		value is "infinity".  Note, however, that the maximum rate of
;		display is limited by the speed of your computer and video 
;		hardware.  The delay between loading successive images is 
;		1.0/Rate.
;
; KEYWORD PARAMETERS:
;	SET:	A vector of parameters that initialize XANIMATE.  SET should 
;		be set to a 3- to 5-element integer vector containing the 
;		following parameters:
;		Sizex, Sizey:	The X and Y sizes of the images to be 
;				displayed, in pixels.
;
;		Nframes:	The number of frames in the animated sequence.
;
;		Show_Window:	The number of the window in which to display 
;				the animation.  If this parameter is omitted,
;				window 0 is used.  This parameter is ignored 
;				for Sun (the current window is used.)
;
;	IMAGE:	A 2D array containing an image to be loaded at the position
;		given by FRAME.  The FRAME keyword must also be specified.
;
;	FRAME:	The number of the frame to load an image in.  FRAME must be 
;		in the range 0 to Nframes-1.  FRAME is used in conjunction with
;		either the IMAGE or WINDOW keywords.
;
;	WINDOW:	The number of an existing window to copy an image from.
;		When using X windows, this technique is much faster than 
;		reading from the display and then calling XANIMATE.
;
;		The value of this parameter is either a simple window
;		index (in which case the entire window is copied),
;		or a 5-element vector containing the window index, the
;		starting X and Y locations of the area to be copied, and the 
;		X and Y sizes of the area to be copied (in pixels).
;
;	ORDER:	Set this keyword if images are to be displayed from top down.
;		Omit it or set it to zero if images go from bottom to top.  
;		This keyword is only used when loading images.
;
;	CLOSE:	Set this keyword to delete the pixwin and window and free 
;		memory.
;
;	TITLE:	A string to use as the title of the animation window (X only).
;
; OUTPUTS:
;	No explicit outputs.
;
; COMMON BLOCKS:
;	XANIMATE_COM - private common block.
;
; SIDE EFFECTS:
;	A pixmap and window are created.
;
; RESTRICTIONS:
;	XANIMATE only works for X windows or Sun View.
;
;	FOR X:  An animation may not have more than approximately 127 frames.
;
;	FOR SUN:  A large 2D memory array is made to contain the images.
;		  For large images or a large number of frames, this procedure
;		  can be a real memory hog.  For SunView, faster operation can
;		  be obtained by using a non-retained window.
;
;	Users of X windows can use an improved, "widgetized" version of this
;	routine called XINTERANIMATE from the IDL widget library.
;
; PROCEDURE:
;	When initialized, this procedure creates an approximately square
;	pixmap or memory buffer, large enough to contain Nframes of
;	the requested size.
;
;	Once the images are loaded using the FRAME and IMAGE or WINDOW 
;	keywords, they are displayed by copying the images from the pixmap
;	or buffer to the visible window.
;
; MODIFICATION HISTORY:
;	DMS, April, 1990.
;
;	Modified to use numerous windows under X, DMS, March, 1991.
;		This mod improves virtual memory allocation and the size of
;		animations the VAXen can do.
;-
common xanimate_com, pwin, swin, nframes, xs, ys, nfx, buffer

if (!d.name ne 'SUN') and (!d.name ne 'X') then $
	message,'Not a window oriended device.'

if keyword_set(close) then begin
	if !d.name eq 'SUN' then begin
		if n_elements(buffer) gt 1 then buffer = 0
		return
		endif
	if n_elements(pwin) le 1 then return
	for i=0,n_elements(pwin)-1 do $
		if pwin(i) ge 0 then wdelete,pwin(i)
	wdelete, swin
	pwin = -1
	return
	endif

if keyword_set(set) then begin
	xs = set(0)
	ys = set(1)
	nframes = set(2)
	if n_elements(set) ge 4 then swin = set(3) else swin = 0
	if n_elements(set) ge 5 then $
		message, 'XANIMATE: pixwin param no longer supported'
	if !d.name eq 'SUN' then begin
		s = size(buffer)  ;Existing buffer
		new = 1		;Make a new image
		if s(0) eq 2 then begin  ;Will previous window do?
		  if (s(1) ge xs) and (s(2) ge ys * nframes) then new = 0
		endif
		if new then begin	;Make new buffer
		  buffer = 0		;Delete old buffer
		  buffer = bytarr(xs, ys * nframes, /nozero)
		  endif
		return
		endif
	wdelete, swin		   ;Remove previous windows
	if n_elements(pwin) gt 1 then $
		for i=0,n_elements(pwin)-1 do $
			if pwin(i) ge 0 then wdelete,pwin(i)
	pwin = replicate(-1, nframes)	;Pixwin indices
	if n_elements(title) eq 0 then title = 'Xanimate'
	window,retain=0, swin, xsize = xs, ysize = ys, title= title
	wset, swin
	return
	endif

;	Here, windows must exist
if !d.name eq 'X' then begin
	if n_elements(pwin) le 1 then message,"Not initialized"
endif

if !d.name eq 'SUN' then $
	if n_elements(buffer) le 1 then $
		message, "Not initialized."

if n_elements(frame) gt 0 then begin	;Check frame param
	if (frame lt 0) or (frame ge nframes) then $
		message, "Frame number must be from 0 to nframes -1."
	endif

if n_elements(order) eq 0 then order = 0  ;Default order

j = n_elements(window)
if j gt 0 then begin		;Copy image from window?
	old_window = !d.window
	wset, window(0)
	if j lt 5 then begin	;If coords not spec, use all
		p = [ window(0), 0, 0, !d.x_vsize, !d.y_vsize ]
	endif else p = window
	if (p(3) gt xs) or (p(4) gt ys) then $
		message, "Window parameter larger than setup"
	if !d.name eq 'SUN' then begin
		buffer(0, frame * ys) = $
			tvrd(p(1),p(2), p(3), p(4),/order) ;Read from sun
	endif else begin		;X
		if pwin(frame) lt 0 then begin	;Create window?
			window, /FREE, xs = xs, ys = ys, /PIXMAP
			pwin(frame) = !d.window
			endif
		wset, pwin(frame)
		device, copy = [ p(1), p(2), p(3), p(4), 0, 0, p(0)]
	endelse		
	if old_window ge 0  then wset, old_window
	return
endif
	
if n_elements(image) ne 0 then begin	;Load image?
	s = size(image)
	if (s(0) ne 2) or (s(1) gt xs) or (s(2) gt ys) then $
		message, "Image parameter must be 2D of size" $
		+ string(xs)+ string(ys)
	if !d.name eq 'SUN' then begin
		if order eq 0 then buffer(0,frame * ys) = reverse(image,2) $
		else buffer(0, frame * ys) = image
	endif else begin
		old_window = !d.window
		if pwin(frame) lt 0 then begin	;Create window?
			window, /free, xs = xs, ys = ys, /pixmap
			pwin(frame) = !d.window
			endif
		wset, pwin(frame)
		tv,image, order = order
		wset, old_window
	endelse
	return
endif
	

if n_elements(rate) ne 0 then delay = 1./rate else delay =0.0
t = systime(1)
j = 0L

if !d.name eq 'SUN' then begin
	while 1 do for i=0,nframes-1 do begin
		y = i * ys
		tv, buffer(*, y : y + ys-1), /order
		j = j + 1
		wait, delay
		if get_kbrd(0) ne '' then goto, done
		endfor
endif

wset, swin		;Display animation with X
wshow, swin
while 1 do for i=0, nframes-1 do begin
	device, copy = [ 0, 0, xs, ys, 0, 0, pwin(i)]  ;Copy it
	j = j + 1
	wait, delay
	if get_kbrd(0) ne '' then goto, done
	endfor

done: print,j / (systime(1) - t), ' Frames per second.'
end
