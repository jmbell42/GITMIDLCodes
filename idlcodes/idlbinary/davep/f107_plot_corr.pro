makesatfile = 1
loadct,39
setdevice,'plot.ps','p',5,.95
meantime = 120*60.
  file = '~/GITM2/srcData/f107.txt'
  if n_elements(date) eq 0 then date = ' '
  date = ask('beginning date of solar rotation to correlate: (yyyymmdd)',date)
  nsolrots = 1
  iyear2 = strmid(date,0,4)
  imonth2 = strmid(date,4,2)
  iday2 = strmid(date,6,2)
  
  
  day2 = jday(iyear2,imonth2,iday2)
  day2o = day2  
for isolrot = 0, nsolrots -1 do begin
      day2 = day2o + 27*isolrot
       leapyear = isleapyear(iyear2)
       if leapyear then ndays = 366 else ndays = 365

       if iday2 gt ndays then begin
           day2 = day2 - ndays
           iyear2 = iyear2 + 1
       endif
      
      time2 = fromjday(iyear2,day2)
      imonth2 = time2(0)
      iday2 = time2(1)
      day3 = day2 + 31
      day1 = day2 - 27
      day0 = day2 - 27*2.
 

  if day1 le 0 then begin
     iyear1 = iyear2 - 1
     ly = isleapyear(iyear1)
     if ly then day1 = 366 + day1 else day1 = 365 + day1
  endif else begin
    iyear1 = iyear2
endelse
    
if day0 le 0 then begin
     iyear0 = iyear2 - 1
     ly = isleapyear(iyear0)
     if ly then day0 = 366 + day0 else day0 = 365 + day0
  endif else begin
    iyear0 = iyear2
 endelse

if day3 gt ndays then begin
    day3 = day3 - ndays
    iyear3 = iyear2 + 1
endif else begin
   iyear3 = iyear2
endelse

time1 = fromjday(iyear1,day1)
imonth1 = time1(0)
iday1 = time1(1)

time0 = fromjday(iyear0,day0)
imonth0 = time0(0)
iday0 = time0(1)

time3 = fromjday(iyear3,day3)
imonth3 = time3(0)
iday3 = time3(1)

f107 = fltarr(20000)
rtime = fltarr(20000)
close,1
openr,1,file
t= ' '
it = 0
while not(eof(1)) do begin
   readf,1,t
   if strpos(t,'#') lt 0 then begin
      tarr = strsplit(t,/extract)
      cdate = strsplit(tarr(0),'-',/extract)
      idate = fix(cdate)
      itime = [idate,0,0,0]
      c_a_to_r,itime,rt
      rtime(it) = rt
      f107(it) = tarr(2)

      it = it + 1
   endif

endwhile
close,1
ntimes = it - 1
f107 = f107(0:ntimes - 1)
rtime = rtime(0:ntimes-1)

itimearr0 = [iyear0,imonth0,iday0,0,0,0]
itimearr1 = [iyear1,imonth1,iday1,0,0,0]
itimearr2 = [iyear2,imonth2,iday2,0,0,0]
itimearr3 = [iyear3,imonth3,iday3,0,0,0]

c_a_to_r,itimearr0,rt0
c_a_to_r,itimearr1,rt1
c_a_to_r,itimearr2,rt2
c_a_to_r,itimearr3,rt3

locs = where(rtime ge rt0 and rtime lt rt3)
f107 = f107(locs)
rtime = rtime(locs)

locs = where(rtime ge rt2)
data_current = f107(locs)
t_current = rtime(locs)

ttotal = rt3-rt2
locs = where(rtime lt rt1+ttotal and rtime ge rt1)
datatemp = f107(locs)
ttemp = rtime(locs)

locs = where(rtime lt rt1 and rtime ge rt0)
datatemp0 = f107(locs)
ttemp0 = rtime(locs)

nt = n_elements(t_current)
;solrot = 27.2753*24*3600.
;solrot = 26.24*24*3600.
solrot = 27*24*3600.

