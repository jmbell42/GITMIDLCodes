; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/utilities/xmtool.pro#1 $
;
; Copyright (c) 1991-2006, Research Systems, Inc.  All rights reserved.
;	Unauthorized reproduction prohibited.

PRO UpdateXMToolList, widList

  COMPILE_OPT hidden
  COMMON MANAGED,	ids, $		; IDs of widgets being managed
  			names, $	; and their names
			modalList	; list of active modal widgets

  ; Make sure XManager's version of the list is up to date
  ValidateManagedWidgets
  
  ; put some error handling around our calls to WIDGET_CONTROL since
  ; our widget could have gone away behind our backs
  err = 0
  catch, err
  if (err EQ 0) THEN BEGIN
    ; get our list of widgets
    WIDGET_CONTROL, widList, GET_UVALUE=list
    selectedWid = WIDGET_INFO(widList, /LIST_SELECT)
  
    ; are the lists different?
    listSize = size(list)
    namesSize = size(names)
    IF (namesSize[N_ELEMENTS( namesSize)-2] EQ 7) THEN BEGIN
        IF((listSize[0] NE namesSize[0]) OR (listSize[1] NE namesSize[1]) OR $
          (listSize[2] NE namesSize[2]) OR ((where(list NE names))[0] NE -1)) $
          THEN $
          WIDGET_CONTROL, widList, SET_UVALUE=names, SET_VALUE=names, $
          SET_LIST_SELECT=selectedWid
    ENDIF
  ENDIF
END

PRO XManTool_event, event

  COMPILE_OPT hidden
  COMMON MANAGED,	ids, $		; IDs of widgets being managed
  			names, $	; and their names
			modalList	; list of active modal widgets

  WIDGET_CONTROL, event.id, GET_UVALUE = evntval
  widList = WIDGET_INFO(event.top, /CHILD)
  
  selectedWid = WIDGET_INFO(widList, /LIST_SELECT)

  ; Handle events for everything but the list widget (the list widget's
  ; uvalue is an array, so we can't use it in the case statement)
  IF (event.id NE widList) THEN BEGIN
    CASE evntval OF
      'KILLWID' : BEGIN
	IF (selectedWid NE -1) THEN $
	  WIDGET_CONTROL, ids[selectedWid], /DESTROY
      END

      'SHOWWID' : BEGIN
	IF (selectedWid NE -1) THEN $
	  WIDGET_CONTROL, ids[selectedwid], /SHOW
      END

      'UPDATE' : BEGIN
	WIDGET_CONTROL, event.id, TIMER = 1
      END
      ELSE:
    ENDCASE
  ENDIF

  ; Make sure the list is up to date
  UpdateXMToolList, widList

END


;-----------------------------------------------------------------------------
;+
; NAME:
;	XMTOOL
;
; PURPOSE:
;	Provide a tool for viewing Widgets currently being managed by the 
;	XMANAGER.
;
; CATEGORY:
;	Widgets.
;
; CALLING SEQUENCE:
;	XMTOOL
;
; KEYWORD PARAMETERS:
;	GROUP:	The widget ID of the group leader that the XMANAGERTOOL 
;		is to live under.  If the group is destroyed, the 
;		XMANAGERTOOL is also destroyed.
;
;	BLOCK:  Set this keyword to have XMANAGER block when this
;		application is registered.  By default the Xmanager
;               keyword NO_BLOCK is set to 1 to provide access to the
;               command line if active command 	line processing is available.
;               Note that setting BLOCK for this application will cause
;		all widget applications to block, not only this
;		application.  For more information see the NO_BLOCK keyword
;		to XMANAGER.
;
; SIDE EFFECTS:
;	This procedure creates a widget that has the ability to destroy other 
;	widgets being managed by the XManager.
;
; RESTRICTIONS:
;	Only one instance of the XMANAGERTOOL can run at one time.
;
; PROCEDURE:
;	Initiate the widget and then let the timer routine update the
;	lists as the widgets being managed by the XMANAGER are changed.
;
; MODIFICATION HISTORY:
;	Written by Steve Richards, Dec, 1990.
;	SMR - 6/93	Modified the routine to work with a timer instead
;			of the obsolete background tasks.
;-

PRO XMTool, GROUP = GROUP, BLOCK=block

  COMMON MANAGED,	ids, $		; IDs of widgets being managed
  			names, $	; and their names
			modalList	; list of active modal widgets

  IF (XRegistered('XManagerTool')) THEN RETURN

  IF N_ELEMENTS(block) EQ 0 THEN block=0

  toolbase = WIDGET_BASE(TITLE = 'Managed Widgets', $
			 /COLUMN, UVALUE = 'UPDATE', TLB_FRAME_ATTR=1)

  widList = WIDGET_LIST(toolbase, VALUE = 'XmanagerTool', $
  			UVALUE = 'XmanagerTool', YSIZE = 10)
  WIDGET_CONTROL, widList, SET_LIST_SELECT=0

  litcontbase = WIDGET_BASE(toolbase, /ROW, /GRID_LAYOUT)
  showster = WIDGET_BUTTON(litcontbase, VALUE = 'Bring To Front', $
			   UVALUE = 'SHOWWID')
  killer = WIDGET_BUTTON(litcontbase, VALUE = 'Kill Widget', $
			 UVALUE = 'KILLWID')

  WIDGET_CONTROL, toolbase, /REALIZE

  ; If XMANAGER is not yet compiled, compile it because we rely on internal
  ; support routines from that module. We can't indescriminately just
  ; compile because that would kill a running XMANAGER if one is present.
  ; We rely on the MANAGED common block variable modalList to be defined
  ; only when XMANAGER runs to detect which is the case.
  if (n_elements(modalList) eq 0) then RESOLVE_ROUTINE,'XMANAGER'

  UpdateXMToolList, widList
  WIDGET_CONTROL, toolbase, TIMER = 1

  Xmanager, 'XManagerTool', toolbase, EVENT_HANDLER = 'XManTool_event', $
	    GROUP_LEADER = GROUP, NO_BLOCK=(NOT(FLOAT(block)))

END

