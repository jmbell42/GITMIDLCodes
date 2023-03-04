; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/pwidget.pro#1 $
;
; Copyright (c) 1993-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

pro list_draw, i0, i1, ERASE = erase	;Draw the annotations from the list
common pwidget_comm, pw, original, style, list

oldclip = !p.noclip
!p.noclip = 1

for i=i0, i1 do begin		;Each thing
	a = list(i)
	if keyword_set(erase) then c = !p.background else c = a.color
	p = convert_coord(a.params(0:1), a.params(2:3), norm = a.acoord eq 1, $
		data = a.acoord eq 0, /TO_NORM)
	boxx = [p(0,0), p(0,1), p(0,1), p(0,0), p(0,0)]
	boxy = [p(1,0), p(1,0), p(1,1), p(1,1), p(1,0)]
	case a.name of 
	'ARROW' : arrow, p(0,0), p(1,0), p(0,1), p(1,1), $
		THICK = a.params(4), color = c, /norm, /SOLID
	'BOX' : BEGIN
		if a.aback then polyfill, boxx, boxy, color=!p.background, $
			/NORM
		plots, boxx, boxy, thick = a.params(4), color = c, /norm
		ENDCASE
	'TEXT' : xyouts, p(0,0), p(1,0), a.text, /NORM, $
		chars = a.params(5), align = a.params(6), color = c
	'LEGEND': BEGIN
		x0 = min(boxx, max = x1)
		y0 = min(boxy, max = y1)
		if a.aback then polyfill, boxx, boxy, color=!p.background, $
			/NORM
		plots, boxx, boxy, thick = a.params(4), color = c, /norm
		dy = (y1-y0) / (pw.n(0)+1)	;Height
		dx = (x1-x0) / 20.
		for j=0, pw.n(0)-1 do begin	;Each annotation
		   y =  y0 + (j+1) * dy
		   if keyword_set(erase) then cc = !p.background $
			else cc = style(j).color		   
		   xyouts, x0+dx, y, /NORM, style(j).name, color = cc, $
			chars = a.params(5), width = s
		   plots, [ s + 2*dx, 19*dx]+x0, y, /NORM, $
			color = cc, lines = style(j).linestyle, $
			thick = style(j).thick
		   ENDFOR
		ENDCASE
	ENDCASE
ENDFOR
!p.noclip = oldclip
END



pro pw_redraw		;Redraw the entire thing
common pwidget_comm, pw, original, style, list

s = style(0)
if pw.n(0) eq 1 then $
	plot,	routine_names(pw.vnames(0), FETCH = pw.level), $
		routine_names(pw.vnames(1), FETCH = pw.level), $
		color=s.color, linestyle=s.linestyle, thick=s.thick, $
		psym=s.psym, symsize = s.symsize, xtype = !x.type, $
		ytype = !y.type $
else begin
	plot,	(routine_names(pw.vnames(0), FETCH = pw.level))(*,0), $
		(routine_names(pw.vnames(1), FETCH = pw.level))(*,0), $
		color=s.color, linestyle=s.linestyle, thick=s.thick, $
		psym=s.psym, symsize = s.symsize, xtype = !x.type, $
		ytype = !y.type 
	sx = pw.n(1) ne 1
	sy = pw.n(2) ne 1
	for i=1, pw.n(0)-1 do begin
	   s = style(i)
	   oplot, (routine_names(pw.vnames(0), FETCH = pw.level))(*,i*sx), $
		(routine_names(pw.vnames(1), FETCH = pw.level))(*,i*sy), $
		color=s.color, linestyle=s.linestyle, thick=s.thick, $
		psym=s.psym, symsize = s.symsize 
	endfor
endelse
list_draw, 0, pw.nlist-1		;Add extras

   p = pw.pwidgets			;Redraw axis text
   for i=0,1 do begin
	if i eq 0 then t = !x.range else t = !y.range
	if t(0) eq t(1) then begin
	   if i eq 0 then t = !x.crange else t = !y.crange
	   endif
	WIDGET_CONTROL, WIDGET_INFO(p(i+1),/CHILD), GET_UVALUE=x
	WIDGET_CONTROL, x.range(0), SET_VALUE=strtrim(t(0),2)
	WIDGET_CONTROL, x.range(1), SET_VALUE=strtrim(t(1),2)
	endfor

end

pro pw_set_line, new=new, name = name	;Set the elements of a line
common pwidget_comm, pw, original, style, list

if n_elements(new) ne 0 then begin
	pw.lindex = new
	s = style(new)
	widget_control, pw.lname, set_value=s.name
	widget_control, pw.color, set_value = s.color
	widget_control, pw.linestyle(s.linestyle), /SET_BUTTON
	widget_control, pw.thick(s.thick), /SET_BUTTON
	if s.psym ge 0 then j = s.psym else j = 8-s.psym
	widget_control, pw.psym(j), /SET_BUTTON
	endif
