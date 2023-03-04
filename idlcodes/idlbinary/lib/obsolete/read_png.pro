; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/read_png.pro#1 $
;
; Copyright (c) 2000-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

;----------------------------------------------------------------------
;+
; NAME:
;       READ_PNG
;
; PURPOSE:
;   Read the contents of a PNG format image file and return the image
;   and color table vectors (if present) in the form of IDL variables.
;
;   This routine is included to allow a developer to easily
;   replace calls to READ_GIF with calls to the procedure
;   READ_PNG.  Note that this wrapper routine calls the
;   intrinsic function READ_PNG, which is still supported
;   and should be used when writing new code.
;
;   Note also that your GIF files must actually be converted to PNG
;   file using a separate application. READ_PNG cannot read the GIF format.
;
;   The CLOSE and MULTIPLE keywords of the obsolete READ_GIF
;   are not supported and will generate compiler errors that the
;   developer should fix during the conversion process.
;
; CATEGORY:
;       Input/Output.
;
; CALLING SEQUENCE:
;       READ_PNG, File, Image [, R, G, B]
;
; INPUTS:
;       File:   Scalar string giving the name of the rasterfile to read
;
; Keyword Inputs:
;
;    ORDER: Set this keyword to indicate that the rows of the image should
;           be read from bottom to top. The rows are read from top to bottom
;           by default. ORDER provides compatibility with PNG files written
;           using versions of IDL prior to IDL 5.4, which wrote PNG files
;           from bottom to top.
;
;    VERBOSE: Produces additional diagnostic output during the read.
;
;    TRANSPARENT: Returns an array of pixel index values that are to be
;           treated as "transparent" for the purposes of image display.
;           If there are no transparent values then TRANSPARENT will be set
;           to a long-integer scalar with the value 0.
;
; OUTPUTS:
;
;       Image:  The 2D byte array to contain the image.
;
; OPTIONAL OUTPUT PARAMETERS:
;
;     R, G, B:  The variables to contain the Red, Green, and Blue color vectors
;               if the rasterfile containes colormaps.
;
; MODIFICATION HISTORY:
;     Written: September, 2000, RSI.
;
;-
;
PRO READ_PNG, file, image, r, g, b, _REF_EXTRA=_ref_extra

    ON_ERROR, 2			;Return to caller if error

    image = READ_PNG(file, r, g, b, _EXTRA=_ref_extra)

end
