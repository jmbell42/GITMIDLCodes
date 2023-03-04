; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/components/idlitmanipvisrotate2d__define.pro#1 $
;
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;----------------------------------------------------------------------------
;
; Purpose:
;   The IDLitManipVisRotate2D class is the 2D rotate manipulator visual.
;


;----------------------------------------------------------------------------
; Purpose:
;   This function method initializes the object.
;
; Syntax:
;   Obj = OBJ_NEW('IDLitManipVisRotate2D')
;
;   or
;
;   Obj->[IDLitManipVisRotate2D::]Init
;
; Result:
;   1 for success, 0 for failure.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
function IDLitManipVisRotate2D::Init, $
    COLOR=color, $
    NAME=inName, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Prepare default name.
    name = (N_ELEMENTS(inName) ne 0) ? inName : "Rotate2D Visual"

    ; Initialize superclasses.
    if (self->IDLitManipulatorVisual::Init( $
        NAME=name, $
        VISUAL_TYPE='Rotate', $
        _EXTRA=_extra) ne 1) then $
        return, 0


    self._oFont = OBJ_NEW('IDLgrFont', 'Hershey', SIZE=10)
    textex = {ALIGN: 0.45, $
        VERTICAL_ALIGN: 0.47, $
        COLOR: [0,150,0], $
        FONT: self._oFont, $
        RECOMPUTE_DIM: 2, $
        RENDER: 1}

    data = [ $
        [-1,-1], $
        [1,-1], $
        [1,1], $
        [-1,1]]

    ; Corners.
    for i=0,3 do begin
        oText = OBJ_NEW('IDLgrText', 'o', $
            LOCATION=data[*,i], _EXTRA=textex)
        oCorner = OBJ_NEW('IDLitManipulatorVisual', $
            VISUAL_TYPE='Rotate')
        oCorner->Add, oText
        self->Add, oCorner
    endfor


    return, 1
end


;----------------------------------------------------------------------------
; Purpose:
;   This function method cleans up the object.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
pro IDLitManipVisRotate2D::Cleanup

    compile_opt idl2, hidden

    OBJ_DESTROY, self._oFont
    self->IDLitManipulatorVisual::Cleanup
end


;----------------------------------------------------------------------------
pro IDLitManipVisRotate2D__Define

    compile_opt idl2, hidden

    struct = { IDLitManipVisRotate2D, $
        inherits IDLitManipulatorVisual, $
        _oFont: OBJ_NEW() $
        }
end
