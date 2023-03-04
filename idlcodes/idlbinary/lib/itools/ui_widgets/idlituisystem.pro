; $ID:$
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;   IDLitUISystem
;
; PURPOSE:
;   Initializes the system us
;
; CALLING SEQUENCE:
;   IDLitUISystem, oSystem
;
; INPUTS:
;   oSystem  - The system object
;-



;-------------------------------------------------------------------------
Pro IDLitUISystem, oSystem
    compile_opt idl2, hidden

    ;; Pretty simple, just create an UI object and associated it with
    ;; the system.
    oUI = OBJ_NEW('IDLitUI', osystem)

end

