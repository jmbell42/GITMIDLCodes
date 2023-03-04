; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/itdelete.pro#1 $
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;   itDelete
;
; PURPOSE:
;   Used to delete a tool in the system from the command line
;
; CALLING SEQUENCE:
;   itDelete[, idTool]
;
; INPUTS:
;   idTool  - The identifier for the tool to delete. If not provided,
;             the current tool is used.
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
PRO itDelete, idTool

   compile_opt hidden, idl2

@idlit_on_error2.pro
@idlit_catch.pro
   if(iErr ne 0)then begin
       catch, /cancel
       obj_destroy, oImageData
       MESSAGE, /REISSUE_LAST
       return
   endif

   ;; Basically Get the system object and return the current tool
   ;; identifier.
   oSystem = _IDLitSys_GetSystem()
   if(not obj_valid(oSystem))then $
     return

   if(n_elements(idTool) eq 0)then $
     idTool = oSystem->GetCurrentTool()

   oSystem->DeleteTool, idTool
end


