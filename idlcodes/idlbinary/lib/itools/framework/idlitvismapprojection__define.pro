; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/framework/idlitvismapprojection__define.pro#1 $
;
; Copyright (c) 2004-2006, Research Systems, Inc.  All rights reserved.
;    Unauthorized reproduction prohibited.
;
;+
; CLASS_NAME:
;    IDLitVisMapProjection
;
; PURPOSE:
;    The IDLitVisMapProjection class is a helper class for viz objects with
;    map projection data.
;
; MODIFICATION HISTORY:
;     Written by:   CT, May 2004
;-


;----------------------------------------------------------------------------
function IDLitVisMapProjection::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->_IDLitVisualization::Init(NAME='Map Projection', $
        IMPACTS_RANGE=0, $
        /PRIVATE, $
        /ISOTROPIC, $
        ICON='surface', $
        _EXTRA=_extra)) then $
        return, 0

    if (~self->_IDLitMapProjection::Init(_EXTRA=_extra)) then $
        return, 0

    ; Request no axes.
    self->SetAxesRequest, 0, /ALWAYS

    self->SetPropertyAttribute, ['NAME', 'DESCRIPTION', 'HIDE'], /HIDE

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisMapProjection::SetProperty, _EXTRA=_extra

    return, 1 ; Success
end


;----------------------------------------------------------------------------
pro IDLitVisMapProjection::GetProperty, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    self->_IDLitVisualization::GetProperty, _EXTRA=_extra
    self->_IDLitMapProjection::GetProperty, _EXTRA=_extra

end


;----------------------------------------------------------------------------
pro IDLitVisMapProjection::SetProperty, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    self->_IDLitVisualization::SetProperty, _EXTRA=_extra
    self->_IDLitMapProjection::SetProperty, _EXTRA=_extra

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisMapProjection__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisMapProjection object.
;
;-
pro IDLitVisMapProjection__Define

    compile_opt idl2, hidden

    struct = { IDLitVisMapProjection, $
        inherits _IDLitVisualization, $
        inherits _IDLitMapProjection $
        }
end
