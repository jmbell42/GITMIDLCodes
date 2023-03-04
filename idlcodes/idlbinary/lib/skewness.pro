;$Id: //depot/idl/IDL_63_RELEASE/idldir/lib/skewness.pro#1 $
;
; Copyright (c) 1997-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;       SKEWNESS
;
; PURPOSE:
;       This function computes the statistical skewness of an
;       N-element vector.  If the variance of the vector is zero,
;       the skewness is not defined, and SKEWNESS returns
;       !VALUES.F_NAN as the result.
;
; CATEGORY:
;       Statistics.
;
; CALLING SEQUENCE:
;       Result = SKEWNESS(X)
;
; INPUTS:
;       X:      An N-element vector of type integer, float or double.
;
; KEYWORD PARAMETERS:
;       DOUBLE: IF set to a non-zero value, computations are done in
;               double precision arithmetic.
;
;       NAN:    If set, treat NaN data as missing.
;
; EXAMPLE:
;       Define the N-element vector of sample data.
;         x = [65, 63, 67, 64, 68, 62, 70, 66, 68, 67, 69, 71, 66, 65, 70]
;       Compute the mean.
;         result = SKEWNESS(x)
;       The result should be:
;       -0.0942851

;
; PROCEDURE:
;       SKEWNESS calls the IDL function MOMENT.
;
; REFERENCE:
;       APPLIED STATISTICS (third edition)
;       J. Neter, W. Wasserman, G.A. Whitmore
;       ISBN 0-205-10328-6
;
; MODIFICATION HISTORY:
;       Written by:  GSL, RSI, August 1997
;-
FUNCTION SKEWNESS, X, Double = Double, NaN = NaN

  ON_ERROR, 2

  RETURN, (moment( X, Double=Double, Maxmoment=3, NaN = NaN ))[2]
END