data_previous = fltarr(nt)
t_previous = dblarr(nt)
data_previous2 = fltarr(nt)
t_previous2 = dblarr(nt)

for itime = 0L, nt - 1 do begin
   rt = t_current(itime) - solrot
   mint = min(abs(rt - ttemp),im)
   
   if abs(rt - ttemp(im)) ge 3600/50. then begin
      t_previous(itime) = -99999. 
   endif else begin
      t_previous(itime) = ttemp(im)
      data_previous(itime) = datatemp(im)
   endelse

   rt = t_current(itime) - solrot*2
   mint = min(abs(rt - ttemp0),im)
   
   if abs(rt - ttemp0(im)) ge 3600/50. then begin
      t_previous2(itime) = -99999. 
   endif else begin
      t_previous2(itime) = ttemp0(im)
      data_previous2(itime) = datatemp0(im)
   endelse

endfor

locs = where(t_previous gt 0); and t_previous2 gt 0)
t_previous = t_previous(locs)
t_current = t_current(locs)
data_previous = data_previous(locs)
data_current = data_current(locs)
t_previous2 = t_previous2(locs)
data_previous2 = data_previous2(locs)

;data_current2 = 2*data_previous-data_previous2
data_current2 = data_previous + (mean(data_previous) - mean(data_previous2))
correlation = c_correlate(data_current,data_previous,0)
rms = sqrt(mean((data_current-data_previous)^2))/sqrt(mean((data_previous)^2))
correlation2 = c_correlate(data_current,data_current2,0)
rms2 = sqrt(mean((data_current-data_current2)^2))/sqrt(mean((data_current2)^2))

if isolrot eq 0 then begin
    ppp = 4
    space = 0.1
    pos_space, ppp, space, sizes, ny = ppp
endif    
    stime = t_current(0)
    etime = max(t_current)

    time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn

    mon = strmid(xtitle,0,3)
    if strpos( xtickname(0),mon) eq -1 then xtickname = mon+' '+xtickname 
    

get_position, ppp, space, sizes, isolrot mod ppp, pos, /rect
pos(2) = pos(2) - .1
yrange = [75,250]
if isolrot mod ppp eq 0 then begin
   plotdumb
    plot,t_current-stime,data_current,pos = pos,ytitle = 'F107',$
      xtickname=xtickname,xtickv=xtickv,xticks=xtickn,xminor=xminor,$
      yrange=yrange,xtitle=xtitle,title='F107 correlation ',ystyle = 1,thick=3
endif else begin
   plot,t_current-stime,data_current,pos = pos,ytitle = 'F107',/noerase,thick=3,$
        yrange=yrange,xtickname=xtickname,xtitle=xtitle,xtickv=xtickv,xticks=xtickn,xminor=xminor
    endelse

