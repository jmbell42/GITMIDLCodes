; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/pmf.pro#1 $
;
; Copyright (c) 1991-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

;+
; NAME:
;	PMF
; PURPOSE:
;	Perform formatted output of matrices stored in the IMSL/IDL
;	linear algebra storage scheme to the specified file.
; CATEGORY:
;	Linear Algebra
; CALLING SEQUENCE:
;	PMF, UNIT, E1, ..., E10
; INPUTS:
;	Unit - The output file unit.
;	E1, ... E20 - Expressions to be output. These can be scalar or
;		array and of any type.
; OUTPUTS:
;	Output is written to the file specified by unit.
; COMMON BLOCKS:
;	None.
; RESTRICTIONS:
;	No more than 20 expressions can be output. This should be sufficient
;	for typical use.
; MODIFICATION HISTORY:
;	13, September 1991, Written by AB (RSI), MP (IMSL)
;-

function pmf_trans, v
if n_elements(v) lt 2 then return, v
return, transpose(v)
end


pro PMF, unit, E1, E2, E3, E4, E5, E6, E7, E8, E9, E10, $
        E11, E12, E13, E14, E15, E16, E17, E18, E19, E20, format = fmt,$
        title=title

on_error, 2		; Return to caller on error

n = n_params()
if (n eq 0) then message, 'UNIT argument is required when calling PMF.'
if n_elements(title) then printf, unit, title

if keyword_set(fmt) then format = fmt else format = ''
case (n-1) of
1:$
printf, unit, pmf_trans(e1), $
       format = format

2:$
printf, unit, pmf_trans(e1), pm_trans(e2), $
       format = format

3:$
printf, unit, pmf_trans(e1), pmf_trans(e2), pmf_trans(e3), $
       format = format

4:$
printf, unit, pmf_trans(e1), pmf_trans(e2), pmf_trans(e3), pmf_trans(e4), $
       format = format

5:$
printf, unit, pmf_trans(e1), pmf_trans(e2), pmf_trans(e3), pmf_trans(e4), pmf_trans(e5), $
       format = format

6:$
printf, unit, pmf_trans(e1), pmf_trans(e2), pmf_trans(e3), pmf_trans(e4), pmf_trans(e5), $
       pmf_trans(e6), $
       format = format
7:$
printf, unit, pmf_trans(e1), pmf_trans(e2), pmf_trans(e3), pmf_trans(e4), pmf_trans(e5), $
       pmf_trans(e6), pmf_trans(e7), $
       format = format

8:$
printf, unit, pmf_trans(e1), pmf_trans(e2), pmf_trans(e3), pmf_trans(e4), pmf_trans(e5), $
       pmf_trans(e6), pmf_trans(e7), pmf_trans(e8), $
       format = format

9:$
printf, unit, pmf_trans(e1), pmf_trans(e2), pmf_trans(e3), pmf_trans(e4), pmf_trans(e5), $
       pmf_trans(e6), pmf_trans(e7), pmf_trans(e8), pmf_trans(e9), $
       format = format
10:$
printf, unit, pmf_trans(e1), pmf_trans(e2), pmf_trans(e3), pmf_trans(e4), pmf_trans(e5), $
       pmf_trans(e6), pmf_trans(e7), pmf_trans(e8), pmf_trans(e9), pmf_trans(e10), $
       format = format
11:$
printf, unit, pmf_trans(e1), pmf_trans(e2), pmf_trans(e3), pmf_trans(e4), pmf_trans(e5), $
       pmf_trans(e6), pmf_trans(e7), pmf_trans(e8), pmf_trans(e9), pmf_trans(e10), $
       pmf_trans(e11), $
       format = format
12:$
printf, unit, pmf_trans(e1), pmf_trans(e2), pmf_trans(e3), pmf_trans(e4), pmf_trans(e5), $
       pmf_trans(e6), pmf_trans(e7), pmf_trans(e8), pmf_trans(e9), pmf_trans(e10), $
       pmf_trans(e11), pmf_trans(e12), $
       format = format
