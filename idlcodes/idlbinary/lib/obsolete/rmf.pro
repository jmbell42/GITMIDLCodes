; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/rmf.pro#1 $
;
; Copyright (c) 1991-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

;+
; NAME:
;	RMF
; PURPOSE:
;	Perform formatted input of matrices stored in the IMSL/IDL
;	linear algebra storage scheme from the specified file.
; CATEGORY:
;	Linear Algebra
; CALLING SEQUENCE:
;	RMF, UNIT, A [, Rows, Columns]
; INPUTS:
;	Unit - The input file unit.
;	E1, ... E10 - Expressions to be output. These can be scalar or
;		array and of any type.
; OUTPUTS:
;	Input is written to the file specified by unit.
; COMMON BLOCKS:
;	None.
; MODIFICATION HISTORY:
;	13, September 1991, Written by AB (RSI), Mike Pulverenti (IMSL)
;-

pro RMF, unit, A, rows, columns, double=dbl, complex=cmplx, format = format

on_error, 2		; Return to caller on error

n = n_params()
if (n ne 2) and (n ne 4) then message, 'Wrong number of arguments."

;       If Rows and Columns were not given, then make sure a is
;       defined.
s = size(a)
if ((n eq 2) and (s(0) eq 0))  then message, 'Argument must be defined as an array if Rows and Columns are not supplied.'
;
;       Only read in 1-D and 2-D arrays.
if ((n eq 2) and(s(0) gt 2)) then message, 'Array has too many dimensions.'

if (n eq 2) then begin
    a = transpose(a)
    s = size(a)
    l_columns = s(1)
    if (s(0) eq 1) then l_rows=1 else l_rows=s(2)
    type = s(s(0)+1)
endif else begin
    l_rows = rows
    l_columns = columns
    dbl = keyword_set(dbl)
    cmplx = keyword_set(cmplx)
    a = make_array(l_columns, l_rows, double= keyword_set(dbl), $
		   complex=keyword_set(cmplx))
endelse

if keyword_set(format) then readf, unit, a, format = format $
else readf, unit, a

a = transpose(a)

end
