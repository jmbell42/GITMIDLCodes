;+
; PROCEDURE NAME:
;   MGH_GRAPH_DEFAULT
;
; PURPOSE:
;   Provide default values for MGHgrGraph properties related to sizing
;   and layout
;
; CATEGORY:
;   Object graphics.
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
;   Mark Hadfield, 2009-05:
;     Written.
;-
pro mgh_graph_default, $
     DIMENSIONS=dimensions, FONTSIZE=fontsize, $
     SCALE=scale, SYMSIZE=symsize, TICKLEN=ticklen, $
     UNITS=units

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Set FONTSIZE, SYMSIZE & TICKLEN.

   case 1B of
      float(strmid(!version.release, 0, 3)) ge 7.1: begin
         if n_elements(fontsize) eq 0 then fontsize = 13.0
      end
      else: begin
         if n_elements(fontsize) eq 0 then fontsize = 10.0
      end
   endcase

   if n_elements(symsize) eq 0 then symsize = 0.02

   if n_elements(ticklen) eq 0 then ticklen = 0.04D0

   if n_elements(units) eq 0 then units = 2
   
   case 1B of
      float(strmid(!version.release, 0, 3)) ge 7.1: begin
         ;; As of version 7.1, the resolution of IDLgrWindow objects
         ;; is 72 DPI
         default_scale_cm = 10.6
         default_scale_pix = default_scale_cm*(72/2.54)
      end
      else: begin
         ;; In versions before 7.1, IDLgrWindow objects took their resolution
         ;; from the operating system. On my systems, this has typically been
         ;; ~ 100 dpi. 
         default_scale_cm = 7.5
         default_scale_pix = default_scale_cm*(100/2.54)
      end
   endcase

   case units of
      0:  if n_elements(scale) eq 0 then scale = default_scale_cm*(100/2.54)
      1:  if n_elements(scale) eq 0 then scale = default_scale_cm/2.54
      2:  if n_elements(scale) eq 0 then scale = default_scale_cm
      3:  if n_elements(dimensions) eq 0 then dimensions = [1,1]
   endcase

end


