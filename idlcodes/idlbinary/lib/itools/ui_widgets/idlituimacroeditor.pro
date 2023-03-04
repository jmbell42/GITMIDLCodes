; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/ui_widgets/idlituimacroeditor.pro#1 $
; Copyright (c) 2003-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;   IDLitUIMacroEditor
;
; PURPOSE:
;   This function implements the user interface for the Macro Editor
;   for the IDL Tool. The Result is a success flag, either 0 or 1.
;
; CALLING SEQUENCE:
;   Result = IDLitUIMacroEditor(UI, Requester)
;
; INPUTS:
;   UI object
;   Requester - Set this argument to the object reference for the caller.
;
; KEYWORD PARAMETERS:
;
; MODIFICATION HISTORY:
;   Written by:  AY, RSI, Jan 2004
;   Modified:
;
;-



;-------------------------------------------------------------------------
function IDLitUIMacroEditor, oUI, oRequester


  compile_opt idl2, hidden

  IDLitwdMacroEditor, oUI

  return, 1

end

