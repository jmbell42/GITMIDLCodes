; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/betai.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.

function betac, a,b,x

 lc = a + b
 ln = a - 1.0
 lq = a + 1.0
 max = 100
 ja = 1.0 & jn = 1.0 
 
 ka = 1.0 - lc*x/lq 
 kn = 1.0
 for i = 1,max DO BEGIN
    ep = float(i)
    tm = ep + ep
    d = ep * (b-ep) * x/((ln + tm) * (a + tm))
    jq = ja + d*jn
    kq = ka + d * kn
    d  = -(a + ep) * (lc + ep)*x/((lq + tm) * (a + tm))
    jq1 = jq + d * ja
    kq1 = kq + d*ka
    prev = ja
    jn = jq /kq1
    kn = kq / kq1
    ja = jq1 /kq1
    ka = 1.0

    if ( ABS ( ja - prev) LT 3.0e-7 * ABS(ja)) then  return ,ja

 ENDFOR

 
end

 function betai, x,a,b

if (x GT 1 OR x LT 0) THEN BEGIN
  print, ' betat - x parameter out of bounds'
  return, -1
  ENDIF

;gab =gamma(a) * gamma(b) 
;  gamma(a+b)/gab  * exp( a*alog(x) + b*alog(1.0-x))         $

if (x NE 0 and x NE 1 ) THEN temp =    $
    exp(lngamma(a+b)-lngamma(a) -lngamma(b) + a*alog(x) + b*alog(1.0-x)) $
else  temp = 0.0

if (x LT (a+1.0)/(a+b+2.0)) THEN return, temp * betac (a,b,x)/a     $
else return, 1.0 -temp * betac(b,a,1.0 -x)/b
END

