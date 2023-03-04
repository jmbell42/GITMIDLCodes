; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/c_edit.pro#1 $
;
; Copyright (c) 1988-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

pro c_edit_draw_bar, bar

on_error,2                      ;Return to caller if an error occurs
sx = bar.x1 - bar.x0 + 1
if bar.inten_0 ne bar.inten_1 then $
	z = byte(bar.inten_0 + findgen(sx) * (bar.inten_1 - bar.inten_0)/sx) $
  else z = replicate(bar.inten_0,sx)

for i=bar.y0, bar.y1 do tv,z,bar.x0,i
xyouts, bar.x0, bar.y1+2, strtrim(string(bar.minv,format=bar.nfmt),2),/dev
xyouts, bar.x1, bar.y1+2, strtrim(string(bar.maxv,format=bar.nfmt),2),/dev,align=1.0
xyouts, (bar.x1 + bar.x0)/2, bar.y1+2, bar.title, align=0.5,/dev
plots,[bar.x0, bar.x0,bar.x1,bar.x1,bar.x0],$	;incribe it
	[bar.y0,bar.y1,bar.y1,bar.y0,bar.y0],/dev
end


pro c_edit_back
common c_edit_common,nc, nc1, nc2, wxsize, wysize, $
	colors, plot_xs, plot_ys, names, bars

on_error,2                      ;Return to caller if an error occurs
ramp = bytscl(indgen(512),top=nc1)
for i=wysize-60,wysize-30 do tv,ramp,wxsize/2-256,i

;define bar structure
a = { slide_bar, x0:0, y0:0, x1:0, y1:0, title:'', minv:0.0, maxv:0.0, $
	inten_0:0, inten_1:0, nfmt:'', str_val:'', value: 1, s: [0.,0.] }

bars = replicate(a,4)	;make 4 of them
bar_wid = wxsize/2.2
bar_x0 = wxsize/4-bar_wid/2

bars.x0 = bar_x0
bars.x1 = bar_x0 + bar_wid
bars.y0 = 100*(findgen(4)+1) 
bars.y1 = bars.y0 + 30
bars.title=names
bars.nfmt= ['(f4.0)','(f4.2)','(f4.2)','(f4.0)']
bars.minv = [0,0,0,0]
bars.maxv = [360.,1.0,1.0,nc1]
bars.inten_0 = [nc2,nc2,nc2,0]
bars.inten_1 = [nc2,nc2,nc2,nc1]
for i=0,3 do c_edit_draw_bar, bars(i)

c_labels = ['Red','Green','Blue','Red']
c_align = [0,.5,.5,1]
for i=0,3 do $		;Label colors for hue
  xyouts,bar_x0 + bar_wid*i/3, bars(0).y0 - !d.y_ch_size,$
	c_labels(i), align = c_align(i), /dev
	
plot_xst = .6
plot_xend = .9
plot_ht = 0.2
yr = [360.,1.,1.]

plot_position = fltarr(4,3)
plot_xs = fltarr(2,3)
plot_ys = plot_xs
for i=0,2 do begin
	y = i/3.5+0.1	;Y of bottom
	plot_position(0,i) = [plot_xst,y, plot_xend, y+plot_ht]
	plot,/noer,colors(*,i),yrange=[0,yr(i)],title=names(i),$
		pos=plot_position(*,i),ystyle=2,xstyle=3, tickl = -0.02
	plot_xs(0,i) = !x.s 
	plot_ys(0,i) = !y.s
	endfor
end



