;+
; NAME:
;   MGH_EXAMPLE_IMAGE_SEQUENCE
;
; PURPOSE:
;   Various approaches to animating a sequence of images.
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
;   Mark Hadfield, 2001-02:
;     Written.
;-

pro mgh_example_image_sequence, option

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(option) eq 0 then option = 0

   ;; Get image-sequence data & rebin to get a bigger data set.

   openr, lun, /GET_LUN, filepath('abnorm.dat', SUBDIR=['examples','data'])
   h = bytarr(64, 64, 15)
   readu, lun, h
   free_lun, lun

   h = rebin(h, 384, 384, 60)

   ;; Animate it

   dims = size(h, /DIMENSIONS)

   case option of

      0: begin

         animator = obj_new('MGH_Imagator', DIMENSIONS=dims[0:1])

         ;; Add images

         for f=0,dims[2]-1 do begin

            ;; Check to see if the user has selected the "Finish
            ;; Loading" menu item

            if animator->Finished() then break

            ;; Load images into IDLgrImage objects

            animator->AddImage, h[*,*,f]

         endfor

         animator->Finish

      end

      1: begin

         xinteranimate, SET=dims, /SHOWLOAD

         for f=0,dims[2]-1 do xinteranimate, FRAME=f, IMAGE=h[*,*,f], WINDOW=mypix

         xinteranimate, 70

      end

   endcase

end

