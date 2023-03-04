; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/itgetcurrent.pro#1 $
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;   itGetCurrent
;
; PURPOSE:
;   Returns the current tool in the system.
;
; CALLING SEQUENCE:
;   idTool = itGetCurrent()
;
; INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   TOOL: Set this keyword to a named variable in which to return the
;       object reference to the current tool object.
;       If there is no current tool then a null object is returned.
;
; RETURN VALUE
;   An identifier for the current tool. If no tool is current,
;   an empty ('') string is returned.
;
; MODIFICATION HISTORY:
;   Written by:  KDB, RSI, Novemember 2002
;   Modified: CT, RSI, Jan 2004: Added TOOL keyword.
;
;-

;-------------------------------------------------------------------------
FUNCTION itGetCurrent, TOOL=oTool

   compile_opt hidden, idl2

@idlit_on_error2.pro
@idlit_catch.pro
   if(iErr ne 0)then begin
       catch, /cancel
       MESSAGE, /REISSUE_LAST
       return,''
   endif

   ;; Basically Get the system object and return the current tool
   ;; identifier.
   oSystem = _IDLitSys_GetSystem()
   if(not obj_valid(oSystem))then $
     return, ''

    idTool = oSystem->GetCurrentTool()

    if ARG_PRESENT(oTool) then $
        oTool = oSystem->GetByIdentifier(idTool)

    return, idTool
end


