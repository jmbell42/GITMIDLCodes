; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/nr_svbksb.pro#1 $
;
; Copyright (c) 1994-2006, Research Systems, Inc.  All rights reserved.
;	Unauthorized reproduction prohibited.
;+
; NAME:
;	NR_SVBKSB
;
; PURPOSE:
;
;	NR_SVBKSB now executes SVSOL, the updated version of this routine. 
;       SVSOL has been modified to accept row vectors as the default input 
;	and column vectors with use of the COLUMN keyword.  This routine
;	preserves the input of column vectors.
;
; MODIFICATION HISTORY:
; 	Written by: 	BMH Nov, 1994	
;
;-
FUNCTION NR_SVBKSB, u, w, v, b, DOUBLE=double

  IF NOT KEYWORD_SET(DOUBLE) THEN double = 0 

  result = SVSOL(u, w, v, b, DOUBLE=double, /COLUMN)

  RETURN, result

END