13:$
printf, unit, pmf_trans(e1), pmf_trans(e2), pmf_trans(e3), pmf_trans(e4), pmf_trans(e5), $
       pmf_trans(e6), pmf_trans(e7), pmf_trans(e8), pmf_trans(e9), pmf_trans(e10), $
       pmf_trans(e11), pmf_trans(e12), pmf_trans(e13), $
       format = format
14:$
printf, unit, pmf_trans(e1), pmf_trans(e2), pmf_trans(e3), pmf_trans(e4), pmf_trans(e5), $
       pmf_trans(e6), pmf_trans(e7), pmf_trans(e8), pmf_trans(e9), pmf_trans(e10), $
       pmf_trans(e11), pmf_trans(e12), pmf_trans(e13), pmf_trans(e14), $
       format = format
15:$
printf, unit, pmf_trans(e1), pmf_trans(e2), pmf_trans(e3), pmf_trans(e4), pmf_trans(e5), $
       pmf_trans(e6), pmf_trans(e7), pmf_trans(e8), pmf_trans(e9), pmf_trans(e10), $
       pmf_trans(e11), pmf_trans(e12), pmf_trans(e13), pmf_trans(e14), pmf_trans(e15), $
       format = format
16:$
printf, unit, pmf_trans(e1), pmf_trans(e2), pmf_trans(e3), pmf_trans(e4), pmf_trans(e5), $
       pmf_trans(e6), pmf_trans(e7), pmf_trans(e8), pmf_trans(e9), pmf_trans(e10), $
       pmf_trans(e11), pmf_trans(e12), pmf_trans(e13), pmf_trans(e14), pmf_trans(e15), $
       pmf_trans(e16), $
       format = format
17:$
printf, unit, pmf_trans(e1), pmf_trans(e2), pmf_trans(e3), pmf_trans(e4), pmf_trans(e5), $
       pmf_trans(e6), pmf_trans(e7), pmf_trans(e8), pmf_trans(e9), pmf_trans(e10), $
       pmf_trans(e11), pmf_trans(e12), pmf_trans(e13), pmf_trans(e14), pmf_trans(e15), $
       pmf_trans(e16), pmf_trans(e17), $
       format = format
18:$
printf, unit, pmf_trans(e1), pmf_trans(e2), pmf_trans(e3), pmf_trans(e4), pmf_trans(e5), $
       pmf_trans(e6), pmf_trans(e7), pmf_trans(e8), pmf_trans(e9), pmf_trans(e10), $
       pmf_trans(e11), pmf_trans(e12), pmf_trans(e13), pmf_trans(e14), pmf_trans(e15), $
       pmf_trans(e16), pmf_trans(e17), pmf_trans(e18), $
       format = format
19:$
printf, unit, pmf_trans(e1), pmf_trans(e2), pmf_trans(e3), pmf_trans(e4), pmf_trans(e5), $
       pmf_trans(e6), pmf_trans(e7), pmf_trans(e8), pmf_trans(e9), pmf_trans(e10), $
       pmf_trans(e11), pmf_trans(e12), pmf_trans(e13), pmf_trans(e14), pmf_trans(e15), $
       pmf_trans(e16), pmf_trans(e17), pmf_trans(e18), pmf_trans(e19), $
       format = format
20:$
printf, unit, pmf_trans(e1), pmf_trans(e2), pmf_trans(e3), pmf_trans(e4), pmf_trans(e5), $
       pmf_trans(e6), pmf_trans(e7), pmf_trans(e8), pmf_trans(e9), pmf_trans(e10), $
       pmf_trans(e11), pmf_trans(e12), pmf_trans(e13), pmf_trans(e14), pmf_trans(e15), $
       pmf_trans(e16), pmf_trans(e17), pmf_trans(e18), pmf_trans(e19), pmf_trans(e20), $
       format = format
else: $
    if (n gt 21) then $
          message, 'Too many arguments sent to PM.  Maximum allowed is twenty-one'
endcase

end
