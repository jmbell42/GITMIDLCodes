FUNCTION Distance2Line, line, pointx, pointy, grid=grid, close_area=close_area
;+
; NAME:
;	Distance2Line
; PURPOSE:
;	Calculates the distance of a point to a line for points and lines in the x-y plane
; CATEGORY:
;	Tricks
; CALLING SEQUENCE:
;	d = Distance2Line(line, point, [,/close])
; INPUTS:
;	line			array[2,n]; type: any
;						array of points (x,y coordinates) defining line(s)
;						There should be at least 2 points (n>=2)
;	pointx			if only pointx is specified:
;						array[2,m1,m2,...]; type: any
;						points to be tested
;					if both pointx and pointy are specified:
;	pointx				array[m1]
;						x-coordinates of points to be tested
;	pointy				array[m2]
;						y-coordinates of points to be tested
;						if /grid is not set then m1 MUST be equal to m2
;						if /grid is set then each x-coordinate is combined with
;						each y-coordinate to cover an m1 x m2 grid of points
; OPTIONAL INPUT PARAMETERS:
;	/close_area		adds first point of 'line' array to the end of the array
;						(this effectively 'closes' the curve described by the 'line' array).
;	/grid			(only used if both pointx and pointy are used)
; OUTPUTS:
;	d				array[n',m1,m2,...]
;						n'=n-1 if /close_area not set
;						n'=n   if /close_area set
; OPTIONAL OUTPUT PARAMETERS:
; INCLUDE:
	@compile_opt.pro		; On error, return to caller
; CALLS:
;	SubArray, SuperArray, SyncDims
; RESTRICTIONS:
;	If the 'line' array represents a boundary of an area in the x-y plane with a simple
;	enough shape then this procedure can be used to find points inside the closed area.
;	If 'line' runs in the clockwise/counter-clockwise direction around the area then all
;	distances will be positive/negative for points inside the closed area.
;	'Simple enough shape' means that the curvature should be in the same sense everywhere.
; PROCEDURE:
; >	Each pair of points line[*,i] and line[*,i+1] (i=0,n-1) defines a line in the
;	x-y plane. If /close_area is set then an additional pair line[*,n], line[*,0]
;	is defined.
; >	For each point in the 'point' array the distance to each of the lines is
;	calculated. The distance is positive it the point is toward the right of the line when
;	looking from line[*,i] to line[*,i+1], and negative on the other side.
; >	If vectors r1 and r2 correspond to points line[*,i] and line[*,i+1], respectively, and
;	vector p corresponds to a point then the distance calculated as
;	(r2-p)x(r1-p).z/|r2-r1| (z is a unit vector in the z-direction)
; MODIFICATION HISTORY:
;	JAN-2000, Paul Hick (UCSD/CASS; pphick@ucsd.edu)
;-

close_area = keyword_set(close_area)
grid = keyword_set(grid)

r1 = line						; Don't change input arrays

IF n_params() EQ 2 THEN	$
	pp = pointx			$

ELSE IF NOT grid THEN BEGIN
	nx = n_elements(pointx) < n_elements(pointy)
	pp = [reform(pointx[0:nx-1],1,nx),reform(pointy[0:nx-1],1,nx)]
	IF nx EQ 1 THEN pp = reform(pp)

ENDIF ELSE BEGIN
	nx = n_elements(pointx)
	ny = n_elements(pointy)
	pp = replicate(pointx[0],2,nx,ny)
	pp[0,*,*] = SuperArray(pointx,/trail,ny)
	pp[1,*,*] = SuperArray(pointy,/lead ,nx)

ENDELSE

sz = size(pp)

nl = n_elements(r1)/2			; # lines
np = n_elements(pp)/2			; # points to be tested

r1 = reform(r1,2,nl,/overwrite)
IF np GT 1 THEN pp = reform(pp,2,np,/overwrite)

r2 = shift(r1,0,-1)

IF NOT close_area THEN BEGIN
	nl = nl-1
	r1 = r1[*,0:nl-1]			; array[2,nl] (array[2] if nl=1)
	r2 = r2[*,0:nl-1]
ENDIF

r21 = r2-r1
r21 = sqrt( total(r21*r21,1) )	; array[nl] (scalar if nl=1)

IF nl GT 1 THEN	$
	pp  = SuperArray(pp , nl, after=1)	; 2 x nl x np array

IF np GT 1 THEN BEGIN
	r1  = SuperArray(r1 , np, /trail)	; 2 x nl x np array
	r2  = SuperArray(r2 , np, /trail)	; 2 x nl x np array
	r21 = SuperArray(r21, np, /trail)	;     nl x np array
ENDIF

r1 = r1-pp
r2 = r2-pp

pp  = (SubArray(r2,elem=0)*SubArray(r1,elem=1)-SubArray(r2,elem=1)*SubArray(r1,elem=0))/r21

; Remove leading dimension of 2 from 'point'

IF np EQ 1 THEN				$
	sz = [0,sz[sz[0]+1],1]	$
ELSE						$
	sz = [sz[0]-1,sz[2:sz[0]],sz[sz[0]+1],sz[sz[0]+2]/2]

; Add leading dimension of nl elements

IF nl GT 1 THEN BEGIN
	IF np EQ 1 THEN					$
		sz = [1,nl,sz[sz[0]+1],nl]	$
	ELSE							$
		sz = [sz[0]+1,nl,sz[1:sz[0]],sz[sz[0]+1],nl*sz[sz[0]+2]]
ENDIF

SyncDims, pp, size=sz

RETURN, pp  &  END
