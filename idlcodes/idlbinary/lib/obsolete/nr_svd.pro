; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/nr_svd.pro#1 $
;
; Copyright (c) 1994-2006, Research Systems, Inc.  All rights reserved.
;	Unauthorized reproduction prohibited.
;+
; NAME:
;	NR_SVD
;
; PURPOSE:
;
;	NR_SVD now executes SVDC, the updated version of this routine. 
;       SVDC has been modified to accept row vectors as the default input 
;	and column vectors with use of the COLUMN keyword.  This routine
;	preserves the input of column vectors.
;
; MODIFICATION HISTORY:
; 	Written by: 	BMH Nov, 1994	
;
;-
PRO NR_SVD, a, w, u, v, DOUBLE=double

  IF NOT KEYWORD_SET(double) THEN  double = 0 

  SVDC, a, w, u, v, DOUBLE=double, /COLUMN

END
