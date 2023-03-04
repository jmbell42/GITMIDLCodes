; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/simpson.pro#1 $
;
; Copyright (c) 1991-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

function simpson_simprec1, funct, a, b, y, level, tol, count, S0, p, complex
ON_ERROR,2
common simp2, reclev
maxlev = 10
if level > maxlev THEN BEGIN
reclev=1
 count = 0
 m = (a+b)/2
 if p THEN BEGIN
   v = CALL_Function(funct,m)
   if complex eq 0 THEN $
      plots, [m, v], psym = 2  $
   else BEGIN
      plots, [m, float(v)], psym = 2
      plots, [m, imaginary(v)], psym=4
   ENDELSE
   wait,1
 ENDIF

 return, S0
ENDIF ELSE BEGIN
 
h = (b - a)/2.
m = (a + b)/2.
int =  [a + h/2., b - h/2.]
if complex eq 0 then y1 = fltarr(2) else y1=complexarr(2)
for i = 0,1 do y1(i) = CALL_FUNCTION(funct, int(i))
count = 2

if p ne 0 THEN BEGIN
  if complex eq 0 THEN $
    plots, int, y1, psym=2 $
  else BEGIN
    plots, int, float(y1), psym = 2
    plots, int, imaginary(y1), psym=4
  ENDELSE
  wait, 1
ENDIF
  
  
S1 =  h*(y(0) + 4*y1(0) + y(1))/6.
S2 =  h*(y(1) + 4 * y1(1) + y(2))/6.
S = S1 + S2

if abs(S - S0) gt tol * abs(S) THEN BEGIN
   S1 = simpson_simprec1(funct,a,m, [y(0), y1(0), y(1)], level + 1, tol/2, c1, S1, $
                 p, complex)
   S2 = simpson_simprec1( funct,m, b, [y(1), y1(1), y(2)], level + 1, tol/2, c2, S2, $
                  p, complex)
   count = count + c1 + c2
   return, S1 + S2
ENDIF ELSE return, S

ENDELSE
END



function simpson, funct, a, b, count,  tol=tol, plot_it = plot_it, $
                   complex = complex
;+
; NAME:
;	SIMPSON
;
; PURPOSE:
;	Numerically approximate the definite integral of a function 
;	with limits [A, B].
;
; CATEGORY:
;	Mathematical functions, general.
;
; CALLING_SEQUENCE:
;	Result = SIMPSON(Funct, A, B, Count, TOL = Tol)
;
; INPUTS: 
;	Funct:	A character string that contains the name of the function
;		to be integrated.  The user should write this function
;		to accept a single scalar argument.
;
;	A:	The lower limit of the integral.
;
;	B:	The upper limit of the integral.
;
; KEYWORD PARAMETERS:
;	TOL:	The error tolerance. The default is .001.    
;
;     COMPLEX:	Set this keyword if Funct returns complex values.
;
;     PLOT_IT:	Set this keyword to plot the points where the integrand is 
;		evaluated.
;
; OUTPUT:
;	SIMPSON returns the approximation to the integral of Funct for the 
;	limits [A, B].
;
; OUTPUT PARAMETERS:
;	Count:	On return, this variable contains the number of function 
;		evaluations needed to approximate the integral.
;
; COMMON BLOCKS:
;	SIMP2
;
; SIDE EFFECTS:
;	None.
;
; RESTRICTIONS:
;	None.
;
; PROCEDURE:
;	This function uses the recursive adaptive Simpson's rule.
;
; MODIFICATION HISTORY:
;	1991, Ann Bateson.
;
;-


On_Error,2

common simp2, reclev

reclev = 0
if KEYWORD_SET(tol) eq 0 THEN tol = .001
if KEYWORD_SET(complex) eq 0 THEN complex = 0
if a eq b THEN return,0
if KEYWORD_SET(plot_it) eq 0 THEN p = 0 $
else BEGIN
  p = 1
  m = (b+a)/2
  x = [m, b, a + findgen(11) * (b-a)/10.]
  if complex eq 0 THEN v = fltarr(13) else v = complexarr(13)

  for i = 0,12 do v(i) = CALL_FUNCTION(funct,x(i))

  if complex eq 0 THEN BEGIN
     plot, x, v, /nodata  
     plots, x(0:2), v(0:2), psym=2
  ENDIF ELSE BEGIN
     v1 = imaginary(v)
     v  = float(v)
     plot, [x,x], [v, v1], /nodata
     plots,x(0:2), v(0:2), psym=2
     plots, x(0:2), v1(0:2), psym=4
  
  ENDELSE
  wait,1
ENDELSE

level = 1
m = (a + b)/2

if complex eq 0 THEN y = fltarr(3) else y = complexarr(3)
x = [ a, m, b]
for i = 0,2 do  y(i) = CALL_FUNCTION(funct, x(i))

int = simpson_simprec1(funct, a, b, y, level, tol, count, 1.e+30, p, complex)

if reclev ne 0 THEN $
  print, "Recursion limit has been exceeded. Beware singularity"
count = count + 3
return, int
END
