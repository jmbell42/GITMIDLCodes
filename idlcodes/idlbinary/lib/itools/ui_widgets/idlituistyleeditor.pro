; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/ui_widgets/idlituistyleeditor.pro#1 $
; Copyright (c) 2003-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;   IDLitUIStyleEditor
;
; PURPOSE:
;   This function implements the user interface for the Style Editor
;   for the IDL Tool. The Result is a success flag, either 0 or 1.
;
; CALLING SEQUENCE:
;   Result = IDLitUIStyleEditor(UI, Requester)
;
; INPUTS:
;   UI object
;   Requester - Set this argument to the object reference for the caller.
;
; KEYWORD PARAMETERS:
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, Oct 2003
;   Modified:
;
;-



;-------------------------------------------------------------------------
function IDLitUIStyleEditor, oUI, oRequester


  compile_opt idl2, hidden

  IDLitwdStyleEditor, oUI

  return, 1

end

