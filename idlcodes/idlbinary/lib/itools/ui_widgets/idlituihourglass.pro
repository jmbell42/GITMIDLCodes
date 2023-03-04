; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/ui_widgets/idlituihourglass.pro#1 $
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;   IDLitUIHourGlass
;
; PURPOSE:
;   Impelments a ui service that sets the hourglass cursor
;
;-



;-------------------------------------------------------------------------
function IDLitUIHourGlass, oUI, oRequester
    compile_opt idl2, hidden
    ;; pretty simple
    catch, err
    if (err ne 0) then begin
        catch, /cancel
        return,1
    endif
    if (WIDGET_INFO(/ACTIVE)) then $
        widget_control, /hourglass
    return,1
end

