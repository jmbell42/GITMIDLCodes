;+
; NAME:
;   MGH_POLY_SPLIT
;
; PURPOSE:
;   Extract a set of polygon/polyline descriptors from a single vector
;   and bundle them in an MGH_Vector object or a pointer array.
;
; CALLING SEQUENCE:
;   Result = MGH_POLY_SPLIT(poly)
;
; POSITIONAL PARAMETERS:
;   poly (input, vector integer)
;     A list of polygon/polyline descriptors in the format specified
;     by IDLgrPolygon, IDLgrPolyline and others.
;
; RETURN VALUE:
;   The function returns a vector containing a list of
;   polygon/polyline descriptor
;
; SEE ALSO:
;   MGH_POLY_JOIN
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
;   Mark Hadfield, Jul 2001:
;       Written.
;-
function MGH_POLY_SPLIT, poly

   compile_opt DEFINT32
   compile_opt STRICTARR

   if n_elements(poly) eq 0 then begin
      message, 'The input must be an integer array containing one or more ' + $
               'polygon/polyline descriptors'
   endif

   vector = obj_new('MGH_Vector')

   n = n_elements(poly)

   i = 0

   while i lt n do begin

      m = poly[i]               ; Number of indices in this descriptor

      if m lt 0 then break      ; A -1 terminates the list

      vector->Add, poly[i:i+m]  ; Store the polygon/polyline descriptor with the
                                ; leading number of indices

      i = i + m + 1             ; Go to next descriptor

   endwhile

   return, vector

end

