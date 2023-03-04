;+
; NAME:
;   MGH_EXAMPLE_GLAXIS
;
; PURPOSE:
;   Plot one year's data with an axis labelled at the centre of each
;   month using the MGHgrGLaxis class.
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

pro mgh_example_glaxis

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Data begins at 00:00 on 1 Jan in an arbitrary non-leap year

   dt0 = mgh_dt_julday(YEAR=1981)

   ;; Generate x & y data

   x = timegen(START=dt0, 366)

   y = sin(2*!dpi*(x-dt0)/365)

   z = y + 0.1*randomn(seed, 366)

   ;; Create graph & axes

   ograph = obj_new('MGHgrGraph2D', ASPECT=0.4)

   ograph->NewFont, SIZE=12

   ograph->NewAxis, 0, TITLE='Time of year', $
        CLASS='MGHgrGLaxis', LABEL_GAPS=1, $
        RANGE=dt0+[0,366], /EXACT, /EXTEND, MINOR=0, $
        TICKUNITS='month', TICKINTERVAL=1, TICKFORMAT='(C(CMoA))'

   ograph->NewAxis, DIRECTION=1, RANGE=mgh_minmax(z), TITLE='Data'

   ;; Plot data

   ograph->NewAtom, 'IDLgrPlot', x, y, COLOR=mgh_color('red')

   ograph->NewSymbol, 0, RESULT=osym, $
        CLASS='MGHgrSymbol', COLOR=mgh_color('blue')

   ograph->NewAtom, 'IDLgrPlot', x, z, LINESTYLE=6, SYMBOL=osym

   ;; Display & return

   mgh_new, 'MGH_Window', ograph

end



