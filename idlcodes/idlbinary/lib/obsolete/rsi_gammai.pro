; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/rsi_gammai.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.

; modification: 09/21/92 - changed the number of iterations in
;			   rsi_gammai_g_series (jiy)


pro rsi_gammai_g_series,result,x,a
;evaluates incomplete gamma function with series representation.
glog =lngamma(a)
nsample=long(x/50.) > 1000l
resarray = 1.0/(findgen(nsample) + a)
resarray(1:*) = x*resarray(1:*)
sum =1.0/a
for i =1 ,nsample-1 DO BEGIN
resarray(0) = resarray(0) * resarray(i)
sum = sum + resarray(0)
if (abs(resarray(0)) LT abs(sum)*3.0e-7) THEN BEGIN
  result = sum * exp(-x + a * alog(x) - glog)
  return
ENDIF
ENDFOR

result = -1
return
END


pro rsi_gammai_g_fract, result,x,a
 glog = lngamma(a)
 gd =0.0 & fc =1.0 & b1= 1.0
 bo = 0.0 & ao =1.0

 a1 = x
 for n=1,100  DO BEGIN
    an = float(n)
    ana = an -a
    ao = (a1 +ao * ana) * fc
    bo = (b1 + bo *ana) * fc
    anf = an * fc
    a1 = x * ao + anf * a1
    b1 = x * bo + anf * b1
   if a1 THEN BEGIN
     fc = 1.0/a1
     g = b1 * fc
     if abs((g-gd)/g) LT 3.0e-7 THEN BEGIN
       result =  exp(-x + a* alog(x) - glog) * g
       return
     ENDIF
    gd = g
   ENDIF
 ENDFOR
 result =-1
RETURN
END



function rsi_gammai,a,x

if  x LT a+1.0 THEN BEGIN
   rsi_gammai_g_series,result,x,a
   return, result
ENDIF ELSE BEGIN
     rsi_gammai_g_fract,result,x,a
     if result ne -1 then return, 1.0 - result  $
    else return, -1
ENDELSE

END
 

  
     



