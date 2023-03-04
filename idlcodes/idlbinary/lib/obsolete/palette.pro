; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/palette.pro#1 $
;
; Copyright (c) 1988-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

pro palette_draw_bar, bar

on_error,2                      ;Return to caller if an error occurs
sx = bar.x1 - bar.x0 + 1
if bar.inten_0 ne bar.inten_1 then $
	z = byte(bar.inten_0 + findgen(sx) * (bar.inten_1 - bar.inten_0)/sx) $
  else z = replicate(bar.inten_0,sx)

for i=bar.y0, bar.y1 do tv,z,bar.x0,i
xyouts, bar.x0, bar.y1+2, strtrim(string(bar.minv,format=bar.nfmt),2),/dev
xyouts, bar.x1, bar.y1+2, strtrim(string(bar.maxv,format=bar.nfmt),2),/dev,align=1.0
xyouts, (bar.x1 + bar.x0)/2, bar.y1+2, bar.title, align=0.5,/dev
plots,[bar.x0-1, bar.x0-1,bar.x1+1,bar.x1+1,bar.x0-1],$	;incribe it
	[bar.y0,bar.y1,bar.y1,bar.y0,bar.y0],/dev
end



pro palette_back
common palette_common,nc, nc1, nc2, wxsize, wysize, $
	colors,  bars, rect, array, cell_size, c_array

on_error,2                      ;Return to caller if an error occurs
ramp = bytscl(indgen(256),top=nc1)
for i=wysize-30,wysize-5 do tv,ramp,10,i
x0 = 270 & x1 = 295
y1 = wysize - 5 & y0 = wysize - 140
rect = [[x0,y0],[x1,y0],[x1,y1],[x0,y1],[x0,y0]]
x0 = x0 -1
y1 = y1 + 1
plots, [[x0,y0],[x1,y0],[x1,y1],[x0,y1],[x0,y0]],/dev
;define bar structure
a = { slide_bar, x0:0, y0:0, x1:0, y1:0, title:'', minv:0.0, maxv:0.0, $
	inten_0:0, inten_1:0, nfmt:'', str_val:'', value: 1, s: [0.,0.] }
nbars = 3
bars = replicate(a,nbars)	;make 3 of them
bar_wid = 200
bar_x0 = 10

bars.x0 = bar_x0
bars.x1 = bar_x0 + bar_wid
bars.y1 = wysize-60 - findgen(nbars) * 40
bars.y0 = bars.y1 - 20
bars.title= ['Red','Green','Blue']

bars.nfmt= ['(i3)','(i3)','(i3)']
bars.minv = [0,0,0]
bars.maxv = [255,255,255]
bars.inten_0 = [0,0,0]		;dark bars
bars.inten_1 = bars.inten_0
; Equation to cvt from screen to data.
bars.s(1) = float(bars.maxv - bars.minv) / (bars.x1 - bars.x0)
bars.s(0) = bars.minv - bars.s(1) * bars.x0

for i=0,nbars-1 do palette_draw_bar, bars(i)

cell_size = 17
c_array = [10, 10+17*16, wysize - 170, wysize - 170 - 17*((nc+15)/16)]

x = (indgen(16*cell_size)/cell_size) # replicate(1,cell_size)  ;ramp
for i = 0,(nc-1)/16 do begin
	tv,x,c_array(0),c_array(2)-(i+1)*cell_size
	x = x + 16 < nc1
	endfor

for i=0,16 do begin
	x0 = c_array(0) + i*17
	plots,[x0,x0],[c_array(2),c_array(3)],/dev
	endfor
for i=0,(nc+15)/16 do begin
	y0 = c_array(2) - i*17
	plots,[c_array(0),c_array(1)],[y0,y0],/dev
	endfor
xyouts,10,5,'Undo Current Color',/dev
xyouts,wxsize-5, 5,'Undo All',/dev,ali=1.0
xyouts,10,30,'Help',/dev
end


pro update_bar, i, v	;update bar(i) with new value v
common palette_common,nc, nc1, nc2, wxsize, wysize, $
	colors,  bars, rect, array, cell_size, c_array