if n_elements(name) ne 0 then begin
	style(pw.lindex).name = name
	widget_control, pw.lbutton(pw.lindex), set_value=name
	endif
end


function row_buttons, base, label, choices, uvalues, EXCLUSIVE = exclusive, $
     NONEXCLUSIVE = nonexclusive, SET_BUTTON = set_index, NO_RELEASE = no_rel
; Make a row base with buttons.
; Default no_rel = 1.
a = widget_base(base, /row)
if strlen(label) gt 0 then b = widget_label(a, value= label)
b = widget_base(a, /row, exclusive = keyword_set(exclusive), $
	nonexclu = keyword_set(nonexclusive))
rslt = lonarr(n_elements(choices))
if n_elements(uvalues) le 0 then uvalues = choices
nuv1 = n_elements(uvalues)-1
if n_elements(no_rel) le 0 then no_rel = 1
for i=0,n_elements(choices)-1 do  $
  rslt(i) = widget_button(b, value=choices(i), $
	uvalue = uvalues(i < nuv1), $
	NO_REL = keyword_set(no_rel))
if n_elements(set_index) gt 0 then widget_control, rslt(set_index), /set_button
return, rslt
end



function CW_AXIS_WIDGETG, id		;Get the value of an axis widget
widget_control, widget_info(id, /child), get_uvalue=state
return, state
end


function CW_AXIS_WIDGET, parent, LABEL = label, FRAME = frame, $
	UVALUE = uvalue, name = name
if n_elements(frame) eq 0 then frame = 0
if n_elements(uvalue) eq 0 then uvalue = 0
if n_elements(label) eq 0 then label = ''

base = widget_base(parent, /COLUMN, FRAME = frame, $
	EVENT_FUNC = 'CW_AXIS_WIDGETE', FUNC_GET_VALUE = 'CW_AXIS_WIDGETG', $
	PRO_SET_VALUE = 'CW_AXIS_WIDGETS', UVALUE = uvalue)
state = { CW_AXIS_STATE, name : '', $
	type : lonarr(2),  title : 0L, style : lonarr(4), range : lonarr(2), $
	margin : lonarr(2), tmodes : lonarr(3), tbase: lonarr(3), $
	fixed:lonarr(3), ftick: fltarr(3) }

state.name = name
child = widget_label(base, value = label, xsize=75)
state.type = row_buttons(base, 'Scaling:', ['Linear', 'Logarithmic'], $
	'@C'+name + ['.type=0', '.type=1'], /exclu, set_button = uvalue.type)
state.style = row_buttons(base, 'Style:', $
	['Exact', 'Extend', 'Suppress', 'No Box'], $
	['style1','style2','style4','style8'], /NONEXC, NO_REL = 0)
for i=0,3 do if (uvalue.style and 2^i) ne 0 then $
	widget_control, state.style(i), /set_button
junk = widget_base(base, /row)
junk1 = widget_label(junk, value = 'Title:', xsize=75)
state.title = widget_text(junk, xsize = 24, ysize = 1, /edit, $
	uvalue="@S"+name+".TITLE=", value=uvalue.title, /FRAME)

junk = widget_base(base, /row)
junk1 = widget_label(junk, value = 'Range: ', xsize=75)
state.range = [ $
	widget_text(junk, xsize=12, ysize=1, /edit, $
		uvalue= "@Nwidget_control, s.range(1), /INPUT_FOCUS & " + $
		name+'.range(0)=',/FRAME, $
		value=strtrim(uvalue.range(0),2)), $
	widget_text(junk, xsize=12, ysize=1, /edit, $
		uvalue= "@Nwidget_control,s.range(0), /INPUT_FOCUS & " + $
		name+'.range(1)=', /FRAME, $
		value=strtrim(uvalue.range(1),2))]

junk = widget_base(base, /row)
junk1 = widget_label(junk, value = 'Margins: ', xsize=75)
state.margin = [ $
	widget_text(junk, xsize=12, ysize=1, /edit, $
	uvalue= "@N"+name+'.margin(0)=', /FRAME, $
		value = strtrim(uvalue.margin(0),2)), $
	widget_text(junk, xsize=12, ysize=1, /edit, $
	uvalue= "@N"+name+'.margin(1)=', /FRAME, $
		value = strtrim(uvalue.margin(1),2))]

base1 = widget_base(base, /column, /frame)
junk1 = widget_label(base1, value = 'Ticks')

state.tmodes = row_buttons(base1, 'Values:',  $
	['Auto','Fixed Increment'], /EXCLUSIVE, SET=0)
