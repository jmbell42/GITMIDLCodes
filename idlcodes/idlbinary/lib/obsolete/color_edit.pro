; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/color_edit.pro#1 $
;
; Copyright (c) 1988-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

pro color_edit_back

common color_edit,nc, nc1, nc2, wxsize, wysize,r0,cx,cy,bar_ht, $
	colors, plot_xs, plot_ys, order, $
	bar_wid, bar_x0, bar_y, pv_y, pv_wid, pv_x0, names

on_error,2                      ;Return to caller if an error occurs
ramp = bytscl(indgen(512),top=nc1)
for i=wysize-60,wysize-30 do tv,ramp,wxsize/2-256,i

r0 = 120
cx = wxsize/4.
cy = wysize - 90. - r0
angle = !dtor * 10 * findgen(37) ;degrees
sina = sin(angle)
cosa = cos(angle)
plots,[cx,cx],[cy,cy],/dev	;Center of circle
polyfill,/dev,r0*cosa+cx,r0*sina+cy,col=nc2
for i=0.5, 1.0, 0.5 do plots,r0*i*cosa+cx, r0*i*sina+cy,/dev
c_name = ['Red','Yellow','Green','Cyan','Blue','Magenta']
align = [0,0,1,1,1,0]
for i=0,5 do begin
	a = i*60 * !dtor
	x = r0*cos(a) + cx
	y = r0 * sin(a) + cy
	plots,[cx,x],[cy,y],/dev
	xyouts,r0*1.1*cos(a)+cx,r0*1.1*sin(a)+cy,c_name(i),/dev,ali = align(i)
	end

bar_ht = 20	;Draw the brightness bar
bar_wid = wxsize/3
bar_x0 = wxsize/4-bar_wid/2
bar_y = cy - r0 - 40 - bar_ht
xyouts,wxsize/4, bar_y+bar_ht+3, names(order(2)), ali=0.5,/dev
xyouts,bar_x0,bar_y+bar_ht+3,ali=0,/dev,'0'
xyouts,bar_x0+bar_wid,bar_y+bar_ht+3,ali=1,/dev,'1.0'
polyfill,[bar_x0, bar_x0, bar_x0+bar_wid, bar_x0+bar_wid],$
	[ bar_y, bar_y+bar_ht, bar_y+bar_ht, bar_y],/dev
;
;	Pixel value bar
;
pv_y = bar_y - bar_ht - 30
pv_wid = wxsize/3.
pv_x0 = wxsize/4-pv_wid/2
x = bytscl(findgen(pv_wid-1),top=nc-1)
for i=pv_y, pv_y+bar_ht do tv,x,pv_x0,i ;Another ramp
xyouts,wxsize/4, pv_y+bar_ht+3,'Pixel Value',ali=0.5,/dev
xyouts,pv_x0, pv_y+bar_ht+3,ali=0,/dev,'0'
xyouts,pv_x0+pv_wid, pv_y+bar_ht+3,ali=1,/dev,strtrim(nc1,2)
plots,[pv_x0, pv_x0, pv_x0+pv_wid, pv_x0+pv_wid,pv_x0],$
	[ pv_y, pv_y+bar_ht, pv_y+bar_ht, pv_y,pv_y],/dev

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
	plot,/noer,colors(*,order(i)),yrange=[0,yr(i)],title=names(i),$
		pos=plot_position(*,i),ystyle=2,xstyle=3, tickl = -0.02
	plot_xs(0,i) = !x.s 
	plot_ys(0,i) = !y.s
	endfor
end



pro color_edit_interp_colors,pts, npts, colors	;interpolate colors
;	pts = array of subscripts of tie points.
;	npts = # of elements in pts
;	colors = (n,3) array of colors.  Interpolated between tie points.
;
	on_error,2                      ;Return to caller if an error occurs
	for i=0,npts-2 do begin	;interpolate
		i0 = pts(i) & i1 = pts(i+1)
		kc = i1 - i0 		;# of colors to interp+1
		if kc gt 1 then begin	;do it?
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


