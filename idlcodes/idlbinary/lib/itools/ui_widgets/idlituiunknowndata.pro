; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/ui_widgets/idlituiunknowndata.pro#1 $
; Copyright (c) 2003-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;   IDLituiUnknownData
;
; PURPOSE:
;   This function implements the user interface for unknown data import.
;   The Result is a success flag, either 0 or 1.
;
; CALLING SEQUENCE:
;   Result = IDLituiUnknownData(oUI, oRequester)
;
; INPUTS:
;   UI - UI objref.
;   Requester - Set this argument to the object reference for the caller.
;
; KEYWORD PARAMETERS:
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, Jan 2003
;   Modified:
;
;-



;-------------------------------------------------------------------------
function IDLituiUnknownData, oUI, oRequester

    compile_opt idl2, hidden

    ; Retrieve widget ID of top-level base.
    oUI->GetProperty, GROUP_LEADER=groupLeader

    ; Retrieve the irregular data.
    oRequester->GetProperty, METHOD=method

    ; Fire off the wizard and wait for it to return.
    result = IDLitwdUnknownData(oUI, $
        GROUP_LEADER=groupLeader, $
        METHOD=method)

    if (result eq 0) then $
        return, 0

    ; Fill in our results.
    oRequester->SetProperty, METHOD=result

    return, 1
end