if uvalue.tickv(0) eq uvalue.tickv(1) then i = 0 else i = 2  ;Button to select?
widget_control, state.tmodes(i), /SET_BUTTON

state.tbase(0) = (junk = widget_base(base1, /ROW))
for i=0,2 do begin
	junk1 = widget_label(junk, value=(['From:', 'To:', 'Incr:'])(i))
	if i eq 2 then begin
	  x = uvalue.range(1) - uvalue.range(0)
	  if x eq 0. then x = 1 else x = x/5
	endif else x = uvalue.range(i)
	state.ftick(i) = x
	state.fixed(i) = widget_text(junk, xsize=9, ysize = 1, /edit, $
		uvalue='F0', /FRAME, value=strtrim(x,2))
	ENDFOR

state.tbase(1) = (junk = widget_base(base1, /COLUMN))
for j=0,1 do if (j+1) ne i then widget_control, state.tbase(j), map=0
widget_control, child, set_uvalue = state
return, base
end


function get_numeric_widget, str, id, FLOAT=flt, $ 	;Get a numeric value
	MINV = minv, MAXV = maxv
on_ioerror, bad
msg = "Non-numeric value entered"
again: str = strtrim(str,2)
if keyword_set(flt) then f = float(str) else f = long(str)
if n_elements(minv) gt 0 then if f lt minv then begin
	msg = "Value is below minimum of "+strtrim(minv,2)
	goto, bad
	endif
if n_elements(maxv) gt 0 then if f gt maxv then begin
	msg = "Value is above maximum of "+strtrim(maxv,2)
	goto, bad
	endif
	
return, f
bad:	a= widget_base(/column, TITLE="ERROR")
	b = widget_label(a, value = msg)
	b = widget_label(a, value = "Enter the correct value: ")
	widget_control, a, /real
	junk = widget_event(id)
	widget_control, id, get_value=str
	str = str(0)
	widget_control, id, set_value = str
	widget_control, a, /destroy
	goto, again	
end


pro pw_set, id, uval, s 	;Set a variable or execute a command
common pwidget_comm, pw, original, style, list


i = pw.lindex
case strmid(uval,1,1) of
'N':	BEGIN		;Read numeric value from text widget
	widget_control, id, get_value = value
	a = get_numeric_widget(value(0), id, /FLOAT)
	k = execute(strmid(uval, 2, 100) + 'a')
	ENDCASE
'S':	BEGIN		;Read string value from text widget
	widget_control, id, get_value = value
	value = strtrim(value(0),2)
	k = execute(strmid(uval, 2,100) + 'value')
	ENDCASE
'C':	BEGIN		;Execute uvalue
	k = execute(strmid(uval, 2,100))
	ENDCASE
ENDCASE
end

function CW_AXIS_WIDGETE, ev
base = ev.handler
id = ev.id
widget_control, (c  = widget_info(base, /child)), get_uvalue = state
widget_control, id, get_uvalue = uval

;print, uval

if strmid(uval,0,1) eq '@' then pw_set, id, uval, state $
ELSE if strpos(uval, 'style') eq 0 then begin
	  j = strmid(uval,5,1)		;Bit value
	  if ev.select ne 0 then op = ' or ' else op = ' and  not '
	  k = state.name + '.style =' + state.name + ".style" + op + j
	  k = execute(k)
ENDIF   ELSE case uval of
"Auto": BEGIN
	for i=0,1 do widget_control, state.tbase(i), map = 0
	k = execute(state.name + '.tickv = 0. & ' + state.name + '.ticks=0')
	ENDCASE
"F0":	BEGIN		;Fixed increment widget
	i = (where(id eq state.fixed))(0)	;Index number
	widget_control, id, get_value = value
	state.ftick(i) = get_numeric_widget(value(0), id, /FLOAT)
	widget_control, c, set_uvalue = state	;Save value
	widget_control, state.fixed((i+1) mod 3), /INPUT_FOCUS
	goto, do_fixed
	ENDCASE
"Fixed Increment": BEGIN
	for i=0,1 do widget_control, state.tbase(i), map=1-i
do_fixed:
	a = state.ftick
	if a(2) le 0.0 then return, 0
	n = long((a(1)-a(0))/a(2)+.001)		;# of ticks
	if (n lt 1) or (n gt 29) then return,0
	b = findgen(n+1)*a(2) + a(0)
	k = execute(state.name + '.TICKV = b & ' + state.name + '.TICKS = n')
	k = execute(state.name + '.RANGE = a(0:1)')
	ENDCASE
else : print,'No match'	
endcase
pw_redraw
return, 0
end



function pwidget_b_button, a
;Return a 1 bit deep bitmap given a byte image.
;width of image MUST be a multiple of 8.
s = size(a)
b = bytarr(s(1)/8, s(2))
if (s(1) and 7) ne 0 then $
	message, 'PWIDGET_B_BUTTON: image width must be a multiple of 8.'
