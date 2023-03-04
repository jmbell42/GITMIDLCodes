; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/components/idlitsymbol__define.pro#1 $
;
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;    Unauthorized reproduction prohibited.
;
;+
; CLASS_NAME:
;    IDLitSymbol
;
; PURPOSE:
;    The IDLitSymbol class is the component wrapper for IDLgrSymbol.
;
; CATEGORY:
;    Components
;
; SUPERCLASSES:
;   IDLitComponent
;
; SUBCLASSES:
;
; MODIFICATION HISTORY:
;     Written by:   Chris, August 2002
;-


;----------------------------------------------------------------------------
pro IDLitSymbol::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin

        ; Register font properties.
        self->RegisterProperty, 'SYM_INDEX', $
            /SYMBOL, $
            NAME='Symbol', $
            DESCRIPTION='Symbol index'

        self->RegisterProperty, 'SYM_SIZE', /FLOAT, $
            NAME='Symbol size', $
            DESCRIPTION='Symbol size', $
            VALID_RANGE=[0,1,0.01d]

        ; Allow handling the aggregated color of the parent
        ; makes it possible to set the symbol color to the
        ; color of the parent if use_default_color is set to true.
        ; Note: We must register the property because aggregation
        ; only passes on registered properties.
        self->RegisterProperty, 'COLOR', /COLOR, $
            NAME='Color', $
            DESCRIPTION='Color', $
            /HIDE

        self->RegisterProperty, 'USE_DEFAULT_COLOR', /BOOLEAN, $
            NAME='Use default color', $
            DESCRIPTION='Use the default color instead of the symbol color'

        self->RegisterProperty, 'SYM_COLOR', /COLOR, $
            NAME='Symbol color', $
            DESCRIPTION='Symbol color'

        self->RegisterProperty, 'SYM_THICK', /FLOAT, $
            NAME='Symbol thickness', $
            DESCRIPTION='Symbol thickness', $
            VALID_RANGE=[1.0,10.0, .1d]

        self->RegisterProperty, 'SYM_INCREMENT', /INTEGER, $
            DESCRIPTION='Symbol spacing increment', $
            NAME='Symbol increment', $
            VALID_RANGE=[1, 2147483646], $
            /HIDE   ; only needed for certain classes

    endif

    ; prior to 6.1 these props were created insensitive
    ; there is no need to alter the settings of a restored
    ; symbol, however, since the sensitivity is managed
    ; by the SYM_INDEX property.
    ;['SYM_SIZE', $
    ; 'USE_DEFAULT_COLOR', $
    ; 'SYM_COLOR', $
    ; 'SYM_THICK', $
    ; 'SYM_INCREMENT' $
    ; ]

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitSymbol::Init
;
; PURPOSE:
;    Initialize this component
;
; CALLING SEQUENCE:
;
;    Obj = OBJ_NEW('IDLitSymbol')
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;   All keywords that can be used for IDLgrSymbol
;
; OUTPUTS:
;    This function method returns 1 on success, or 0 on failure.
;
;-
function IDLitSymbol::Init, PARENT=oParent, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass
    success = self->IDLitComponent::Init(NAME='IDLitSymbol')

    if (not success) then $
      return, 0

    ; Create symbol object with default of "no symbol".
    symSize = 0.2d   ; initial default, will be scaled by data range after init
    self._oSymbol = OBJ_NEW('IDLgrSymbol', DATA=0, SIZE=symSize)
    self._symbolSize = symSize
    self._useDefaultColor = 1b  ; true

    self->IDLitSymbol::_RegisterProperties

    if (N_ELEMENTS(oParent) gt 0) then $
        self._oParent=oParent

    ; Set any properties
    self->IDLitSymbol::SetProperty, _EXTRA=_extra

    RETURN, 1 ; Success
end


;----------------------------------------------------------------------------
pro IDLitSymbol::Cleanup

    compile_opt idl2, hidden

    OBJ_DESTROY, self._oSymbol

    ; Cleanup superclass
    self->IDLitComponent::Cleanup

end


;----------------------------------------------------------------------------
; IDLitSymbol::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitSymbol::Restore
    compile_opt idl2, hidden

    ; No need to call superclass restore (IDLitComponent::Restore)

    ; Register new properties.
    self->IDLitSymbol::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion
end


