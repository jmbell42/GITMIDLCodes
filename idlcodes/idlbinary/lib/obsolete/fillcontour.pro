; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/fillcontour.pro#1 $
;
; Copyright (c) 1991-2006, Research Systems, Inc.  All rights reserved.
;	Unauthorized reproduction prohibited.
;+
; NAME:	
;	FILLCONTOUR
; PURPOSE:
;	Contour, /fill does not fill the lowest contour level.
;	FILLCONTOUR attempts to fill that level.
; CATEGORY:
;	Plot
; CALLING SEQUENCE:
;	FILLCONTOUR, data, x, y, ......(keyword parameters)
; INPUTS:
;	data     - 2 dimensional data displayable with CONTOUR command.
;	x, y 	 - x and y coordinates (see description on CONTOUR)
;
;	KEYWORD INPUTS:
;		All the contour keywords are allowed.
;
; OUTPUTS:
;	A filled contour plot to the current graphics device.
; COMMON BLOCKS:
;	None.
; SIDE EFFECTS:
;	None.
; RESTRICTIONS:
;	Does not work with certain map projections.
; PROCEDURE:
;	Pretty much Straightforward.
; MODIFICATION HISTORY:
;       July, 1993 JIY - Initial creation
;-


pro fillcontour, data, x, y, _extra = _extra

   on_error, 2

   if (not keyword_set(data)) then $
      message, 'Incorrect number of arguments', /traceback

   if keyword_set(_extra) then begin
      list  = tag_names (_extra)
      for i=0,n_elements(list)-1 do begin
         if (strmid("C_COLORS",0,strlen(list(i))) eq list(i)) then $
            color = _extra.(i)(0)
         if (strmid("FILL",0,strlen(list(i))) eq list(i)) then $
            _extra.(i) = 0
      endfor
   endif
 
   dsize = size (data)

   if (dsize(0) ne 2) then $
      message, 'Array must have 2 dimensions',/traceback

   if not keyword_set(x) then x = lindgen(dsize(1))
   if not keyword_set(y) then y = lindgen(dsize(2))
  
   if (not keyword_set(color)) then color = 30
   contour, data, x, y, /nodata, /xsty, /ysty, _extra=_extra
   polyfill, !x.window([0,1,1,0,0]),!y.window([0,0,1,1,0]), color=color,/norm
   contour, data, x, y, _extra=_extra, /fill,/xsty,/ysty,/over
   tick = replicate(' ',30)
   axis, xax=0, /xsty, xtickname=tick
   axis, xax=1, /xsty, xtickname=tick
   axis, yax=0, /ysty, ytickname=tick
   axis, yax=1, /ysty, ytickname=tick
end 