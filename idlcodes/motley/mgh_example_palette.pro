;+
; NAME:
;   MGH_EXAMPLE_PALETTE
;
; PURPOSE:
;   Generate & display various palettes.
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
;   Mark Hadfield, 2002-12:
;     Written.
;-

pro mgh_example_palette, option

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   if n_elements(option) eq 0 then option = 0

   ograph = obj_new('MGHgrGraph', NAME='Palette example')

   ograph->NewFont, SIZE=10

   case option of

      0: begin
         ;; Colour table retrieved from user colour table file by index.
         table = mgh_get_ct(2)
      end

      1: begin
         ;; Colour table retrieved from system colour table file by name.
         table = mgh_get_ct('Prism', /SYSTEM)
      end

      2: begin
         ;; Colour table constructed using specified points
         indices = [0,25,76,127,178,230,255]
         colors =  ['(0,30,127)','blue','yellow','red','green','(200,0,200)','(0,127,30)']
         table = mgh_make_ct(indices, colors)
      end

   endcase

   ograph->NewPalette, RESULT=opal, TABLE=table

   ograph->NewAtom, 'MGHgrColorBar', PALETTE=opal, VERTICAL=0, RESULT=obar

   obar->GetProperty, XRANGE=xrange, YRANGE=yrange

   ograph->SetProperty, $
        VIEWPLANE_RECT=[xrange[0],yrange[0],xrange[1]-xrange[0], $
                        yrange[1]-yrange[0]]+[-0.1,-0.2,0.2,0.3]

   mgh_new, 'MGH_Window', ograph, RESULT=owin

end

