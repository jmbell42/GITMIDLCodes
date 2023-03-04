; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/phaser.pro#1 $

pro phaser, legal=legal, letter=letter, $
            landscape=landscape, portrait=portrait

;+
; NAME:
;	PHASER
;
; PURPOSE:
;	Issue the SET_PLOT and DEVICE commands appropriate for the Tektronix
;	Phaser IIpxi color PostScript laser printer.
;
; CATEGORY:
;	Device drivers.
;
; CALLING SEQUENCE:
;	PHASER [, /LETTER] [, /LEGAL] [, /LANDSCAPE] [, /PORTRAIT]
;
; INPUTS:
;	None.
;
; KEYWORD PARAMETERS:
;      LETTER:	If this keyword is set, output is produced for letter-sized 
;		paper.  This setting is the default.
;
;       LEGAL:	If this keyword is set, output is produced for legal-sized
;		papter.  /LEGAL should be used for overhead transparencies as 
;		well, since these are legal size before the borders are 
;		removed.
;
;   LANDSCAPE:	If this keyword is set, output is produced in landscape 
;		orientation, i.e. with the X axis along the long edge of the 
;		page.  This setting is the default.
;
;    PORTRAIT:	If this keyword is set, output is produced in portrait 
;		orientation, i.e. wih the X axis  along the short edge of the 
;		paper.
;
; OUTPUTS:
;	None.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	The plotting device is set to PostScript, 8 bits/pixel, color and with
;	sizes, offsets and orientations appropriate to the keywords used.
;
; RESTRICTIONS:
;	Because of the paper handling mechanism in the Phaser printer it is
;	unable to print over the entire page.  The actual print dimensions
;	are 8.0" x 8.5" for /LETTER and 8.0" x 10.5" for /LEGAL.
;
; PROCEDURE:
;	The SET_PLOT, 'PS' command is issued. 
;	Then PHASER issues a command like:
;
;	DEVICE, BITS=8, /COLOR, XSIZE=SHORT_SIDE, YSIZE=LONG_SIDE, $
;		XOFFSET = SMALL_OFFSET, YOFFSET = BIG_OFFSET, $
;		/INCH, /PORTRAIT, [/LANDSCAPE or /PORTRAIT]
;
;	The values of SHORT_SIDE, LONG_SIDE, SMALL_OFFSET, BIG_OFFSET are
;	calculated for the paper size (/LETTER or /LEGAL) and orientation
;	(/LANDSCAPE or /PORTRAIT).
;
; MODIFICATION HISTORY:
;	Created 22-OCT-1991 by Mark Rivers.
;-

short_side = 8.0
small_offset=(8.5-short_side)/2.
set_plot, 'ps'
if n_elements(legal) ne 0 then begin
  long_side=10.5
  big_offset=(14.-long_side)/2.
endif else begin
  long_side=8.5
  big_offset=(11.-long_side)/2.
endelse
if n_elements(portrait) ne 0 then begin
  device, bits=8, /color, xsize=short_side, ysize=long_side, $
         xoffset=small_offset, yoffset=big_offset, $
         /inch, /portrait
endif else begin
  device, bits=8, /color, xsize=long_side, ysize=short_side, $
         xoffset=small_offset, yoffset=long_side+big_offset, $
         /inch, /landscape
endelse

end
