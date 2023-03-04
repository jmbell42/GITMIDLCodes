; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/rot_int.pro#1 $
;
; Copyright (c) 1982-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

FUNCTION ROT_INT, A, ANGLE, MAG, X0, Y0, CUBIC=cubic
;+
; NAME:
;	ROT_INT
;
; PURPOSE:
;	Rotate, magnify or demagnify, and/or translate an image with
;	bilinear interpolation.
;
;	Note that this function is made obsolete by the new ROT User
;	Library function which supports bilinear interpolation through
;	the use of the INTERP keyword.
;
; CATEGORY:
;	Z3 - Image processing, geometric transforms.
;
; CALLING SEQUENCE:
;	Result = ROT(A, Angle, [Mag, X0, Y0])
;
; INPUTS:
;	A:	The image array to be rotated.  This array may be of any type,
;		but it must have two dimensions.
;
;	ANGLE:	Angle of rotation in degrees CLOCKWISE. (Why?,
;		because of an error in the old ROT.)
;
; KEYWORD PARAMETERS:
;	CUBIC:	If set, uses "Cubic convolution" interpolation.  A more
;		accurate, but more time-consuming, form of interpolation.
;		CUBIC has no effect when used with 3 dimensional arrays.
;
; OPTIONAL INPUT PARAMETERS:
;	MAG:	Magnification/demagnification factor.  A value of 1.0 = no
;		change, > 1 is magnification and < 1 is demagnification.
;
;	X0:	X subscript for the center of rotation.  If omitted, X0 equals
;		the number of columns in the image divided by 2.
;
;	Y0:	Y subscript for the center of rotation.  If omitted, y0 equals
;		the number of rows in the image divided by 2.
;
; OUTPUTS:
;	ROT_INT returns a rotated, magnified, and translated version of the
;	input image.  Note that the dimensions of the output image are
;	always the same as those of the input image.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	None.
;
; RESTRICTIONS:
;	None.
;
; PROCEDURE:
;	The POLY_2D function is used to translate, scale, and
;	rotate the original image.
;
;	Note that bilinear interpolation is used by default (rather than
;	the nearest-neighbor method used by default in ROT).
;
; EXAMPLE:
;	Create and display an image.  Then display a rotated and magnified
;	version.  Create and display the image by entering:
;
;		A = BYTSCL(DIST(256))
;		TV, A
;
;	Rotate the image 33 degrees and magnify it 1.5 times.  Bilinear
;	interpolation is used to make the image look nice.  Enter:
;
;		B = ROT(A, 33, 1.5)
;		TV, B
;	
; MODIFICATION HISTORY:
;	June, 1982. 	Written by DMS, RSI.
;
;	Feb, 1986. 	Modified by Mike Snyder, ES&T Labs, 3M Company.
;	 		Adjusted things so that rotation is exactly on the 
;			designated center.
;
;	October, 1986.  Modified by DMS to use the POLY_2D function.
;	Nov, 1993.	DMS, RSI, Added CUBIC keyword.
;-
;
;
;
on_error,2		;Return to caller if error
B = FLOAT(SIZE(A))	;Get dimensions
if b(0) ne 2 then begin
	print,'ROT_INT - parameter must be 2d array'
	return,undef
	endif

IF N_PARAMS(0) LT 5 THEN BEGIN
	X0 = (B(1)-1)/2.		;Center of rotation in X.
	Y0 = (B(2)-1)/2.		; and in Y.
	IF N_PARAMS(0) LT 3 THEN MAG = 1. ;Mag specified?
	ENDIF
;
;			Use rot function
return,rot(a, angle, mag, x0, y0, interp=1, CUBIC=KEYWORD_SET(cubic))
END

