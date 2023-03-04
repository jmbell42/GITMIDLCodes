; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/ui_widgets/idlituidisplayerrorobj.pro#1 $
;
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;   IDLitUIDisplayErrorObj
;
; PURPOSE:
;   Provides the user interface for selecting an IDL command line
;   variable
;
; CALLING SEQUENCE:
;   Result = IDLitUIFileOpen(oUI, Requester)
;
; INPUTS:
;   Requester - Set this argument to the object reference for the caller.
;
; KEYWORD PARAMETERS:
;
;
; MODIFICATION HISTORY:
;
;-



;-------------------------------------------------------------------------
function IDLitUIDisplayErrorObj, oUI, oError

   compile_opt idl2, hidden

   ;; Basically that the text in the error object and display an
   ;; dialog_message()

   if(obj_valid(oError) eq 0)then $
     return,0

   oError->GetProperty, message=message, description=description, $
     severity=severity

    ; For group leader use the top-level base that has the focus.
    ; This is usually the current tool, but may be a modal widget.
    oUI->GetProperty, WIDGET_FOCUS=wLeader

    status = DIALOG_MESSAGE(description, $
        DIALOG_PARENT=wLeader, $
        TITLE=message,  $
        ERROR=(severity eq 2), $
        INFORMATION=(severity eq 0))

   return, 1
end