on_error,2                      ;Return to caller if an error occurs
a = bars(i)	;get struct
x = (a.value - a.s(0))/a.s(1)	;old X
plots,[x,x],[a.y0+1,a.y1-1],/dev,col=0	;Erase line
x = (v-a.s(0))/a.s(1)	;New Screen X
plots,[x,x],[a.y0+1,a.y1-1],/dev,col=255 ;new line
bars(i).value = v		;store new value

xyouts, a.x1+5, a.y0+3 ,a.str_val,col=0,/dev ;erase old string value
bars(i).str_val = strtrim(string(v,format=a.nfmt),2)
xyouts, a.x1+5, a.y0+3 ,bars(i).str_val,color=nc1,/dev ;new string value
end



pro palette
;+
; NAME:
;	PALETTE
;
; PURPOSE:
;	Interactively create color tables based on
;	the RGB color system using the mouse, three sliders,
;	and a cell for each color index.  Single colors can be
;	defined and multiple color indices between two endpoints
;	can be interpolated.
;
; CATEGORY:
;	Color tables.
;
; CALLING SEQUENCE:
;	PALETTE
;
; INPUTS:
;	No explicit inputs.  The current color table is used as a starting
;	point.
;
; KEYWORD PARAMETERS:
;	None.
;
; OUTPUTS:
;	None.
;
; COMMON BLOCKS:
;	COLORS:	Contains the current RGB color tables.
;
; SIDE EFFECTS:
;	The new color tables are saved in the COLORS common block and loaded
;	to the display.
;
; RESTRICTIONS:
;	Only works with window systems.  
;
; PROCEDURE:
;	A window is created with:
;
;	1) A color ramp at the top.
;	2) A rectangle containing the current color index at upper left.
;	3) Three slider bars for red, green, and blue.
;	4) An array of cells, one for each color index.
;	5) Buttons for help, undo current color, and undo all at the bottom.
;
;	To use the PALETTE tool:
;	Select the color index to be modified by clicking the mouse in the 
;	cell array over the color to be changed.  The index of this color
;	appears under the upper right rectangle.
;
;	Move the mouse to the slider bars and vary the color content
;	by depressing the left button within these bars.
;
;	You can interpolate all color indices between two endpoints
;	by defining the color first for one endpoint, and then 
;	for the other.  Move the mouse back to the cell of the first endpoint
;	and click the center button.  The colors between the two endpoints 
;	change to a smooth gradient between the two points.
;
;	Exit this procedure and save the colors by clicking the
;	right button.
;
;	The current color can be restored by clicking "Undo Current
;	Color".
;
;	All colors are restored to their entry values by clicking
;	"Undo All".
;
;	You can access the new color tables by declaring the common block
;	COLORS, as shown below (PALETTE sets both the original and current 
;	arrays):
;
;		COMMON COLORS, R_ORIG, G_ORIG, B_ORIG, R_CURR, G_CURR, B_CURR
;
;	Users of the Motif and OPEN LOOK window systems can use XPALETTE, 
;	a widgets version of PALETTE.
;
; MODIFICATION HISTORY:
;	DMS, September, 1988.
;
;       SNG, December, 1990.	Added support for DOS version, only supports
;                             	640 x 480 x 16 display mode.
;
;	SMR, March, 1991.	Fixed a bug where the existing IDL window was
;				used instead of creating a new window.
;-

common palette_common,nc, nc1, nc2, wxsize, wysize, $
	colors,  bars, rect, array, cell_size, c_array
common colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr

on_error,2              ;Return to caller if an error occurs
nc = !d.table_size	;# of colors avail
if nc eq 0 then message, "Device has static color tables.  Can't modify."

psave = !p		;Save !p
nc1 = nc -1
nc2 = nc1-1		;Current color
!p.noclip = 1		;No clipping
!p.color = nc1		;Foreground color
!p.font = 0		;Hdw font
if ((!d.flags and 256) EQ 256) then $
	old_window = !d.window	;Previous window
