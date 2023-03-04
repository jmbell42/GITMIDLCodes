; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/read_gif.pro#1 $
;
; Copyright (c) 1992-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

;----------------------------------------------------------------------
;
;  GifReadByte
;       Read a single byte out of the given file
;
FUNCTION GifReadByte, unit
        COMPILE_OPT hidden

        ch      = 0b
        READU, unit, ch
        RETURN, ch
END

;----------------------------------------------------------------------
;+
; NAME:
;       READ_GIF
;
; PURPOSE:
;       Read the contents of a GIF format image file and return the image
;       and color table vectors (if present) in the form of IDL variables.
;
; CATEGORY:
;       Input/Output.
;
; CALLING SEQUENCE:
;       READ_GIF, File, Image [, R, G, B]
;
; INPUTS:
;       File:   Scalar string giving the name of the rasterfile to read
;
; Keyword Inputs:
;       CLOSE = if set, closes any open file and returns if the MULTIPLE images
;               per file mode was used.  This keyword is used
;               without additional parameters.
;
;       MULTIPLE = if set, read files containing multiple images per
;               file.  Each call to READ_GIF returns the next image,
;               with the file remaining open between calls.  The File
;               parameter is ignored after the first call.  Reading
;               past the last image returns a scalar value of -1 in IMAGE, and
;               closes the file.  When reading the 2nd and subsequent
;               images, R, G, and B are not returned.
;
; OUTPUTS:
;       Image:  The 2D byte array to contain the image.
;
;
; OPTIONAL OUTPUT PARAMETERS:
;     R, G, B:  The variables to contain the Red, Green, and Blue color vectors
;               if the rasterfile containes colormaps.
;
; SIDE EFFECTS:
;       None.
;
; COMMON BLOCKS:
;       READ_GIF_COMMON.
; RESTRICTIONS:
;       This routine only reads in the first image in a file (the format
;       allows many). Local colormaps are not supported.
;       Only 8 bit images are supported.
;
;       The Graphics Interchange Format(c) is the Copyright property
;       of CompuServ Incorporated.  GIF(sm) is a Service Mark property of
;       CompuServ Incorporated.
;
; EXAMPLE:
;       To open and read the GIF image file named "foo.gif" in the current
;       directory, store the image in the variable IMAGE1, and store the color
;       vectors in the variables R, G, and B, enter:
;
;               READ_GIF, "foo.gif", IMAGE1, R, G, B
;
;       To load the new color table and display the image, enter:
;
;               TVLCT, R, G, B
;               TV, IMAGE1
;
; MODIFICATION HISTORY:
;       Written June 1992, JWG
;       Added GIF89a and interlaced format, Jan, 1995, DMS.
;       Added MULTIPLE and CLOSE, Aug, 1996.
; 	August, 2000  KDB
;	 - Fixed issues with multiple image files that contain
;	   images of differing sizes. 
;	 - Cleaned up the formatting and added comments.
;	 - Removed junk reads used to skip data and made
;	   use of point_lun (save some memory cycles).
;
;-
;
PRO READ_GIF, FILE, IMAGE, R, G, B, MULTIPLE=mult, CLOSE=close

   ;; Define GIF header (and screen descriptor. Used for Multiple)

   COMMON READ_GIF_COMMON, unit, scrWidth, scrHeight

   on_error, 2          ;Return to caller on errors

   if(n_elements(unit) eq 0)then $
      unit = -1
   image  = -1          ;No image read yet

   ;; Error handling block
