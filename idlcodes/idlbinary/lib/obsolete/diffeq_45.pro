; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/diffeq_45.pro#1 $
;
; Copyright (c) 1991-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
 
pro diffeq_45, funct, init, start, finish, times, yvalues, tol=tol,  $
               report = report, Params = params, Listname = listname,$
               Depvar = depvar
;+
; NAME:
;	DIFFEQ_45
;
; PURPOSE:
;	Solve system of first-order, ordinary differential equations:
;                    yi' = fi(t, y1(t),...yn(y)), i = 1,..., n
;                    ai  = yi(start),             i = 1,..., n         
;	using the Runge-Kutta method of order 4 and 5. Step size is selected
;	automatically and hence is variable.
;         
; CATEGORY:
;       Mathematical Functions, General
;
; CALLING SEQUENCE:
;       DIFFEQ_45, Funct, Init, Start, Finish, Times, Yvalues, $
;                  TOL = Tol, PARAMS = Params, REPORT = Report, $
;                  LISTNAME = Listname, DEPVAR = Depvar
;
; INPUTS:
;	Funct:	A character string containing the name of the user-supplied
;              	function implementing f = [f1, ...., fn].  This function
;              	should be written in IDL and have two arguments -- the scalar-
;              	valued time argument t, and the vector argument
;              	[y1(t), ... , yn(t)].  Additional constant parameters may be
;              	supplied through the keyword PARAMS.
;
;	Init:	The vector [a1, ..., an] of initial values.
;
;	Start:	The initial value of t.
;
;	Finish:	The final value of t. 
;  
;  
; KEYWORD PARAMETERS:
;	TOL:	The error tolerance.  The default is 1.e-6.
;
;	PARAMS:	A keyword to be passed to the function f. Params can be used
;		to specify constant-paramter values if f is a parametric
;		family of functions. See the example for the procedure 
;		DIFFEQ_23.
;
;		If the IDL function to compute f does not accept the keyword
;		PARAMS, then PARAMS should not be set in the call to DIFFEQ_45.
;
;	REPORT: If set, this flag signals that, at each step, the time
;		value, step size, and dependent variable values should
;		be written to the screen or to a file specified by keyword
;		LISTNAME.    
;
;     LISTNAME:	The name of the file to receive any output. The default is
;		to write to the screen. 
;
;	DEPVAR:	A string array of the names of the dependent variables to
;		be used in the output. Depvar(i) = name of variable i.
;
; OUTPUT PARAMETERS:
;      	Times:	A vector of times at which f is computed.
;
;     Yvalues:	An array of y values. If ti = times(i),
;
;                 Yvalues(*, i) = f(ti,y1(ti),..., yn(ti))
;                               = [f1(ti,y1(ti),..., yn(ti)),  ..., 
;                                              fn(ti,y1(ti), ...,yn(ti))].
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	None.
;
; RESTRICTIONS:
;	None.
;
; EXAMPLE: 
;       See the example for DIFFEQ_23.
;
; PROCEDURE:
;           The constants of Fehlberg are used to obtain the Runge-Kutta
;           formula. See "Klassiche Runge-Kutta Formeln vierter und
;           niedrigerer Ordnung mit Schrittweiten-Kontrolle und ihre
;           Anwendung auf Warmeleitungsprobleme", Computing 6, 1970,
;           pp. 61 - 71.
;
; MODIFICATION HISTORY:
;                CAB, Sept., 1991.
;-              

On_Error,2

; Check parameters
if n_params(0) lt 4 THEN $
   message, "Missing parameters"


if KEYWORD_SET(listname) THEN $
   openw, unit, /get, listname $
else unit = -1


if KEYWORD_SET(tol) eq 0 THEN tol = 1.e-6
if KEYWORD_SET(Params) eq 0 THEN  $
  Paramset = 0   $
else Paramset = 1



