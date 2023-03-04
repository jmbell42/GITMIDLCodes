; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/prompt.pro#1 $
;
; Copyright (c) 1990-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

pro PROMPT, String
;+
; NAME:
;	PROMPT
;
; PURPOSE:
;	PROMPT sets the interactive prompt, normally "IDL>", to the
;	specified string.  If no parameter is supplied, the prompt string
;	reverts to "IDL>".  This procedure was built-in under version 1 VMS
;	IDL, and is provided in this form to help users of that version
;	adapt to version 2.
;
; CALLING SEQUENCE:
;	PROMPT [, String]
;
; OPTIONAL INPUT:
;	String:	A scalar string giving the new prompt.
;
; OUTPUT:
;	The interactive prompt (controlled by the !PROMPT system variable)
;	is changed.
;
; RESTRICTIONS: None
;
; REVISION HISTORY:
;	10 January 1990
;-
on_error,2                      ;Return to caller if an error occurs
if n_params() eq 0 then !prompt = 'IDL> ' else !prompt = string
end
