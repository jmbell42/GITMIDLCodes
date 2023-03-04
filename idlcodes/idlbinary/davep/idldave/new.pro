;  $Id: //depot/idl/IDL_70/idldir/examples/doc/plot/plot09#1 $

;  Copyright (c) 2005-2007, ITT Visual Information Solutions. All
;       rights reserved.
; 
; This batch file creates window with four plots. It is used as an
; example inin Chapter 10, "Plotting", of _Using IDL_.

; Define 12 monthly precipitation values, average temperatures, names
; of months, and create a vector containing approximate day number of
; the middle of each month.

PRECIP=[0.5,0.7,1.2,1.8,2.5,1.6,1.9,1.5,1.2,1.0,0.8,0.6]

TEMP=[30, 34, 38, 47, 57, 67, 73, 71, 63, 52, 39, 33]

MONTH=['Ja', 'Fe', 'Ma', 'Ap', 'Ma', 'Ju', 'Ju', 'Au', 'Se', 'Oc', 'No', 'De']

DAY=FINDGEN(12) * 30 + 15

; Set up for 4 plots in the window, increasing bottom outer margin.

!P.MULTI=[0,2,2]
!Y.OMARGIN=[1,0]

; Plot #1: Upper left.
; Plot, setting tick-mark length to full and setting number, position, 
; and labels of ticks.

PLOT, DAY, PRECIP, XTICKS = 11, XTICKNAME = MONTH, $
    TICKLEN = 1.0, XTICKV = DAY, TITLE = 'Average Monthly Precipitation', $
    XTITLE = 'Inches', SUBTITLE = 'Denver'

; Plot #2: Upper right.
; Same plot as above, but with tick-marklength set to a negative
; value for outside ticks.

PLOT, DAY, PRECIP, XTICKS = 11, XTICKNAME = MONTH, $
    TICKLEN = -0.02, XTICKV = DAY, TITLE = 'Average Monthly Precipitation', $
    XTITLE = 'Inches', SUBTITLE = 'Denver'

; Plot #3: Lower left.
; Set XSTYLE and YSTYLE keyword equal to 8 to inhibit drawing the box-style
; axes - only the left and bottom sides are drawn. We will draw the top and
; right axes explicitly, using the AXIS command.

PLOT, DAY, TEMP, /YNOZERO, SUBTITLE = 'Denver Average Temperature', $
    XTITLE = 'Day of Year', YTITLE = 'Degrees Fahrenheit', $
    XSTYLE=8, YSTYLE=8, XMARGIN=[8, 8], YMARGIN=[4, 4]

AXIS, XAXIS=1, XTICKS=11, XTICKV=DAY, XTICKN=MONTH, XTITLE='Month', charsize=0.8

AXIS, YAXIS=1, YRANGE = (!Y.CRANGE-32)*5./9., YSTYLE = 1, $
   YTITLE = 'Degrees Celsius'
	
; Plot #4: Lower right.
; This time, we suppress the automatic axis drawing entirely by setting
; XSYTLE and YSTYLE equal to 4. The central axes are drawn explicitly
; with two calls to the AXIS procedure.

R = FINDGEN(100)        ;Make a radius vector.
THETA = R/5             ;Make a vector.

PLOT, R, THETA, SUBTITLE='Polar Plot!3', XSTYLE=4, YSTYLE=4, /POLAR

AXIS, 0, 0, XAXIS=0
AXIS, 0, 0, YAXIS=0
	
; Reset number of plots and outer margin.

!P.MULTI = 0
!Y.OMARGIN=[0,0]
