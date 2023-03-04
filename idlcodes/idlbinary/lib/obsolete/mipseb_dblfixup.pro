; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/mipseb_dblfixup.pro#1 $
;
; Copyright (c) 1992-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

; NAME:
;	MIPSEB_DBLFIXUP
;
; PURPOSE:
;	This procedure exists to fix data improperly written
;	by IDL due to two separate bugs that have occured in IDL
;	at different times in its handling of XDR double precision
;	data on MIPS cpu based machines (SGI, MIPS, and Dec Risc Ultrix)
;
;	Bug#1: SGI and MIPS, but not the DecStation).
;	---------------------------------------------
;
;	    IDL 2.4.0 and earlier has a bug that affects users of 
;	    big-endian MIPS cpu based machines. On these systems, all
;	    XDR output of double precision floating point data has its
;	    least and most significant longwords reversed. This presents no
;	    problem as long as such files are only used on these
;	    machines. However, XDR files with double precision
;	    data cannot be moved between these machines and others
;	    without the need to correct the data.
;
;	    To further complicate matters, IDL versions later than 2.4.0
;	    have this bug corrected, meaning that older double precision
;	    data saved on one of these machines cannot be restored using
;	    a newer version of IDL without using this routine to correct
;	    the data.
;
;	Bug#2: Dec Risc Ultrix (DecStation) only
;	---------------------------------------------
;	    IDL 4.0 for Dec Ultrix has a bug that causes all
;	    XDR double precision floating point data to have its
;	    least and most significant longwords reversed. This presents
;	    no problem as long as such files are only used on these
;	    machines. However, XDR files with double precision
;	    data cannot be moved between these machines and others
;	    without the need to correct the data.

;
;      IDL uses XDR for Save/Restore files, and for files opened
;      with the XDR keyword to OPENR, OPENW, and OPENU.
;
;	
; CATEGORY:
;	Bug impact mitigation.
;
; CALLING SEQUENCE:
;	MIPSEB_DBLFIXUP, VAR
;
; INPUTS:
;	VAR - An IDL variable of any type (excluding ASSOC variables).
;		Scalars, arrays, and structures are supported.
;
; OUTPUTS:
;	VAR - Any double precision floating point data contained in
;	      VAR has had its least and most significant longwords
;	      swapped.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	None.
;
; MODIFICATION HISTORY:
;	12, November, 1992, AB
;	24 July 1995, AB, Updated documentation header to discuss
;		explain new error.
;-
;
;

PRO MIPSEB_DBLFIXUP, VAR

  on_error, 2				; Return to caller if an error occurs

  s = size(var)
  type = s(s(0)+1)
  elts = s(s(0) + 2) - 1

  if (type eq 5) then begin
    for i = 0, elts do begin
      val = long(var, i*8, 2)		; Pull out double as two longwords
      ; Swap the two longwords
      tmp = val(0)
      val(0) = val(1)
      val(1) = tmp
      var(i) = double(val, 0, 1)	; Put it back
    endfor
  endif else if (type eq 8) then begin
	n = n_tags(var) - 1
	for i = 0, n do begin
	    newvar = var.(i)		; Needs to be named var instead of expr
	    mipseb_dblfixup, newvar	; Recursively fix each tag.
	    var.(i) = newvar
	endfor
  endif
end