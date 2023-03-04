loadct,39
setdevice,'plot.ps','p',5,.95
meantime = 6*60*60.

  if n_elements(date) eq 0 then date = ' '
  date = ask('beginning date of solar rotation to correlate: (yyyymmdd)',date)
  nsolrots = 1
  iyear2 = strmid(date,0,4)
  imonth2 = strmid(date,4,2)
  iday2 = strmid(date,6,2)
  
 ppp = 6
  space = 0.1
  pos_space, ppp, space, sizes, ny = ppp/2.
loadct,39
  setdevice,'plot.ps','p',5,.95

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
 print, 'Working on '+tostr(iyear2)+'-'+tostr(imonth2)+'-'+tostr(iday2)

  if day1 le 0 then begin
     iyear1 = iyear2 - 1
     ly = isleapyear(iyear1)
     if ly then day1 = 366 + day1 else day1 = 365 + day1
  endif else begin
    iyear1 = tostr(fix(iyear2))
endelse
    
if day3 gt ndays then begin
    day3 = day3 - ndays
    iyear3 = tostr(fix(iyear2 + 1))
endif else begin
   iyear3 = iyear2
endelse

time1 = fromjday(iyear1,day1)
imonth1 = time1(0)
iday1 = time1(1)

time3 = fromjday(iyear3,day3)
imonth3 = time3(0)
iday3 = time3(1)


close,1

nfiles = 3
files = strarr(nfiles)
files(0) ='~/UpperAtmosphere/GOES/'+tostr(iyear1)+'/data/A*'+ chopr('0'+tostr(imonth1),2)+'.TXT'
files(1) = '~/UpperAtmosphere/GOES/'+tostr(iyear2)+'/data/A*'+chopr('0'+tostr(imonth2),2)+'.TXT'
files(2) = '~/UpperAtmosphere/GOES/'+tostr(iyear3)+'/data/A*'+ chopr('0'+tostr(imonth3),2)+'.TXT'

if files(0) eq files(1) then begin
   nfiles = nfiles - 1
   files = files(1:2)
endif else begin
   if files(1) eq files(2) then begin
      nfiles = nfiles - 1
      files = files(0:1)
   endif
endelse

maxtimes = 100000
XL = fltarr(maxtimes)
XS = XL
rtime = dblarr(maxtimes)
    iline = 0
for ifile = 0, nfiles-1 do begin
    file = files(ifile)
 openr,1,file
    done = 0
    temp = ' '
    while not done do begin
        readf,1,temp
        if strpos(temp,'------') ge 0 then done = 1
    endwhile

    while not eof(1) do begin
        readf,1,temp
        t = strsplit(temp,/extract)
        yymmdd = t(0)
        hhmm = t(1)
        y = fix(strmid(yymmdd,0,2))
        m = fix(strmid(yymmdd,2,2))
        d = fix(strmid(yymmdd,4,2))
        h = fix(strmid(hhmm,0,2))
        mn = fix(strmid(hhmm,2,2))
        
        if y gt 10 then y = 1900+y else y = 2000+y
        
        iTimeArray = [y,m,d,h,mn,0]
        
        XL(iline) = float(t(3))
        XS(iline) = float(t(4))

        c_a_to_r, itimearray,rt
        rtime(iline) = rt
        iline = iline + 1

    endwhile
    close, 1

endfor


nlines = iline - 1 
rtime = rtime(0:nlines-1)
XL = XL(0:nlines-1)
XS = XS(0:nlines-1)

loc = where(XL ne 32700.0)
rtime = rtime(loc)
XL =  XL(loc)
XS = XS(loc)

data = XL

itimearr1 = [iyear1,imonth1,iday1,0,0,0]
itimearr2 = [iyear2,imonth2,iday2,0,0,0]
itimearr3 = [iyear3,imonth3,iday3,0,0,0]

c_a_to_r,itimearr1,rt1
c_a_to_r,itimearr2,rt2
c_a_to_r,itimearr3,rt3

locs = where(rtime ge rt1 and rtime le rt3)
data = data(locs)
rtime = rtime(locs)

locs = where(rtime ge rt2)
data_current = data(locs)
t_current = rtime(locs)

ttotal = rt3-rt2
locs = where(rtime lt rt1+ttotal and rtime ge rt1)
datatemp = data(locs)
ttemp = rtime(locs)

nt = n_elements(t_current)
;solrot = 27.2753*24*3600.
solrot = 26.24*24*3600.

data_previous = fltarr(nt)
t_previous = dblarr(nt)

for itime = 0L, nt - 1 do begin

   rt = t_current(itime) - solrot
   mint = min(abs(rt - ttemp),im)
   
   if abs(rt - ttemp(im)) ge 3600/50. then begin
      t_previous(itime) = -99999. 
   endif else begin
      t_previous(itime) = ttemp(im)
      data_previous(itime) = datatemp(im)
   endelse

endfor

