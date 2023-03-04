; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/framework/idlitophelpabout__define.pro#1 $
;
; Copyright (c) 2000-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopHelpAbout
;
; PURPOSE:
;    Simple op to relay a call to "help about"
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopHelpAbout::Init
;
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopHelpAbout::Init
;;
;; Purpose:
;; The constructor of the IDLitopHelpAbout object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
;function IDLitopHelpAbout::Init, _REF_EXTRA=_extra
;    compile_opt idl2, hidden
;    return, self->IDLitOperation::Init(_EXTRA=_extra)
;end


;;---------------------------------------------------------------------------
;; IDLitopHelpAbout::DoAction
;;
;; Purpose:
;;    Will cause Help About to be displayed
;;
;; Parameters:
;;   oTool - The tool
;; None.
;;
function IDLitopHelpAbout::DoAction, oTool

    compile_opt idl2, hidden

    status = oTool->DoUIService("IDLitAboutITools", self)

    return, obj_new()
end


;-------------------------------------------------------------------------
pro IDLitopHelpAbout__define

    compile_opt idl2, hidden
    struc = {IDLitopHelpAbout, $
        inherits IDLitOperation}

end

