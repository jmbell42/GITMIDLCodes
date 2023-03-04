; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/cw_loadstate.pro#1 $
;
; Copyright (c) 1992-2006, Research Systems, Inc.  All rights reserved.
;	Unauthorized reproduction prohibited.
;+
; NAME:
;	CW_LOADSTATE
;
; PURPOSE:
;      --------------------------------------------------------------
;      | This is an obsolete routine. New applications should       |
;      | be written to use the NO_COPY keyword to WIDGET_CONTROL to |
;      | efficiently maintain widget state in a UVALUE.)            |
;      --------------------------------------------------------------
;
;	See the description of CW_SAVESTATE.
;
; CATEGORY:
;	Compound widgets.
;
; MODIFICATION HISTORY:
;	AB, June 1992
;-


pro CW_LOADSTATE, base, state_base, state_stash, state

  if (base ne state_base) then begin
    ; Preserve the existing state before replacing it
    if ((n_elements(state_base) ne 0) and $
        (WIDGET_INFO(state_base, /VALID) ne 0)) then $
      WIDGET_CONTROL, state_stash, SET_UVALUE=state

    ; Recover the new state
    state_base = base
    state_stash = widget_info(state_base, /child)
    WIDGET_CONTROL, state_stash, GET_UVALUE = state
  endif

end