locs = where(t_previous gt 0)
t_previous = t_previous(locs)
t_current = t_current(locs)
data_previous = data_previous(locs)
data_current = data_current(locs)


ctime = ceil(meantime / 2.)
ntimes = n_elements(t_current)
s_previous = fltarr(6,ntimes)
s_current = fltarr(6,ntimes)

for itime = 0, ntimes -1 do begin
   time = t_current(itime)
   if (time - t_current(0) ge ctime and $
       t_current(ntimes-1) - time ge ctime) then begin
      
      locs = where(t_current ge time-ctime and t_current lt time+ctime)
         s_previous(itime) = mean(data_previous(locs))
         s_current(itime) = mean(data_current(locs))

      
   endif
   
   if (time - t_current(0) lt  ctime) then begin
      
      locs = where(time ge t_current(0) and time lt t_current(0) + ctime)
         s_previous(itime) = mean(data_previous(locs))
         s_current(itime) = mean(data_current(locs))


   endif

   if (t_current(ntimes - 1) - time lt ctime ) then begin
        
      locs = where(time le t_current(ntimes-1) and time gt t_current(ntimes-1) - ctime)
         s_previous(itime) = mean(data_previous(locs))
         s_current(itime) = mean(data_current(locs))

  endif
endfor

correlation = c_correlate(data_current,data_previous,0)
s_correlation = c_correlate(s_current,s_previous,0)
s_rms = sqrt(mean((data_current-data_previous)^2))/sqrt(mean((data_previous)^2))
print, "S_RMS: ",s_rms
data_previous = alog10(data_previous)
data_current = alog10(data_current)
s_previous = alog10(s_previous)
s_current = alog10(s_current)


yrange = [-9,-3]

  stime = t_current(0)
  etime = max(t_current)
  time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
nx = strlen(xtickname(0))
xtickname = strmid(xtickname,nx-2,2)
get_position, ppp, space, sizes, (isolrot*2) mod ppp, pos, /rect
pos(2) = pos(2) - .05
if (isolrot*2) mod ppp eq 0 then begin
   plotdumb
    plot,t_current-stime,data_current,pos = pos,ytitle = 'Flux (.1 - .8 nm)',$
      xtickname=xtickname,xtickv=xtickv,xticks=xtickn,xminor=xminor,$
      yrange=yrange,xtitle=xtitle,title='GOES .1 - .8 nm correlation ',ystyle = 1
endif else begin
   plot,t_current-stime,data_current,pos = pos,ytitle = 'Flux (.1 - .8 nm)',/noerase,ystyle = 1,$
        yrange=yrange,xtickname=xtickname,xtitle=xtitle,xtickv=xtickv,xticks=xtickn,xminor=xminor
    endelse

oplot,t_current-stime,data_previous,color = 220

xyouts,pos(0)+.01,pos(3)-.02,'P!DXY!N:  '+tostrf(correlation),/norm
xyouts,etime-stime+2500.,-5.65,'C'
xyouts,etime-stime+2500.,-4.65,'M'
xyouts,etime-stime+2500.,-3.65,'X'

loadct,0
oplot,[0,etime-stime],[-6,-6],linestyle=2,color=130
oplot,[0,etime-stime],[-5,-5],linestyle=2,color=130
oplot,[0,etime-stime],[-4,-4],linestyle=2,color=130
loadct,39
;----------------

get_position, ppp, space, sizes, (isolrot*2+1) mod ppp, pos, /rect
pos(0) = pos(0) + .05
if (isolrot*2+1) mod ppp eq 1 then begin
plot,t_current-stime,s_current,pos = pos,ytitle = 'Flux (.1 - .8 nm)',$
     xtickname=xtickname,xtickv=xtickv,xticks=xtickn,xminor=xminor,$
     yrange=yrange,xtitle=xtitle,ystyle = 1,/noerase,$
     title='GOES .1 - .8 nm !C'+tostr(meantime/60.)+' min smooth correlation '
 endif else begin
   plot,t_current-stime,s_current,pos = pos,ytitle = 'Flux (.1 - .8 nm)',ystyle = 1,/noerase,$
        yrange=yrange,xtickname=xtickname,xtitle=xtitle,xtickv=xtickv,xticks=xtickn,xminor=xminor
    endelse

oplot,t_current-stime,s_previous,color = 220
xyouts,pos(0)+.01,pos(3)-.02,'P!DXY!N:  '+tostrf(s_correlation),/norm
xyouts,etime-stime+2500.,-5.65,'C'
xyouts,etime-stime+2500.,-4.65,'M'
xyouts,etime-stime+2500.,-3.65,'X'

loadct,0
oplot,[0,etime-stime],[-6,-6],linestyle=2,color=130
oplot,[0,etime-stime],[-5,-5],linestyle=2,color=130
oplot,[0,etime-stime],[-4,-4],linestyle=2,color=130
loadct,39

endfor
closedevice
end
