;+
; NAME:
;   MGH_SUBSET
;
; PURPOSE:
;   Given a 1D monotonic vector (xin) representing location, and a pair of
;   positions (bound), this function returns the indices into the vector that
;   bracket those positions.
;
;   This function addresses a very common situation: we have a vector
;   representing (say) longitude for a global dataset and we wish
;   to draw out a subset of the data.
;
;   If xin is increasing (decreasing) then it is expected that bound[1] will
;   be greater (less) than or equal to bound[0].
;
; CALLING SEQUENCE:
;   Result = MGH_SUBSET(xin, bound)
;
; POSITIONAL PARAMETERS:
;   xin (input, 1-D numeric array)
;     X positions of the vertices of the input grid. The X values
;     should be monotonic (if not, results will be unpredictable);
;     they need not be uniform.
;
;   bound (input, 2-element numeric array)
;     The boundaries of the subset in the position space defined by xin.
;     If the first (second) element of bound is non-finite, then the
;     corresponding result will be 0 (n_elements(xin)-1).
;
; KEYWORD PARAMETERS:
;   EMPTY (output, logical scalar)
;     Set this keyword to a named variable to return a logical value
;     indicating whether the range is empty.
;
;   ROUND (input, integer scalar)
;     This keyword determines whether we search for a subset that
;     either matches the range as closely as possible (round eq 0)
;     exceeds the range (round gt 0) or fits inside the range (round lt 0)
;
; RETURN_VALUE:
;   The function returns a 2-element integer vector representing the range
;   of indices.
;
; PROCEDURE:
;   Locate the end points via MGH_LOCATE, then round up or down as necessary.
;   Clip so that the result represents a valid range of indices.
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
;   Mark Hadfield, 2003-04:
;     Written.
;   Mark Hadfield, 2004-04:
;     Added handling for non-finite bounds..
;   Mark Hadfield, 2004-11:
;     Added handling for single-element input vector. I'm not at all sure
;     this is well-behaved, but it gets me past the immediate problem
;     that prompted the change.
;   Mark Hadfield, 2002-07:
;     Changed default setting for ROUND from 0 to -1, as the behaviour
;     with ROUND = 0 is usually not we want.
;   Mark Hadfield, 2008-02:
;     Added EMPTY keyword
;-
function mgh_subset, xin, bound, EMPTY=empty, ROUND=round

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(xin) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'xin'

   if size(xin, /N_DIMENSIONS) gt 1 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'xin'

   if n_elements(bound) ne 2 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'bound'

   if n_elements(round) eq 0 then round = -1

   ;; Locate boundaries in index space. If either boundary is non-finite,
   ;; set a result outside the domain--this will be clipped later.

   case n_elements(xin) gt 1 of

      0B: begin
         ibound = [finite(bound[0]) ? (xin[0] gt bound[0] ? 0 : -1) : -1, $
                   finite(bound[1]) ? (xin[0] lt bound[1] ? 0 : -1) : -1]
      end

      1B: begin
         ibound = [finite(bound[0]) $
                   ? mgh_locate(xin, XOUT=bound[0], /EXTRAPOLATE) : -1, $
                   finite(bound[1]) $
                   ? mgh_locate(xin, XOUT=bound[1], /EXTRAPOLATE) : n_elements(xin)]
      end

   endcase

   ;; Convert to integer, clip to limits of XIN & return

   case 1B of

      round eq 0: $
           result = round(ibound)

      round lt 0: $
           result = [ceil(ibound[0]), floor(ibound[1])]

      round gt 0: $
           result = [floor(ibound[0]), ceil(ibound[1])]

   endcase
   
   n_in = n_elements(xin)
   
   empty = 0B
   if result[0] lt 0 and result[1] lt 0 then empty = 1B
   if result[0] gt n_in-1 and result[1] gt n_in-1 then empty = 1B
   if result[0] gt result[1] then empty = 1B

   result = (result > 0) < (n_in - 1)

   return, result

end

