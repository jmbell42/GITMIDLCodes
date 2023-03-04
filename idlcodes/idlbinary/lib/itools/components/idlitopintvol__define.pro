; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/components/idlitopintvol__define.pro#1 $
;
; Copyright (c) 2003-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopIntVol
;
; PURPOSE:
;   This operation creates an Interval Volume for a volume.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitopIsoSurface
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopIntVol::Init
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopIntVol::Init
;
; Purpose:
; The constructor of the IDLitopIntVol object.
;
; Parameters:
; None.
;
function IDLitopIntVol::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    ;; This only works with volumes as input
    if ~self->IDLitopIsoSurface::Init( $
        NAME="Interval Volume", $
        DESCRIPTION="IDL Interval Volume") then $
        return, 0

    self._uiService = 'IntervalVolume'

    self->SetPropertyAttribute, '_ISOVALUE0', NAME="Isovalue 0"
    self->SetPropertyAttribute, '_ISOVALUE1', HIDE=0

    return, 1
end


;-------------------------------------------------------------------------
pro IDLitopIntVol__define
    compile_opt idl2, hidden
    struc = {IDLitopIntVol, $
             inherits IDLitopIsoSurface $
            }

end

