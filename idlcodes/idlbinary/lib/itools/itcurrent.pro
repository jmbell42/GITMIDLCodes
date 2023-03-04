; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/itcurrent.pro#1 $
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;   itCurrent
;
; PURPOSE:
;   Used to set the current tool in the iTools system.
;
; CALLING SEQUENCE:
;   itCurrent, idTool
;
; INPUTS:
;   idTool  - The identifier for the tool to set current
;
; KEYWORD PARAMETERS:
;   None
;
; MODIFICATION HISTORY:
;   Written by:  KDB, RSI, Novemember 2002
;   Modified:
;
;-

;-------------------------------------------------------------------------
PRO itCurrent, idTool

   compile_opt hidden, idl2

@idlit_on_error2.pro
@idlit_catch.pro
   if(iErr ne 0)then begin
       catch, /cancel
       MESSAGE, /REISSUE_LAST
       return
   endif

   if(n_elements(idTool) eq 0 || size(/type, idTool) ne 7)then $
     message, "Provided argument must be a valid iTool identifier"

   ;; Basically Get the system object and return the current tool
   ;; identifier.
   oSystem = _IDLitSys_GetSystem()
   if(not obj_valid(oSystem))then $
     message, "Unable to access the iTools environment"

   ;; validate the id
   if(~obj_valid(oSystem->GetByIdentifier(idTool)))then $
     message, "Invalid iTool identifier provided. No such iTool."
   oSystem->SetCurrentTool, idTool
end


