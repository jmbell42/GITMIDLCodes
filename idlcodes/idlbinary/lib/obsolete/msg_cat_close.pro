; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/msg_cat_close.pro#1 $
;
; Copyright (c) 1998-2006, Research Systems, Inc.  All rights reserved.
;	Unauthorized reproduction prohibited.
;
;+
; NAME:
;	MSG_CAT_CLOSE
;
; PURPOSE:
;	This function will close a catalog.
;
; CATEGORY:
;	Internationalization
;
; CALLING SEQUENCE:
;	MSG_CAT_CLOSE, object
;
; INcloseS:
;	object - The catalog object reference returned from MSG_CAT_OPEN.
;
; EXAMPLE:
;	MSG_CAT_CLOSE, oCat
;
; MODIFICATION HISTORY
;	Written by:	Scott Lasica,  11/13/98
;-

pro MSG_CAT_CLOSE, object
	common I18N_CATALOG_COMMON, oCats, refCnt

	on_error,2

	if (not OBJ_VALID(object)) then return
	n_oCats = N_ELEMENTS(oCats)
	if ((n_oCats eq 0) or (N_ELEMENTS(refCnt) eq 0)) then return
	obj_destroy, object
	; Remove the object from the list
	found = where(object eq oCats)
	idx = found[0]
	if (idx ne -1) then begin
		refCnt = refCnt - 1
 		; Remove entry from oCats array
		if (n_oCats eq 1) then begin
		  toss_this = temporary(oCats)	; Make list undefined again
	        endif else if (idx eq 0) then begin
		  oCats = oCats[1:*]		; Clip first (0th) enty
		endif else if (idx eq (n_oCats - 1)) then begin
		  oCats = oCats[0:n_oCats-2]	; Clip last entry
		endif else begin
		  oCats = [oCats[0:idx-1], oCats[idx+1:*]]	; Clip middle
		endelse
	endif

END