subs = lindgen(n_elements(b)) * 8
for ibit = 0,7 do b = b or byte(2^ibit) * (a(subs+ibit) ne 0b)
return, reverse(b,2)
end

			;Make charsize buttons
function charsize_but, base, width, e_string, SET_INDEX = set
b = widget_base(base, /row)	;CHARSIZE
junk = widget_label(b, value='Char Size:', xsize=70)
b = widget_base(b, /row, /exclusive)
ct = [.75, 1, 1.5, 2., 3.]
n = n_elements(ct)
window, /free, /pixmap, xsize = width, ysize=16
buttons = lonarr(n)
if n_elements(set) eq 0 then set = -1
for i=0,n-1 do begin
	erase, 0
	xyouts, width/2, 0, /dev, ali=0.5, 'Abc', CHARS = ct(i), $
		col=!d.n_colors-1
	buttons(i) = widget_button(b, value = pwidget_b_button(tvrd()), $
			uvalue = e_string+strtrim(ct(i),2), /NO_REL)
	if (ct(i) eq !p.charsize) or (i eq set) then $
		widget_control, buttons(i), /SET_BUTTON
	endfor
wdelete
return, buttons
end




pro zoom_drag, release, x, y		;Zoom or drag main window
;	Release = button that was released.
common pwidget_comm, pw, original, style, list


redraw = 0
if release eq 2 then begin   ;Done zooming?
  pw.r_prev = [ !x.range, !y.range]
  p0 = convert_coord([pw.boxx(0), pw.boxy(0)], /TO_DATA, /DEV)
  p1 = convert_coord([pw.boxx(2), pw.boxy(2)], /TO_DATA, /DEV)
  if pw.xmx(0) lt pw.xmx(1) then $
	!x.range = [p0(0) < p1(0), p0(0) > p1(0)] $
  else !x.range = [p0(0) > p1(0), p0(0) < p1(0)]
  if pw.ymx(0) lt pw.ymx(1) then $
	!y.range = [p0(1)< p1(1), p0(1)> p1(1)] $
  else !y.range = [p0(1) > p1(1), p0(1) < p1(1)]
  redraw = 1
endif		;middle
if release eq 1 then begin	;Drag
  pw.r_prev = [ !x.range, !y.range ]
  dx = (pw.boxx(0) - x)/!x.s(1)/!d.x_size
  dy = (pw.boxy(0) - y)/!y.s(1)/!d.y_size
  !x.range = !x.range + dx
  !y.range = !y.range + dy
  redraw = 1
endif

if redraw then begin	;Update text windows
   pw_redraw
   endif
end


pro pwidget_events, ev
common pwidget_comm, pw, original, style, list


id = ev.id

wset, pw.window
if id eq pw.draw then BEGIN		;Mouse or motion?
		; Box is true for drawing a box. Box or line mode?
	if pw.mode eq 4 then box = (pw.amode eq 1) or (pw.amode eq 3)  $
	else box = (pw.button or ev.press) eq 2

	if (ev.press eq 0) and (ev.release eq 0) then begin ;No button chg?
		p = convert_coord([ev.x, ev.y], /TO_DATA, /DEV)
		WIDGET_CONTROL, pw.txt, set_value= 'X,Y = ' + $
			strtrim(p(0),2) + ', ' + strtrim(p(1),2)
	endif

	if pw.button ne 0 then begin	;Dragging?
		device, set_graphics=6	;XOR writing mode
		if !d.name eq 'X' then device, /bypass
			;True if a single point
		point = pw.boxx(0) eq pw.boxx(1) and pw.boxy(1) eq pw.boxy(2)
		if not point then begin
		   if box then plots,pw.boxx, pw.boxy, /dev, $;Erase old
			thick=1, lines=0, color=pw.xor_color $
		   else plots, pw.boxx(0:1), pw.boxy(1:2), /dev, $;Erase old
			thick=1, lines=0, color=pw.xor_color
		endif
		pw.boxx([1,2]) = ev.x
		pw.boxy([2,3]) = ev.y
		if ev.release eq 0 then begin	;Draw again?
		  if box then plots,pw.boxx, pw.boxy, /dev, $ ;Draw new
			thick=1, lines=0, color=pw.xor_color $
		  else plots, pw.boxx(0:1), pw.boxy(1:2), /dev, $ ;Draw new
				thick=1, lines=0, color=pw.xor_color
		endif				;Release
		device, set_graphics=3
		if !d.name eq 'X' then device, bypass=0
	endif			;Dragging

	if ev.press ne 0 then begin	;Button down?
		pw.button = pw.button or ev.press
		pw.boxx = replicate(ev.x,5)
		pw.boxy = replicate(ev.y,5)
	endif				;Press

	if ev.release ne 0 then begin	;Done with motion?
		pw.button = pw.button and (not ev.release)
		if pw.mode ne 3 then zoom_drag, ev.release, ev.x, ev.y $
		else begin		;Annotation...
		  if pw.nlist ge n_elements(list)-1 then begin
			print,'List Full'
			return
			endif
		  names = ['ARROW', 'BOX', 'TEXT', 'LEGEND']
		  p = convert_coord(pw.boxx(0:1), pw.boxy([0,2]), /device, $
			to_normal = pw.acoord eq 1, to_data = pw.acoord eq 0)
		  widget_control,  pw.atext, get_value = s
		  list(pw.nlist) =  { PW_LIST, names(pw.amode), s(0), $
			pw.acolor, pw.acoord, pw.aback, $
			[p(0,0), p(0,1), p(1,0), p(1,1), $
				pw.athick, pw.atextsize, pw.atextal]}
		  list_draw, pw.nlist, pw.nlist
		  pw.nlist = pw.nlist + 1
		  endelse			;Annotation
	endif			;Release

	return
