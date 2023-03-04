; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/framework/idlitopsendtoback__define.pro#1 $
;
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;----------------------------------------------------------------------------
;;---------------------------------------------------------------------------
;; IDLitopSendToBack::DoAction
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopSendToBack::DoAction, oTool

    compile_opt idl2, hidden

    return, self->IDLitopOrder::DoAction(oTool, 'Send to Back')
end


;-------------------------------------------------------------------------
pro IDLitopSendToBack__define

    compile_opt idl2, hidden
    struc = {IDLitopSendToBack, $
        inherits IDLitopOrder}

end