pro color_edit, colors_out, hsv = hsv, hls = hls
;+
; NAME:
;	COLOR_EDIT
;
; PURPOSE:
;	Interactively create color tables based on the HLS or the HSV color
;	systems using the mouse and a color wheel.
;
; CATEGORY:
;	Color tables.
;
; CALLING SEQUENCE:
;	COLOR_EDIT [, Colors_Out] [, HSV = hsv] [, HLS = hls]
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
;	Colors_Out:  If supplied, this variable contains the final color
;       table triples as an array of the form (number_colors, 3).
;
; COMMON BLOCKS:
;	COLORS:  Contains the current RGB color tables.
;
; SIDE EFFECTS:
;	Color tables are modified, values in COLORS common are changed.
;	A temporary window is used.
;
; RESTRICTIONS:
;	Only works with window systems.
;
; PROCEDURE:
;	A window is created with:
;	1) A color bar centered at the top.
;
;	2) A color wheel for the hue (azimuth of mouse from the center) 
;	   and saturation (distance from the center).
;
;	3) Two "slider bars", the top one for the Value (HSV) or Lightness
;	   (HLS), and the other for the pixel value.
;
;	4) 3 graphs showing the current values of the three parameters
;	   versus pixel value.
;
;	Operation:  The left mouse button is used to mark values on the
;		sliders and in the color wheel.  The middle button is used
;		to erase marked pixel values (tie points) in the Pixel Value
;		slider.  The right button updates the color tables and exits
;		the procedure.
;
;	To use: Move the mouse into the circle or middle slider and depress
;		the left button to select a Hue/Saturation or a
;		Value/Lightness.  Move the mouse with the left button
;		depressed to interactively alter a color (shown in the color
;		wheel.
;
;		When you have created a color, move the mouse to the bottom
;		"Pixel Value" slider and select	a pixel value.  The three 
;		color parameters are interpolated between pixel values that 
;		have been marked (called tie points).  Tie points are shown
;		as small vertical lines beneath the "Pixel Value" slider.
;		Press the middle button with the cursor over the Pixel Value
;		slider to delete the nearest tie point.
;
;       Note that in the HSV system, a Value of 1.0 represents the maximum
;       brightness of the selected hue.  In the HLS system, a Lightness of 0.5
;       is the maximum brightness of a chromatic hue, 0.0 is black, and 1.0
;       is bright white.  In the HLS color space, modeled as a double-ended
;       cone, the Saturation value has no effect at the extreme ends of the
;       cone (i.e., lightness = 0 or 1).
;
;       You can access the new color tables by declaring the common block
;       COLORS as follows:
;       COMMON COLORS, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr
;
; MODIFICATION HISTORY:
;	DMS, July, 1988.
;       SNG, December, 1990 - Added support for DOS version.
;                             Does not support resolutions lower than 640x480.
;-

common color_edit,nc, nc1, nc2, wxsize, wysize,r0,cx,cy,bar_ht, $
	colors, plot_xs, plot_ys, order, $
	bar_wid, bar_x0, bar_y, pv_y, pv_wid, pv_x0, names

common colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr

on_error,2              ;Return to caller if an error occurs
nc = !d.table_size	;# of colors avail
if nc eq 0 then message, 'Device has static color tables, Can''t adjust.'

psave = !p		;Save !p
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
	names = ['Hue','Saturation','Value']
	order = [0,1,2]
endif else begin
	names = ['Hue','Lightness','Saturation']
	order = [0,2,1]
endelse

colors = [[fltarr(nc)],[replicate(1.0,nc)],[findgen(nc)/nc]]
if (windows = (!d.flags and 256) ne 0) then begin  ;Windows?
	wxsize = 640
	wysize = 600
	window,xs=wxsize, ys=wysize, title='Intensity transformation',/free
  endif else begin
	wxsize = !d.x_vsize
	wysize = !d.y_vsize
  endelse

color_edit_back
tvcrs,.5,.5,/norm
colors(nc1,*) = [0,0,1.]
tvlct,colors(*,order(0)),colors(*,order(1)),colors(*,order(2)), $
	hsv = hsv, hls = hls

npts = 2		;tie points
pts = indgen(nc)	;x values of tie points
pts(1) = nc1		;init values
h = 0.
s = 1.0
v = 1.0
pxl_ind = 0
old_v = 0.
;		*** Main loop ***

next:
cursor,x,y,/dev		;read mouse with wait
next1:
if !err eq 1 then begin
next2:
	if !d.name ne 'VGA' then cursor,x,y,0,/dev else cursor,x,y,2,/dev
	if !err ne 1 then goto,next
	if (y ge pv_y) and (y le pv_y + bar_ht) then goto, mark_pixel
	reload = 0
	d = sqrt((x - cx)^2 + (y-cy)^2) ;In circle?
	if d le (1.05 * r0) then begin	;New hue, sat & lightness
		h = atan(y-cy,x-cx) * !radeg ;hue
		s = d/r0 < 1.0		;saturation
		reload = 1
		endif
	if (y ge bar_y) and (y le bar_y+bar_ht) then begin ;lightness
		v = (x - bar_x0) / float(bar_wid) ;fract of brightness
		v = v > 0.0 < 1.0
		xyouts, bar_x0, bar_y,string(old_v,format='(f4.2,1x)'),$
			ali=1.,/dev,col=0
		xyouts, bar_x0, bar_y,string(v,format='(f4.2,1x)'),ali=1.,/dev
		old_v = v
		reload = 1
		endif
	if reload then if hls then tvlct,h,v,s,/hls,nc2 else $
				tvlct,h,s,v,/hsv,nc2
	!err = 0
	goto,next2

mark_pixel:		;Get a hit in the pixel value Y values
	x = x > pv_x0 < (pv_x0 + pv_wid)
	pxl_ind = fix(nc * float(x - pv_x0) / pv_wid) < nc1 > 0
	x = pv_x0 + float(pxl_ind) * pv_wid/nc
	plots,[x,x],[pv_y-8,pv_y],/dev
	p = where(pxl_ind eq pts(0:npts-1), n)
	if n eq 0 then begin	;already there?
		pts(npts) = pxl_ind
		pts(0) = pts(sort(pts(0:npts))) ;re sort
		npts = npts + 1
	endif
	while h lt 0 do h = h + 360.	;always positive

interp_it:
	 for i=0,2 do begin	;erase old plots
		!x.s = plot_xs(*,i)
		!y.s = plot_ys(*,i)
		oplot,colors(*,order(i)),col=0
		endfor
	colors(pxl_ind,*) = [h,s,v]
	color_edit_interp_colors, pts, npts, colors	;color interp
	tvlct,colors(1:nc2-1,order(0)),colors(1:nc2-1,order(1)), $
		colors(1:nc2-1,order(2)),1, hls = hls, hsv = hsv
	for i=0,2 do begin	;draw new plots
		!x.s = plot_xs(*,i)
		!y.s = plot_ys(*,i)
		oplot,colors(*,order(i))
		endfor
endif $		;!err eq 1
;		here we delete a point:

else if (!err eq 2) and  (y ge pv_y) and (y le pv_y + bar_ht) then  begin
	x = x > pv_x0 < (pv_x0 + pv_wid)
	pxl_ind = fix(nc * float(x - pv_x0) / pv_wid) < nc1 > 0
	j = min(abs(pts(0:npts-1) - pxl_ind),i)	;get index of closest point
	x = pv_x0 + float(pts(i)) * pv_wid / nc
	plots,[x,x],[pv_y-8,pv_y-1],/dev,col=0 ;erase tick
		 ;never	delete first or last points
	if (i eq 0) or (i eq nc1) then goto, next
	pxl_ind = pts(i)	;old pixel index
	pts = [pts(0:i-1), pts(i+1:*)] ;remove it
	npts = npts - 1
	goto, interp_it
endif $	
else if !err eq 4 then goto,done		;all done

goto,next


done:	tvlct,r_orig, g_orig, b_orig,/get	;Read rgb, save in common
	r_curr = r_orig & g_curr = g_orig & b_curr = b_orig
	if n_params() ge 1 then colors_out = [r_orig, g_orig, b_orig]

	if (windows) then begin	;Using windows?
		wdelete			;kill window
		if old_window ge 0 then begin	;restore window?
			tvcrs,0.5,0.5,/norm	;show the table
			empty
			tvcrs			;hide cursor
			endif
	endif		;windows
!p = psave		;restore !p
device,set_write=old_mask	;Restore write mask
end

