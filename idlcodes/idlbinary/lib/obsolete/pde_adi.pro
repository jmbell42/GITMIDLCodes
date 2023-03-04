; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/pde_adi.pro#1 $
;
;  Copyright (c) 1992-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.

function BOUNDARY_LT,y,t
; left boundary condition as a function of y and t
  bound=75.0
  return,bound
end

function BOUNDARY_RT,y,t
; right boundary condition as a function of y and t
  bound=50.0
  return,bound
end

function BOUNDARY_BOT,x,t
; bottom boundary condition as a function of x and t
  bound=0.0
  return,bound
end

function BOUNDARY_TOP,x,t
; top bondary condition as a function of x and t
  bound=100.0
  return,bound
end

function NONHOMOGENEOUS,x,y,t
; the right hand side of the differential equation
; as a function of x, y, and t
  nonhomo=0.0
  return,nonhomo
end

function INITIAL_COND,x,y
; the initial condition as a function of x and y
  initial=0.0
  return,initial
end


PRO PDE_ADI 
;+        
; NAME:
;	PDE_ADI
;
; PURPOSE:
;	This procedure computes the numerical solution of the 
;	initial-boundary value problem (parabolic partial  
;       differential equation) using the ADI method
;       (ALTERNATING DIRECTION IMPLICIT) in two space dimensions (x,y).
;      
; CATEGORY:
;	Numerical Analysis
;	
; CALLING SEQUENCE:
;	.run PDE_ADI 	(compiles the procedure)
;	PDE_ADI		(runs the procedure)
;
; INPUTS:
;	There are no input parameters that can be specified from
;	the IDL command line. However, the following Internal
;	Parameters should be specified by editing the PDE_ADI.PRO
;	file before compiling the procedure:
;
;       DIFFUSIVITY ......................... DIFF
;       ENDPOINTS ........................... XMAX, YMAX
;       TIME STEP ........................... DELTA_TIME
;       NUMBER OF INTERIOR X-NODES .......... X_NODE_MAX
;       NUMBER OF INTERIOR Y-NODES .......... Y_NODE_MAX
;       NUMBER OF TIME STEPS ................ TIME_MAX
;
; OUTPUTS:
;	The numerical solution computed at each time step is stored
;	in the file PDE_ADI.DAT.
; 
; RESTRICTIONS:
;	All Internal Parameters must be positive scalars.
;
; PROCEDURE:
;	This procedure uses the ADI method to compute the  
;       temperature U at each node (M,N) in the rectangular  
;       grid defined by DELTA_X and DELTA_Y for each time 
;       step from time=0 to time=TIME_MAX with steps of 
;       DELTA_TIME.
;
; EXAMPLE:
;	This procedure solves the partial differential equation:
;       Ut-diff*(Uxx+Uyy)=NONHOMOGENEOUS(X,Y,T)
;       Subject to the initial and boundary conditions:
;       U(x,y,0)=INITIAL_COND(X,Y)
;       U(0,y,t)=BOUNDARY_LT(Y,T)   U(1,y,t)=BOUNDARY_RT(Y,T)
;       U(x,0,t)=BOUNDARY_BOT(X,T)  U(x,1,t)=BOUNDARY_TOP(X,T)
;       where:
;             Ut ....   first partial derivative of U with respect to t
;             Uxx ...  second partial derivative of U with respect to x
;	      Uyy ...  second partial derivative of U with respect to y
;
;       The computational grid has X_NODE_MAX x Y_NODE_MAX interior mesh points
;       and X_NODE_MAX+2 x Y_NODE_MAX+2 total mesh points. 
;
; MODIFICATION HISTORY:
;	GGS; AUGUST 1992
;	Adapted from:
;		Graduate course work at the University of Colorado, Boulder
;	Published References:
;		Advanced Engineering Mathematics (sixth edition)
;		Erwin Kreyzig
;		Wiley & Sons Inc.
;
;-

