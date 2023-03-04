; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/write_gif.pro#1 $
;
; Copyright (c) 1992-2006, Research Systems, Inc.  All rights reserved.
;	Unauthorized reproduction prohibited.

PRO WRITE_GIF, FILE, IMG, R, G, B, MULTIPLE=mult, CLOSE=close
;+
; NAME:
;	WRITE_GIF
;
; PURPOSE:
;	Write an IDL image and color table vectors to a
;	GIF (graphics interchange format) file.
;
; CATEGORY:
;
; CALLING SEQUENCE:
;
;	WRITE_GIF, File, Image  ;Write a given array.
;
;	WRITE_GIF, File, Image, R, G, B  ;Write array with given color tables.
;
;
; INPUTS:
;	Image:	The 2D array to be output.
;
; OPTIONAL INPUT PARAMETERS:
;      R, G, B:	The Red, Green, and Blue color vectors to be written
;		with Image.
; Keyword Inputs:
;	CLOSE = if set, closes any open file if the MULTIPLE images
;		per file mode was used.  If this keyword is present,
;		nothing is written, and all other parameters are ignored.
;	MULTIPLE = if set, write files containing multiple images per
;		file.  Each call to WRITE_GIF writes the next image,
;		with the file remaining open between calls.  The File
;		parameter is ignored, but must be supplied,
;		after the first call.  When writing
;		the 2nd and subsequent images, R, G, and B are ignored.
;		All images written to a file must be the same size.
;
;
; OUTPUTS:
;	If R, G, B values are not provided, the last color table
;	established using LOADCT is saved. The table is padded to
;	256 entries. If LOADCT has never been called, we call it with
;	the gray scale entry.
;
;
; COMMON BLOCKS:
;	COLORS
;
; SIDE EFFECTS:
;	If R, G, and B aren't supplied and LOADCT hasn't been called yet,
;	this routine uses LOADCT to load the B/W tables.
;
; COMMON BLOCKS:
;	WRITE_GIF_COMMON.
; RESTRICTIONS:
;	This routine only writes 8-bit deep GIF files of the standard
;	type: (non-interlaced, global colormap, 1 image, no local colormap)
;
;	The Graphics Interchange Format(c) is the Copyright property
;	of CompuServ Incorporated.  GIF(sm) is a Service Mark property of
;	CompuServ Incorporated.
;
; MODIFICATION HISTORY:
;	Written 9 June 1992, JWG.
;	Added MULTIPLE and CLOSE, Aug, 1996.
;-
;

COMMON WRITE_GIF_COMMON, unit, width, height, position
COMMON colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr

; Check the arguments
ON_ERROR, 2			;Return to caller if error
n_params = N_PARAMS();

;; Fix case where passing through undefined r,g,b variables
;; SJL - 2/99
if ((n_params eq 5) and (N_ELEMENTS(r) eq 0)) then n_params = 2

; let user know about demo mode limitation.
; encode_gif is disabled in demo mode
if (LMGR(/DEMO)) then begin
    MESSAGE, 'Feature disabled for demo mode.'
    return
endif

if n_elements(unit) le 0 then unit = -1

if KEYWORD_SET(close) then begin
  if unit ge 0 then FREE_LUN, unit
  unit = -1
  return
  endif

IF ((n_params NE 2) AND (n_params NE 5))THEN $
  message, "usage: WRITE_GIF, file, image, [r, g, b]'

; Is the image a 2-D array of bytes?

img_size	= SIZE(img)
IF img_size[0] NE 2 OR img_size[3] NE 1 THEN	$
	message, 'Image must be a byte matrix.'



if keyword_set(mult) and unit ge 0 then begin
  if width ne img_size[1] or height ne img_size[2] then $
	message,'Image size incompatible'
  point_lun, unit, position-1	;Back up before terminator mark
endif else begin		;First call
  width = img_size[1]
  height = img_size[2]

; If any color vectors are supplied, do they have right attributes ?
  IF (n_params EQ 2) THEN BEGIN
	IF (n_elements(r_curr) EQ 0) THEN LOADCT, 0	; Load B/W tables
	r	= r_curr
	g	= g_curr
	b	= b_curr
  ENDIF

  r_size = SIZE(r)
  g_size = SIZE(g)
  b_size = SIZE(b)
  IF ((r_size[0] + g_size[0] + b_size[0]) NE 3) THEN $
	message, "R, G, & B must all be 1D vectors."
  IF ((r_size[1] NE g_size[1]) OR (r_size[1] NE b_size[1]) ) THEN $
	message, "R, G, & B must all have the same length."

  ;	Pad color arrays

  clrmap = BYTARR(3,256)

  tbl_size		= r_size[1]-1
  clrmap[0,0:tbl_size]	= r
  clrmap[0,tbl_size:*]	= r[tbl_size]
  clrmap[1,0:tbl_size]	= g
  clrmap[1,tbl_size:*]	= g[tbl_size]
  clrmap[2,0:tbl_size]	= b
  clrmap[2,tbl_size:*]	= b[tbl_size]

  ; Write the result
  ; MACTYPE find me
  if (!version.os EQ 'MacOS') then begin
  OPENW, unit, file, /STREAM, /GET_LUN, MACTYPE = "GIFf"
  endif else begin
  OPENW, unit, file, /STREAM, /GET_LUN
  endelse

  hdr	=  { giffile, $		;Make the header
  magic:'GIF87a', 		$
  width_lo:0b, width_hi:0b,	$
  height_lo:0b, height_hi:0b,	$
  global_info: BYTE('F7'X),	$	; global map, 8 bits color
  background:0b, reserved:0b }		; 8 bits/pixel

  hdr.width_lo	= width AND 255
  hdr.width_hi	= width / 256
  hdr.height_lo	= height AND 255
  hdr.height_hi	= height / 256

  WRITEU, unit, hdr				;Write header
  WRITEU, unit, clrmap				;Write color map

endelse				;Not Multiple

ihdr	= { 	imagic: BYTE('2C'X),		$	; BYTE(',')
	left:0, top: 0,			$
	width_lo:0b, width_hi:0b,	$
	height_lo:0b, height_hi:0b,	$
	image_info:7b }
ihdr.width_lo	= width AND 255
ihdr.width_hi	= width / 256
ihdr.height_lo	= height AND 255
ihdr.height_hi	= height / 256
WRITEU, unit, ihdr

ENCODE_GIF, unit, img

if keyword_set(mult) then begin ;Multiple image mode?
  POINT_LUN, -unit, position	;Get the position
endif else begin		;Single image/file
  FREE_LUN, unit		; Close file and free unit
  unit = -1
endelse
END
