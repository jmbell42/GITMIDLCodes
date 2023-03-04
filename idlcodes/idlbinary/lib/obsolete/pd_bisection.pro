; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/pd_bisection.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.



function pd_bisection, a, funct, U, L, del
; pd_bisections uses a simple bisection technique on probabilty
; distribution funct to find the cutoff point x so that the probabilty of
; an observation from the given distribution less than x is a(0). U and L are
; respectively upper and lower limits for x. a(1) and a(2) are df`s if
; appropriate. Funct is a string.

 SA = size(a)

 if (N_Elements(del) EQ 0) then del =.000001
 p = a(0)
 if (p LT 0 or p GT 1) then return, -1

 Up = U
 Low = L
 Mid = L + (U-L)*p
 count = 1

 while (abs(up - low) GT del*mid) and (count lt 100) DO BEGIN
   if n_elements(z) ge 1 then begin	;1st time?
	if z GT p then  Up = Mid else Low = Mid
	Mid = (Up + Low) /2.
	endif
   case n_elements(a) of
	1: z = call_function(funct, mid)
	2: z = call_function(funct, mid, a(1))
	3: z = call_function(funct, mid, a(1), a(2))
	else: return, -1
	ENDCASE
  count = count + 1
 endwhile
 return,Mid
END


  