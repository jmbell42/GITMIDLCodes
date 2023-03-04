; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/components/idlitopinsertaxisy__define.pro#1 $
;
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the insert Y Axis operation.
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
function IDLitopInsertAxisY::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Allow this operation to work on 2D or 3D dataspaces.
    return, self->IDLitopInsertAxis::Init( $
        TYPE='DATASPACE_' + ['2D','ROOT_2D','3D','ROOT_3D'], _EXTRA=_extra)
end


;---------------------------------------------------------------------------
; Purpose:
;   Perform the action.
;
; Arguments:
;   None.
;
function IDLitopInsertAxisY::DoAction, oTool

    compile_opt idl2, hidden

    return, self->IDLitOpInsertAxis::DoAction(oTool, DIRECTION=1)   ; Y axis

end


;-------------------------------------------------------------------------
pro IDLitopInsertAxisY__define

    compile_opt idl2, hidden

    struc = {IDLitopInsertAxisY, $
        inherits IDLitopInsertAxis}

end

