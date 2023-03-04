; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/cw_color_index.pro#1 $
;
; Copyright (c) 1993-2006, Research Systems, Inc.  All rights reserved.
;	Unauthorized reproduction prohibited.
;+
; NAME:	
;	CW_COLOR_INDEX
;
; PURPOSE:
;	CW_COLOR_INDEX is a compound widget for the selection of a color
;	index. A horizontal color bar is displayed. Clicking on the bar sets
;	the color index.
;
; CATEGORY:
;	Compound Widgets
;
; CALLING SEQUENCE:
;	Widget = CW_COLOR_INDEX(Parent)
;
; INPUTS:
;	Parent:	      ID of the parent widget.
;
; KEYWORD PARAMETERS:
;	COLOR_VALUES: A vector of color indices containing the colors to
;		      be displayed in the color bar. If omitted, NCOLORS
;		      and START_COLOR specify the range of color indices.
;	EVENT_FUNCT:  The name of an optional user-supplied event function.
;		      This function is called with the return value structure
;		      whenever a button is pressed, and follows the conventions ;		      for user-written event functions.
;	FRAME:        If set, a frame will be drawn around the widget.
;	LABEL:        A text label that appears to the left of the color bar.
;	NCOLORS:      The number of colors to place in the color bar.  
;		      The default = !D.N_COLORS.
;	START_COLOR:  The starting color index, placed at the left of the bar.
;	UVALUE:       The user value to be associated with the widget.
;	XSIZE:        The width of the color bar in pixels. The default =192.
;	YSIZE:        The height of the color bar in pixels. The default = 12.
;
; OUTPUTS:
;       The ID of the created widget is returned.
;
; SIDE EFFECTS:
;	This widget generates event structures with the following definition:
;
;	Event = { CW_COLOR_INDEX, ID: base, TOP: ev.top, HANDLER: 0L, VALUE: c}
;	Value is the color index selected.
;
; PROCEDURE:
;	Standard Compound widget.  Use WIDGET_CONTROL, SET_VALUE and GET_VALUE
;	to change/read the widget's value.
;
; EXAMPLE:
;	A = WIDGET_BASE(TITLE='Example', /COLUMN)
;	B = CW_COLOR_INDEX(A, LABEL='Color:')
;
; MODIFICATION HISTORY:
;	DMS,	June, 1993.	Written.
;	TAC,	Oct, 1993.	Name changed to CW_CLR_INDEX
;-

function CW_COLOR_INDEX, parent, _EXTRA=extra
;	this function name was changed to be unique within
;	the first eight characters.  This is necessary
;	for 8.3 files systems like Windows 3.1

	return, CW_CLR_INDEX (parent, _EXTRA=extra) 
end