;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitSymbol::GetProperty
;
; PURPOSE:
;      This procedure method retrieves the
;      value of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitSymbol::]GetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitSymbol::Init followed by the word "Get"
;      can be retrieved using IDLitSymbol::GetProperty.
;
;-
pro IDLitSymbol::GetProperty, $
    SYM_INDEX=symbolIndex, $
    SYM_SIZE=symbolSize, $
    SYM_COLOR=symbolColor, $
    SYM_INCREMENT=symIncrement, $
    SYM_THICK=symbolThick, $
    SYM_TRANSPARENCY=symbolTransparency, $
    USE_DEFAULT_COLOR=useDefaultColor, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden


    ; Get my properties
    if ARG_PRESENT(symbolIndex) then $
        symbolIndex = self._symbolIndex

    ; This gets handled by the IDLitVisPlot class.
    if ARG_PRESENT(symIncrement) then $
        symIncrement = 1

    if ARG_PRESENT(symbolSize) then begin
        symbolSize = self._symbolSize
    endif

    if ARG_PRESENT(useDefaultColor) then $
        useDefaultColor = self._useDefaultColor

    if ARG_PRESENT(symbolColor) then begin
        self._oSymbol->GetProperty, COLOR=color
        if ARRAY_EQUAL(color, -1) then begin
            ; retrieve the color from the parent
            ; the symbol's color is -1, indicating match the parent,
            ; but the property sheet needs a real color to display
            self._oParent->GetProperty, COLOR=symbolColor
        endif else begin
            symbolColor = color
        endelse
    endif


    if ARG_PRESENT(symbolThick) then $
        self._oSymbol->GetProperty, THICK=symbolThick

    if ARG_PRESENT(symbolTransparency) then begin
        self._oSymbol->GetProperty, ALPHA_CHANNEL=alpha
        symbolTransparency = 0 > FIX(100 - alpha*100) < 100
    endif

    ; Get superclass properties
    self->IDLitComponent::GetProperty, _EXTRA=_extra

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitSymbol::SetProperty
;
; PURPOSE:
;      This procedure method sets the value
;      of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitSymbol::]SetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitSymbol::Init followed by the word "Set"
;      can be set using IDLitSymbol::SetProperty.
;-

pro IDLitSymbol::SetProperty,  $
    COLOR=color, $
    SYM_INCREMENT=swallow, $   ; don't handle in our class
    SYM_INDEX=symbolIndex, $
    SYM_SIZE=symbolSize, $
    SYM_COLOR=symbolColor, $
    SYM_THICK=symbolThick, $
    SYM_TRANSPARENCY=symbolTransparency, $
    USE_DEFAULT_COLOR=useDefaultColor, $
    _EXTRA=_extra

    compile_opt idl2, hidden


    ; Set font properties.
    if (N_ELEMENTS(symbolIndex)) then begin

        ; SYM_INDEX
        self._symbolIndex = symbolIndex

        self._oSymbol->SetProperty, $
            DATA=self._symbolIndex

        ; (De)sensitize my symbol properties.
        self->SetPropertyAttribute, $
            ['SYM_SIZE', 'USE_DEFAULT_COLOR', $
            'SYM_THICK', 'SYM_INCREMENT'], $
            SENSITIVE=(self._symbolIndex gt 0)
        ; Need to handle separately since it depends upon use_default_color.
        self->SetPropertyAttribute, 'SYM_COLOR', $
            SENSITIVE=(~self._useDefaultColor) && (self._symbolIndex gt 0)

    endif


    ; scale by data space range
    if ((N_ELEMENTS(symbolSize) gt 0) AND $
        (OBJ_VALID(self._oParent))) then begin
        self->GetPropertyAttribute, 'SYM_SIZE', VALID_RANGE=validRange
        symbolSize >= validRange[0]
        symbolSize <= validRange[1]
        self._symbolSize = symbolSize
        ; determined experimentally to give a nice range to the
        ; symbol size given the user's range of 0 to 1.
        symbolFactor = 20.0
        if (OBJ_ISA(self._oParent, 'IDLgrPolyline')) then begin
            self._oSymbol->SetProperty, $
                        SIZE=symbolSize/symbolFactor/2*[2,2] ;adjust for annotation layer
        endif else begin

