;$Id: //depot/idl/IDL_63_RELEASE/idldir/lib/utilities/xobjview_write_image.pro#1 $
;
;  Copyright (c) 1997-2006, Research Systems, Inc. All rights reserved.
;       Unauthorized reproduction prohibited.
;
pro xobjview_write_image, $
    filename, $ ; IN
    format, $   ; IN: scalar string (e.g. 'bmp', 'jpeg', etcetera).
    tlb=tlb_, $ ; IN: (opt) Widget ID of an xobjview (or similar widget).
    dimensions=dimensions   ; IN: (opt) Pixel size of output. [x, y].
;
;Purpose: Write (to a file) a picture from a currently-running xobjview.
;If input keyword TLB is not supplied, and if at least one instance of
;xobjview is currently running, then this routine will write a picture
;from the most recently created currently-running xobjview.  
;
;See IDL's query_image command for a list of valid file FORMATs.
;
;Example:
;   xobjview, /test
;   for i=0,359 do begin
;       xobjview_rotate, [0,1,0], 1, /premult
;       xobjview_write_image, $
;           'img' + strcompress(i, /remove_all) + '.bmp', 'bmp'
;       end
;
on_error, 2
;
;Obtain valid TLB.
;
if n_elements(tlb_) gt 0 then begin
    if size(tlb_, /tname) ne 'LONG' then $
        message, 'TLB must be of type LONG.'
    if n_elements(tlb_) gt 1 then $
        message, 'TLB must be a single value.'
    if not widget_info(tlb_, /valid_id) then $
        message, 'Invalid TLB.'
    widget_control, tlb_, get_uvalue=pState
    if not ptr_valid(pState) then $
        message, 'Incorrect TLB.'
    if size(*pState, /tname) ne 'STRUCTURE' then $
        message, 'Incorrect TLB.'
    if max(tag_names(*pState) eq 'OOBJVIEWWID') eq 0 then $
        message, 'Incorrect TLB.'
    tlb = tlb_
    end $
else begin
    if xregistered('xobjview') eq 0 then $
        message, 'No valid XOBJVIEW available.'
    tlb = LookupManagedWidget('xobjview')
    end
;
;Export from TLB.
;
widget_control, tlb, get_uvalue=pState
(*pState).oObjViewWid->WriteImage, $
    filename, format, dimensions=dimensions

end
