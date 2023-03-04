; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/hist_equal_ct.pro#1 $
;
; Copyright (c) 1992-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

pro hist_equal_ct, image
;+NODOCUMENT
;+
; NAME:
;	HIST_EQUAL_CT
;
; PURPOSE:
;	The HIST_EQUAL_CT procedure has been renamed H_EQ_CT for
;	compatibility with operating systems with short filenames
;	(i.e. MS DOS). HIST_EQUAL_CT remains as a wrapper that calls
;	the new version. See the documentation of H_EQ_CT for information.
;	Histogram-equalize the color tables for an image or a region
;	of the display.
;
; CATEGORY:
;	Image processing.
;
; MODIFICATION HISTORY:
;	AB, 21 September 1992
;-

H_EQ_CT, image

end
