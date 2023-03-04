close,1
openr,1,'cond.dat'
t = ' '
readf,1,t
nalts = float(t)+ 4

alt = fltarr(nalts)
cond = fltarr(nalts-4)
temp = fltarr(nalts)
kappa = fltarr(nalts-2)
kappa2 = fltarr(nalts-2)
readf,1,alt
readf,1,cond
readf,1,temp
readf,1,kappa
close,1

ppp = 4
space = 0.08
pos_space, ppp, space, sizes

get_position, ppp, space, sizes, 0, pos, /rect
condcalc = kappa*deriv(alt(1:nalts-2),deriv(alt(1:nalts-2),temp(1:nalts-2))) + $
           deriv(alt(1:nalts-2),kappa)*deriv(alt(1:nalts-2),temp(1:nalts-2))
setdevice,'plot.ps','p',5,.95
plot,condcalc,alt(2:nalts-3)/1000.,pos=pos,/noerase,xtitle='Conduction (dashed GITM, solid IDL)'
oplot,cond,alt(1:nalts-2)/1000.,linestyle=2

get_position, ppp, space, sizes, 1, pos, /rect
plot,kappa(1:nalts-4),alt(2:nalts-3)/1000.,linestyle = 2,$
     pos=pos,/noerase,xtitle='Kappa'
;oplot,kappa2(1:nalts-4),alt(2:nalts-3)/1000.,linestyle=0

closedevice



end
