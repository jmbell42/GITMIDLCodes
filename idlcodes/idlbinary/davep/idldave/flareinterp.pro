seefile = 'seeflux2003298.306'
c_a_to_r,[2003,10,28,0,0,0],plstime
c_a_to_r,[2003,10,28,23,59,0],pletime

flarelength = 5
nlinesmax = 5000
nflaresmax = 20
seeflux = fltarr(59,nlinesmax)
seetime = intarr(6,nlinesmax)
rtime = fltarr(nlinesmax)
flaretime = fltarr(nflaresmax)

close,1
openr,1,seefile
temp = ' '
tt = fltarr(65)
nlmin = file_lines(seefile)
sf = fltarr(59,nlmin)
st = fltarr(nlmin)
close,2
openr,2,seefile
while temp ne '#START' do begin
    readf,2,temp
endwhile
ll = 0
while not eof(2) do begin
    readf,2,tt
    sf(*,ll) = tt(6:*)
    ta = tt(0:5)
    c_a_to_r,ta,taa
    st(ll) = taa
    ll = ll + 1

endwhile
sf = sf(*,0:ll-1)
st = st(0:ll-1)
close,2
isdone = 0
while not isdone do begin
    readf, 1, temp
    if temp eq '#FLARES' then begin
        readf, 1, nflares
        flaretimes = intarr(6,nflares)
        
        for iflare = 0, nflares - 1 do begin
           temp2 = intarr(6)
           readf, 1, temp2
           flaretimes(*,iflare) = temp2
            c_a_to_r, flaretimes(*,iflare), rt
            flaretime(iflare) = rt
        endfor
        
    endif
    
    if temp eq '#START' then isdone = 1
endwhile

iline = 0
temp = fltarr(65)
while not eof(1) do begin
    readf, 1,  temp
    seetime(*,iline) = fix(temp(0:5))
    c_a_to_r, seetime(*,iline), rt
    rtime(iline) = rt
    seeflux(*,iline) = temp(6:*)
    iline = iline + 1
endwhile

close, 1

seeflux = seeflux(*,0:iline-1)
seetime = seetime(*,0:iline-1)
rtime = rtime(0:iline-1)
stime = rtime(0)
etime = max(rtime)

dt = 60
time = findgen((etime-stime)/dt)*60+stime
ntimes = n_elements(time)
flux1 = fltarr(59,ntimes)
flux2 = fltarr(59,ntimes)
flux3 = fltarr(59,ntimes)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;EXPONENTIAL INTERPOLATION

iflare = 0
DuringFlare = 0

for itime = 0, ntimes - 1 do begin
    tdiff = time(itime) - (rtime)
    loc = where(tdiff ge 0)
    mindt = min(tdiff(loc),imin)
    flux1(*,itime) = seeflux(*,loc(imin))
    testtime = seetime(*,loc(imin))
    c_r_to_a, taa,time(itime)
  ;  print, 'simulation time: ',taa
  ;  print, 'see time: ',testtime
  ;  print, ' '

    if itime gt 0 then begin
   
        if time(itime) ge flaretime(iflare) and time(itime - 1) le flaretime(iflare) then begin
           
            FlareStartIndex = itime
            SEEStartIndex = loc(imin)+1
            FlareEndIndex = loc(imin)+flarelength
            flux1(*,FlareStartIndex) = seeflux(*,SEEStartIndex)
            c_a_to_r, seetime(*,loc(imin)+flarelength), FlareEndTime
            DuringFlare = 1
            iflare = iflare+1
          
        endif else begin
            if DuringFlare then begin
                if rtime(loc(imin)+1) lt flaretime(iflare) or flaretime(iflare) eq 0 then begin
                    
                    if time(itime) lt rtime(SeeStartIndex) then begin
                                ;We may not be to the point where the
                                ;flare has begun in see...
                        flux1(*,itime) = seeflux(*,SEEStartIndex)
                    endif else begin
                        if time(itime) le FlareEndTime then begin
                                ;Exponentially interpolate between
                                ;last seetime and next see time using
                                ;y = kexp(-mx)
                            
                            y1 = seeflux(*,loc(imin))
                            y2 = seeflux(*,loc(imin)+1)                       
                            x1 = 0
                            x2 = rtime(loc(imin)+1)-rtime(loc(imin))
                            x = time(itime)-rtime(loc(imin))
                            
                            m = alog(y2/y1)/(x1-x2)
                            k = (y1)*exp(m*(x1))
                            flux1(*,itime) = k*exp(-1*m*x)
                            
                        endif else begin
                            DuringFlare = 0
                        endelse
                    endelse
                endif
            endif
        endelse
        
           
    endif
endfor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;LINEAR INTERPOLATION





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;STEP INTERPOLATION






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


time_axis, plstime, pletime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
;loadct, 39
setdevice, 'plot.ps','p',5,.95
ptimes = where(time ge plstime and time le pletime)
stimes = where(st ge plstime and st le pletime)
pos = [.05,.05,.95,.3]
plot, time(ptimes)-plstime, alog10(flux1(56,ptimes)), /nodata, xtickname = xtickname, xtitle = xtitle, xtickv = xtickv, yrange = [-6,-3],$
  xminor = xminor, xticks = xtickn, charsize = 1.2, ytitle = 'Flux (.5 nm) log !D10!N W/m!U2!N',$
  xrange = [0,pletime-plstime],xstyle = 1,pos = pos
 
oplot, time(ptimes)-plstime, alog10(flux1(56,ptimes)), thick = 3
lines = reform(sf(56,*))
oplot, [st(stimes(0)),st(stimes)+45*60.]-plstime, alog10([lines(stimes(0)),lines(stimes)]), psym = 10,linestyle=2, thick = 3

legend, ['Interpolation','No Interpolation'],linestyle = [0,2], box = 0,pos = $
  [pos(2) - .34,pos(3) - .03],/norm

closedevice

end
        
        
