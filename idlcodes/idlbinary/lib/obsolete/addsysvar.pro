; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/addsysvar.pro#1 $
;
; Copyright (c) 1990-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

pro ADDSYSVAR, Name, Type, String_length
;+
; NAME:
;	ADDSYSVAR
;
; PURPOSE:
;	ADDSYSVAR allows the user to define new system variables. 
;	It was a built in procedure under version 1 VMS, and is superceeded
;	by DEFSYSV. It is provided in this form to help users of that version
;	adapt to version 2.
;
; CALLING SEQUENCE:
;	ADDSYSVAR, Name, Type [, String_length]
;
; INPUTS:
;	Name:  The name of the system variable. This variable must be a scalar
;	       string starting with the "!" character.
;
;	Type:  The type of the system variable expressed as a one character
;	       string. The following values are valid: 'B' for byte, 'I' for
;	       integer, 'L' for longword, 'F' for floating-point, 'D' for 
;	       double-precision floating-point, and 'S' for string.
;
;	String_length:  This parameter is ignored.
;
; OUTPUT:
;	A new system variable is created, if possible.
;
; RESTRICTIONS:
;	DEFSYSV is a much better interface for creating system variables,
;	and should be used instead.
;
; REVISION HISTORY:
;	10 January 1990
;-

  on_error,2                      ;Return to caller if an error occurs


  case strupcase(type) of 
    'B' : value = 0B
    'I' : value = 0
    'L' : value = 0L
    'F' : value = 0.0
    'D' : value = 0D
    'S' : value = ''
    ELSE : message, "Unknown value for Type argument."
  endcase

  DEFSYSV, name, value

end
