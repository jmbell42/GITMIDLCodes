; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/ui_widgets/idlituimapregisterimage.pro#1 $
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;   IDLitUIConvolKernel
;
; PURPOSE:
;   This function implements the user interface for the Operation Browser
;   for the IDL Tool. The Result is a success flag, either 0 or 1.
;
; CALLING SEQUENCE:
;   Result = IDLitUIConvolKernel(Requester [, UVALUE=uvalue])
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
;   Written by:  CT, RSI, March 2002
;   Modified:
;
;-



;-------------------------------------------------------------------------
function IDLitUIMapRegisterImage, oUI, oRequester

    compile_opt idl2, hidden

    ; Retrieve widget ID of top-level base.
    oUI->GetProperty, GROUP_LEADER=groupLeader

    result = IDLitwdMapRegisterImage(oUI, $
        GROUP_LEADER=groupLeader, $
        VALUE=oRequester->GetFullIdentifier())

    return, result
end