pro c_edit_interp_colors,pts, npts, colors	;interpolate colors
;	pts = array of subscripts of tie points.
;	npts = # of elements in pts
;	colors = (n,3) array of colors.  Interpolated between tie points.
;
	on_error,2                      ;Return to caller if an error occurs
	for i=0,npts-2 do begin	;interpolate
		i0 = pts(i) & i1 = pts(i+1)
		kc = i1 - i0 		;# of colors to interp+1
		if kc gt 1 then begin
		c = colors(i0,*)
		dc = colors(i1,*) - c	;delta clockwise
		dc0 = dc(0)		;hue dist clockwise
		while (dc0 lt (-180.)) do dc0 = dc0 + 360.
		while (dc0 gt 180.) do  dc0 = dc0 - 360.
		dc1 = -dc(0)		;delta ccw
		while (dc1 lt (-180.)) do dc1 = dc1 + 360.
		while (dc1 gt 180.) do dc1 = dc1 - 360.
		if abs(dc1) lt abs(dc0) then begin	;Use closest
			dc(0) = dc1
		  endif else begin
			dc(0) = dc0
		  endelse
		dc = dc / kc
		colors(i0+1,0) = ((findgen(kc-1)+1) # dc) + $  ;Interpolate
				 (replicate(1,kc-1) # c)
		endif		;kc gt 1
		endfor		;i loop
	colors(0,0) = (colors(*,0) + 360.) mod 360.	;wrap the hue
end



pro c_edit, colors_out, hsv = hsv, hls = hls
;+
; NAME:
;	C_EDIT
;
; PURPOSE:
;	Interactive creation of color tables based on the HLS or the HSV color
; 	systems using the mouse and three sliders.  Similar to COLOR_EDIT but
;	two sliders replace the color wheel.  The sliders allow better control
; 	of HSV colors near 0% saturation, but the interface is less intuitive.
;
; CATEGORY:
;	Color tables.
;
; CALLING SEQUENCE:
;	C_EDIT [,COLORS_OUT] [, HSV = hsv] [, HLS = hls]
;
; INPUTS:
;	None.
;
; KEYWORD PARAMETERS:
;	HLS:  If this keyword is set, use the Hue Lightness Saturation system.
;	HSV:  If this keyword is set, use the Hue Saturation Value system
;	      (the default).
;
; OUTPUTS:
;	COLORS_OUT:  If supplied, this variable contains the final color
;	table triples as an array of the form (number_colors, 3).
;
; COMMON BLOCKS:
;	COLORS:  Contains the current RGB color tables.
;
; SIDE EFFECTS:
;	Color tables are modified and values in COLORS common block are
;	changed.  A temporary window is used.
;
; RESTRICTIONS:
;	Works only with window systems.
;
; PROCEDURE:
;	A window is created with a color bar centered at top and four
;	sliders along the left side.  The four sliders are labeled:
;		1) Pixel Value (from 0 to the number of available colors -1 )
;
;		2) Value (for HSV) or Lightness (HLS) can have values from
;		   0 to 1.
;
;		3) Saturation can have values from 0 to 1.
;
;		4) Hue (0 to 360): Red is 0 degrees, green is 120 degrees,
;		   and blue is 240 degrees.
;
;	Three graphs on the right show the current values of the three
;	parameters versus pixel value.
;
;	Operation:  The left mouse button is used to mark values on the
;		sliders.  The middle button is used to erase marked pixel
;		values (tie points) in the Pixel Value slider.  The right
;		button updates the color tables and exits the procedure.
;.
;	To use: Move the mouse into the slider whose value you want
;		to change and press the left button to select 
;		a Value/Lightness, Saturation, or Hue.  Move the mouse
;		with the left button depressed to interactively alter a color.
;
;		When you have created a color, move the mouse to the top
;		slider and select a pixel value.  The three color parameters
;		are interpolated between pixel values that have been marked
;		(called tie points).  Tie points are shown as small vertical
;		lines beneath the "Pixel Value" slider.  Press the middle
;		button with the cursor over the Pixel Value slider to delete 
;		the nearest tie point.
;
;	Note that in the HSV system, a Value of 1.0 represents the maximum
;	brightness of the selected hue.  In the HLS system, a Lightness of 0.5
;	is the maximum brightness of a chromatic hue, 0.0 is black, and 1.0
;	is bright white.  In the HLS color space, modeled as a double-ended
;	cone, the Saturation value has no effect at the extreme ends of the
;	cone (i.e., lightness = 0 or 1).
;
;	You can access the new color tables by declaring the common block
;	COLORS as follows:
;   	COMMON COLORS, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr
;
; MODIFICATION HISTORY:
;	DMS, July, 1988.
;       SNG, December, 1990 - For MSDOS only: c_edit does not support 
;                             resolutions lower than 640x480.
;-

common c_edit_common,nc, nc1, nc2, wxsize, wysize, $
	colors, plot_xs, plot_ys, names, bars

common colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr

on_error,2              ;Return to caller if an error occurs
psave = !p		;Save !p
nc = !d.table_size	;# of colors avail
if nc eq 0 then message, 'Device has static color tables, Can''t adjust'

device,get_write=old_mask, set_write=255 ;Enable all bits
nc1 = nc -1
nc2 = nc1-1		;Current color
!p.noclip = 1		;No clipping
!p.color = nc1		;Foreground color
!p.font = 0		;Hdw font
old_window = !d.window	;Previous window

if n_elements(hsv) eq 0 then hsv = 0
if n_elements(hls) eq 0 then hls = 0
if (hsv eq 0) and (hls eq 0) then hsv = 1	;default system

if hsv then begin
	names = ['Hue','Saturation','Value','Pixel Value']
endif else begin
	names = ['Hue','Lightness','Saturation','Pixel Value']
