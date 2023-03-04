; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/only_8bit.pro#1 $
;
; Copyright (c) 1987-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

pro only_8bit,mask = mask, colors = colors
;Set up IDL to work on a Sun with 8 bit color only.
;+
; NAME:
;	ONLY_8BIT
;
; PURPOSE:
;	Set up the Sun workstation colors (SunView) to work with IDL.
;	This procedure must be called before any windows are created.
;	It creates a window the number of colors specified by the COLORS
;	keyword (the default is 249).  The remaining colors are reserved for 
;	the other SunView windows.
;
;	Why a default of 249 colors?  This default leaves 7 colors for 
;	other windows which is adequate for most applications.  If this is not
;	enough, use the command:
;
;		ONLY_8BIT, COLORS=241, /MASK
;
;	leaving 15 colors for the other windows.
;
; CATEGORY:
;	General display.
;
; CALLING SEQUENCE:
;	ONLY_8BIT [, MASK = Mask] [, COLORS = Colors]
;
; INPUTS:
;	None.
;
; Keyword Input parameters:
;	MASK:	Set this keyword to set the write mask to disable writing 
;		the low-order bits.  If this keyword is set, images and color 
;		indices scaled in the normal range of 0 to 255 will appear 
;		properly, but without the full number of colors.
;
;		For example, if you specify 249 colors, leaving 8 for other 
;		windows, the write mask will be set to 'f8'x, disabling the 
;		writing of the bottom 3 bits.  Only 32 distinct colors will be 
;		written, but data scaled from 0 to 255 are written into
;		color indices 0 to 248.  If you can always scale your
;		images and color indices into the range 0 to 247, you
;		need not set the mask.
;
;      COLORS:	The number of color indices for IDL to use.  The default
;		is 249.
; OUTPUTS:
;	None.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	A window with only 249 colors is created and the write mask is
;	set to 255, passing all bits.
;
; RESTRICTIONS:
;	As described above.
;
; PROCEDURE:
;	Straightforward.
;
; MODIFICATION HISTORY:
;	DMS, 11/1987.
;	DMS, 3/6/89,	Modified to work with the new color table scheme,
;			which preserves the color mapping of indices not used
;			by IDL.
;-
on_error,2                      ;Return to caller if an error occurs
if n_elements(colors) eq 0 then colors = 249
old_device = !d.name
set_plot,'SUN3'
window,colors=colors
if keyword_set(mask) ne 0 then begin	;Set write mask?
	i = 0		;# of bits enabled
	while (255 and ((mask = 256-2^i))) gt colors do i=i+1
	message, 'Mask set to ' + string(mask)
	device,set_write = mask
	endif
set_plot,old_device
end