ENDIF			;Button / motion event

redraw = 0		;True to redraw
WIDGET_CONTROL, id, get_uvalue = uval

;print, uval
if strmid(uval, 0,1) eq '@' then begin
	pw_set, id, uval, pw
	redraw = 1
ENDIF ELSE if strmid(uval, 0,1) eq '#' then begin
	pw_set, id, uval, pw
ENDIF ELSE if strmid(uval, 0, 6) eq 'PRINT_' then begin	;Print
	name = strmid(uval, 6,100)
	a = widget_base(TITLE = 'Working:')
	b = widget_label(a, value = 'Creating a Plot file for: ' + name) 
	widget_control, a, /realize
	olddev	= !D.NAME
	t0 = systime(1)
	if name eq 'EPS' then begin
		set_plot, 'PS'
		device, encap = 1
	endif else set_plot, name, /COPY
	pw_redraw
;;;;	device, /close
	set_plot, olddev, /COPY
	t0 = 3 - (systime(1) - t0)	;Show message for 3 secs
	if t0 gt 0 then wait, t0
	widget_control, a, /destroy
ENDIF ELSE CASE uval of
"EXIT":   widget_control, ev.top, /destroy
"UNDO": if pw.nlist gt 0 then begin
		pw.nlist = pw.nlist -1
		list_draw, pw.nlist, pw.nlist, /ERASE
		endif
"MODE": BEGIN
	i = (where(id eq pw.mode_buttons))(0)
	if i eq pw.mode then return
	widget_control, pw.pwidgets(pw.mode), map = 0
	pw.mode = i
	widget_control, pw.pwidgets(pw.mode), map = 1
	redraw = 0
	ENDCASE
"RESET_SCL": BEGIN
	!x.range = pw.xmx
	!y.range = pw.ymx
	!x.type = 0
	!y.type = 0
	redraw = 1
	ENDCASE
"RESET_ANN": BEGIN
	pw.nlist = 0
	redraw = 1
	ENDCASE
"RESET_REDRAW": redraw = 1
"RESET_ALL": BEGIN
	!x = original.x
	!y = original.y
	!p = original.p
	pw.nlist = 0
	redraw = 1
	ENDCASE
"COLOR":  tek_color
"BW":	BEGIN
	c = bytscl([0, 15-indgen(15)])
	tvlct,c,c,c
	ENDCASE
    "HELP": BEGIN
;	xdisplayfile, 'pwidget.txt', $	;Debugging
	xdisplayfile, filepath("pwidget.txt", subdir=['help', 'widget']), $  ;Working
		title = "Pwidget Help", $
		group = ev.top, $
		width = 72, height = 24
	ENDCASE
"HIDE": BEGIN
	widget_control, pw.main, map=0
	window, xs= !d.x_size, ys=!d.y_size, /free, title=!p.title
	pw_redraw
	a = widget_base(title='PWIDGET')
	b = widget_button(a, value = 'Click to Resume')
	widget_control, a, /real
	b = widget_event(a)
	widget_control, a, /destroy
	wdelete, !d.window
	widget_control, pw.main, map=1
	ENDCASE	
else:	BEGIN
	print,'No match'
	ENDCASE
endcase
if redraw then pw_redraw
end



PRO PWIDGET, GROUP = group, x, y, SAVE = save, WINDOW_SIZE = w_size, $
	RESTORE = restore
;+NODOCUMENT
;-
common pwidget_comm, pw, original, style, list

if XRegistered("pwidget") THEN RETURN
if n_elements(w_size) lt 2 then begin	;Use default window size?
	device, get_screen = w_size
	w_size = (w_size(0) * [5, 4]) / 9
	endif

