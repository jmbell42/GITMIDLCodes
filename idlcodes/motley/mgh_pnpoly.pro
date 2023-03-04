;+
; NAME:
;   MGH_PNPOLY
;
; PURPOSE:
;   Determine whether a point or set of points is inside a polygon.
;
; CALLING SEQUENCE:
;   Result = MGH_PNPOLY(XP, YP, X, Y)
;
; INPUTS:
;   XP,YP:      Vectors of X, Y positions defining the polygon.
;
;   X,Y:        X, Y position(s) defining the point(s) to be tested. Can
;               be vectors.
;
; OUTPUTS:
;   The function returns an array of the same shape as X. Each element
;   is 0 if the point is outside the polygon, 1 if it is inside the polygon.
;   The comp.graphics.algorithms has the following to say about points
;   on the boundary:
;
;       "It returns 1 for strictly interior points, 0 for strictly exterior,
;       and 0 or 1 for points on the boundary.  The boundary behavior is
;       complex but determined; in particular, for a partition of a region
;       into polygons,  each point is "in" exactly one polygon. (See p.243
;       of [O'Rourke (C)] for a discussion of boundary behavior.)"
;
; PROCEDURE:
;   Ray-crossing technique of WR Franklin from Comp.graphics.algorithms FAQ.
;
; REFERENCES:
;    *  "Misc Notes - WR Franklin", http://www.ecse.rpi.edu/Homepages/wrf/misc.html:
;       includes a reference (broken @ Jul 2001) to his point-in-polygon code.
;    *  Comp.graphics.algorithms FAQ, http://www.faqs.org/faqs/graphics/algorithms-faq/:
;       See subject 2.03
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
;   Mark Fardal, Nov 1999:
;       Written as PNPOLY.
;   Mark Fardal, Jul 2001:
;       Added header.
;   Mark Hadfield, Jul 2001:
;       Renamed MGH_PNPOLY. Output now matches input in shape, not just size.
;-

function MGH_PNPOLY, xpol, ypol, xpt, ypt

   compile_opt DEFINT32
   compile_opt STRICTARR

    npol = n_elements(xpol)
    if (npol lt 3) then message, 'Need 3 points to define polygon.'
    if npol ne n_elements(ypol) then message, 'xpol, ypol mismatched.'

    nd = n_elements(xpt)
    if nd eq 0 then message, 'XPT undefined.'
    if nd ne n_elements(ypt) then message, 'xpt, ypt mismatched.'

    inside = mgh_reproduce(0L,xpt)

    j = npol-1
    for i=0,npol-1 do begin
        betw = where( ( (ypol[i] le ypt) and (ypt lt ypol[j]) ) $
                   or ( (ypol[j] le ypt) and (ypt lt ypol[i]) ), count)
        if (count gt 0) then begin
            invslope = (xpol[j]-xpol[i]) / (ypol[j]-ypol[i])
            cond = where( (xpt[betw]-xpol[i]) lt invslope * (ypt[betw]-ypol[i]), count)
            if (count gt 0) then begin
                incr = betw[cond]
                inside[incr] ++
            endif
        endif
        j = i
    endfor

    return, byte(inside mod 2)

end
