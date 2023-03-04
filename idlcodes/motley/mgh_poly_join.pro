;+
; NAME:
;   MGH_POLY_JOIN
;
; PURPOSE:
;   Given a container object with a list of polygon/polyline descriptors
;   combine them into a single vector.
;
; CALLING SEQUENCE:
;   Result = MGH_POLY_JOIN(vector)
;
; POSITIONAL PARAMETERS:
;   vector (input, object reference)
;     An MGH_Vector object containg a list of integer vectors
;
; RETURN VALUE:
;   The function returns a long-integer vector of the format required
;   by IDLgrPolygon & IDLgrPolyline.
;
; SEE ALSO:
;   MGH_POLY_SPLIT
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
;   Mark Hadfield, 2001-07:
;     Written.
;   Mark Hadfield, 2005-06:
;     Updated.
;-
function MGH_POLY_JOIN, vector

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(vector) ne 1 then $
        message, 'The input must be a container object'

   if ~ obj_valid(vector) then $
        message, 'The input must be a container object'

   count = vector->Count()

   ;; First pass through container adds up lengths

   length = 0

   for p=0,count-1 do begin

      length += n_elements(vector->Get(POSITION=p))

   endfor

   if length eq 0 then return, [-1]

   ;; Second pass through container accumulates descriptors

   result = lonarr(length)

   l = 0

   for p=0,count-1 do begin

      poly = vector->Get(POSITION=p)

      n = n_elements(poly)

      result[l:l+n-1] = poly

      l += n

   endfor

   return, result

end

