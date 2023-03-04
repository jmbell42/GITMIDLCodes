; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/cosines.pro#1 $
;
; Copyright (c) 1987-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

function cosines,x,m
;+
; NAME:
;	COSINES
;
; PURPOSE:
;	Example of a function to be used by SVDFIT.  Returns cos(i*cos(x(j)).
;
; CATEGORY:
;	Curve fitting.
;
; CALLING SEQUENCE:
;	Result  = COSINES(X, M)
;
; INPUTS:
;	X:  A vector of data values with N elements.
;	M:  The order, or number of terms.
;
; OUTPUTS:
;	Function result = (N,M) array, where N is the number of points in X,
;	and M is the order.  R(I,J) = cos(J * X(I))
;
; MODIFICATION HISTORY:
;	DMS, Nov, 1987.
;-
on_error,2                  ;Return to caller if an error occurs
return,cos( x # findgen(m)) ;Couldn't be much simpler
end

