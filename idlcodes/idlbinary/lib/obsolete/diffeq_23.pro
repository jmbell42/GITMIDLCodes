; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/diffeq_23.pro#1 $
;
; Copyright (c) 1991-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

pro diffeq_23, funct, init, start, finish, times, yvalues, tol=tol, $
               report = report, Params= params, Listname = listname, $
               Depvar = depvar
;+
; NAME:
;       DIFFEQ_23
;
; PURPOSE:
;	Solve a system of first-order, ordinary differential equations:
;                    yi' = fi(t, y1(t), ... yn(y)), i = 1,..., n
;                    ai  = yi(start),               i = 1,..., n         
;	using the Runge-Kutta method of order 2 and 3. Step size is selected
;	automatically and hence is variable. 
;         
; CATEGORY:
;	Mathematical Functions, General
;
; CALLING SEQUENCE:
;       DIFFEQ_23, Funct, Init, Start, Finish, Times, Yvalues, $
;                  TOL = Tol, PARAMS = Params, REPORT = Report, $
;                  LISTNAME = Listname, DEPVAR = Depvar
;
; INPUTS:
;	Funct:  A character string containing the name of the user-supplied
;              	function implementing f = [f1, ...., fn]. This function
;              	should be written in IDL and have two arguments -- the scalar-
;		valued time argument t, and the vector argument 
;		[y1(t), ... ,yn(t)].  Additional constant parameters may be
;		supplied through the keyword PARAMS.
;
;      Init:	The vector [a1, ..., an] of initial values.
;
;      Start:	The initial value of t.
;
;      Finish:	The final value of t. 
;  
; KEYWORD PARAMETERS:
;      TOL:	The error tolerance. The default is .001.
;
;      PARAMS:	A keyword to be passed to the function f.  PARAMS can be used 
;		to specify constant-parameter values if f is a parametric 
;		family of functions.  See the example below.
;
;		If the IDL function to compute f does accept the keyword 
;		PARAMS, then PARAMS should not be set in the call to DIFFEQ_23.
;
;      REPORT:	If set, this flag signals that, at each step, the time
;		value, step size, and dependent variable values should
;		be written to the screen or to a file specified by keyword
;		LISTNAME.    
;
;    LISTNAME:	The name of the file to receive any output. The default is
;               to write to the screen. 
;
;      DEPVAR: 	A string array of the names of the dependent variables to
;               be used in the output. Depvar(i) = name of variable i.
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
;       Solve the set of equations:
;
;          	y1' = -.1 * y1, 
;          	y2' = .1*y1 - .05*y2,
;          	y3' = .05*y2
; 
;          	y1(0) = 1000, y2(0) = 0, y3(0) = 0
;
;       on the interval [0, 5].
;
;       First, we define the function RADIO as
;
;		FUNCTION RADIO, t, y, PARAMS = params
;		k = params(0)
;		kp = params(1)
;		RETURN, [-k*y(0), k*y(0) - kp*y(1), kp* y(1)]
;		END
;
;      	Next, call DIFFEQ_23:
;
;            	DIFFEQ_23, "radio", [1000, 0, 0], 0, 5., times, yvalues, $
;                          PARAMS = [.1, .05], /REPORT
;
;      	The result can be plotted by entering:
;
;          	PLOT, times, yvalues(0,*)
;          	FOR i = 1,2 DO OPLOT, times, yvalues(i,*)
;
; MODIFICATION HISTORY:
;	CAB, Sept., 1991.
;-

On_Error,2

; Check parameters
if n_params(0) lt 4 THEN $
   message, "Missing parameters"

if KEYWORD_SET(listname) THEN $
   openw, unit, /get, listname $
else unit = -1

if KEYWORD_SET(tol) eq 0 THEN tol =.001
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

; Initialize
h = (finish - start)   ;h = stepsize
minh  = h/20000        
maxh  = h/5
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


errbound = tol * max([sqrt(total(v^2)), 1])

; compute yvalues for variable step sizes


   while t lt finish and h ge minh DO BEGIN

     if t+h gt finish THEN h = finish - t
     
     if Paramset eq 0 THEN BEGIN
       k1 = CALL_FUNCTION(funct,t, v)
       k2 = CALL_FUNCTION(funct, t+h, v + h * k1)
       k3 = CALL_FUNCTION(funct, t + h/2, v + h*(k1 + k2)/4)
    ENDIF ELSE BEGIN
       k1 = CALL_FUNCTION(funct,t, v, Params = Params)
       k2 = CALL_FUNCTION(funct, t+h, v + h * k1, Params = Params)
       k3 = CALL_FUNCTION(funct, t + h/2, v + h*(k1 + k2)/4, Params = Params)
    ENDELSE

    err = (h*(k1 - 2*k3 + k2)/3)^2
    err = sqrt(total(err))
    err_bound = tol * max([sqrt(total(v^2)), 1])

 if  err le err_bound THEN BEGIN
    t = t + h
    v = v + h*(k1 + 4*k3 + k2)/6
    times   = [times,t]
    yvalues = [[yvalues], [v]]
    if report  ne 0 THEN BEGIN
       printf,unit, format ='(G13.6, 2x, G13.6, 2x, $)', t, h
      for i = 0, n-2 do printf,unit, format ='(G13.6, 2x,$)', v(i)
      printf,unit,format = '(G13.6)', v(n-1)
   ENDIF
ENDIF

if err ne 0 THEN  $
   h = min([maxh, .9*h*(err_bound / err)^(1/3.0)])

 endwhile


 if ( t lt finish) THEN $
     print, " Beware of singularity"

if unit ne -1 THEN Free_lun, unit

return
end
   