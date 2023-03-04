; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/framework/idlitopbringtofront__define.pro#1 $
;
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;----------------------------------------------------------------------------
;;---------------------------------------------------------------------------
;; IDLitopBringToFront::DoAction
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopBringToFront::DoAction, oTool

    compile_opt idl2, hidden

    return, self->IDLitopOrder::DoAction(oTool, 'Bring to Front')
end


;-------------------------------------------------------------------------
pro IDLitopBringToFront__define

    compile_opt idl2, hidden
    struc = {IDLitopBringToFront, $
        inherits IDLitopOrder}

end

