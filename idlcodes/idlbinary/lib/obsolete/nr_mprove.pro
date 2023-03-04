; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/nr_mprove.pro#1 $
;
; Copyright (c) 1994-2006, Research Systems, Inc.  All rights reserved.
;	Unauthorized reproduction prohibited.
;+
; NAME:
;	NR_MPROVE
;
; PURPOSE:
;
;	NR_MPROVE now executes LUMPROVE, the updated version of this routine. 
;       LUMPROVE has been modified to accept row vectors as the default input 
;	and column vectors with use of the COLUMN keyword.  This routine
;	preserves the input of column vectors.
;
; MODIFICATION HISTORY:
; 	Written by: 	BMH Nov, 1994	
;
;-
FUNCTION NR_MPROVE, a, alud, index, b, x, DOUBLE=double

  IF NOT KEYWORD_SET(DOUBLE) THEN  DOUBLE = 0
  result = LUMPROVE(a, alud, index, b, x, DOUBLE=double, /COLUMN)

  RETURN, result

END
