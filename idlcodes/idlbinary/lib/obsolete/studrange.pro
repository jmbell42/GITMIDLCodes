; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/studrange.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.


 function student1_range,Q,V,R,Ifault
;student_range returns the probability from
;0 to Q for a studentized range having V
; degrees of freedom and R samples

IFault = 0
if V lt 1.0 or R lt 2. then IFault = 1
if ( Q le 0 or IFault eq 1) THEN $
   return,0 
retval = 0.0

QW    = fltarr(30)
VW    = QW 

CV    = [.318309886, -.00268132716, .00347222222, .0833333333]
JMin  = 3
JMax  = 15
KMIN  = 7
KMAX =  15
pcutk = .000001
pcutj = .000001
vmax =  120.0
step  = .45
G     = step * R^(-.2)
cvmax = .39894228
GMid  = .5 * ALOG(R)
R1    = R-1
C     = Alog(R*G*cvmax)
if V gt VMAX THEN goto, next20
H     = Step * V ^(-.5)
V2    = .5 * V
CV1   = .193064705
CV2   = .293525326

if V EQ 1 THEN C = CV1 ELSE $
 if V eq 2 THEN C = CV2 ELSE  $
    C = sqrt(V2) * CV(0)  $
        / ( 1.0 + (( CV(1) / V2 + CV(2))/V2 +CV(3))/V2)
C    = ALOG(C * R * G * H)

next20:
  GStep  = G
QW(0)    = -1.0
QW(JMAX) = -1.0 
PK1      = 1.0
Pk2      = 1.0

for k = 1,kmax DO BEGIN
 GStep    = GStep - G
next21:
 Gstep = -  Gstep
 Gk       = GMid + Gstep
 Pk       = 0
 if (pk2 le Pcutk and K gt kmin) THEN goto, next26
 W0 = C - .5 * GK ^2
 PZ = gaussint(GK)
 X =  PZ - gaussint(GK-Q)

 if X GT 0 THEN pk = exp( W0 + R1 * ALog(x)) 
 if V GT VMax THEN goto, next26
 jump = -JMax
next22:
 jump  = jump + jmax

 for j = 1,jmax Do BEGIN
  JJ = J + jump
  if QW(JJ-1) GT 0 THEN goto,next23
  HJ = H * float(J)
  if ( J LT JMax) THEN QW(JJ) = -1.0
  EHJ = EXP(HJ)
  QW(JJ-1) = Q * EHJ
  VW(JJ-1) = V * (HJ + .5 - .5*EHJ^2)
  
next23:
  PJ = 0
  X = PZ - gaussint(GK-QW(JJ-1))
  If ( X GT 0.0) THEN PJ = EXP(W0 + VW(JJ-1) + R1 * ALOG(x))
  PK = PK + PJ
  if (PJ GT PCUTJ) THEN goto, next24
  if (JJ GT JMIN or K GT KMIN) THEN goto, next25
next24:
 ENDFOR
 
next25:
 H = -H
 if ( H LT 0.0) THEN goto, next22

next26:
  retval = retval + PK
 if (K GT KMIN and PK LE PCUTK and Pk1 LE PCutK) THEN $
  goto, done
 PK2 = PK1
 PK1 = PK
 If (Gstep GT 0.0 ) THEN goto,next21
ENDFOR

done: return, retval
END     


function QTRNGO, P, V, R, IFault
 
C1 = .8843
c2 = .2368
c3 = 1.214
c4 = 1.208
c5 = 1.4142
T = gauss(.5 - .5*P)

if ( V LT 120.0) THEN T = T + (T^3 + T)/V/4.0
Q = c1 - c2 * T
if ( V LT 120.0) THEN Q = Q - C3/V + C4 * T/V
QTRNGO = T * (Q * ALOG(R-1) + C5)
return,QTRNGO
END



 
function studrange, P ,V ,R
;+
; NAME:
;	STUDRANGE
;
; PURPOSE:
;	Approximate the quantile P for a studentized range distribution 
;	with V degrees of freedom and R samples. P must be between .9 and .90.
;
; CATEGORY:
;	Statistics.
;
; CALLING SEQUENCE:
;	Result = STUDENT_RANGE(P, V, R)
;
; INPUT:
;	P:	The probability. .9 <= P <= .99.
;
;	V:	Degrees of freedom. V >=1.
;
;	R:	The number of samples. R > 1.
;
; OUTPUT:
;	The cutoff point of the student_range for probability P, degrees 
;	of freedom V and sample size R.
;-

NFault = 0
PCut = .000001
JMax = 20 

if P  LT .90 or P GT .99 THEN BEGIN
  print,'student_range--- P must be between .9 and .99'
  return, -1
ENDIF

if V LT 1 or R LT 2 THEN BEGIN
 print,'student_range, must have V>0 and R >1'
 return, -1
ENDIF

Q1 = QTRNGO(P,V,R,NFault)
if Nfault NE 0 THEN goto,done
P1 = student1_range(Q1,V,R,NFault)

 if NFault NE 0 THEN goto,done
QTRNG = Q1   
if abs(P1 - P) LT PCut THEN goto,done
if P1 GT P THEN P2 = 1.75 * P -.75 * P1 else $
    P2 = P + .75 * (P - P1) * (1-p)/(1-P1)
if ( P2 LT .8) THEN P2 = .8
if ( P2 GT .995) THEN P2 = .995
Q2 =  QTRNGO(P2,V,R,NFault)

if Nfault NE 0 THEN goto,done

for j = 2,JMax do BEGIN
 P2 = student1_range(Q2,V,R,NFault)
 if(Nfault ne 0) THEN goto,done
 E1 = P1 - P
 E2 = P2 - P
 QTRNG = (E2 * Q1 - E1 * Q2)/(E2 - E1)
 if abs(E1) LT Abs(E2) THEN goto,next12
 Q1 = Q2
 P1 = P2
next12:
 if abs(P1 - P) LT PCut  THEN goto,done
 Q2 = Qtrng
ENDFOR
done:
return,QTRNG
END
