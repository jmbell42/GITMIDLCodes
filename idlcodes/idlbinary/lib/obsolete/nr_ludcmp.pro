; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/nr_ludcmp.pro#1 $
;
; Copyright (c) 1994-2006, Research Systems, Inc.  All rights reserved.
;	Unauthorized reproduction prohibited.
;+
; NAME:
;	NR_LUDCMP
;
; PURPOSE:
;
;	NR_LUDCMP now executes LUDC, the updated version of this routine. 
;       LUDC has been modified to accept row vectors as the default input 
;	and column vectors with use of the COLUMN keyword.  This routine
;	preserves the input of column vectors.
;
; MODIFICATION HISTORY:
; 	Written by: 	BMH Nov, 1994	
;
;-
PRO NR_LUDCMP, a, index, DOUBLE=double, INTERCHANGES=interchanges

  IF NOT KEYWORD_SET(double) THEN  double = 0
  IF NOT KEYWORD_SET(interchanges) THEN interchanges = 0

  LUDC, a, index, DOUBLE=double, INTERCHANGES=interchanges, /COLUMN

END
