; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/helpsy.pro#1 $
;
; Copyright (c) 1990-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

pro HELPSY
;+
; NAME:
;	HELPSY
;
; PURPOSE:
;	HELPSY prints the values of all of the system variables.
;	This procedure was built-in under version 1 VMS
;	IDL, and is provided in this form to help users of that version
;	adapt to version 2.
;
; CALLING SEQUENCE:
;	HELPSY
;
; INPUT:
;	None.
;
; OUTPUT:
;	The the values of all of the system variables are printed.
;
; RESTRICTIONS:
;	None.
;
; REVISION HISTORY:
;	10 January 1990
;-
on_error,2                        ;Return to caller if an error occurs
HELP, /SYSTEM_VARIABLES
end
