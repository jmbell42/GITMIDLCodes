; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/ui_widgets/idlituistyleapply.pro#1 $
; Copyright (c) 2003-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;   IDLituiStyleApply
;
; PURPOSE:
;   This function implements the user interface for the Style Browser
;   for the IDL Tool. The Result is a success flag, either 0 or 1.
;
; CALLING SEQUENCE:
;   Result = IDLituiStyleApply(UI, Requester)
;
; INPUTS:
;   UI object
;   Requester - Set this argument to the object reference for the caller.
;
; KEYWORD PARAMETERS:
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, Dec 2003
;   Modified:
;
;-


;-------------------------------------------------------------------------
function IDLituiStyleApply, oUI, oRequester

    compile_opt idl2, hidden

    oUI->GetProperty, GROUP_LEADER=groupLeader

    ; Retrieve initial settings.
    oRequester->GetProperty, STYLE_NAME=styleName, $
        UPDATE_CURRENT=updateCurrent

    success = IDLitwdStyleApply(oUI, $
        APPLY=apply, $
        GROUP_LEADER=groupLeader, $
        STYLE_NAME=styleName, $
        UPDATE_CURRENT=updateCurrent)

    if (success) then begin
        ; Set final settings.
        oRequester->SetProperty, STYLE_NAME=styleName, APPLY=apply, $
            UPDATE_CURRENT=updateCurrent
    endif

    return, success

end

