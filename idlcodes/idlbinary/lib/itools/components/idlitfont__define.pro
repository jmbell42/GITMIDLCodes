; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/components/idlitfont__define.pro#1 $
;
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;    Unauthorized reproduction prohibited.
;
;+
; CLASS_NAME:
;    IDLitFont
;
; PURPOSE:
;    The IDLitFont class is the component wrapper for IDLgrFont.
;
; CATEGORY:
;    Components
;
; SUPERCLASSES:
;   IDLgrFont
;
; SUBCLASSES:
;
; METHODS:
;  Intrinisic Methods
;    IDLitFont::Cleanup
;    IDLitFont::Init
;
;  Private Methods
;
;  IIDLProperty Interface
;    IDLitFont::GetProperty
;    IDLitComponent::QueryPropertyDescriptor
;    IDLitComponent::RegisterProperty
;    IDLitFont::SetProperty
;
; MODIFICATION HISTORY:
;     Written by:   Chris, August 2002
;-


;----------------------------------------------------------------------------
pro IDLitFont::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin

        ; Register font properties.
        self->RegisterProperty, 'FONT_INDEX', $
            ENUMLIST=['Helvetica', 'Courier', 'Times', 'Symbol', 'Hershey'], $
            NAME='Text font', $
            DESCRIPTION='Font name'

        self->RegisterProperty, 'FONT_STYLE', $
            ENUMLIST=['Normal', 'Bold', 'Italic', 'Bold Italic'], $
            NAME='Text style', $
            DESCRIPTION='Font style'

        self->RegisterProperty, 'FONT_SIZE', /INTEGER, $
            NAME='Text font size', $
            DESCRIPTION='Font size in points', $
            VALID_RANGE=[1,1000];
    endif

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitFont::Init
;
; PURPOSE:
;    Initialize this component
;
; CALLING SEQUENCE:
;
;    Obj = OBJ_NEW('IDLitFont')
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;   All keywords that can be used for IDLgrFont
;
; OUTPUTS:
;    This function method returns 1 on success, or 0 on failure.
;
;-
function IDLitFont::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass
    success = self->IDLitComponent::Init(NAME='IDLitFont')

    if (not success) then $
      return, 0

    self._oFont = OBJ_NEW('IDLgrFont')
    self._oFont->GetProperty, SIZE=fSize
    self._fontSize = fSize
    self._fontZoom = 1.0
    self._viewZoom = 1.0
    self._fontNorm = 1.0

    self->IDLitFont::_RegisterProperties

    ; Set any properties
    self->IDLitFont::SetProperty, _EXTRA=_extra

    RETURN, 1 ; Success
end


;----------------------------------------------------------------------------
pro IDLitFont::Cleanup

    compile_opt idl2, hidden

    OBJ_DESTROY, self._oFont

    ; Cleanup superclass
    self->IDLitComponent::Cleanup

end


;----------------------------------------------------------------------------
; IDLitFont::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitFont::Restore
    compile_opt idl2, hidden

    ; No need to call superclass restore (IDLitComponent::Restore)

    ; Register new properties.
    self->IDLitFont::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion

    ; ---- Required for SAVE files transitioning ----------------------------
    ;      from IDL 6.0 to 6.1 or above:
    if (self.idlitcomponentversion lt 610) then begin
        self._oFont->GetProperty, SIZE=fSize
        self._fontSize = fSize
        self._fontZoom = 1.0
    endif    

    ; ---- Required for SAVE files transitioning ----------------------------
    ;      to 6.2 or above:
    if (self.idlitcomponentversion lt 620) then begin
        self._viewZoom = 1.0
        self._fontNorm = 1.0
    endif    

end


;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitFont::GetProperty
;
; PURPOSE:
;      This procedure method retrieves the
;      value of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitFont::]GetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitFont::Init followed by the word "Get"
;      can be retrieved using IDLitFont::GetProperty.
;
;-
pro IDLitFont::GetProperty, $
    FONT_INDEX=fontIndex, $
    FONT_NORM=fontNorm, $
    FONT_SIZE=fontSize, $
    FONT_STYLE=fontStyle, $
    FONT_ZOOM=fontZoom, $
    VIEW_ZOOM=viewZoom, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden


    ; Get my properties
    if ARG_PRESENT(fontIndex) then $
        fontIndex = self._fontindex
    if ARG_PRESENT(fontStyle) then $
        fontStyle = self._fontstyle
    if ARG_PRESENT(fontSize) then $ ; Report un-zoomed font size.
        fontSize = FIX(self._fontsize)
    if ARG_PRESENT(fontZoom) then $
        fontZoom = self._fontzoom
    if ARG_PRESENT(viewZoom) then $
        viewZoom = self._viewZoom
    if ARG_PRESENT(fontNorm) then $
        fontNorm = self._fontNorm

    ; Get superclass properties
    self->IDLitComponent::GetProperty, _EXTRA=_extra

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitFont::SetProperty
;
; PURPOSE:
;      This procedure method sets the value
;      of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitFont::]SetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitFont::Init followed by the word "Set"
;      can be set using IDLitFont::SetProperty.
;-