original = { PW_SAVE, x: !X, y: !Y, p: !P}

maxv = 8			;Maximum # of independent vects

pw = { PW_STRUCTURE, $
	main : 0L, $			;Main base
	level : 0, $			;Routine level
	n  : [0,0,0], $			;# of vectors x,y, total
	lindex : 0, $			;Current line index
	vnames : strarr(2), $		;Names of xy vars
	mode : 0, $			;Main mode
	amode : 0, $			;Annotation mode
	mode_buttons : lonarr(5), $	;mode buttons
	pwidgets : lonarr(5), $		;Main bases
	background:0L, $		;background widget
	charsize:lonarr(5), $		;charsize widget
	color:0L, $			;color widget
	draw:0L, $			;Draw widget
	window: 0, $			;Window index
	linestyle: lonarr(6), $		;Linestyle buttons
	subtitle: 0L, $			;subtitle widget
	title: 0L, $			;title widget
	psym : lonarr(16), $		;psym buttons
	thick: lonarr(7), $		;thick buttons
	ticklen : lonarr(3), $		;ticklen buttons
	lname : 0L, $			;Line name widget
	lbutton : lonarr(10), $		;Line name buttons
	msize : lonarr(4), $		;Psymsize buttons
	atext : 0L, $			;Annotation text widget
	atextsize : 1.0, $		;Annotation text size
	atextal : 0.0, $		;Annotation text alignment
	athick : 1.0, $			;Line thickness
	acolor : 1, $			;Line color
	acoord : 0, $			;0 = data coords, 1 = norm
	aback : 0, $			;=1 to erase box background	
	nlist : 0, $			;# of items in list
	xmx:fltarr(2), $
	ymx: fltarr(2), $
	txt : 0L, $
	button : 0, $
	xor_color : 0, $
	boxx : fltarr(5), boxy: fltarr(5), r_prev : fltarr(4) }

col = 1			;Default color = white = 1

style = replicate({ PW_STYLE_STRUCT, $	;Attributes for each line
		color : col, $
		linestyle : !p.linestyle, $
		thick : !p.thick, $
		psym  : !p.psym, $
		symsize : !p.symsize, $
		name : ''}, maxv)

style.name = 'LINE '+	strtrim(sindgen(maxv),2)

; Params(0:1) = x0, x1
; Params(2:3) = y0, y1
list = { PW_LIST, name: '', text: '', color: 0L, acoord: 0, aback:0, $
	params : fltarr(7)}
list = replicate(list,30)

sx = size(x)
if sx(0) eq 2 then nx = sx(2) else nx = 1
pw.xmx = [min(x, max=x1), x1]	;Get range

if n_elements(y) gt 0 then begin
	sy = size(y)
	if sy(0) eq 2 then ny = sy(2) else ny = 1
	if nx eq 1 then n = ny else if ny eq 1 then n = nx else n = nx < ny
	pw.ymx = [min(y, max=x1), x1]
	pw.n = [n, nx, ny]
	pw.vnames = ['X','Y']
endif else begin
	pw.ymx = pw.xmx
	pw.xmx = [0, sx(1)-1]
	pw.vnames = ['XX','X']
	pw.n = [nx,1,nx]
	xx = findgen(sx(1))
endelse

!x.range = pw.xmx			;Current ranges
!y.range = pw.ymx




if n_elements(restore) gt 0 then begin
	!x = restore.x
	!y = restore.y
	!p = restore.p
	list = restore.list
	style = restore.style
	pw = restore.pw
	endif
pw.level = ROUTINE_NAMES(/LEVEL)


pw.mode = 0


base_names = [ 'General', 'X Axis', 'Y Axis', 'Annotation']
pw.main = widget_base(title='Pwidget',/ROW)
mainl = widget_base(pw.main, /COLUMN)		;Left side
pw.draw = widget_draw(pw.main, XSIZE = w_size(0), YSIZE = w_size(1), $
	RETAIN=2, /BUTTON_EVENTS, /MOTION_EVENTS)

XPdMenu, [	'" Done "			EXIT', $
		'" Reset " {' , $
		'" All "		RESET_ALL',$
		'" Annotation "		RESET_ANN',$
		'" Redraw "		RESET_REDRAW', $
		'" Scaling "		RESET_SCL',$
		'}', $
		'" Help "			HELP', $
		'" Print " {', $
		'" PostScript "		PRINT_PS',$
		'" Encapsulated PostScript "		PRINT_EPS',$
		'" HPGL "		PRINT_HP',$
		'" Dec LJ-250 "		PRINT_LJ',$
		'" HP PCL "		PRINT_PCL',$
		'" CGM "		PRINT_CGM',$
		'}', $
		'"Hide Controls"	HIDE' $
	],  mainl

