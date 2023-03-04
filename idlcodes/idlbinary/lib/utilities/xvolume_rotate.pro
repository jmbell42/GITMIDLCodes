;$Id: //depot/idl/IDL_63_RELEASE/idldir/lib/utilities/xvolume_rotate.pro#1 $
;
;  Copyright (c) 1997-2006, Research Systems, Inc. All rights reserved.
;       Unauthorized reproduction prohibited.
;
pro xvolume_rotate, $
    axis, $     ; IN: three-element vector about which to rotate.
    angle, $    ; IN: The amount (measured in degrees) of rotation
    tlb=tlb_, $ ; IN: (opt) Widget ID of an xvolume.
    premultiply=premultiply ; IN: (opt) if set, do "data-centric" rotation.
;
;Purpose:  Provide an interface to the same behavior that occurs
;when a user rotates xvolume's graphic with the mouse.
;If input keyword TLB is not supplied, and if at least one instance of
;xvolume is currently running, then this routine will operate on
;the most recently created currently-running xvolume.
;
;Example:
;   xvolume, /test
;   for i=0,29 do begin
;       xvolume_rotate, [0,1,0], 1, /premult
;       xvolume_write_image, $
;           'img' + strcompress(i, /remove_all) + '.bmp', 'bmp'
;       end
;
on_error, 2

if n_elements(tlb_) gt 0 then begin
    xobjview_rotate, axis, angle, tlb=tlb_, premultiply=premultiply
    end $
else begin
    if xregistered('xVolume') eq 0 then $
        message, 'No valid XVOLUME available.'
    tlb = LookupManagedWidget('xVolume')

    widget_control, tlb, get_uvalue=pState
    (*pState).oObjViewWid->Rotate, axis, angle, premultiply=premultiply
    end

end