closeFile:
   CATCH, errorIndex
   if keyword_set(close) OR (errorIndex NE 0) then begin
      CATCH,/CANCEL   ; no infinite loops...
      if unit gt 0 then FREE_LUN, unit
        unit = -1
        IF(errorIndex NE 0)THEN BEGIN
           errorMessage = !ERROR_STATE.MSG
           MESSAGE, errorMessage, $
                    NONAME=STRMID(errorMessage,0,8) EQ 'READ_GIF'
        ENDIF
        return
     endif

   ;; Main GIF Header declaration.
   header = { magic	: bytarr(6),            $
              width_lo  : 0b,                   $
              width_hi  : 0b,                   $
              height_lo : 0b, 			$
              height_hi : 0b,                   $
              screen_info : 0b, 		$
	      background : 0b, 			$
	      reserved  : 0b }

   ;; local image header declaration
   ihdr  = {   left_lo         : 0B,           $
               left_hi         : 0B,           $       
               top_lo          : 0B,           $
               top_hi          : 0B,           $
               iwidth_lo       : 0B,           $
               iwidth_hi       : 0B,           $
               iheight_lo      : 0B,           $       
               iheight_hi      : 0B,           $
               image_info      : 0b }        ; its content

   if(keyword_set(mult) and unit gt 0)then $
      goto, next_image

   if(unit gt 0)then $
      free_lun, unit

   OPENR, unit, file, /GET_LUN, /BLOCK
   READU, unit, header          ;Read gif header

   ;; Check Magic in header: GIF87a or GIF89a.
   gif  = STRING(header.magic[0:2])
   vers = STRING(header.magic[3:5])

   if( gif NE 'GIF')then $
       MESSAGE, 'File ' + file + ' is not a GIF file.'

   if(vers ne '87a' and vers ne '89a')then $
        MESSAGE, /INFO, 'Unknown GIF Version: '+vers+'. Attempting to read...'

   ;; Get the virtual screen width and height

   scrWidth   = header.width_hi * 256 + header.width_lo
   scrHeight  = header.height_hi * 256 + header.height_lo

   ;; Find out how big the color map is

   bits_per_pixel  = (header.screen_info AND 'F'X) + 1
   color_map_size  = 2 ^ bits_per_pixel

   ;; Read in the colormap (optional)

   if((header.screen_info AND '80'X) NE 0 )then begin
      map     = BYTARR(3,color_map_size, /NOZERO)
      READU, unit, map
      map     = transpose(map)
      r       = map[*,0]
      g       = map[*,1]
      b       = map[*,2]
   endif

   ;; Read the image description

next_image:

   while( 1 )do begin                ;; Read till we get a terminator
      cmd = GifReadByte(unit)        ;; Loop thru commands in file.

      case string(cmd) of

      ';':    begin                  ;; GIF trailer (0x3b)
           close = 1
           GOTO, closeFile
           END

      ',':    begin                  ;; Image description (0x2c)
           readu,unit,ihdr

           ;; Check for file formats we don't support
           ;; We don't support local colormaps

           if((ihdr.image_info AND '80'X) NE 0)then begin  ;;Local color map
              lcolor_map_size = 2^((ihdr.image_info and 7) + 1)
              point_lun, (-unit), iPnt
	      point_lun, unit, iPnt + (3*lcolor_map_size)
             message,'Local colormaps ignored.', /CONTINUE
           endif

           ;; Size of this image?
           iWidth   = ihdr.iwidth_hi  * 256 + ihdr.iwidth_lo
           iHeight  = ihdr.iheight_hi * 256 + ihdr.iheight_lo

           ;; Allocate an array to hold the image
           image   = BYTARR(iWidth, iHeight, /NOZERO)

           ;; Now call special GIF-LZW routine hidden within IDL
           ;; to do the ugly serial bit stream decoding

           DECODE_GIF,unit,image           ; magic

           ;; This should be the 0 byte that ends the series:

           junk = GifReadByte(unit)       ;Loop thru commands in file.

           if(junk ne 0)then $
              message,/info,'No trailing 0.'

           ;; Reorder rows in an interlaced image

           if((ihdr.image_info AND '40'X) NE 0 )then begin
              l = lindgen(iHeight)        ;Row indices...

              ;;  Gif interlace ordering

              p = [l[where(l mod 8 eq 0)], l[where(l mod 8 eq 4)], $
                   l[where(l mod 4 eq 2)], l[where(l and 1)]]

              tmpImage = bytarr(iWidth, iHeight, /NOZERO)
              l = iHeight-1
              for i=0, l do $
                  tmpImage[0, l-p[i]] = image[*,l-i]
              image = temporary(tmpImage)
            endif

            ;; Ok, is this image the same size as the screen size (main image)?

            if( iHeight ne scrHeight or iWidth ne scrWidth)then begin
               tmpImage = replicate(header.background, scrWidth, scrHeight)
               x0 = ihdr.left_hi * 256 + ihdr.left_lo
               y0 = scrHeight - ((ihdr.top_hi * 256 + ihdr.top_lo) + iHeight)
               tmpImage[x0:x0+iWidth-1, y0:y0+iHeight-1] = $
                                  image[0:iWidth-1, 0:iHeight-1]
               image = temporary(tmpImage) ;; Nuc the memory
            endif

            if(keyword_set(mult)) then $
               return        ;Leave file open

            close = 1  ; otherwise close the file
            GOTO, closeFile
         end

     '!':    BEGIN              ;Gif Extention block (ignored) (0x21)
            label = GifReadByte(unit)       ;; toss extension block label
            repeat begin                    ;; read and ignore blkss
              blk_size = GifReadByte(unit)  ;; block size
              if(blk_size ne 0 )then begin
		 point_lun, (-unit), iPnt
		 point_lun, unit, iPnt + blk_size
              endif
            endrep until(blk_size eq 0)
         end

     ELSE:   message,'Unknown GIF keyword in ' + $
			file + string(cmd, format='(2x,Z2)')
     ENDCASE
   endwhile

END
