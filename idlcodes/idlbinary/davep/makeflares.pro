if n_elements(flarefile) eq 0 then flarefile = 'flaredata.dat'
flarefile = ask('name of flare file: ',flarefile)

nwaves = 59
base = fltarr(nwaves)
flare = fltarr(nwaves)
close,1
openr,1,flarefile

pref = 0
maxf = 0
t = ' '


while not pref do begin
readf,1,t
if strpos(t,'Pre-Flare') ge 0 then pref = 1
endwhile
readf,1,base

while not maxf do begin
readf,1,t
if strpos(t,'Maximum Flare') ge 0 then maxf = 1
endwhile
readf,1,flare

close,1

if n_elements(energytotal) eq 0 then energytotal = 0
energytotal = float($
  ask('how much energy this flare should have (run calc_flarenergy for an example): ',$
      tostrf(energytotal)))

print, 'Peak value of flare has been read: ',tostrf(flare(56))
print, 'compared to base value of: ',tostrf(base(56))

;energytotal=energytotal*.5
base = base * .5
;flare = flare *.5
;ftypes = ['Constant Energy and Height','Constant Energy, Variable Height']
;display, ftypes
;if n_elements(itype) eq 0 then itype = 0
;itype = fix(ask('which flare type: ',tostr(itype)))
;
;if itype eq 0 then begin
    if n_elements(flarepercent) eq 0 then flarepercent = 1.0
    flarepercent = float(ask('factor to alter the peak height by: ',tostrf(flarepercent)))

    ;if n_elements(basefac) eq 0 then basefac = 1.0
    ;basefac = float(ask('factor to alter the base height by: ',tostrf(basefac)))

    if flarepercent ge 1.0 then flare = flare+((flare-base)*abs((1.0-flarepercent))) else $
      flare = flare-((flare-base)*(1.0-flarepercent))
    
    ;base = base * basefac
    

    baseold = base
   ; base = base/basefac
    
    if n_elements(risetime) eq 0 then risetime = 10
    risetime = fix(ask('minutes from base to peak: ',tostr(risetime)))
    timerise = risetime

    
    x1 = 0
    x2 = timerise
    y1 = base
    y2 = flare
    sloperise = (y2-y1)/(x2-x1)
    krise = base
    
    nminsmax = 2000
    time = findgen(nminsmax)
    flux = fltarr(59,nminsmax)
    
    xe1 = timerise
    ye1 = flare
    ye2 = base
    
    baseelinear = total((x2-x1)*baseold*60.0)
    energylinear = (total((.5*sloperise*(x2^2-x1^2)+(x2-x1)*krise)*60.0))-baseelinear
 ; Convert from min * W/m2 to J/m2

    energycurve = energytotal-energylinear

    done = 0
    xe2 = 2 * xe1
    xold = xe1
    smaller = 1
    iint = 0
    while not done do begin
        me = alog(ye2/ye1)/(xe1-xe2)
        k = ye1*exp(me*xe1)
        baseetest = total((xe2-xe1)*60.0*baseold)

        energytest = total(k/me*(exp(-me*xe1)-exp(-me*xe2))*60.0)-baseetest
        
        xold1 = xe2
        if (energytest - energycurve)/energycurve lt 0.0 and smaller then xe2 = xe2 * 2
        if (energytest - energycurve)/energycurve lt 0.0 and not smaller then $
          xe2 = xe2 + abs((xe2-.5*(xold+xe2)))
        if (energytest - energycurve)/energycurve ge 0.0 then begin 
            smaller = 0
            xe2 = xe2 - abs((xe2-.5*(xold+xe2)))
        endif
        xold = xold1
        
        
        if abs((energytest - energycurve)/energycurve) lt 0.001 then done = 1
;    iint = iint + 1
;    print, iint,((energytest - energycurve)/energycurve) 
        
    endwhile

    xe2 = fix(xold)+1
    me = alog(ye2/ye1)/(xe1-xe2)
    k = ye1*exp(me*xe1)
    print, (k(56)/me(56)*(exp(-me(56)*xe1)-exp(-me(56)*xe2))*60.0)
    
    
    for imin = 0, xe2 do begin
        if imin le risetime then begin
            flux(*,imin) = sloperise*imin + krise
        endif else begin
            flux(*,imin) = k*exp(-me*imin)
        endelse
    endfor
    
    flux = flux(*,0:xe2)
    
    ntimes = xe2+1
    itime = [2005,09,20,0,0,0]
    c_a_to_r,itime,time0
    openw,1,'flux.dat'
    printf,1,'#START'
    printf,1,fix(itime(0)),fix(itime(1)),fix(itime(2)),fix(itime(3)),fix(itime(4)),$
      fix(itime(5)),fix(0),flux(*,0)

    rt = time0+60.0
    
    itime = [2005,09,21,0,0,0]
    c_a_to_r,itime,time0  

    while rt lt time0 do begin
        c_r_to_a,itime,rt
        printf,1,fix(itime(0)),fix(itime(1)),fix(itime(2)),fix(itime(3)),fix(itime(4)),$
          fix(itime(5)),fix(0),flux(*,0)
        
        rt = rt + 60.0
    endwhile

    
    printf,1,fix(itime(0)),fix(itime(1)),fix(itime(2)),fix(itime(3)),fix(itime(4)),$
      fix(itime(5)),fix(0),flux(*,0)

    for it = 1, ntimes - 1 do begin
        time0 = time0 + 60.0
        
        c_r_to_a,itime,time0
        printf,1,fix(itime(0)),fix(itime(1)),fix(itime(2)),fix(itime(3)),fix(itime(4)),$
          fix(itime(5)),fix(0),flux(*,it)
        
    endfor
    
    rt = time0 + 60.
    time0 = time0 + 24*3600.
    while rt lt time0 do begin
        c_r_to_a,itime,rt
        printf,1,fix(itime(0)),fix(itime(1)),fix(itime(2)),fix(itime(3)),fix(itime(4)),$
          fix(itime(5)),fix(0),flux(*,ntimes-1)
        
        rt = rt + 60.0
    endwhile
;    printf,1,2005,09,25,0,0,0,0,flux(*,ntimes-1)
    close,1
    
;plot,x,1e-5*20*x,yrange=[1e-5,1e-3],xtitle = 'Minutes',ytitle='Flux'
;oplot,x,1e-5*2*x    
;if n_elements(tc1) eq 0 then tc1 = 0
;tc1 = fix(ask("the time constant for the rise: ",tostr(tc1)))
    
;    plot,flux(56,*)

    

end