pw.mode_buttons = row_buttons(mainl, '', base_names, "MODE", /EXCLU, /NO_REL)
junk1 = row_buttons(mainl, '', ["Color", "Black & White"], /EXCLU, $
	["COLOR", "BW"], SET_BUTTON = 0)

cbase = widget_base(mainl)		;Will contain multi-modes

pw.pwidgets(0) = (a = widget_base(cbase, /column))	;General widget

a = widget_base(a, /column, /frame)	;Top box
b = widget_base(a, /row)
junk = widget_label(b, value='Title:', xsize=75)
pw.title = widget_text(b, xsize=32, ysize=1, value=!p.title, $
	/EDIT, /FRAME, $
	uvalue = '@SWidget_control, s.subtitle, /INPUT_FOCUS & !P.TITLE=')
b = widget_base(a, /row)
junk = widget_label(b, value='Sub-title:', xsize=75)
pw.subtitle = widget_text(b, xsize=32, ysize=1, value=!p.subtitle, $
	/EDIT, /FRAME, $
	uvalue = '@SWidget_control, s.title, /INPUT_FOCUS & !P.SUBTITLE=')

b = widget_base(a,/row)
junk = widget_label(b, value='Nsum:', xsize = 75)
junk1 = widget_text(b, xsize=4, ysize=1, value=strtrim(!p.nsum,2), $
	/EDIT, /FRAME, uvalue = '@N!P.NSUM=')

pw.ticklen = row_buttons(b, "Tick Style:", ['In', 'Out', 'Grid'], $
	"@C!P.TICKLEN="+ ['0.02', '-0.02', '1.0'], /EXCLU)
if !p.ticklen lt 0.0 then i = 1 else if !p.ticklen gt .5 then i = 2 else i = 0
widget_control, pw.ticklen(i), /set_button

pw.background = CW_COLOR_INDEX(a, label = 'Bkgd ', $
	uvalue = '@N!P.BACKGROUND=', NCOLORS = 16)

tek_color
width = 32


pw.charsize = charsize_but(a, width, '@C!P.CHARSIZE=', SET=1)


window, /free, /pixmap, xsize = width, ysize=16

a = widget_base(pw.pwidgets(0), /frame, /column)
n = pw.n(0)		;Extra plots
if n gt 1 then pw.lbutton = $
	row_buttons(a, 'Line Select:', style(0:n-1).name, $
		'#Cpw_set_line, NEW='+strtrim(indgen(n),2), /NO_REL, $
		SET = 0, /EXCLUSIVE)

junk = widget_base(a,/row)
junk1 = widget_label(junk ,value = 'Name:', xsize=70)
pw.lname = widget_text(junk, xsize=12, ysize=1, value=style(0).name, $
	uvalue = '@Spw_set_line, NAME=', /EDIT, /FRAME)

pw.color = CW_COLOR_INDEX(a, label = 'Color', NCOLORS = 16, $
	uvalue = '@Nstyle(i).color=')

b = widget_base(a, /row)	;LINESTYLES
junk = widget_label(b, value='Linestyle:',xsize=70)
b = widget_base(b, /row, /exclusive)
for i=0,5 do begin
	erase, 0
	plots, [0,width-1], [8,8], /dev, lines = i, thick=1, col=col
	pw.linestyle(i) = widget_button(b, value = pwidget_b_button(tvrd()), $
		uvalue = '@Cstyle(i).linestyle='+strtrim(i,2), /NO_REL)
	if i eq !p.linestyle then widget_control, pw.linestyle(i), /SET_BUTTON
	endfor


b = widget_base(a, /row)	;THICKNESS
junk = widget_label(b, value='Thickness:', xsize=70)
b = widget_base(b, /row, /exclusive)
for i=1,6 do begin
	erase, 0
	plots, [0,width-1], [8,8], /dev, thick = i, lines=0, col=col
	pw.thick(i) = widget_button(b, value = pwidget_b_button(tvrd()), $
			uvalue = '@Cstyle(i).thick='+strtrim(i,2), /NO_REL)
	if abs(i - !p.thick) lt .5 then widget_control, pw.thick(i), $
			/SET_BUTTON
	endfor
pw.thick(0) = pw.thick(1)

width = 24
b = widget_base(a, /row)	;PSYM
junk = widget_label(b, value='Marker:', xsize=70)
b = widget_base(b, column = 8, /exclusive)
wdelete
window, /free, /pixmap, xsize = width, ysize=16
for j=-1,1,2 do for i=0,7 do begin
	erase,0
	plots, [width/4, 3*width/4], [8,8], /dev, psym=i * j, thick=1, $
		lines=0, col=col
	k = (j+1)*4+i
	pw.psym(k) = widget_button(b, value = pwidget_b_button(tvrd()), $
			uvalue = '@Cstyle(i).psym='+strtrim(i*j,2), /NO_REL)
	if (i*j) eq !p.psym then widget_control, pw.psym(k), /SET_BUTTON
	endfor

