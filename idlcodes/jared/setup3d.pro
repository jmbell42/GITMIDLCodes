PRO setup3d, d0, d1, n0, n1, rotate=rotate, oblique=oblique, xyplane=xyplane, yzplane=yzplane, xzplane=xzplane
;+
; NAME:
;	setup3d
; PURPOSE:
;	Sets up scaling (!x.s, !y.s, !z.s) and transformation matrix (!p.t)
; CATEGORY:
; CALLING SEQUENCE:
;	setup3d, d0, d1, n0, n1 [, /rotate, /oblique]
;	setup3d, d0, d1, n0, n1 [, rotate=[[a,b,c],[d,e,f]], oblique=[p,q] ]
; INPUTS:
;	d0		scalar or array[3]; default: -1.5*[1,1,1]
;	d1		scalar or array[3]; default:  1.5*[1,1,1]
;				begin and end of data coordinate range
;				scalars are interpreted as scalar*[1,1,1]
;	n0		scalar or array[3]; default:  0.0*[1,1,1]
;	n1		scalar or array[3]; default:  1.0*[1,1,1]
;				begin and end of normal coordinate range
;				scalars are interpreted as scalar*[1,1,1]
;
;			!x.s, !y.s and !z.s are set up to map data ranges [d0,d1] to normal ranges [n0,n1]
; OPTIONAL INPUT PARAMETERS:
;	rotate=rotate
;			array[3,n] or array[3*n]; type: float
;				The special form /rotate is identical to rotate=[ [ 0.,-20.,0.], [20., 0. ,0.] ]
;				Set of rotations to be set up in !p.t matrix
;				rotations are processed left to right; rotate[0,*], rotate[1,*] and rotate[2,*]
;				are rotations around x,y and z-axis respectively
;	oblique=oblique
;			array[2]; type: float
;				The special form /oblique is identical to oblique=[.4,-125]
;				Parameters for an oblique projection
;	/xyplane	Puts x-y plane in plane of screen
;	/yzplane	Pust y-z plane in plane of screen
;	/xzplane	Puts x-z plane in plane of screen
; OUTPUTS:
;	Sets !x.s, !y.s, !z.s and !p.t
; INCLUDE:
	@compile_opt.pro		; On error, return to caller
; CALLS:
;	t3d_oblique
; RESTRICTIONS:
; PROCEDURE:
;	!p.t is first reset. Then clockwise rotations around y and z-axis over 90 degrees are
;	executed to point the x-axis perpendicular to the screen, the y-axis pointing right and the
;	z-axis pointing up in the plane of the screen.
;	After that the rotations supplied as keywords are applied, followed by the oblique projection.
; MODIFICATION HISTORY:
;	AUG-1999, Paul Hick (UCSD/CASS; pphick@ucsd.edu)
;-
IF n_elements(d0	) EQ 0 THEN d0 = -1.5*[1,1,1] ELSE IF n_elements(d0) NE 3 THEN d0 = d0[0]*[1,1,1]
IF n_elements(d1	) EQ 0 THEN d1 =  1.5*[1,1,1] ELSE IF n_elements(d1) NE 3 THEN d1 = d1[0]*[1,1,1]
IF n_elements(n0	) EQ 0 THEN n0 =  0.0*[1,1,1] ELSE IF n_elements(n0) NE 3 THEN n0 = n0[0]*[1,1,1]
IF n_elements(n1	) EQ 0 THEN n1 =  1.0*[1,1,1] ELSE IF n_elements(n1) NE 3 THEN n1 = n1[0]*[1,1,1]

IF n_elements(rotate ) EQ 1 THEN rotate = [ [ 0.0,-20.0,0.0], [20.0,0.0,0.0] ]
IF n_elements(oblique) EQ 1 THEN oblique = [0.4, -125]

!x.s = [n0[0]*d1[0]-n1[0]*d0[0],n1[0]-n0[0]]/(d1[0]-d0[0])
!y.s = [n0[1]*d1[1]-n1[1]*d0[1],n1[1]-n0[1]]/(d1[1]-d0[1])
!z.s = [n0[2]*d1[2]-n1[2]*d0[2],n1[2]-n0[2]]/(d1[2]-d0[2])

initrot = [ 0.0,-90.0,-90.0]
IF keyword_set(xyplane) THEN initrot = [0.0,0.0,0.0]		; x-y plane in screen; z towards viewer
IF keyword_set(yzplane) THEN initrot = [ 0.0,-90.0,-90.0]	; y-z plane in screen; x towards viewer
IF keyword_set(xzplane) THEN initrot = [ -90.0,0.0,0.0]	; x-z plane in screen; y away from viewer

; Setup transformation matrix for transformation relative to the origin in data coordinates

T = [!x.s[0],!y.s[0],!z.s[0]]

t3d, /reset
t3d, translate=-T						; Translate to origin of normal coordinates (lower-left corner of screen)

t3d, rotate=initrot						; Rotate to put y-z coordinates in plane of screen
										; .. with y to the right, and z up; the x-axis points out of the screen

IF n_elements(rotate) NE 0 THEN BEGIN	; Set up orientation of coordinate system
	n = n_elements(rotate)
	rotate = reform(rotate,n)
	FOR i=0,n/3-1 DO t3d, rotate=rotate[i*3:i*3+2]
ENDIF

IF n_elements(oblique) NE 0 THEN t3d_oblique, oblique=oblique

t3d, translate=T						; Translate back to origin of data coordinates

RETURN  &  END
