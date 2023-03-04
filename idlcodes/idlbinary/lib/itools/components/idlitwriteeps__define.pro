; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/components/idlitwriteeps__define.pro#1 $
;
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitWriteEPS class.
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
; Keywords:
;   All superclass keywords.
;
function IDLitWriteEPS::Init, $
    _EXTRA=_extra


    compile_opt idl2, hidden

    ; Init superclass
    ; The only properties that can be set at INIT time can be set
    ; in the superclass Init method.
    if(self->IDLitWriter::Init('eps', $
        NAME='Encapsulated Postscript', $
        TYPES=["IDLDEST"], $
        DESCRIPTION="Encapsulated postscript file", $
        _EXTRA=_extra) eq 0) then $
        return, 0

    self->RegisterProperty, 'GRAPHICS_FORMAT', $
        NAME='Graphics format', $
        DESCRIPTION='Render graphics using bitmap or vector output', $
        ENUMLIST=['Bitmap','Vector']

    self->RegisterProperty, 'COLOR_MODEL', $
        ENUMLIST=['RGB', 'CMYK'], $
        NAME='Color model', $
        Description='PostScript Output Color Model'

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitWriteEPS::SetProperty, _EXTRA=_extra

    return, 1
end


;---------------------------------------------------------------------------
; Purpose:
; The destructor for the class.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
;pro IDLitWriteEPS::Cleanup
;    compile_opt idl2, hidden
;    ; Cleanup superclass
;    self->IDLitWriter::Cleanup
;end


;---------------------------------------------------------------------------
; Property Management
;---------------------------------------------------------------------------
; IDLitWriteEPS::GetProperty
;
; Purpose:
;   Used to get the value of the properties associated with this class.
;
; Arguments:
;   None.
;
; Keywords:
;    TYPES   - The data types supported by this writer
;
;    All keywords are passed to the superclasses
;
pro IDLitWriteEPS::GetProperty, $
    COLOR_MODEL=colorModel, $
    _REF_EXTRA=_super

    compile_opt idl2, hidden

    if (ARG_PRESENT(colorModel)) then $
        colorModel = self._colorModel

    if(N_ELEMENTS(_super) gt 0) then begin
        self->IDLitWriter::GetProperty, _EXTRA=_super
    endif

end


;---------------------------------------------------------------------------
; IDLitWriteEPS::SetProperty
;
; Purpose:
;   Used to set the value of the properties associated with this class.
;
; Arguments:
;   None.
;
; Keywords:
;   All properties are passed to the super-class
;
pro IDLitWriteEPS::SetProperty, $
    COLOR_MODEL=colorModel, $
    _EXTRA=_super

    compile_opt idl2, hidden

    if (N_ELEMENTS(colorModel) eq 1) then $
        self._colorModel = colorModel

    if(N_ELEMENTS(_super) gt 0)then $
        self->IDLitWriter::SetProperty, _EXTRA=_super
end


;---------------------------------------------------------------------------
; Implementation
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
; Purpose:
;   Procedure for writing data out to the file.
;
; Arguments:
;   ImageData: An object reference to the data to be written.
;
; Keywords:
;   None.
;
function IDLitWriteEPS::SetData, oItemIn

    compile_opt idl2, hidden

    strFilename = self->GetFilename()

    ; If we are a winscene, get the scene
    oItem = OBJ_ISA(oItemIn, "_IDLitgrDest") ? $
        oItemIn->GetScene() : oItemIn

    ; Do we have to rasterize this ?
    if (OBJ_ISA(oItem, "IDLitgrScene") || $
        OBJ_ISA(oItem, "IDLitgrView")) then begin

        oTool = self->GetTool()

        ; Get the system rastor service.
        oClipCopy = oTool->GetService("SYSTEM_CLIPBOARD_COPY")
        oClipCopy->SetProperty, SCALE_FACTOR=self._scaleFactor

        ; Do the draw
        status = oClipCopy->DoWindowCopy(oTool->GetCurrentWindow(), oItem, $
            FILENAME=strFilename, /POSTSCRIPT, VECTOR=self._graphicsFormat, $
            CMYK=self._colormodel)
        return, status

    endif

    return, 0  ; failure
end


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; Purpose:
;   Class definition.
;
pro IDLitWriteEPS__Define

    compile_opt idl2, hidden

    void = {IDLitWriteEPS, $
        inherits IDLitWriter, $
        _colormodel: 0b $
        }
end
