; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/set_screen.pro#1 $
;
; Copyright (c) 1989-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

pro set_screen, xmin, xmax, ymin, ymax
;+
; NAME:
;	SET_SCREEN
;
; PURPOSE:
;	Emulate the Version I VMS/IDL SET_SCREEN procedure.
;	Sets the default position and size of the plot data window.
;	Uses device coordinates, rather than normalized coords.
;
; CATEGORY:
;	Plotting.
;
; CALLING SEQUENCE:
;	SET_SCREEN, Xmin, Xmax [, Ymin, Ymax]
;
; INPUTS:
;	Xmin:	Minimum X device coordinate of the plotting data window.
;
;	Xmax:	Maximum X device coordinate of the plotting data window.
;
; OPTIONAL INPUT PARAMETERS:
;	Ymin:	Minimum Y device coordinate of the plotting data window.
;
;	Ymax:	Maximum Y device coordinate of the plotting data window.
;
; KEYWORD PARAMETERS:
;	None.
;
; OUTPUTS:
;	No explicit outputs.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	The system variable !P.POSITION is set.
;
; RESTRICTIONS:
;	None.
;
; PROCEDURE:
;	Straightforward.  !P.POSITION is directly set.
;
; MODIFICATION HISTORY:
;	DMS, June, 1989.
;-
on_error, 2		;Return to caller in case of error
n = n_params()
if n le 2 then begin	;Calculate Ymin and Ymax
	y = !x.margin * !d.x_ch_size ;Margins in device coords
	ymin = y(0)
	ymax = !d.y_size - y(1)
	endif
xs = float(!d.x_size)	;Scale factors
ys = float(!d.y_size)
!p.position = [ xmin/xs, ymin/ys, xmax/xs, ymax/ys] ;Set it
end
