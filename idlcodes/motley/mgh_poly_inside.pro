;+
; NAME:
;   MGH_POLY_INSIDE
;
; PURPOSE:
;   Determine whether a point or set of points is inside a polygon.
;
; CALLING SEQUENCE:
;   Result = MGH_POLY_INSIDE(XP, YP, X, Y)
;
; INPUTS:
;   XP,YP:      Vectors of X, Y positions defining the polygon.
;
;   X,Y:        X, Y position(s) defining the point(s) to be tested. Can
;               be vectors.
;
; INPUT KEYWORDS:
;   EDGE:       Set this keyword to accept edge (& vertex) points as
;               "inside". Default is to reject them.
;
;   NAN:        Set this keyword to specify that all points for which
;               X or Y is not finite (eg Nan, Inf) are to return 0.
;               Default is to process non-finite points, which leads
;               to floating point errors and an undefined result for
;               that point.
;
; OUTPUTS:
;   The function returns an array of the same shape as X. Each element
;   is 0 if the point is outside the polygon, 1 if it is inside the polygon.
;
; PROCEDURE:
;   This routine calculates the displacement vectors from each point to
;   all the vertices of the polygon and then takes angles between each pair
;   of successive vectors. The sum of the angles is zero
;   for a point outside the polygon, and +/- 2*pi for a point
;   inside. A point on an edge will have one such angle
;   equal to +/- pi. Points on a vertex have a zero displacement vector.
;
; REFERENCES:
;   Note that the question of how to determine whether a point is
;   inside or outside a polygon was discussed on comp.lang.idl-pvwave
;   in October 1999. The following is quoted from a post by Randall Frank
;   <randall-frank@computer.org>:

;       I would suggest you read the Graphics FAQ on this issue and also
;       check Graphics Gem (I think volume 1) for a more detailed explanation
;       of this problem.  The upshot is that there really are three core methods
;       and many variants.  In general, you can sum angles, sum signed areas or
;       clip a line.  There are good code examples of all these approaches on the
;       net which can be coded into IDL very quickly.  It also depends on how
;       you intend to use the function.  If, you are going to repeatedly test many
;       points, you are better off using one of the sorted variants of the line
;       clipping techniques.  In general, the line clipping techniques are the
;       fastest on the average, but have poor worst case performance without
;       the sorting overhead.  The angle sum is one of the slowest methods
;       unless you can get creative and avoid the transcendentals (and you
;       can).  The area sum approach generally falls in between.  In IDL code,
;       I believe you can vectorize the latter with some setup overhead, making
;       it the fastest for .pro code when testing multiple points with one
;       point per call.
;
;   Further resources:
;    *  "Misc Notes - WR Franklin", http://www.ecse.rpi.edu/Homepages/wrf/misc.html:
;       includes a reference (broken @ Jul 2001) to his point-in-polygon code.
;    *  Comp.graphics.algorithms FAQ, http://www.faqs.org/faqs/graphics/algorithms-faq/:
;       See subject 2.03
;
; SEE ALSO:
;   MGH_PNPOLY, which implements a line-clipping technique.
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
;   Mark Hadfield, June 1995:
;     Written based on ideas in MATLAB routine INSIDE.M in the WHOI
;     Oceanography Toolbox v1.4 (R. Pawlowicz, 14 Mar 94,
;     rich@boreas.whoi.edu).
;   Mark Hadfield, Dec 2000:
;     Updated.
;   Mark Hadfield, Jul 2001:
;     Changed argument order: polygon vertices are now before test
;     position(s).
;-
function MGH_POLY_INSIDE, XP, YP, X, Y, DOUBLE=double, EDGE_INSIDE=edge, NAN=nan

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Check geometry of the array of points. Note that this array is
   ;; treated as a 1-D array internally to allow matrix operations,
   ;; but the result of the function matches the shape of the inputs.
   n = n_elements(x)

   ;; Make a local copy of polygon data
   ;; If necessary, add a last point to close the polygon
   xpp = xp[*]
   ypp = yp[*]
   npp = n_elements(xpp)
   if (xpp[npp-1] ne xpp[0]) || (ypp[npp-1] ne ypp[0]) then begin
      xpp = [xpp,xpp[0]]
      ypp = [ypp,ypp[0]]
      npp = npp+1
   endif

   if npp eq 0 then message, 'The polygon when closed must have two or more vertices'

   ;; Construct 1D arrays holding x & y values
   xx = x[*]
   yy = y[*]
   if keyword_set(nan) then begin
      ff = where(finite(xx) and finite(yy), n_finite)
      case n_finite of
         0: return, mgh_reproduce(0, x)
         n:
         else: begin
            xx = xx[ff]
            yy = yy[ff]
         end
      endcase
   endif

   ;; Construct arrays dimensioned (npp,n) holding
   ;; x & y displacements from points to vertices

   one = keyword_set(double) ? 1.0D : 1.0

   dx = xpp#make_array(n, VALUE=one) - make_array(npp, VALUE=one)#temporary(xx)
   dy = ypp#make_array(n, VALUE=one) - make_array(npp, VALUE=one)#temporary(yy)

   ;; Calculate angles. Randall says we could eliminate
   ;; transcendentals here--I wonder how?

   angles = (atan(dy,dx))
   angles = angles[1:npp-1,*] - angles[0:npp-2,*]

   ;; Force angles into range [-pi,+pi)

   oor = where(angles le -!dpi, count)
   if count gt 0 then angles[oor] += 2*!dpi
   oor = where(angles gt !dpi,count)
   if count gt 0 then angles[oor] -= 2*!dpi

   ;; The following operation generates an array with value 1
   ;; for each point where angles sum to a non-zero value (inside
   ;; the polygon) and zero elsewhere

   inside = round(total(angles/!dpi,1,/DOUBLE)) ne 0

   ;; Are any of the points currently considered to be outside
   ;; the polygon actually on an edge or a vertex?

   if keyword_set(edge) then begin
      for i=0,n-1 do begin
         if (~ inside[i]) then begin
            dummy = where(angles[*,i] eq -!dpi, count)
            if count gt 0 then begin
               inside[i] = 1
            endif else begin
               dummy = where((abs(dx[*,i])+abs(dy[*,i])) eq 0, count)
               if count gt 0 then inside[i] = 1
            endelse
         endif
      endfor
   endif

   ;; Result has same dimensions as input
   result = mgh_reproduce(0, x)

   ;; Load values into result & return

   case keyword_set(nan) of
      0: result[*] = inside
      1: result[ff] = inside
   endcase

   return, result

end

