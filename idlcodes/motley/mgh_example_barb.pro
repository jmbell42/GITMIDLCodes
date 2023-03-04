;+
; NAME:
;   MGH_EXAMPLE_BARB
;
; PURPOSE:
;   This procedure presents a series of example graphs using the
;   MGHgrBarb class
;
; CALLING SEQUENCE:
;   MGH_EXAMPLE_BARB, option
;
; POSITIONAL PARAMETERS:
;   option (input)
;     Specify a value between 0 and 3 to select the plot.
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
;   Mark Hadfield, 2000-08:
;     Written.
;-

pro mgh_example_barb, option

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(option) eq 0 then option = 0

   case option of

      0: begin

         ;; A velocity vector time series. This example illustrates
         ;; how the barb plot object chooses sensible default values
         ;; for data that are not supplied and how to scale the barb
         ;; plot in a situation where the velocity scaling is to be
         ;; taken from one of the axes (here the Y axis).

         ;; Generate the data

         n = 101

         t = mgh_range(0, 6, N_ELEMENTS=n)

         u = sin(!pi*t)
         v = cos(!pi*t)

         u[[n/3,2*n/3]] = !values.f_nan

         ;; Generate the base & axes

         ograph = obj_new('MGHgrGraph2D', ASPECT=0.4)

         ograph->SetProperty, NAME='Velocity vector time series example'

         ograph->NewFont, SIZE=10

         ograph->NewMask

         ograph->NewTitle

         ograph->NewAxis, 0, RANGE=mgh_minmax(t)+0.5*[-1,1], /EXACT, TITLE='Time'
         ograph->NewAxis, 1, RANGE=[-2,2]*max(abs(v), /NAN), /EXACT, TITLE='Velocity', RESULT=oyaxis

         ;; The x & y axes have different units (time and velocity,
         ;; respectively). We want the barbs to represent velocity in
         ;; both directions, so that (for example) a barb at 45
         ;; degrees represents a velocity with equal U & V
         ;; components. So we choose normalised scaling, with a SCALE
         ;; property that is equal in the X & Y directions and taken
         ;; from the Y axis.

         ;; Note that this relationship will be broken if the Y axis scaling
         ;; is changed. I'm thinking about ways to address this.

         oyaxis[0]->GetProperty, YCOORD_CONV=ycoord

         ograph->NewAtom, 'MGHgrBarb', RESULT=obarb, $
              DATAX=t, DATAU=u, DATAV=v, SCALE=ycoord[1], /NORM_SCALE, $
              BARB_COLORS=mgh_color(['red','blue','dark green'])

         mgh_new, 'MGH_Window', ograph

      end

      1: begin

         ;; A velocity field on a 2-D grid with a symbol marking the
         ;; base of each barb.

         ;; Generate the data

         n = 31

         x = mgh_range(0,1,N_ELEMENTS=n)
         y = mgh_range(0,1,N_ELEMENTS=n)

         datax = rebin(x,n,n)
         datay = rebin(reform(y,1,n),n,n)

         datau = sin(!pi*datay)
         datav = sin(2.*!pi*datax)*cos(2.*!pi*datay)

         ;; Generate the base & axes

         ograph = obj_new('MGHgrGraph2D')

         ograph->SetProperty, NAME='Two-D velocity field example'

         ograph->NewFont, SIZE=10

         ograph->NewMask

         ograph->NewTitle

         ograph->NewAxis, DIRECTION=0, RANGE=mgh_minmax(x), /EXACT, /EXTEND, TITLE='X'
         ograph->NewAxis, DIRECTION=1, RANGE=mgh_minmax(y), /EXACT, /EXTEND, TITLE='Y'

         ;; Create the symbol. Its size and scaling are taken from the
         ;; axes.

         ograph->NewSymbol, CLASS='MGHgrSymbol', 0, /FILL, $
              COLOR=mgh_color('blue'), NORM_SIZE=0.005

         ;; Velocity scale is not related to any axis scale.

         ograph->NewAtom, 'MGHgrBarb', SCALE=0.03, /NORM_SCALE, $
              COLOR=mgh_color('red'), DATAX=datax, DATAY=datay, $
              DATAU=datau, DATAV=datav, SYMBOL=ograph->GetSymbol()

         mgh_new, 'MGH_Window', ograph

      end

      2: begin

         ;; 3-D velocity vectors with common origin (hedgehog)

         ;; Generate the data.

         n = 1000

         u = randomn(seed, n)
         v = randomn(seed, n)
         w = 0.1*randomn(seed, n)

         ;; Generate the base & axes

         ograph = obj_new('MGHgrGraph3D')

         ograph->SetProperty, NAME='Velocity vectors in 3-D (hedgehog) example'

         ograph->NewFont, SIZE=10

         ograph->NewTitle

         ;; Here the axes provide a scale for the velocity data.

         ograph->NewAxis, 0, RANGE=[-3,3], /EXACT, /EXTEND, TITLE='U'
         ograph->NewAxis, 1, RANGE=[-3,3], /EXACT, /EXTEND, TITLE='V'
         ograph->NewAxis, 2, RANGE=[-1,1], /EXACT, /EXTEND, TITLE='W'

         ograph->NewAtom, 'MGHgrBarb', COLOR=mgh_color('red'), $
              NORM_SCALE=0, SCALE=1, DATAU=u, DATAV=v, DATAW=w

         mgh_new, 'MGH_Window', ograph, MOUSE_ACTION=['Rotate','Pick','Context']

      end

      3: mgh_new, 'mgh_bprofile_movie', /EXAMPLE

      else: message, /INFORM, "Sorry, there is no such option'

   endcase

end

