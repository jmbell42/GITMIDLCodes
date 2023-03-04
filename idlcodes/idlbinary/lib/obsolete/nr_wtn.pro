; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/nr_wtn.pro#1 $
;
; Copyright (c) 1994-2006, Research Systems, Inc.  All rights reserved.
;	Unauthorized reproduction prohibited.
;+
; NAME:
;	NR_WTN
;
; PURPOSE:
;
;	NR_WTN now executes WTN, the updated version of this routine. 
;       WTN has been modified to accept row vectors as the default input 
;	and column vectors with use of the COLUMN keyword.  This routine
;	preserves the input of column vectors.
;
; MODIFICATION HISTORY:
;       Written by:     BMH Nov, 1994
;-
FUNCTION NR_WTN, a, coef, DOUBLE=double, INVERSE=inverse, OVERWRITE=overwrite

  IF NOT KEYWORD_SET(double) THEN  double = 0
  IF NOT KEYWORD_SET(inverse) THEN  inverse = 0
  IF NOT KEYWORD_SET(overwrite) THEN  overwrite = 0

  result = WTN(a, coef, DOUBLE=double, INVERSE=inverse, OVERWRITE=overwrite, $
           /COLUMN)

  RETURN, result

END
