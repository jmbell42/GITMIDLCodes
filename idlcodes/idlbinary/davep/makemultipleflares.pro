
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

    if n_elements(flarepercent) eq 0 then flarepercent = 1.0
    flarepercent = float(ask('factor to alter the peak height by: ',tostrf(flarepercent)))

   ; if n_elements(basefac) eq 0 then basefac = 1.0
   ; basefac = float(ask('factor to divide the base height by: ',tostrf(basefac)))

    if flarepercent ge 1.0 then flare = flare+((flare-base)*abs((1.0-flarepercent))) else $
      flare = flare-((flare-base)*(1.0-flarepercent))

    baseold = base
   ; base = base/basefac
    
    if n_elements(risetime) eq 0 then risetime = 10
    risetime = fix(ask('minutes from base to peak: ',tostr(risetime)))
    timerise = risetime

    if n_elements(delay) eq 0 then delay = 60
    delay = fix(ask('minutes between flares: ',tostr(delay)))

    
    
    x1 = 0
    x2 = timerise
    y1 = base
    y2 = flare
    sloperise = (y2-y1)/(x2-x1)
    krise = base
    
    nminsmax = 4321
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


    for imin = 0, 2219 do begin
        if imin mod delay eq 0 then restart = 1 
        if restart then begin
            iminfl = 0
            restart = 0
        endif
        if iminfl le risetime then begin
            flux(*,imin) = sloperise*iminfl + krise
        endif else begin
            if iminfl le xe2 then begin
                flux(*,imin) = k*exp(-me*iminfl)
            endif else begin
                flux(*,imin) = flux(*,0)
            endelse
        endelse
        iminfl = iminfl + 1
    endfor
;    while iminfl le xe2 do begin
;        flux(*,imin) = k*exp(-me*iminfl)
;        iminfl = iminfl + 1
;        imin = imin + 1;

;    endwhile

    flux(*,imin) = k*exp(-me*xe2)
    flux(*,imin+1) = flux(*,0)
    flux = flux(*,0:imin+1)
    ntimes = n_elements(flux(0,*))

    itime = [2005,09,20,0,0,0]
    c_a_to_r,itime,time0
    openw,1,'flux.dat'
    printf,1,'#START'
    printf,1,fix(itime(0)),fix(itime(1)),fix(itime(2)),fix(itime(3)),fix(itime(4)),$
      fix(itime(5)),fix(0),flux(*,0)
    
    itime = [2005,09,21,0,0,0]
    c_a_to_r,itime,time0
    printf,1,fix(itime(0)),fix(itime(1)),fix(itime(2)),fix(itime(3)),fix(itime(4)),$
      fix(itime(5)),fix(0),flux(*,0)
    for it = 1, ntimes - 1 do begin
        time0 = time0 + 60.0
        
        c_r_to_a,itime,time0
        printf,1,fix(itime(0)),fix(itime(1)),fix(itime(2)),fix(itime(3)),fix(itime(4)),$
          fix(itime(5)),fix(0),flux(*,it)
        
    endfor
    
    printf,1,2005,09,24,0,0,0,0,flux(*,0)
    close,1


end