if KEYWORD_SET(report) eq 0 THEN report = 0 $
ELSE  BEGIN
   SN = size( depvar)
   n = n_elements(init)
   if (SN(1) eq 0) THEN BEGIN
      I = indgen(n)
      Names = ['Var' + StrTrim(I, 2)]
   ENDIF ELSE  $
      if SN(1) lt n THEN BEGIN
      I = Indgen(N)
      Names = [DepVar, 'Var' + StrTrim(I(SN(1) : N-1),2)]
      ENDIF else Names = depvar
  
   printf, unit, format = '(A13, 2x, A13, 2x, $)', "Times", "Stepsize"
   for i = 0, n-2 do printf,unit,format = '(A13,2x,$)',Names(i)
   printf,unit, format = '(A13)',Names(n-1)
  Printf,unit, " "
ENDELSE

; Constants of Fehlberg
a = [1/4., 3/8., 12/13., 1., 1/2.]

b = [ [ 1./4, 0, 0, 0, 0],  $
      [ 3./32., 9/32., 0, 0, 0], $
      [1932./2197, -7200/2197., 7296/2197., 0, 0], $
      [439/216., -8., 3680/513., -845./4104., 0], $
      [-8/27., 2., -3544/2565., 1859./4104, $
                    -11/40.]]

 slope_weight =   [16./135., 0, 6656./12825., 28561/56430., -9./50., 2./55.]
 err_weight = [-1./360., 0, 128./4275., 2197./75240., -1./50., $
                 -2./55.]

; Initialize
h = (finish - start)
minh  = h/20000.
maxh  = h/5.
times = start

h = h/100.
t = start
v = init
yvalues = v

if report  ne 0 THEN BEGIN
   printf,unit, format ='(G13.6, 2x, G13.6, 2x, $)', t, h
   for i = 0, n-2 do printf,unit, format ='(G13.6, 2x,$)', v(i)
   printf,unit,format = '(G13.6)', v(n-1)
ENDIF


slopes = fltarr(N_ELEMENTS(v), 6)

errbound = tol * max([sqrt(total(v^2)), 1])

; compute yvalues for smaller (as needed) step sizes

while t lt finish and h ge minh DO BEGIN

 if t+h gt finish THEN h = finish - t
 
 if Paramset eq 0 THEN BEGIN
   slopes(0, 0) = CALL_FUNCTION( funct, t, v)
   for i = 1,5 do $
       slopes(0, i) = CALL_FUNCTION( funct, t + a(i-1) * h, v +   $
                                    h * (slopes(*,0:4) # b(*,i-1)))
 ENDIF ELSE BEGIN
   slopes(0, 0) = CALL_FUNCTION( funct, t, v, Params = Params)
   for i = 1,5 do $
       slopes(0, i) = CALL_FUNCTION( funct, t + a(i-1) * h, v +   $
                                    h * (slopes(*, 0:4 ) # $
                                    b(*,i-1)), Params =Params)
 ENDELSE
 
 err = ( h * (slopes # err_weight))^2

 err = sqrt(total(err))
 err_bound = tol * max([sqrt(total(v^2)), 1])

 if err le err_bound THEN BEGIN
    t = t + h
    v = v + h*(slopes # slope_weight)
    times   = [times,t]
    yvalues = [[yvalues], [v]]
    if report  ne 0 THEN BEGIN
      printf,unit, format ='(G13.6, 2x, G13.6, 2x, $)', t, h
      for i = 0, n-2 do printf,unit, format ='(G13.6, 2x,$)', v(i)
      printf,unit,format = '(G13.6)', v(n-1)
   ENDIF
 ENDIF

 if KEYWORD_SET(do_print) ne 0 THEN $
    print, t, h, v

 if err ne 0 THEN  $
    h = min([maxh, .8*h*(err_bound / err)^(1/5.0)])

 endwhile

 if ( t lt finish) THEN $
     printf,unit, " Beware of singularity"
 if unit ne -1 THEN Free_lun,unit
return
end
   