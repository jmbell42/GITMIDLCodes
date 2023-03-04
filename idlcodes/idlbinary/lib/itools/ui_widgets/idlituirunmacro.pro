; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/ui_widgets/idlituirunmacro.pro#1 $
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;   IDLituiRunMacro
;
; PURPOSE:
;   This function implements the user interface for file selection
;   for the IDL Tool. The Result is a success flag, either 0 or 1.
;
; CALLING SEQUENCE:
;   Result = IDLituiRunMacro(Requester [, UVALUE=uvalue])
;
; INPUTS:
;   Requester - Set this argument to the object reference for the caller.
;
; KEYWORD PARAMETERS:
;
;   UVALUE: User value data.
;
;
; MODIFICATION HISTORY:
;   Written by:  AY, RSI, Dec 2003
;   Modified:
;
;-



;-------------------------------------------------------------------------
function IDLituiRunMacro, oUI, oRequester

    compile_opt idl2, hidden

    ; Retrieve widget ID of top-level base.
    oUI->GetProperty, GROUP_LEADER=groupLeader

    IDLitwdRunMacro, oUI, oRequester, $
        GROUP_LEADER=groupLeader

    return, 1

end

