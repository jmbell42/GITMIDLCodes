;+
; NAME:
;   MGH_POLYBOX
;
; PURPOSE:
;   Clip an arbitrary polygon on the X-Y plane to a box (a rectangle
;   defined by X and Y limits) using the Sutherland-Hodgman algorithm.
;
; CATEGORY:
;   Graphics, Region of Interest, Geometry
;
; CALLING SEQUENCE:
;   result = MGH_POLYBOX(xclip, yclip, polin, COUNT=count)
;
; RETURN VALUE
;   The function returns [2,n] array defining the clipped polygon. The
;   second dimension will equal the value of the COUNT argument, except
;   where this is 0 in which the return value is -1.
;
; POSITIONAL PARAMETERS
;   xclip (input, numeric vector)
;     A 2-element vector specifying the clipping values in the X direction
;
;   yclip (input, numeric vector)
;     A 2-element vector specifying the clipping values in the Y direction
;
;   polin (input, numeric array)
;     A [2,m] array defining the polygon to be clipped.
;
; KEYWORD PARAMETERS
;   COUNT (output, integer)
;     The number of vertices in the clipped polygon.
;
; PROCEDURE:
;   The polygon is clipped to each edge in turn using the Sutherland-Hodgman
;   algorithm.
;
;   This function is based on JD Smith's POLYCLIP function. He can take all
;   of the credit and none of the blame.
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2001-10:
;     I wrote thsi first as a stand-alone function, based on JD Smith's
;     POLYCLIP, then modified it so that it just calls MGH_POLYCLIP
;     up to 4 times.
;   Mark Hadfield, 2005-12:
;     Moved to Motley library. Updated.
;-

function mgh_polybox, xc, yc, polin, COUNT=count

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   polout = mgh_polyclip(xc[0], 0B, 0B, polin, COUNT=count)

   if count eq 0 then return, polout

   polout = mgh_polyclip(xc[1], 0B, 1B, polout, COUNT=count)

   if count eq 0 then return, polout

   polout = mgh_polyclip(yc[0], 1B, 0B, polout, COUNT=count)

   if count eq 0 then return, polout

   polout = mgh_polyclip(yc[1], 1B, 1B, polout, COUNT=count)

   return, polout

end
