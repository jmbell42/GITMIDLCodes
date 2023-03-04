;+
; NAME:
;   MGH_BAND_EDGE
;
; PURPOSE:
;   Given a 2D array as input, return a copy in which there is a band
;   adjacent to the edge with zero gradient normal to the edge
;
; POSITIONAL PARAMETERS:
;   data (input, 2D array)
;     The input array, can be any data type
;
; KEYWORD PARAMETERS:
;   WIDTH (input, integer scalar)
;     The width of the band in which values are changed. Default is 1.
;     If WIDTH is less than 1, the result is just a copy of the input.
;
; RETURN VALUE:
;   The function returns an array of the same type and dimensions as
;   the input.
;
; PROCEDURE
;   Copy interior values into the band. Note that the band width is
;   the same on all boundaries: given this, there is no need for
;   special handling at corners.
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2006-03:
;     Written to replace mgh_moma_top_smoothedge and similar.
;-

function MGH_BAND_EDGE, data, WIDTH=width

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(width) eq 0 then width = 1

   result = data

   if width gt 0 then begin

      dim = size(result, /DIMENSIONS)

      n0 = dim[0]
      n1 = dim[1]

      ;; Western edge
      for j=0,n1-1 do result[0:width-1,j] = result[width,j]

      ;; Eastern edge
      for j=0,n1-1 do result[n0-width:n0-1,j] = result[n0-1-width,j]

      ;; Southern edge
      for i=0,n0-1 do result[i,0:width-1] = result[i,width]

      ;; Northern edge
      for i=0,n0-1 do result[i,n1-width:n1-1] = result[i,n1-1-width]

   endif

   return, result

end




