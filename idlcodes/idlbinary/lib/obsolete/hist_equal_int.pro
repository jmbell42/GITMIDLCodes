; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/hist_equal_int.pro#1 $
;
; Copyright (c) 1992-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

pro hist_equal_int, image	;Histogram equalize color tables from image
;+NODOCUMENT
;+
; NAME:
;	HIST_EQUAL_INT
;
; PURPOSE:
;	The HIST_EQUAL_INT procedure has been renamed H_EQ_INT for
;	compatibility with operating systems with short filenames
;	(i.e. MS DOS). HIST_EQUAL_INT remains as a wrapper that calls
;	the new version. See the documentation of H_EQ_INT for information.
;	Histogram-equalize the color tables for an image or a region
;	of the display.
;
; MODIFICATION HISTORY:
;	AB, 21 September 1992
;-

H_EQ_INT, image

end