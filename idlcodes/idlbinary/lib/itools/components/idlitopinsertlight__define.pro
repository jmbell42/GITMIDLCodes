; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/components/idlitopinsertlight__define.pro#1 $
;
; Copyright (c) 2000-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the insert light operation.
;
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopInsertLight::Init
;
; Purpose:
; The constructor of the IDLitopInsertLight object.
;
; Parameters:
; None.
;
;-------------------------------------------------------------------------
;function IDLitopInsertLight::Init, _REF_EXTRA=_extra
;    compile_opt idl2, hidden
;    return, self->IDLitOperation::Init(_EXTRA=_extra)
;end


;---------------------------------------------------------------------------
; IDLitopInsertLight::DoAction
;
; Purpose:
;
; Parameters:
; None.
;
;-------------------------------------------------------------------------
function IDLitopInsertLight::DoAction, oTool

    compile_opt idl2, hidden

    oCreate = oTool->GetService("CREATE_VISUALIZATION")
    if(not OBJ_VALID(oCreate))then $
        return, OBJ_NEW()

    ; Create the light.
    oVisDesc = oTool->GetVisualization("LIGHT")

    ; Call our internal _Create since we don't have any data
    ; associated with the light object.
    oCmdSet = oCreate->_Create(oVisDesc, $
        ID_VISUALIZATION=idLight)

    return, oCmdSet

end


;-------------------------------------------------------------------------
pro IDLitopInsertLight__define

    compile_opt idl2, hidden
    struc = {IDLitopInsertLight, $
        inherits IDLitOperation}

end