pro IDLitFont::SetProperty,  $
    FONT_INDEX=fontIndex, $
    FONT_NORM=fontNorm, $
    FONT_STYLE=fontStyle, $
    FONT_SIZE=fontSize, $
    FONT_ZOOM=fontZoom, $
    VIEW_ZOOM=viewZoom, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    ; Set font properties.
    if (N_ELEMENTS(fontIndex) or N_ELEMENTS(fontStyle)) then begin

        ; FONT_STYLE
        ; Make sure the font style is within the valid range.
        self->GetPropertyAttribute, 'FONT_STYLE', ENUMLIST=fontstylenames
        if N_ELEMENTS(fontStyle) then $
            self._fontstyle = 0 > fontStyle < (N_ELEMENTS(fontstylenames)-1)

        ; FONT_INDEX
        ; Make sure the font index is within the valid range.
        self->GetPropertyAttribute, 'FONT_INDEX', ENUMLIST=fontnames
        if N_ELEMENTS(fontIndex) then $
            self._fontindex = 0 > fontIndex < (N_ELEMENTS(fontnames)-1)

        fontname = fontnames[self._fontindex]
        isSymbol = (fontname eq 'Symbol')

        ; There is no Italic or Bold for the Symbol font.
        if isSymbol then $
            self._fontstyle = 0

        ; In case the font changes to/from Symbol,
        ; disable/enable the style property.
        if (isSymbol OR self._wasSymbol) then begin
            self->IDLitComponent::SetPropertyAttribute, $
                'FONT_STYLE', SENSITIVE=1-isSymbol
        endif

        self._wasSymbol = isSymbol

;        stylenames = ['Normal', 'Bold', 'Italic', 'Bold Italic']

        styles = (fontname eq 'Hershey') ? $
            ['', '*17', '*8', '*18'] : $
            ['', '*Bold', '*Italic', '*Bold*Italic']

        self._oFont->SetProperty, $
            NAME=fontname+styles[self._fontstyle]
    endif


    ; FONT_SIZE
    bUpdateSize = 0b
    if (N_ELEMENTS(fontSize) gt 0) then begin
        self._fontSize = fontSize
        bUpdateSize = 1b
    endif

    ; FONT_ZOOM
    if (N_ELEMENTS(fontZoom) gt 0) then begin
        self._fontZoom = fontZoom
        bUpdateSize = 1b
    endif

    ; VIEW_ZOOM
    if (N_ELEMENTS(viewZoom) gt 0) then begin
        self._viewZoom = viewZoom
        bUpdateSize = 1b
    endif

    ; FONT_NORM
    if (N_ELEMENTS(fontNorm) gt 0) then begin
        self._fontNorm = fontNorm
        bUpdateSize = 1b
    endif

    ; Displayed font size is set to:
    ;   FS * CanvasZoom * ViewZoom * FontNorm
    ; where:
    ;   FS = reported font size (as it appears in the property sheet)
    ;   FontNorm = a normalizing factor [usually: the minimum normalized 
    ;     dimension of the view (relative to the window in which it appears) 
    ;     in which the text appears].
    if (bUpdateSize) then begin
        dspFontSize = self._fontsize
        if (self._fontzoom ne 1.0) then $
            dspFontSize *= self._fontzoom
        if (self._viewzoom ne 1.0) then $
            dspFontSize *= self._viewzoom
        if (self._fontNorm ne 1.0) then $
            dspFontSize *= self._fontNorm
        if (dspFontSize lt 0.1) then $
            dspFontSize = 0.1
        self._oFont->SetProperty, SIZE=dspFontSize
    endif
    
    ; Set superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitComponent::SetProperty, _EXTRA=_extra

end


;----------------------------------------------------------------------------
function IDLitFont::GetFont

    compile_opt idl2, hidden
    return, self._oFont

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitFont__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitFont object.
;
;-
pro IDLitFont__Define

    compile_opt idl2, hidden

    struct = { IDLitFont,           $
        inherits IDLitComponent, $
        _oFont: OBJ_NEW(), $
        _fontindex: 0L,              $
        _fontsize: 0.0,              $
        _fontstyle: 0L,              $
        _fontzoom: 0.0,              $  ; Canvas zoom.
        _viewzoom: 0.0,              $  ; View zoom.
        _fontNorm: 0.0,              $  ; Normalizing factor for font size.
        _wasSymbol: 0L               $
    }
end
