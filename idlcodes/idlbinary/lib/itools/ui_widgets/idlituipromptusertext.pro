; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/ui_widgets/idlituipromptusertext.pro#1 $
;
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;   IDLitUIPromptUserText
;
; PURPOSE:
;  UI Adaptor for prompting the user for text.
;
; CALLING SEQUENCE:
;
; KEYWORD PARAMETERS:
;
; MODIFICATION HISTORY:
;
;-



;-------------------------------------------------------------------------
function IDLitUIPromptUserText, oUI, oPrompt

   compile_opt idl2, hidden

   ;; Basically that the text in the error object and display an
   ;; dialog_message()

   if(obj_valid(oPrompt) eq 0)then $
     return, 0

   oPrompt->GetProperty, title=title, prompt=prompt
   oUI->GetProperty, GROUP_LEADER=wLeader

   status = IDLitwdPromptText(wLeader, prompt, title=title, strOut)

   if(status ne 0)then $
     oPrompt->SetProperty, ANSWER=strOut
   return, status
end

