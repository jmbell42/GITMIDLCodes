; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/utilities/xpcolor.pro#1 $
;
; Copyright (c) 1993-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;       XPCOLOR
;
; PURPOSE:
;	The primary purpose of this routine is to serve as an example for
;	the Widgets chapter of the IDL User's Guide.
;
;	XPCOLOR allows the user to adjust the value of the current foreground
;	plotting color, !P.COLOR. For a more flexible color editor,
;	try the XPALETTE User Library Procedure.
;
; CATEGORY:
;       Color tables, widgets.
;
; CALLING SEQUENCE:
;       XPCOLOR
;
; INPUTS:
;       No explicit inputs.  The current color table and the value of !P.COLOR
;	are used.
;
; KEYWORD PARAMETERS:
;       GROUP - Group leader, as passed to XMANAGER.
;
; OUTPUTS:
;       None.
;
; COMMON BLOCKS:
;       COLORS: Contains the current RGB color tables.
;
; SIDE EFFECTS:
;       The new plotting foreground color is saved in the COLORS common
;	and loaded to the display.
;
; PROCEDURE:
;       Three sliders (R, G, and B) allow the user to modify the 
;       current color.
;
; MODIFICATION HISTORY:
;	20 October 1993, AB, RSI
;-

PRO xpcolor_event, ev

  COMMON colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr

  WIDGET_CONTROL, GET_UVALUE=type, ev.id
  IF (type EQ 0) THEN BEGIN
    IF (ev.value EQ 0) THEN WIDGET_CONTROL, /DESTROY, ev.top $
    ELSE XDISPLAYFILE,TITLE='XPcolor Help',GROUP=ev.top, HEIGHT=10,WIDTH=60, $
	TEXT = ['This is the XPCOLOR demo program which appears in.', $
		'the IDL User''s Guide near the end of the Widgets Chapter', $
                '', 'It allows you to change the plotting color used by IDL', $
	        'by using the sliders at the bottom of the control panel.', $
                'When you''re finished, press the "Done" button', $
		'', 'For a more full featured color editor, try XPALETTE' ]
  ENDIF ELSE BEGIN
    r_curr[!P.COLOR] = ev.r
    g_curr[!P.COLOR] = ev.g
    b_curr[!P.COLOR] = ev.b
    TVLCT, ev.r, ev.g, ev.b, !P.COLOR
    ; For visuals with static colormaps, update the graphics
    ; after a change by TVLCT.
    IF ((COLORMAP_APPLICABLE(redrawRequired) GT 0) AND $
        (redrawRequired GT 0)) then begin
       WIDGET_CONTROL, ev.top, GET_UVALUE=tmp
       WSET, tmp.win_id
       ERASE, color=!P.COLOR
       WSET, tmp.save
    ENDIF
  ENDELSE

END




pro xpcolor,GROUP=group

  common colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr

  ; Ensure we have a window to establish colors.
  save = !D.WINDOW
  IF (save EQ -1) THEN BEGIN
    WINDOW,/PIXMAP,/FREE,XSIZE=2,YSIZE=2
    ; Can free it right away. 
    WDELETE,!D.WINDOW
  ENDIF

  ; make sure the colormap can be updated
  DEVICE, DECOMPOSED=0

  IF N_ELEMENTS(r_orig) LE 0 THEN BEGIN ;If no common, use current colors
    TVLCT, r_orig, g_orig, b_orig, /GET
    r_curr = r_orig
    b_curr = b_orig
    g_curr = g_orig
  ENDIF

  base = WIDGET_BASE(/COLUMN, title='Set Plot Color')

  ; Setting the managed attribute indicates our intention to put this app
  ; under the control of XMANAGER, and prevents our draw widgets from
  ; becoming candidates for becoming the default window on WSET, -1. XMANAGER
  ; sets this, but doing it here prevents our own WSETs at startup from
  ; having that problem.
  WIDGET_CONTROL, /MANAGED, base

  b = CW_BGROUP(base, /ROW, ['Done', 'Help'], UVALUE=0)
  draw = WIDGET_DRAW(base, XSIZE=100, YSIZE=50)
  rgb = CW_RGBSLIDER(base, /DRAG, UVALUE=1)
  ; Set p.color to allowit to work even for truecolor
  !P.color = !P.color < (!D.TABLE_SIZE-1)
  WIDGET_CONTROL, rgb, SET_VALUE=[r_curr[!P.color], g_curr[!P.color], $
	b_curr[!P.color] ]
  widget_control,/real,base
  WIDGET_CONTROL, draw, GET_VALUE=win_id
  WIDGET_CONTROL, base, SET_UVALUE={win_id:win_id, save:save}

  WSET, win_id
  ERASE, color=!P.COLOR
  WSET, save
  XMANAGER, 'XPCOLOR', base, GROUP=group, /NO_BLOCK
end