oplot,t_current-stime,data_previous,color = 220,thick=3
;oplot,t_current-stime,data_previous2,color = 70
;oplot,t_current-stime,data_current2,color = 150,linestyle = 2
xyouts,pos(2)+.01,pos(3)-.08,'P!DXY!N:  '+tostrf(correlation),/norm
xyouts,pos(2)+.01,pos(3)-.1,'RMS:'+tostrf(rms),/norm
print, correlation(0),RMS(0),correlation2(0),RMS2(0)

 if makesatfile then begin
    ; Unshifted
 
    openw,1,'f107.dat',/append
    printf, 1, '#Data  processed using carrington rotation shift'
      printf,1,'#Element: adjusted'
      printf,1,'#Table: Flux'
      printf,1,'#Description: Adjusted daily solar radio flux'
      printf,1,'#Measure units: W/m^2/Hz'
      printf,1,'#Origin:' 
      printf,1,'#'
      printf,1,'#'
      printf,1,'#Sampling: 1 day'
      printf,1,'#Missing value: 1.0E33'
      printf,1,'#yyyy-MM-dd HH:mm value qualifier description'
     for iday = 2, 25 do begin
       doy = jday(iyear2,imonth2,fix(iday2)+(iday))
       id = fromjday(iyear2,doy)
       
       doyo = jday(iyear2,imonth2,fix(iday2)+iday-1)
       ido = fromjday(iyear2,doyo)
 
       it1 = [iyear2,ido(0),ido(1),0,0,0]
       it2 = [iyear2,id(0),id(1),0,0,0]
       c_a_to_r,it1,rt1
       c_a_to_r,it2,rt2
       locs = where(t_current ge rt1 and t_current lt rt2)
       time = t_current(locs)
       newdata = data_previous(locs)
       nts = n_elements(time)
 
       for itime = 0, nts - 1 do begin
          c_r_to_a,ta,time(itime)
          st = tostr(ta(0))+'-'+chopr('0'+tostr(ta(1)),2)+'-'+chopr('0'+tostr(ta(2)),2)
          printf,1,st,' 00:00 ',tostrf(newdata(itime))," x ", "x"
       endfor

    endfor
       close,1       
  ; Shifted up
  openw,1,'f107times1.5.dat',/append
       printf, 1, '#Data  processed using carrington rotation shift'
      printf,1,'#Element: adjusted'
      printf,1,'#Table: Flux'
      printf,1,'#Description: Adjusted daily solar radio flux'
      printf,1,'#Measure units: W/m^2/Hz'
      printf,1,'#Origin:' 
      printf,1,'#'
      printf,1,'#'
      printf,1,'#Sampling: 1 day'
      printf,1,'#Missing value: 1.0E33'
      printf,1,'#yyyy-MM-dd HH:mm value qualifier description'
 for iday = 2, 25 do begin
       doy = jday(iyear2,imonth2,fix(iday2)+(iday))
       id = fromjday(iyear2,doy)
       
       doyo = jday(iyear2,imonth2,fix(iday2)+iday-1)
       ido = fromjday(iyear2,doyo)
 
       
       
       it1 = [iyear2,ido(0),ido(1),0,0,0]
       it2 = [iyear2,id(0),id(1),0,0,0]
       c_a_to_r,it1,rt1
       c_a_to_r,it2,rt2
       locs = where(t_current ge rt1 and t_current lt rt2)
       time = t_current(locs)
       newdata = data_previous(locs) * 1.5
       nts = n_elements(time)
 
   for itime = 0, nts - 1 do begin
          c_r_to_a,ta,time(itime)
          st = tostr(ta(0))+'-'+chopr('0'+tostr(ta(1)),2)+'-'+chopr('0'+tostr(ta(2)),2)
          printf,1,st,' 00:00 ',tostrf(newdata(itime))," x ", "x"
 
       endfor
       
    endfor
 close,1      
  ; Shifted down
 openw,1,'f107div1.5.dat',/append
      printf, 1, '#Data  processed using carrington rotation shift'
      printf,1,'#Element: adjusted'
      printf,1,'#Table: Flux'
      printf,1,'#Description: Adjusted daily solar radio flux'
      printf,1,'#Measure units: W/m^2/Hz'
      printf,1,'#Origin:' 
      printf,1,'#'
      printf,1,'#'
      printf,1,'#Sampling: 1 day'
      printf,1,'#Missing value: 1.0E33'
      printf,1,'#yyyy-MM-dd HH:mm value qualifier description' 
 for iday = 2, 25 do begin
       doy = jday(iyear2,imonth2,fix(iday2)+(iday))
       id = fromjday(iyear2,doy)
       
       doyo = jday(iyear2,imonth2,fix(iday2)+iday-1)
       ido = fromjday(iyear2,doyo)
 
      
       
       it1 = [iyear2,ido(0),ido(1),0,0,0]
       it2 = [iyear2,id(0),id(1),0,0,0]
       c_a_to_r,it1,rt1
       c_a_to_r,it2,rt2
       locs = where(t_current ge rt1 and t_current lt rt2)
       time = t_current(locs)
       newdata = data_previous(locs) / 1.2
       nts = n_elements(time)
 
       for itime = 0, nts - 1 do begin
          c_r_to_a,ta,time(itime)
          st = tostr(ta(0))+'-'+chopr('0'+tostr(ta(1)),2)+'-'+chopr('0'+tostr(ta(2)),2)
          printf,1,st,' 00:00 ',tostrf(newdata(itime))," x ", "x"
       endfor
       
       
    endfor
 close,1      
  ; Shifted right
 openw,1,'f107up1.dat',/append
      printf, 1, '#Data  processed using carrington rotation shift'
      printf,1,'#Element: adjusted'
      printf,1,'#Table: Flux'
      printf,1,'#Description: Adjusted daily solar radio flux'
      printf,1,'#Measure units: W/m^2/Hz'
      printf,1,'#Origin:' 
      printf,1,'#'
      printf,1,'#'
      printf,1,'#Sampling: 1 day'
      printf,1,'#Missing value: 1.0E33'
      printf,1,'#yyyy-MM-dd HH:mm value qualifier description'
 for iday = 2, 25 do begin
       doy = jday(iyear2,imonth2,fix(iday2)+(iday))
       id = fromjday(iyear2,doy)
       
       doyo = jday(iyear2,imonth2,fix(iday2)+iday-1)
       ido = fromjday(iyear2,doyo)
 
             
       it1 = [iyear2,ido(0),ido(1),0,0,0]
       it2 = [iyear2,id(0),id(1),0,0,0]
       c_a_to_r,it1,rt1
       c_a_to_r,it2,rt2
       locs = where(t_current  ge rt1 + 24*3600.  and t_current lt rt2+24*3600.)
       time = t_current(locs) - 24*3600.
 if iday eq 26 then stop
       newdata = data_previous(locs)
       nts = n_elements(time)
 
      for itime = 0, nts - 1 do begin
          c_r_to_a,ta,time(itime)
          st = tostr(ta(0))+'-'+chopr('0'+tostr(ta(1)),2)+'-'+chopr('0'+tostr(ta(2)),2)
          printf,1,st,' 00:00 ',tostrf(newdata(itime))," x ", "x"         

       endfor
     
    endfor
   close,1      
 ; Shifted left
 openw,1,'f107down1.dat',/append
      printf, 1, '#Data  processed using carrington rotation shift'
      printf,1,'#Element: adjusted'
      printf,1,'#Table: Flux'
      printf,1,'#Description: Adjusted daily solar radio flux'
      printf,1,'#Measure units: W/m^2/Hz'
      printf,1,'#Origin:' 
      printf,1,'#'
      printf,1,'#'
      printf,1,'#Sampling: 1 day'
      printf,1,'#Missing value: 1.0E33'
      printf,1,'#yyyy-MM-dd HH:mm value qualifier description'
 for iday = 2, 25 do begin
       doy = jday(iyear2,imonth2,fix(iday2)+(iday))
       id = fromjday(iyear2,doy)
       
       doyo = jday(iyear2,imonth2,fix(iday2)+iday-1)
       ido = fromjday(iyear2,doyo)
 
      
       it1 = [iyear2,ido(0),ido(1),0,0,0]
       it2 = [iyear2,id(0),id(1),0,0,0]
       c_a_to_r,it1,rt1
       c_a_to_r,it2,rt2
       locs = where(t_current  ge rt1 - 24*3600.  and t_current lt rt2-24*3600.)
       time = t_current(locs) + 24*3600.
       newdata = data_previous(locs)
       nts = n_elements(time)
       for itime = 0, nts - 1 do begin
          c_r_to_a,ta,time(itime)
          st = tostr(ta(0))+'-'+chopr('0'+tostr(ta(1)),2)+'-'+chopr('0'+tostr(ta(2)),2)
           printf,1,st,' 00:00 ',tostrf(newdata(itime))," x ", "x"

       endfor
    
    endfor
   close,1      
 endif

endfor
closedevice

end
