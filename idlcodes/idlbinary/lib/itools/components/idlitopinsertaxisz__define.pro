; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/components/idlitopinsertaxisz__define.pro#1 $
;
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the insert Z Axis operation.
;
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the object.
;
; Arguments:
;   None.
;
function IDLitopInsertAxisZ::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Allow this operation to work only on 3D dataspaces.
    return, self->IDLitopInsertAxis::Init( $
        TYPE=['DATASPACE_3D','DATASPACE_ROOT_3D'], _EXTRA=_extra)
end


;---------------------------------------------------------------------------
; Purpose:
;   Perform the action.
;
; Arguments:
;   None.
;
function IDLitopInsertAxisZ::DoAction, oTool

    compile_opt idl2, hidden

    return, self->IDLitOpInsertAxis::DoAction(oTool, DIRECTION=2)   ; Z axis

end


;-------------------------------------------------------------------------
pro IDLitopInsertAxisZ__define

    compile_opt idl2, hidden

    struc = {IDLitopInsertAxisZ, $
        inherits IDLitopInsertAxis}

end