ON_ERROR,2

; start timer
TIME_0=SYSTIME(1)

; define internal parameters
DIFF=1.0
DELTA_TIME=.01
XMAX=1.0
YMAX=1.0
X_NODE_MAX=8
Y_NODE_MAX=8
TIME_MAX=50

; allocate arrays
X=FLTARR(X_NODE_MAX+2)
Y=FLTARR(Y_NODE_MAX+2)
U=FLTARR(X_NODE_MAX+2,Y_NODE_MAX+2)
V=FLTARR(X_NODE_MAX+2,Y_NODE_MAX+2)
DIMENSION=max([X_NODE_MAX,Y_NODE_MAX])+1
A=FLTARR(DIMENSION)
B=FLTARR(DIMENSION)
C=FLTARR(DIMENSION)
D=FLTARR(DIMENSION)

; define computational grid
DELTA_X=XMAX/FLOAT(X_NODE_MAX+1)
DELTA_Y=YMAX/FLOAT(Y_NODE_MAX+1)

; define computational ratios
X_RATIO=DIFF*DELTA_TIME/(DELTA_X^2.0)
Y_RATIO=DIFF*DELTA_TIME/(DELTA_Y^2.0)
 
T=0.0

; realize computational grid
FOR M=1,X_NODE_MAX DO $
  X(M)=X(M-1)+DELTA_X
FOR N=1,Y_NODE_MAX DO $
  Y(N)=Y(N-1)+DELTA_Y
X(X_NODE_MAX+1)=XMAX
Y(Y_NODE_MAX+1)=YMAX

; initialize corners of computational grid 
U(0,0)=0.5*(BOUNDARY_LT(Y(0),T)+BOUNDARY_BOT(X(0),T))
U(0,Y_NODE_MAX+1)=0.5*(BOUNDARY_LT(Y(0),T)+BOUNDARY_TOP(X(0),T))
U(X_NODE_MAX+1,Y_NODE_MAX+1)=0.5*(BOUNDARY_TOP(X(0),T)+BOUNDARY_RT(Y(0),T))
U(X_NODE_MAX+1,0)=0.5*(BOUNDARY_RT(Y(0),T)+BOUNDARY_BOT(X(0),T))

; compute initial values of U(M,N) on the interior of grid
; this is the temperature of the interior grid at TIME= zero
FOR N=1,Y_NODE_MAX DO BEGIN
  FOR M=1,X_NODE_MAX DO $
    U(M,N)=INITIAL_COND(X(M),Y(N))
ENDFOR

;open data file: PDE_ADI.DAT
OPENW,22,'PDE_ADI.DAT'

; output solution at T=0.0
PRINTF,22,FORMAT='(/"  Time = ",F5.2,/)',T
PRINTF,22,'  NUMERICAL SOLUTION'
FOR N=Y_NODE_MAX+1,0,-1 DO $
  PRINTF,22,FORMAT='(20(F7.2,1x))',U(0:X_NODE_MAX+1,N)

; start time steps
FOR J=1,TIME_MAX DO BEGIN