;           This code is an attempt to construct a normalized symbol size
;           that looks correct regardless of model transforms
;           screen dimensions, etc.
;           It works beautifully, except for the problem that when you
;           change the dataspace range, this code gets called before
;           the dataspace has been fully updated. Hence, you need to
;           tweak the sym size again to get it to update properly.
;           Also, if you scale your plot, the symbols get squashed until
;           you tweak the sym size, when they again get fixed.
;
;            if (OBJ_VALID(self._oParent->GetTool())) then begin
;                symbolFactor = 0.01   ; not verified
;                ; Transform data space origin to screen space.
;                self._oParent->_IDLitVisualization::VisToWindow, $
;                    [0.0d, 0.0d, 0.0d], scrOrig
;                ; Transform +1 in X to screen space.
;                self._oParent->_IDLitVisualization::VisToWindow, $
;                    [1.,0.,0.], xpixel
;                ; Transform +1 in Y to screen space.
;                self._oParent->_IDLitVisualization::VisToWindow, $
;                    [0.,1.,0.], ypixel
;                ; Length of +1 in X & Y in screen pixels.
;                xpixel = SQRT(TOTAL((xpixel[0:1] - scrOrig[0:1])^2))
;                ypixel = SQRT(TOTAL((ypixel[0:1] - scrOrig[0:1])^2))
;                self._oSymbol->SetProperty, $
;                    SIZE=symbolSize/symbolFactor/[xpixel[0],ypixel[0]]
;            endif

            ; Instead of the nice method above, we will simply take
            ; the dataspace axes range, and construct a normalized
            ; symbol size. This does not take into account the window
            ; aspect ratio or any parent model scaling, so symbols
            ; may look squashed.
            oDataSpace = self._oParent->GetDataSpace(/UNNORMALIZED)
            if (OBJ_VALID(oDataSpace)) then begin
                if (oDataSpace-> $
                    _GetXYZAxisRange(xRange, yRange, zRange)) then begin
                    self._oSymbol->SetProperty, $
                        SIZE=symbolSize/symbolFactor*[xRange[1]-xRange[0], $
                                                  yRange[1]-yRange[0]]
                endif
            endif

        endelse
    endif

    ; handle this explicitly to allow following the aggregated color
    ; of the parent
    if (N_ELEMENTS(color) gt 0 && self._useDefaultColor) then begin
        self._oSymbol->SetProperty, COLOR=color
    endif

    if (N_ELEMENTS(useDefaultColor) gt 0) then begin
        ; after internal fix, this flag and setting should be unneccessary
        self._useDefaultColor = useDefaultColor
        self->SetPropertyAttribute, 'SYM_COLOR', $
            SENSITIVE=(~self._useDefaultColor) && (self._symbolIndex gt 0)
        ; If going back to default, set our symbol color to the color
        ; of the parent
        if KEYWORD_SET(useDefaultColor) then begin
            ; match the color of the parent
            self._oParent->GetProperty, COLOR=color
            self._oSymbol->SetProperty, COLOR=color
        endif

    endif

    if (N_ELEMENTS(symbolColor) gt 0) then begin
        ; If this property is being set programmatically,
        ; then set the symbol color regardless of USE_DEFAULT_COLOR,
        ; but *do not* change the value of USE_DEFAULT_COLOR,
        ; otherwise Styles behave incorrectly.
        self._oSymbol->SetProperty, COLOR=symbolColor
    endif

    if (N_ELEMENTS(symbolThick) gt 0) then $
        self._oSymbol->SetProperty, THICK=symbolThick

    if (N_ELEMENTS(symbolTransparency)) then begin
        self._oSymbol->SetProperty, $
            ALPHA_CHANNEL=0 > ((100.-symbolTransparency)/100) < 1
    endif

    ; Set superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitComponent::SetProperty, _EXTRA=_extra


end


;----------------------------------------------------------------------------
function IDLitSymbol::GetSymbol

    compile_opt idl2, hidden
    return, self._oSymbol

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitSymbol__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitSymbol object.
;
;-
pro IDLitSymbol__Define

    compile_opt idl2, hidden

    struct = { IDLitSymbol,           $
        inherits IDLitComponent, $
        _oSymbol: OBJ_NEW(), $
        _oParent: OBJ_NEW(), $
        _symbolSize: 0d, $     ; the unscaled size
        _useDefaultColor: 0b, $
        _symbolIndex: 0b $
    }
end
