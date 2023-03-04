;+
; NAME:
;   MGH_LOCATE
;
; PURPOSE:
;   This function calculates translates positions in physical space into
;   the "index space" of a 1D vector.
;
; CALLING SEQUENCE:
;   Result = MGH_LOCATE(xin)
;
; POSITIONAL PARAMETERS:
;   xin (input, 1-D numeric array)
;     X positions of the vertices of the input grid. The X values
;     should be monotonic (if not, results will be unpredictable);
;     they need not be uniform.
;
; KEYWORD PARAMETERS:
;   The following keywords define the locations in physical space of
;   the output grid, cf. the GRIDDATA routine: DELTA, DIMENSION, START, XOUT.
;
;   In addition:
;     EXTRAPOLATE (input, switch)
;       Set this keyword to cause output locations outside the
;       range of input values to be determined by extrapolation.
;
;     MISSING (input, numeric scalar)
;       Value used for locations outside the range of input
;       values. Ignored if the EXTRAPOLATE keyword is set.
;       Default is NaN.
;
;     SPLINE (input, switch)
;       Set this keyword to use spline interpolation; default is linear.
;       Setting both the SPLINE and EXTRAPOLATE keywords together
;       causes an error.
;
; RETURN_VALUE:
;   The function returns a floating array representing the output
;   location as fractional indices on the grid represented by
;   XIN. The result has the same dimensions as the output locations.
;
; PROCEDURE:
;   Construct variable representing position in i direction &
;   interpolate.
;
;###########################################################################
;
; This software is provided subject to the following conditions:
;
; 1.  NIWA makes no representations or warranties regarding the
;     accuracy of the software, the use to which the software may
;     be put or the results to be obtained from the use of the
;     software.  Accordingly NIWA accepts no liability for any loss
;     or damage (whether direct of indirect) incurred by any person
;     through the use of or reliance on the software.
;
; 2.  NIWA is to be acknowledged as the original author of the
;     software where the software is used or presented in any form.
;
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2002-07:
;     Written.
;   Mark Hadfield, 2003-01:
;     Now calls IDL library routine INTERPOL instead of MGH_INTERPOL.
;   Mark Hadfield, 2004-03:
;     Added SPLINE keyword.
;-

function mgh_locate, xin, EXTRAPOLATE=extrapolate, MISSING=missing, SPLINE=spline, $
     DELTA=delta, DIMENSION=dimension, START=start, XOUT=xout

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(extrapolate) eq 0 then extrapolate = 0B

   if n_elements(missing) eq 0 then missing = !values.f_nan

   if n_elements(spline) eq 0 then spline = 0B

   if keyword_set(spline) && keyword_set(extrapolate) then $
        message, 'Extrapolation is unsafe when using spline interpolation'

   ;; Process input grid.

   if size(xin, /N_ELEMENTS) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'xin'

   if size(xin, /N_DIMENSIONS) ne 1 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'xin'

   ;; Process output grid

   case n_elements(xout) gt 0 of

      0B: begin
         if n_elements(dimension) eq 0 then dimension = 51
         if n_elements(start) eq 0 then start = min(xin)
         if n_elements(delta) eq 0 then $
              delta = (max(xin)-min(xin))/float(dimension-1)
         xx = start + delta*lindgen(dimension)
      end

      1B: xx = xout

   endcase

   n_in = n_elements(xin)

   result = interpol(findgen(n_in), xin, xx, SPLINE=spline)

   if ~ keyword_set(extrapolate) then begin

      l_outside = where(result lt 0 or result gt (n_in-1), n_outside)
      if n_outside gt 0 then result[l_outside] = missing

   endif

   return, result

end