; start y-direction computation
  FOR N=1,Y_NODE_MAX DO BEGIN
    FOR M=1,X_NODE_MAX DO BEGIN
      A(M)=-X_RATIO/2.0
      B(M)=1.0+X_RATIO
      C(M)=-X_RATIO/2.0
      D(M)=0.5*Y_RATIO*U(M,N-1)+(1.0-Y_RATIO)*U(M,N)+0.5*Y_RATIO*U(M,N+1)
      D(M)=D(M)+0.5*DELTA_TIME*(NONHOMOGENEOUS(X(M),Y(N),T) $
               +NONHOMOGENEOUS(X(M),Y(N),T+DELTA_TIME))
    ENDFOR  
    U(0,N)=BOUNDARY_LT(Y(N),T+DELTA_TIME)
    V(0,N)=0.25*Y_RATIO*(BOUNDARY_LT(Y(N-1),T)+BOUNDARY_LT(Y(N+1),T)) $
               +(0.5-0.25*Y_RATIO)*BOUNDARY_LT(Y(N),T) $
               -0.25*Y_RATIO*(BOUNDARY_LT(Y(N-1),T+DELTA_TIME) $
               +BOUNDARY_LT(Y(N+1),T+DELTA_TIME)) $
               +(0.5+0.25*Y_RATIO)*BOUNDARY_LT(Y(N),T+DELTA_TIME)
    D(1)=D(1)+0.5*X_RATIO*V(0,N)
    U(X_NODE_MAX+1,N)=BOUNDARY_RT(Y(N),T+DELTA_TIME)
    V(X_NODE_MAX+1,N)=0.25*Y_RATIO*(BOUNDARY_RT(Y(N-1),T)+BOUNDARY_RT(Y(N+1),T)) $
                          +(0.5-0.25*Y_RATIO)*BOUNDARY_RT(Y(N),T) $
                          -0.25*Y_RATIO*(BOUNDARY_RT(Y(N-1),T+DELTA_TIME) $
                          +BOUNDARY_RT(Y(N+1),T+DELTA_TIME)) $
                          +(0.5+0.25*Y_RATIO)*BOUNDARY_RT(Y(N),T+DELTA_TIME)
    D(X_NODE_MAX)=D(X_NODE_MAX)+0.5*X_RATIO*V(X_NODE_MAX+1,N)
    TRIDAG,A(1:X_NODE_MAX),B(1:X_NODE_MAX),C(1:X_NODE_MAX),D(1:X_NODE_MAX),WEIGHT
    FOR M=1,X_NODE_MAX DO $
      V(M,N)=WEIGHT(M-1)
  ENDFOR

; start x-direction computation
  FOR M=1,X_NODE_MAX DO BEGIN
    FOR N=1,Y_NODE_MAX DO BEGIN
      A(N)=-Y_RATIO/2.0
      B(N)=1.0+Y_RATIO
      C(N)=-Y_RATIO/2.0
      D(N)=0.5*X_RATIO*V(M-1,N)+(1.0-X_RATIO)*V(M,N)+0.5*X_RATIO*V(M+1,N)
      D(N)=D(N)+0.5*DELTA_TIME*(NONHOMOGENEOUS(X(M),Y(N),T) $
               +NONHOMOGENEOUS(X(M),Y(N),T+DELTA_TIME))
    ENDFOR
    U(M,0)=BOUNDARY_BOT(X(M),T+DELTA_TIME)
    D(1)=D(1)+0.5*Y_RATIO*U(M,0)
    U(M,Y_NODE_MAX+1)=BOUNDARY_TOP(X(M),T+DELTA_TIME)
    D(Y_NODE_MAX)=D(Y_NODE_MAX)+0.5*Y_RATIO*U(M,Y_NODE_MAX+1)
    TRIDAG,A(1:Y_NODE_MAX),B(1:Y_NODE_MAX),C(1:Y_NODE_MAX),D(1:Y_NODE_MAX),WEIGHT
    FOR N=1,Y_NODE_MAX DO $
      U(M,N)=WEIGHT(N-1)
  ENDFOR

; let user know how the algorithm is progressing
   PRINT,' ... time step complete     REAL TIME = ',T, ' seconds'

; advance to next time step
    T=T+DELTA_TIME

; output solution at time step T
    PRINTF,22,FORMAT='(/"  Time = ",F5.2,/)',T
    PRINTF,22,'  NUMERICAL SOLUTION'
    FOR N=Y_NODE_MAX+1,0,-1 DO $
      PRINTF,22,FORMAT='(20(F7.2,1x))',U(0:X_NODE_MAX+1,N)
ENDFOR    

; close data file: PDE_ADI.DAT
CLOSE,22

PRINT,'             program execution in ...',SYSTIME(1)-TIME_0,' seconds'

END
