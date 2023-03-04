; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/components/idlitmanipvisscale2d__define.pro#1 $
;
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;----------------------------------------------------------------------------
;
; Purpose:
;   The IDLitManipVisScale2D class is the 2d scale manipulator visual.
;


;----------------------------------------------------------------------------
; Purpose:
;   This function method initializes the object.
;
; Syntax:
;   Obj = OBJ_NEW('IDLitManipVisScale2D')
;
;   or
;
;   Obj->[IDLitManipVisScale2D::]Init
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
function IDLitManipVisScale2D::Init, $
    COLOR=color, $
    NAME=inName, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Prepare default name.
    name = (N_ELEMENTS(inName) ne 0) ? inName : "Scale2D Visual"

    ; Initialize superclasses.
    if (self->IDLitManipulatorVisual::Init( $
        NAME=name, $
        VISUAL_TYPE='Select', $
        _EXTRA=_extra) ne 1) then $
        return, 0


    self._oFont = OBJ_NEW('IDLgrFont', 'Hershey*9', SIZE=6)
    textex = {ALIGN: 0.45, $
        VERTICAL_ALIGN: 0.45, $
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
    types = ['-X-Y','+X-Y','+X+Y','-X+Y']

    for i=0,3 do begin
        xyposition = [data[0:1,i], 0]
        oText = OBJ_NEW('IDLgrText', 'B', $
            LOCATION=xyposition, $
            _EXTRA=textex)
        oCorner = OBJ_NEW('IDLitManipulatorVisual', $
            VISUAL_TYPE='Scale/'+types[i])
        oCorner->Add, oText
        self->Add, oCorner
    endfor

    char2 = 'B'

    ; Edges.
    types = ['-X','+X','-Y','+Y']

    for i=0,3 do begin

        oEdge = OBJ_NEW('IDLitManipulatorVisual', $
            VISUAL_TYPE='Scale/' + types[i])

        case i of
            0: data = [[-1,-1],[-1,1]] ; left
            1: data = [[ 1,-1],[1, 1]] ; right
            2: data = [[-1,-1],[1,-1]] ; bottom
            3: data = [[-1, 1],[1, 1]] ; top
        endcase

;        if KEYWORD_SET(noPadding) then begin
            ; For non-padded selection boxes (like for rectangles)
            ; we put little boxes in the middle of each side.
            oEdge->Add, OBJ_NEW('IDLgrText', char2, $
                LOCATION=TOTAL(data,2)/2, _EXTRA=textex)
;        endif else begin
;            ; For padded selection boxes (like for dataspace or polygons)
;            ; we draw lines along each side.
;            oEdge->Add, OBJ_NEW('IDLgrPolyline', $
;                COLOR=color, DATA=data)
;        endelse

        self->Add, oEdge

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
pro IDLitManipVisScale2D::Cleanup

    compile_opt idl2, hidden

    OBJ_DESTROY, self._oFont
    self->IDLitManipulatorVisual::Cleanup
end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitManipVisScale2D__Define
;
; Purpose:
;   Defines the object structure for an IDLitManipVisScale2D object.
;-
pro IDLitManipVisScale2D__Define

    compile_opt idl2, hidden

    struct = { IDLitManipVisScale2D, $
        inherits IDLitManipulatorVisual, $
        _oFont: OBJ_NEW() $
        }
end
