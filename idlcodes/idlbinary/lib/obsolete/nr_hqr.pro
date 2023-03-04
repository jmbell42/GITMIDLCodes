; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/nr_hqr.pro#1 $
;
; Copyright (c) 1994-2006, Research Systems, Inc.  All rights reserved.
;	Unauthorized reproduction prohibited.
;+
; NAME:
;	NR_HQR
;
; PURPOSE:
;
;	NR_HQR now executes HQR, the updated version of this routine. 
;       HQR has been modified to accept row vectors as the default input 
;	and column vectors with use of the COLUMN keyword.  This routine
;	preserves the input of column vectors.
;
; MODIFICATION HISTORY:
; 	Written by: 	BMH Nov, 1994	
;
;-
FUNCTION NR_HQR, a, DOUBLE=double

  IF NOT KEYWORD_SET(double) THEN double=0

  result = HQR(a, DOUBLE=double, /COLUMN)

  RETURN, result

END