device,get_write=old_mask,set_write=255 ;Enable all bits

if n_elements(r_curr) eq 0 then begin
	r_orig = bytscl(indgen(nc)) & g_orig = r_orig & b_orig = r_orig
	r_curr = r_orig & g_curr = r_orig & b_curr = r_orig
	endif
wxsize = 300		;Window size
wysize = 220 + ((nc+15)/16) * 17
if ((!d.flags and 256) ne 0) then $
	window,xs=wxsize, ys=wysize, title='Palette',/free

tvcrs,.5,.5,/norm

restart:
palette_back
colors = fix( [[r_curr],[g_curr],[b_curr]])  ;n by 3 array
tvlct,colors(*,0),colors(*,1),colors(*,2) ;load current color tbl
curr_color = 0		;current color index
col = 0
csave = colors(0,*)
;		*** Main loop ***

next:
tvrdc,x,y,/dev		;read mouse with wait
if !err eq 4 then goto, done

next2:
for i=0,2 do if (y ge bars(i).y0) and (y le bars(i).y1) then begin
	a = bars(i)		;Bar struct
	v = fix(a.s(0) + a.s(1) * x) < a.maxv > a.minv	;data value
	if v eq a.value then goto, next3
	update_bar,i,v
	colors(curr_color,i) = v ;Save color value
	tvlct,colors(curr_color,0),colors(curr_color,1), $
		colors(curr_color,2),curr_color
next3:	tvrdc,x,y,/dev,0
	if (!err eq 1) then goto,next2
; Check for new color mark
endif else if (y gt c_array(3)) and (y lt c_array(2)) then begin
	xx = (x - c_array(0))/17
	yy = (c_array(2) - y)/17
	col = (xx + yy * 16) < nc1
	if col eq curr_color then goto,next3	;Same color?
	csave = colors(col,*)		;save current colors
	xyouts,rect(0,0),rect(1,0)-15,strtrim(curr_color,2),col=0,/dev
	xyouts,rect(0,0),rect(1,0)-15,strtrim(col,2),/dev
	polyfill,/dev,rect,col=col	;Fill upper corner rect
	for i=0,2 do update_bar,i,colors(col,i) ;new bars
	if (!err eq 2) then begin	;interpolate??
		i0 = col < curr_color
		i1 = col > curr_color
		kc = i1 - i0		;# to interpolate
		c = float(colors(i0,*))
		del = (colors(i1,*) - c)/(i1-i0) ;interp
		colors(i0,0) = findgen(kc) # del + $
		 (replicate(1,kc) # c)
		tvlct,colors(*,0),colors(*,1),colors(*,2)
		endif
	curr_color = col
	goto, next3
endif else if (y ge 30) and (y le 45) then begin
	print,' '
	print,'  Use left button to select a color index from the color grid.'
	print,'  Then vary the color by moving the mouse in the color slider'
	print,'bars with the left button depressed.'
	print,' Interpolate all color indices between two colors by defining'
	print,'the two end point colors. Then mark one endpoint cell with'
	print,'the left button and the other endpoint with the center button.'
	print,'  Right button saves the color tables and exits this procedure.'
	print,' '
	goto, next
endif else if (y le !d.y_ch_size + 5) then begin	;Undo current color?
	if (x lt wxsize/2) then begin	;undo color?
		colors(col,0) = csave	;yes
		for i=0,2 do update_bar,i,colors(col,i)
		tvlct,colors(col,0),colors(col,1), colors(col,2),curr_color
	endif else begin
		erase	;begin again
		goto, restart
	endelse
endif

goto,next


done:
	r_orig = (r_curr = colors(*,0))	;save in common block
        g_orig = (g_curr = colors(*,1))
        b_orig = (b_curr = colors(*,2))
        if ((!d.flags and 256) ne 0) then begin
          wdelete			;kill window
	  if old_window ge 0 then begin	;restore window?
		tvcrs,0.5,0.5,/norm	;show the table
		empty
		tvcrs			;hide cursor
		endif
device,set_write=old_mask		;Restore old write mask
        endif
!p = psave
end