width = 32
b = widget_base(a, /row)	;Marker size
junk = widget_label(b, value='Marker Size:', xsize=70)
b = widget_base(b, /ROW, /exclusive)
wdelete
window, /free, /pixmap, xsize = width, ysize=16
sym_sizes = [ .5, 1., 1.5, 2.0 ]
for i=0,3 do begin
	erase,0
	plots, [width/4, 3*width/4], [8,8], /dev, psym=-4, thick=1, $
		lines=0, col=col, symsize=sym_sizes(i)
	pw.msize(i) = widget_button(b, value = pwidget_b_button(tvrd()), $
		   uvalue = '@Cstyle(i).symsize='+strtrim(sym_sizes(i),2), $
		   /NO_REL)
	endfor

wdelete


pw.pwidgets(1) = cw_axis_widget(cbase, /frame, label = "X Axis", uvalue = !X, $
	name = '!X')
pw.pwidgets(2) = cw_axis_widget(cbase, /frame, label = "Y Axis", uvalue = !Y, $
	name = '!Y')
; pw.pwidgets(3) = cw_axis_widget(cbase, /frame, label = "Z Axis", $
;	uvalue = !Z, name = '!Z')

				;Annotation base
pw.pwidgets(3)= (a = widget_base(cbase, /column, /FRAME))
junk = widget_base(a, /ROW)
junk1 = row_buttons(junk, '',  ['Arrow', 'Box', 'Text', 'Legend'],$
	"#Cpw.amode="+strtrim(indgen(4),2), /EXCLUSIVE, SET_BUTT=0)
junk1 = widget_button(junk, value='Undo', /NO_REL, uvalue = 'UNDO')

junk = row_buttons(a, 'Coordinates:', ['Data', 'Relative'], $
	['#Cpw.acoord=0', '#Cpw.acoord=1'], /EXCLUSIVE, SET_BUTT=0)
junk = row_buttons(a, 'Box background:', ['Transparent','Erase'], $
	['#Cpw.aback=0', '#Cpw.aback=1'], /EXCLUSIVE, SET_BUTT=0)

junk = widget_base(a, /ROW)
junk1 = widget_label(junk, xsize=70, value='Text:')
pw.atext = widget_text(junk, xsize=28, ysize=1, $
		uvalue = '#Ci=0', /FRAME, /EDIT)  ;Do nothing 

a_color = CW_COLOR_INDEX(a, label = 'Color ', uvalue = '#Npw.acolor=', NCOLORS=16)


width = 32
window, /free, /pixmap, xsize = width, ysize=16
b = widget_base(a, /row)	;THICKNESS
junk = widget_label(b, value='Thickness:', xsize=70)
b = widget_base(b, /row, /exclusive)
for i=1,6 do begin
	erase, 0
	plots, [0,width-1], [8,8], /dev, thick = i, lines=0, col=col
	pw.thick(i) = widget_button(b, value = pwidget_b_button(tvrd()), $
			uvalue = '#Cpw.athick='+strtrim(i,2), /NO_REL)
	if i eq 1 then widget_control, pw.thick(i), /SET_BUTTON
	endfor
widget_control, pw.thick(1), /SET_BUTTON
wdelete

junk = charsize_but(a, 32, '#Cpw.atextsize=', set = 1)

junk = row_buttons(a, "Text Alignment:", $
	['Left', 'Centered', 'Right'], $
	["#Cpw.atextal = 0", "#Cpw.atextal = .5", "#Cpw.atextal = 1"], $
	/EXCLUSIVE, SET_BUTTON = 0)

pw.txt = WIDGET_TEXT(mainl, ysize = 1, xsize = 24, /frame)
 

widget_control, pw.main,/real
widget_control, pw.color, set_value = !p.color
widget_control, a_color, set_value = !p.color
widget_control, pw.background, set_value = !p.background
widget_control, pw.draw, get_value = i
pw.window = i
for i=1,n_elements(base_names)-1 do widget_control, pw.pwidgets(i), map=0
pw_redraw

if !d.name eq 'X' then begin	;Tricky for X windows.
    device, translation = i	;Get the translations
    pw.xor_color = i(0) xor i(!d.n_colors-1)
    i = 0			;Clean up
endif else pw.xor_color = !d.n_colors-1

xmanager, "pwidget", pw.main, EVENT_HANDLER = 'pwidget_events', GROUP = group
if n_elements(save) ne 0 then $
	save = { PW_SAVE_STRUCT, pw: pw, style: style, list: list, $
		x: !X, y: !Y, p: !P}
!x = original.x
!y = original.y
!p = original.p


end
