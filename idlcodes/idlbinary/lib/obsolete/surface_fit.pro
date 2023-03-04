; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/surface_fit.pro#1 $

FUNCTION SURFACE_FIT, surface,degree
;+
; NAME:
;	SURFACE_FIT
;
; PURPOSE:
;	Determine a polynomial fit to a surface.
;
;	This function uses POLYWARP to determine the coefficients of the 
;	polynomial, then evaluates the polynomial to yield the fit surface. 
;
; CATEGORY:
;	E2 - Curve and surface fitting.
;
; CALLING SEQUENCE:
;	Result = SURFACE_FIT(Data_Surface, Degree)
;
; INPUTS:
; Data_Surface:	The two-dimensional array of data to be fit to.  The sizes of
;		each dimension may be unequal.
;
;	Degree:	The maximum degree of fit (in one dimension).
;
; OPTIONAL INPUT PARAMETERS:
;	None.
;
; OUTPUTS:
;	SURFACE_FIT returns a two-dimensional array of values from the 
;	evaluation of the polynomial fit.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	None.
;
; RESTRICTIONS:
;	The number of data points in data_surface must be greater or equal to
;	(Degree+1)^2.
;
; PROCEDURE:
;	Generate coordinate arrays for POLYWARP using the indices as
;	coordinates.  The yi and ky arrays for POLYWARP are, in this usage,
;	redundant, so they are sent as dummies.  The coefficients returned
;	from POLYWARP are then used in evaluating the polynomial fit to give
;	the surface fit.
;
; MODIFICATION HISTORY:
;	Written by:  Leonard Sitongia, LASP, University of Colorado,
;		     April, 1984.
;
;	Modified by: Mike Jone, LASP, Sept. 1985.
;	July 1993:	JIY, RSI: became obsolete; use SFIT function
;
;-
;
;				sizes of dimensions of surface
;
	on_error,2                      ;Return to caller if an error occurs

	PRINT, 'This routine is obsolete.  Please use SFIT instead."

	sizes = SIZE (surface)
	size_x = sizes (1)
	size_y = sizes (2)
;
;				initialize
;
	coord_x = indgen(size_x, size_y) mod size_x	;X coords.
	coord_y = indgen(size_x, size_y) / size_x	; & y.
	fit     = FLTARR (size_x,size_y)
	re_surf = FLTARR (size_x,size_y)
;
;				compute fit coefficients
;
	POLYWARP, surface,re_surf,coord_x,coord_y,degree,coef,re_coef
	coef = TRANSPOSE (coef)
;
;				compute fit surface from coefficients
;
	fit = fit + coef(0,0)		;constant term.
	FOR ix = 1,degree DO fit = fit + coef (ix,0)*coord_x^ix
	FOR iy = 1,degree DO fit = fit + coef (0,iy)*coord_y^iy
	FOR ix = 1,degree DO $
		FOR iy = 1,degree DO $
			fit = fit + coef (ix,iy)*coord_x^ix*coord_y^iy
;
;				return fit surface
;
	RETURN, fit
	END
