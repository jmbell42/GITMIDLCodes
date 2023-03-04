; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/menus.pro#1 $
;
; Copyright (c) 1987-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

function menus, fcn, choices, help_str
;+
; NAME:
;	MENUS
;
; PURPOSE:
;	Implement a crude menu facility using character strings
;	at the bottom of an IDL window.  The mouse can be used to select
;	the different menu items.
;
; CATEGORY:
;	??
;
; CALLING SEQUENCE:
;	Result = MENUS(Fcn, Choices, Help_Str)
;
; INPUTS:
;	Fcn:	A flag that tells MENUS to either create the menu or allow 
;		a selection from the menu.  Set Fcn to 0 to draw the original 
;		choices, drawn on bottom of window.  Set Fcn to 1 to select a 
;		choice, and to "unhighlight" the previous choice.
;
;     Choices:	A string array containing the text for each choice.
;
;    Help_str:	A string array with the same number of elements as Choices.  
;		Help text is displayed on top of the window if the 
;		corresponding choice is made.
;
; OUTPUTS:
;	MENUS returns the subscript corresponding to the selected Choice, 
;	from 0 to the number of elements in Choice -1.  If the right button 
;	is pressed, -1 is returned to indicate done.
;
; COMMON BLOCKS:
;	MENU_COMMON
;
; SIDE EFFECTS:
;	Text is written on the display.
;
; RESTRICTIONS:
;	This simple menu-creation utility is quite crude.  X Windows users 
;	can create much better user interfaces with the IDL Widgets.  See the 
;	WIDGETLIB for details.
;
; PROCEDURE:
;	Make menu, allow selections, and exit.
;
; MODIFICATION HISTORY:
;	DMS, December, 1987.
;	DMS, April, 1989.  Added wait for button debouncing
;-
;

common menu_common, isel

on_error,2                             ;Return to caller if an error occurs
nst = n_elements(choices)
nst1 = 1./nst
ych =  1.0 * !d.y_ch_size / !d.y_vsize ;Char ht in normal units
boxx = [0.,0.,nst1-0.05,nst1-0.05]	;Box for highlight
boxy = [0.,ych,ych,0.]

case fcn of
	;	Output original choices....
0:	begin
	for i=0,nst-1 do xyouts,i*nst1, 0., choices(i),/norm,/noclip
	isel = -1
	return,0
	end

1:	begin
	if isel ge 0 then begin		;Remove old choice
	  xyouts,0,1.0-ych,help_str(isel),/norm,col=0,/noclip ;remove instr
	  polyfill,(isel * nst1) + boxx,boxy,col=0,/norm ;remove name highl
	  xyouts,isel*nst1,0,choices(isel),/norm,col=255,/noclip ;Redraw name
	  endif	
;
	isel = -1
	y = 1000
	repeat tvrdc,x,y,0,/norm until !err eq 0  ;Wait for no buttons
	!err = 0
	while (y gt ych) and (!err ne 4) do $  ;Button hit on bottom or rt but
	   tvrdc,x,y,/norm
	if (!err eq 4) then return,-1
	minx = 1000
	for i=0,nst-1 do if ((c = abs(x-(i*nst1)))) lt minx then begin
		minx = c & isel = i
		endif
	polyfill,(isel * nst1) + boxx,boxy,col=255,/norm	;highlight name
	xyouts,0,1.0-ych,help_str(isel),/norm,/nocl	;instructions
	xyouts,isel * nst1,0,choices(isel),/norm,col=0,/noclip
	return,isel
	end
else: message, 'Illegal function code'
endcase
end
