; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/vmscode.pro#1 $
;
; Copyright (c) 1988-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

function VMSCODE, CODE, FROM_V1VMS=from_vms
;+
; Name:
;	VMSCODE
;
; PURPOSE:
;	Convert between VMS Version 1 and the newer IDL type codes.
;
;		Type	       VMS V1	Current
;		-------------------------------
;		undefined	  0	  0
;		byte		  2	  1
;		int		  4	  2
;		long		 16	  3
;		float		  8	  4
;		double		 32	  5
;		complex		 64	  6
;		string		  1	  7
;		structure	128	  8
;
; CATEGORY:
;	Misc.
;
; CALLING SEQUENCE:
;	VMSCODE, Code
;
; INPUTS:
;	Code:	The type code to be converted.
;
; KEYWORDS:
;   FROM_V1VMS:	Normally, CODE is taken to be for the current system
;		and is is converted to it's VMS V1 counterpart. If FROM_V1VMS
;		is present and non-zero, the conversion direction is reversed.
;
; OUTPUTS:
;	The translated code is returned as an integer.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	None.
;
; RESTRICTIONS:
;	None.
;
; MODIFICATION HISTORY:
;	AB, RSI, February 1988
;-
    on_error,2                          ;Return to caller if an error occurs
    vms_codes = [0, 2, 4, 16, 8, 32, 64, 1, 128]

    if (KEYWORD_SET(from_vms)) then begin
	    for i=0,8 do if (code eq vms_codes(i)) then return,i
	    return,0	; If code was invalid, return TYP_UNDEF.
	endif else begin
	    ; If bad code, return TYP_UNDEF
	    if ((code lt 0) or (code gt 8)) then return,0
	    return,vms_codes(code);	; Valid code - translate
	endelse
end
