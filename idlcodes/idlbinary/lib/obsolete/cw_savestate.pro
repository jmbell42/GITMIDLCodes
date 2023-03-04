; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/cw_savestate.pro#1 $
;
; Copyright (c) 1992-2006, Research Systems, Inc.  All rights reserved.
;	Unauthorized reproduction prohibited.
;+
; NAME:
;	CW_SAVESTATE
;
; PURPOSE:
;      --------------------------------------------------------------
;      | This is an obsolete routine. New applications should       |
;      | be written to use the NO_COPY keyword to WIDGET_CONTROL to |
;      | efficiently maintain widget state in a UVALUE.)            |
;      --------------------------------------------------------------
;
;	Compound widgets cannot use a COMMON block to keep their state
;	information in because that would preclude having more than
;	one at a time. One solution is to keep their state as a
;	structure in the UVALUE of one of the widgets in the cluster.
;	Once this is done, it is then possible to use a COMMON block to
;	cache the most recently used state. This is the scheme implemented
;	by the CW_SAVESTATE and CW_LOADSTATE procedures. CW_LOADSTATE is
;	called by the main compound widget function that creates the
;	widgets. It stores the state in the UVALUE of the first child.
;	Other functions that require the state call CW_LOADSTATE to
;	ensure that the correct state is present.
;
; CATEGORY:
;	Compound widgets.
;
; CALLING SEQUENCE:
;	Creation function:
;
;		COMMON CW_XYZ_BLK, state_base, state_stash, state
;		CW_SAVESTATE, base, state_base, new_state
;
;	Other routines:
;
;		COMMON CW_XYZ_BLK, state_base, state_stash, state
;		CW_LOADSTATE, base, state_base, state_stash, state
;
;	If the other routines are called heavily, the following is
;	a more efficient way to call CW_LOADSTATE:
;
;		COMMON CW_XYZ_BLK, state_base, state_stash, state
;		if (base ne state_base) then $
;		    CW_LOADSTATE, base, state_base, state_stash, state
;
;	Note that the COMMON block must be defined in every routine that
;	calls these procedures. The name of the COMMON block is unique
;	to each compound widget, but the names of the variables inside
;	the COMMON must be as shown.
;
; INPUTS:
;   CW_SAVESTATE:
;	BASE - The ID of the base widget of the cluster.
;	STATE_BASE - The state_base variable from the COMMON block.
;	NEW_STATE - The new state that should be saved in the UVALUE.
;
;	    NOTE: This is not the same as the STATE variable from
;		  the COMMON block. Confusing them can result in
;		  corrupting the state of an already existing instance
;		  of the compound widget.
;
;   CW_LOADSTATE:
;	BASE - The ID of the base widget of the cluster.
;	STATE_BASE - The STATE_BASE variable from the COMMON block.
;	STATE_STASH - The STATE_STASH variable from the COMMON block.
;	STATE - The STATE variable from the COMMON block.
;
; KEYWORD PARAMETERS:
;	None.
;
; OUTPUTS:
;	No explicit outputs.
;
; COMMON BLOCKS:
;	None in these routines, but the calling routines must have the
;	per compound widget class COMMON discussed above.
;
; SIDE EFFECTS:
;	CW_SAVESTATE saves the new state for a freshly created compound
;	widget.
;
;	CW_LOADSTATE flushes the current state from the compound widget
;	COMMON block and loads the state for the specified widget.
;
; RESTRICTIONS:
;
;      --------------------------------------------------------------
;      | This is an obsolete routine. New applications should       |
;      | be written to use the NO_COPY keyword to WIDGET_CONTROL to |
;      | efficiently maintain widget state in a UVALUE.)            |
;      --------------------------------------------------------------
;
;	These routines use the UVALUE of the first child of the compound
;	widget base. Hence, the compound widget should not make use
;	of this UVALUE or confusion will result.
;
;	One solution to this problem is to include an extra base
;	between the top base and the rest of the widgets. For example:
;
;		OUTER_BASE = WIDGET_BASE()
;		INNER_BASE = WIDGET_BASE(OUTER_BASE)
;		OTHER_WIDGET = WIDGET_BUTTON(INNER_BASE)
;		...
;
; PROCEDURE:
;	Every compound widget that uses these procedures keeps the
;	most recently accessed state in the UVALUE of the first child
;	of the compound widget base. These procedures load and unload
;	the states for each instance of compound widget as needed.
;
; EXAMPLE:
;
;	Here is the framework for a compound widget at its event function
;
;	function CW_XYZ_EVENT, ev
;
;	  COMMON CW_XYZ_BLK, state_base, state_stash, state
;	  CW_LOADSTATE, ev.handler, state_base, state_stash, state
;
;		; Event processing goes here. The widget state is
;		; contained in the variable state.
;	end
;
;	function CW_XYZ, parent
;
;	  COMMON CW_XYZ_BLK, state_base, state_stash, state
;         ;
;	  base = widget_base()
;
;		; Other widgets are created here
;
;	  new_state = ...	; The new state is widget dependent
;
;	  CW_SAVESTATE, base, state_base, new_state
;	  return, base
;	end
;
; MODIFICATION HISTORY:
;	AB, June 1992
;-


pro CW_SAVESTATE, base, state_base, new_state
  ; Load the new_state variable into the user value of the first child
  ; of base.

  COMMON CW_SAVSTAT_OBS, obsolete

  if not KEYWORD_SET(obsolete) then begin
    obsolete = 1
    message,/INFO,"The CW_SAVESTATE and CW_LOADSTATE user library routines are obsolete. They are superceeded by the NO_COPY keyword to the WIDGET_CONTROL procedure."
  endif



  ; There are many reasons why we might want to invalidate the cache
  ; by setting state_base to zero. The logic can get a bit tricky.
  ;
  ;	- state_base is undefined, meaning that this is the first
  ;       savestate for this compound widget class.
  ;
  ;	- state_base is the same as our new widget, meaning that
  ;	  the state in the common block is for a previous incarnation
  ;       of a widget of this class headed by a widget with the
  ;       same ID. (A very rare case)
  ;
  ;	- state_base is an invalid ID, meaning the widget owning
  ;       the current state has died and not been reused. (This is likely)
  ;
  ;	- state_base is valid, but has a different event handler than
  ;	  the new ID. In this case, the widget owning the current state
  ;       has died and has been since reused, but in a different
  ;       application. The assumption here is that two widgets
  ;       with non-null event handlers that agree must be different
  ;	  instantiations of the same class. (This is likely)
  ;
  ; Note: IDL's IF statement does not do short circuit evaluation, hence
  ;       the strange looking structure of this code.
  if (n_elements(state_base) eq 0) then begin
      state_base=0L
  endif else if (base eq state_base) then begin
      state_base = 0L
  endif else if (not widget_info(state_base, /VALID)) then begin
      state_base = 0L
  endif else if (widget_info(base, /EVENT_FUNC) $
                 ne widget_info(state_base, /EVENT_FUNC)) then begin
      state_base = 0L
  endif

  WIDGET_CONTROL, WIDGET_INFO(base, /CHILD), set_uvalue=new_state

end