endelse

if hls then l = 0.5 else l = 1.0
colors = [[fltarr(nc)],[replicate(l,nc)],[findgen(nc)/nc]]
wxsize = 640
wysize = 600 < !d.y_vsize
if (!d.flags and 256) ne 0 then $
	window,xs=wxsize, ys=wysize, title='Intensity transformation',/free
c_edit_back
tvcrs,.5,.5,/norm
tvlct,colors(0:nc2,0),colors(0:nc2,1),colors(0:nc2,2), hsv = hsv, hls = hls
tvlct,0,0,1,nc1,/hsv		;last color is white
npts = 2		;tie points
pts = indgen(nc)	;x values of tie points
pts(1) = nc1		;init values
curr = [0,l,1.0,0]	;Current values
pxl_ind = 0
old_v = 0.
;		*** Main loop ***

next:
tvrdc,x,y,/dev		;read mouse with wait
next1:
if !err eq 1 then begin
next2:
	for i=0,3 do if (y ge bars(i).y0) and (y le bars(i).y1) then begin
		a = bars(i)		;Bar struct
		v = (x - a.x0)*(a.maxv - a.minv)/(a.x1 - a.x0) + a.minv
		v = v > a.minv < a.maxv
			;update text
		xyouts, a.x1+3, a.y0+3 ,a.str_val,col=0,/dev
		bars(i).str_val = strtrim(string(v,format=a.nfmt),2)
		xyouts, a.x1+3, a.y0+3 ,bars(i).str_val,color=nc1,/dev
		curr(i) = v		;save value
		if i eq 3 then goto, mark_pixel
		tvlct,curr(0),curr(1),curr(2),nc2,hsv=hsv,hls=hls
		tvrdc,x,y,/dev,0
		if !err eq 1 then goto,next2
		endif
	goto,next

mark_pixel:		;Get a hit in the pixel value Y values
	pxl_ind = fix(v)
	x = a.x0 + float(pxl_ind) * (a.x1 - a.x0)/nc1
	plots,[x,x],[a.y0-8,a.y0],/dev
	p = where(pxl_ind eq pts(0:npts-1), n)
	if n eq 0 then begin	;already there?
		pts(npts) = pxl_ind
		pts(0) = pts(sort(pts(0:npts))) ;re sort
		npts = npts + 1
	endif
	colors(pxl_ind,*) = curr(0:2)
interp_it:
	 for i=0,2 do begin	;erase old plots
		!x.s = plot_xs(*,i)
		!y.s = plot_ys(*,i)
		oplot,colors(*,i),col=0
		endfor
	c_edit_interp_colors, pts, npts, colors	;color interp
	tvlct,colors(1:nc2-1,0),colors(1:nc2-1,1), $
		colors(1:nc2-1,2),1, hls = hls, hsv = hsv
	for i=0,2 do begin	;draw new plots
		!x.s = plot_xs(*,i)
		!y.s = plot_ys(*,i)
		oplot,colors(*,i)
		endfor
endif $		;!err eq 1
;		here we delete a point:

;	only remove from bar # 3, the pixel value bar
else if (!err eq 2) and  (y ge bars(3).y0) and (y le bars(3).y1) then  begin
	a = bars(3)		;Bar struct
	v = (x - a.x0)*(a.maxv - a.minv)/(a.x1 - a.x0) + a.minv
	pxl_ind = fix(v > a.minv < a.maxv) < nc1 > 0 ;pixel value
	j = min(abs(pts(0:npts-1) - pxl_ind),i)	;get index of closest point
	pxl_ind = pts(i)
	x = a.x0 + float(pxl_ind) * (a.x1 - a.x0)/nc1
	plots,[x,x],[a.y0-8,a.y0-1],/dev,col=0 ;erase tick
		 ;never	delete first or last points
	if (i eq 0) or (i eq nc1) then goto, next
	pts = [pts(0:i-1), pts(i+1:*)] ;remove it
	npts = npts - 1
	goto, interp_it
endif $	
else if !err eq 4 then goto,done		;all done

goto,next


done:	tvlct,r_orig, g_orig, b_orig,/get	;Read rgb, save in common
	r_curr = r_orig & g_curr = g_orig & b_curr = b_orig
	if n_params() ge 1 then colors_out = [r_orig, g_orig, b_orig]


        if (!d.flags and 256) ne 0 then begin
  	  wdelete			;kill window
	  if old_window ge 0 then begin	;restore window?
		tvcrs,0.5,0.5,/norm	;show the table
		empty
		tvcrs			;hide cursor
		endif
        endif
!p = psave
device,set_write=old_mask
end



