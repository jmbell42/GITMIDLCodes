;+
; NAME:
;   MGH_POLY_OVERLAP
;
; DESCRIPTION:
;    Given 2 polygons, this function returns the area of the region
;    where they overlap
;
; CALLING SEQUENCE:
;    result = mgh_polyoverlap(p0, p1)
;
; POSITiONAL PARAMETERS:
;   p0, p1 (input, numeric [2,n] array)
;     The polygons
;
; RETURN VALUE:
;    The function returns the overlap area as a scalar.
;
; MODIFICATION HISTORY:
;    Mark Hadfield, 2002-08:
;      Written
;-
function mgh_polyfillg, p0, p1, OVERLAP=overlap

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if size(p0, /N_ELEMENTS) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'p0'

   if size(p1, /N_ELEMENTS) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'p1'

   if size(p0, /N_DIMENSIONS) ne 2 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'p0'

   if size(p1, /N_DIMENSIONS) ne 2 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'p1'

   d0 = size(p0, /DIMENSIONS)
   d1 = size(p1, /DIMENSIONS)

   if d0[0] ne 2 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgdimsize', 'p0'

   if d1[0] ne 2 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgdimsize', 'p1'

   n0 = d0[1]
   n1 = d1[1]

   ;; Save a copy of the input polygons and ensure that they are
   ;; closed.

   my_p0 = p0
   my_p1 = p1

   if ~ array_equal(my_p0[*,0], my_p0[*,n0-1]) then begin
      my_p0 = [[my_p0],[my_p0[*,0]]]
      n0 += 1
   endif

   if ~ array_equal(my_p1[*,0], my_p1[*,n0-1]) then begin
      my_p1 = [[my_p1],[my_p1[*,0]]]
      n1 += 1
   endif

   ;; Clip my_p0 with each line in 

   coeff = mgh_line_coeff(xout[i,j],yout[i,j], $
                          xout[i+1,j],yout[i+1,j])
   polc = mgh_polyclip2(poly, coeff, COUNT=n_vert)
   if n_vert eq 0 then continue
   coeff = mgh_line_coeff(xout[i+1,j],yout[i+1,j], $
                          xout[i+1,j+1],yout[i+1,j+1])
   polc = mgh_polyclip2(polc, coeff, COUNT=n_vert)
   if n_vert eq 0 then continue
   coeff = mgh_line_coeff(xout[i+1,j+1],yout[i+1,j+1], $
                          xout[i,j+1],yout[i,j+1])
   polc = mgh_polyclip2(polc, coeff, COUNT=n_vert)
   if n_vert eq 0 then continue
   coeff = mgh_line_coeff(xout[i,j+1],yout[i,j+1], $
                          xout[i,j],yout[i,j])
   polc = mgh_polyclip2(polc, coeff, COUNT=n_vert)
   if n_vert eq 0 then continue
   px = reform(polc[0,*])
   py = reform(polc[1,*])
   result[i,j] = 0.5*abs(total(px*shift(py,-1) - py*shift(px,-1)))
   if ~ keyword_set(area) then begin
      ax = [xout[i,j],xout[i+1,j],xout[i+1,j+1],xout[i,j+1]]
      ay = [yout[i,j],yout[i+1,j],yout[i+1,j+1],yout[i,j+1]]
      aa = 0.5*abs(total(ax*shift(ay,-1) - ay*shift(ax,-1)))
      result[i,j] = result[i,j] / aa
   endif

   return, result

end
