;+
; CLASS:
;   MGHgrMovieFile
;
; PURPOSE:
;   This class generates an animation file from a sequence of image arrays.
;
;   The MGHgrMovieFile class is modelled on the IDLgrMPEG class. It stores
;   images on disk in a sequence of PPM files (Put method) then combines them
;   into a multiple-image file (Save method) by spawning one of the following
;   programs:
;
;    - The ImageMagick "convert" command (http://www.imagemagick.org/)
;
;    - Klaus Ehrenfried's program "ppm2fli" for generating FLC
;      animations, (http://vento.pi.tu-berlin.de/fli.html).
;
;    - The Info-Zip "zip" command (http://www.cdrom.com/pub/infozip/)
;
;   The user is responsible for ensuring that the command names as
;   specified here invoke the command in the shell spawned by
;   IDL. This can be done in a variety of ways depending on the
;   operating system and shell.
;
;   In the current version, frames can only be added at the end of the
;   sequence.
;
; PROPERTIES:
;
;   The following properties (ie keywords to the Init, GetProperty &
;   SetProperty methods) are supported
;
;     COUNT (Get)
;       The number of frames that have been put into the object.
;
;     DIMENSIONS (Get)
;       A 2-element integer array specifying the image dimensions in
;       pixels. This property is determined from the first frame added
;       to the object. It is used by the Save method when generating
;       FLC files, otherwise it is for information only.
;
;     FILE (Init, Get, Set)
;       A string specifying the name of the output file.
;
;     FORMAT (Init, Get, Set)
;       A string (converted internally to upper case) specifying the
;       output file format. See FILE FORMATS section below.
;
; RESTRICTIONS:
;   This class was developed and tested on a Windows XP system with
;   the native Win32 versions of convert, ppm2fli and zip. It should
;   work without modification on Unix systems.
;
; FILE FORMATS:
;
;   With the exceptions noted below, the FORMAT property is
;   interpreted as an ImageMagick descriptor for a graphics-file
;   format supporting multiple images. Possible values include:
;
;     GIF
;       ImageMagick can produce multi-image GIFs. For several years,
;       LZW compression was missing from the binary distributions
;       so they produced only uncompressed GIFS. However as of
;       2004-04 it appears to have been reinstated.
;
;     HDF
;       The CONVERT documentation claims that it can write multiple
;       images to an HDF file, but messages on the ImageMagick
;       mailing list say that HDF is no longer supported.
;
;     MNG
;       MNG (Multiple-Image Network Graphics) is an image format based
;       on PNG (Portable Network Graphics) but supporting multiple
;       images, animation and transparent JPEGs. It's not widely
;       supported at the moment. See http://www.libpng.org/pub/mng/
;       and http://www.libpng.org/pub/png/.
;
;     PDF, PS
;       Images are written to a PDF or PS file, one image per page.
;       This could be used for printing, I guess.
;
;     TIFF
;       This is a handy format for holding a sequence of images with
;       no loss in quality, though there are no players offering
;       speedy playback.  Compression is an issue, because the normal
;       LZW compression is unavailable in ImagMagick by default
;       (cf. GIF above).  I have found Zip compression the best. It is
;       supported by ImageMagick and also by my preferred TIFF viewer,
;       Xnview (http://perso.wanadoo.fr/pierre.g/xnview/enhome.html).
;
;   The following are handled by applications other than ImageMagick:
;
;     FLC
;       The FLC animation format (http://crusty.er.usgs.gov/flc.html),
;       originally developed by Autodesk is generally less
;       resource-hungry than MPEG. It is limited to 256 colours, which
;       are assigned in an optimal way by PPM2FLI.
;
;     ZIP
;       If this format is selected, the PPM files are gathered into a
;       ZIP archive.
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
;   Mark Hadfield, 2000-02:
;     Written.
;   Mark Hadfield, 2003-10:
;     Updated for IDL 6.0.
;   Mark Hadfield, 2004-04:
;     Location & names of the temporary PPM files have been
;     changed. This has been done to make the ZIP format more usable,
;     as the base name for the PPM files inside the ZIP file is now
;     based on the output file name.
;   Mark Hadfield, 2006-05:
;     Deleted code specific to MPEG. I don't use this class to create
;     MPEG files any more.
;-

; MGHgrMovieFile::Init
;
function MGHgrMovieFile::Init, $
     FILE=file, FORMAT=format

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(format) ne 1 then format = 'MNG'

   self.tempdir = filepath('', ROOT=filepath('', /TMP), SUBDIR=cmunique_id())

   file_mkdir, self.tempdir

   self->SetProperty, FILE=file, FORMAT=format

   return, 1

end


; MGHgrAnimation::Cleanup
;
pro MGHgrMovieFile::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   for p=0,self.count-1 do file_delete, self->FrameFileName(p)

   file_delete, self.tempdir

end

; MGHgrMovieFile::GetProperty
;
pro MGHgrMovieFile::GetProperty, $
     COUNT=count, DIMENSIONS=dimensions, FILE=file, FORMAT=format

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   count = self.count

   dimensions = self.dimensions

   file = self.file

   format = self.format

end

; MGHgrMovieFile::SetProperty
;
pro MGHgrMovieFile::SetProperty, $
     FILE=file, FORMAT=format

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(file) gt 0 then begin
      self.file = file
      if strlen(self.base) eq 0 then begin
         self.base = file_basename(self.file)
         p = strpos(self.base, '.')
         if p gt 0 then self.base = strmid(self.base, 0, p)
      endif
   endif

   if n_elements(format) gt 0 then self.format = strupcase(format)

end

; MGHgrMovieFile::Count
;
function MGHgrMovieFile::Count

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   return, self.count

end


; MGHgrMovieFile::FrameFileName
;
function MGHgrMovieFile::FrameFileName, position

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(position) eq 0 then position = 0

   result = mgh_reproduce('', position)

   for i=0,n_elements(position)-1 do $
        result = filepath(string(self.base, position[i], FORMAT='(%"%s.%6.6d.ppm")'), $
                          ROOT=self.tempdir)

   return, result

end


; MGHgrMovieFile::Put
;
pro MGHgrMovieFile::Put, image

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   position = self.count

   n_dims = size(image, /N_DIMENSIONS)

   if (n_dims lt 2) || (n_dims gt 3) then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'image'

   if product(self.dimensions) eq 0 then $
        self.dimensions=(size(image, /DIMENSIONS))[n_dims-2:n_dims-1]

   ;; Generate PPM file

   file = self->FrameFileName(position)

   write_ppm, file, image

   self.count += 1

end


; MGHgrMovieFile::Save
;
pro MGHgrMovieFile::Save

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if file_test(self.file) then file_delete, self.file

   ;; Most of the programs can or must read input file names
   ;; from a list file

   file_list = filepath('list.dat', ROOT=self.tempdir)

   ;; Spawn a program to build the file. The default
   ;; frame rate can be set via CONVERT's -delay switch
   ;; (delay in units of 10 ms) and PPM2FLI's -s switch
   ;; (delay in ms). It would be nice to be able to alter
   ;; this but I haven't got around to it. Handling of options
   ;; generally needs to be cleaned up.

   case 1B of

      self.format eq 'FLC': begin
         openw, lun, file_list, /GET_LUN
         for i=0,self.count-1 do $
               printf, lun, self->FrameFileName(i)
         free_lun, lun
         sdim = strjoin(strtrim(2*(self.dimensions/2),2),'x')
         ;; The -N switch in the following command directs ppm2fli
         ;; to store extra information in the FLC file, for better
         ;; reverse playback with Xanim. It has no apparent effect
         ;; with Imagen, but the increase in file size is modest,
         ;; so I've retained it.
         spawn, LOG_OUTPUT=1, $
                'ppm2fli -vv -Qn 1024 -N -s 67 -g '+sdim+' "'+ $
                file_list+'" "'+self.file+'"'
         file_delete, file_list
      end

      self.format eq 'ZIP': begin
         openw, lun, file_list, /GET_LUN
         for i=0,self.count-1 do $
               printf, lun, self->FrameFileName(i)
         free_lun, lun
         spawn, LOG_OUTPUT=1, $
                'zip -v -j -D "'+self.file+'" -@ < "'+file_list+'"'
         file_delete, file_list
      end

      self.format eq 'TIFF': begin
         openw, lun, file_list, /GET_LUN
         for i=0,self.count-1 do $
               printf, lun, self->FrameFileName(i)
         free_lun, lun
         fmt = '(%"convert -verbose -adjoin -delay 7 @\"%s\" -compress Zip %s:\"%s\" & pause")'
         spawn, LOG_OUTPUT=1, $
                string(file_list, self.format, self.file, FORMAT=fmt)
         file_delete, file_list
      end

      else: begin
         openw, lun, file_list, /GET_LUN
         for i=0,self.count-1 do $
               printf, lun, self->FrameFileName(i)
         free_lun, lun
         fmt = '(%"convert -verbose -adjoin -delay 7 @\"%s\" %s:\"%s\"")'
         spawn, LOG_OUTPUT=1, $
                string(file_list, self.format, self.file, FORMAT=fmt)
         file_delete, file_list
      end

   endcase

end


; MGHgrMovieFile__Define
;
pro MGHgrMovieFile__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGHgrMovieFile, dimensions: lonarr(2), format: '', $
                 file: '', tempdir: '', base: '', count: 0}

end

