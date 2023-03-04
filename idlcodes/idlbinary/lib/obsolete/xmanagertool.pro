; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/xmanagertool.pro#1 $
;
; Copyright (c) 1992-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

pro  XManagerTool, GROUP = GROUP
;+NODOCUMENT
;+
; NAME:
;	XManagerTool
;
; PURPOSE:
;	The XmanagerTool procedure has been renamed XMTool for
;	compatibility with operating systems with short filenames
;	(i.e. MS DOS). XManagerTool remains as a wrapper that calls
;	the new version. See the documentation of XMTool for information.
;
; CATEGORY:
;	Widget Management.
;
; MODIFICATION HISTORY:
;	TC, 20 December 1992
;-

XMTOOL, GROUP = GROUP

end
