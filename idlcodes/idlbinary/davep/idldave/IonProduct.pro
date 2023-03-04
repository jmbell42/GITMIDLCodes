PRO ionproduct

alt = '11'
altitude = '120km'
 iTime = [2003, 10, 28, 0, 0, 0]
c_a_to_r,iTime,stime
iTime =  [2003, 11, 02, 0, 0, 0]
c_a_to_r,iTime,etime

time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn 

elements=8640
IpfN2=fltarr(elements)
IpsN2=fltarr(elements-1)
IpfO=fltarr(elements)
IpsO=fltarr(elements-1)
IpfO2=fltarr(elements)
IpsO2=fltarr(elements-1)
wave = fltarr(57)

close,1
openr,1,'IonProductionN2'+alt+'.dat'
readf,1,IpfN2
close,1

openr,1,'IonProductionN2'+alt+'.dats'
readf,1,IpsN2
close,1

close,1
openr,1,'IonProductionO'+alt+'.dat'
readf,1,IpfO
close,1

openr,1,'IonProductionO'+alt+'.dats'
readf,1,IpsO
close,1

close,1
openr,1,'IonProductionO2'+alt+'.dat'
readf,1,IpfO2
close,1

openr,1,'IonProductionO2'+alt+'.dats'
readf,1,IpsO2
close,1


nf=n_elements(IpfN2)
ns=n_elements(IpsN2)

fsteps = (etime-stime)/nf
ssteps = (etime-stime)/ns

Ipfaxis = fltarr(nf)
Ipsaxis = fltarr(ns)

for i = 0 ,nf - 1 do begin
    Ipfaxis(i) = etime-stime + fsteps * i
endfor
for i = 0, ns -1 do begin
    Ipsaxis(i) = etime-stime + ssteps * i
endfor


;openr,1,'/home/dpawlows/Gitm/run/wavedata'
;readf,1,wave
;close,1

print, 'Enter Maximum Values (O2, O, N)... (0 for automatic): '
read,maxo2, maxo, maxn
if maxn eq 0 then begin
    maxfn = max(IpfN2)
    maxsn = max(IpsN2)
    if (maxfn ge maxsn) then maxn = maxfn else maxn = maxsn
endif
if maxo eq 0 then begin
    maxfo = max(IpfO)
    maxso = max(IpsO)
    if (maxfo ge maxso) then maxo = maxfo else maxo = maxso
endif
if maxo2 eq 0 then begin
    maxfo2 = max(IpfO2)
    maxso2 = max(IpsO2)
    if (maxfo2 ge maxso2) then maxo2 = maxfo2 else maxo2 = maxso2
endif

ntitle='Pseudo N+ production('+altitude+')'
otitle='Pseudo O+ production('+altitude+')'
o2title='Pseudo O2+ production('+altitude+')'
position = [.1,.1,.9,.3]

setdevice,'ionproduction'+alt+'.ps','l',5
loadct, 39

plot, Ipfaxis, /nodata ,yrange=[0,maxn], background=255, color = 1, $
title=ntitle,ytitle='n(s)*I(inf)*e(-t)*sigma',pos=position, $
 xtickname =xtickname , xtickv = xtickv,xminor = xminor,$
xstyle = 1, thick = 3, charsize = 1.2,xtitle=xtitle


oplot,IpfN2, color=50
oplot, IpsN2, color=250
items=['F107','SEE']
legend,items,psym=[0,0],colors=[50,250],delimiter='=',pos=[.7,.97],/norm,textcolors=[1,1]

position(1) = position(1) + .35
position(3) = position(3) + .35
plot, Ipfaxis, /nodata ,/noerase, yrange=[0,maxo], background=255, $
color = 1, title=otitle,ytitle='n(s)*I(inf)*e(-t)*sigma',pos=position, $
 xtickname =xtickname, xtickv = xtickv,xminor = xminor,$
xstyle = 1, thick = 3, charsize = 1.2,xtitle=xtitle


oplot,IpfO, color=50
oplot, IpsO, color=250
items=['F107','SEE']


position(1) = position(1) + .35
position(3) = position(3) + .35

plot, Ipfaxis, /nodata ,/noerase, yrange=[0,maxo2], background=255, color = 1, title=o2title,ytitle='n(s)*I(inf)*e(-t)*sigma', pos=position ,$
 xtickname = xtickname,$
xstyle = 1, thick = 3, charsize = 1.2,xtitle=xtitle,xtickv=xtickv

oplot, IpfO2, color=50
oplot, IpsO2, color=250
items=['F107','SEE']



;Ipftot=total(Ipf)
;Ipstot=total(Ips)

;print, 'F107 production = ', Ipftot, '        SEE production = ' , Ipstot
closedevice

end

