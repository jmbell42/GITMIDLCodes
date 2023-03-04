; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/helpfiles.pro#1 $
;
; Copyright (c) 1990-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

pro HELPFILES
;+
; NAME:
;	HELPFILES
;
; PURPOSE:
;	HELPFILES prints useful information about the currently open
;	files.  This procedure was built-in under version 1 VMS
;	IDL, and is provided in this form to help users of that version
;	adapt to version 2.
;
; CALLING SEQUENCE:
;	HELPFILES
;
; INPUT:
;	None.
;
; OUTPUT:
;	Information about open files is printed.
;
; RESTRICTIONS:
;	None.
;
; REVISION HISTORY:
;	10 January 1990
;-
on_error,2                        ;Return to caller if an error occurs
HELP, /FILES
end
