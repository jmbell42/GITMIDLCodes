; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/wmenu.pro#1 $
;
; Copyright (c) 1993-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

; This is the code for a simple non-exclusive menu widget.
; The menu contains a list of colors.  When a button is
; pushed in (selected), the message, "Color selected." 
; is printed in the IDL window.  When a button that has
; been previously pushed in is de-selected, the message
; "Color de-selected." is printed in the IDL window.

; Non-exclusive menus are lists of buttons in which any
; number of buttons can be selected at the same time.

; For an example of an exclusive menu, see the routine
; WEXCLUS.PRO.




PRO wmenu_event, event
; This procedure is the event handler for a non-exclusive menu widget.

; Use WIDGET_CONTROL to get the VALUE of any action and put it into 'value':

WIDGET_CONTROL, event.id, GET_VALUE = value

; When a widget event occurs, an event structure is returned.
; Part of that structure is a 'select' field that is equal to 
; 1 if a button was selected or 0 if the button was de-selected.
; For Menu items, any VALUE returned will be the text of the menu item.
; Therefore, we can just print out the words as they are selected.

IF (event.select EQ 1) THEN PRINT, value, ' selected.' $
	ELSE PRINT, value, ' de-selected.'

END



PRO wmenu, GROUP = GROUP
; This procedure creates a non-exclusive menu widget.

; Make the top-level base widget:

base = WIDGET_BASE(TITLE = 'Non-Exclusive Menu Example', /COLUMN, XSIZE = 300)

; Make 'items' a 1-dimensional text array containing the menu items:

items = ['Red','Orange','Yellow','Green','Blue','Indigo','Violet']

; The XMENU procedure will automatically create the menu items for us.
; We only have to give it the menu item labels (in the array 'items')
; and, optionally, the base to which the menu belongs (here we use 'base',
; the top-level base widget).  The /NONEXCLUSIVE keyword makes the 
; menu non-exclusive:

XMENU, items, base, /NONEXCLUSIVE	

; Realize the widgets:
WIDGET_CONTROL, base, /REALIZE

; Hand off to the XMANAGER:
XMANAGER, 'wmenu', base, GROUP_LEADER = GROUP

END
