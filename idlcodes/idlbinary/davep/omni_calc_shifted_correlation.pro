ndaysshift = 7
day1 = 1
iyear1 = 2000

while day1 le 365 do begin
  


; if n_elements(date) eq 0 then date = ' '
;  date = ask('beginning date of solar rotation to correlate: (yyyymmdd)',date)
;
;  iyear1 = strmid(date,0,4)
;  imonth1 = strmid(date,4,2)
;  iday1 = strmid(date,6,2)
;  day1 = jday(iyear1,imonth1,iday1)
 
   day2 = day1 + 27-7
  day3 = day1+27+7

  leapyear = isleapyear(iyear1)
  if leapyear then ndays = 366 else ndays = 365

  if day2 gt ndays then begin
     day2 = day2 - ndays
    iyear2 = iyear1 + 1
endif else begin
   iyear2 = iyear1
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

time2 = fromjday(iyear2,day2)
imonth2 = time2(0)
iday2 = time2(1)

time3 = fromjday(iyear3,day3)
imonth3 = time3(0)
iday3 = time3(1)

nfiles = 3
files = strarr(nfiles)

files(0) = 'omni_min'+tostr(iyear1)+chopr('0'+tostr(imonth1),2)+'.save'
files(1) = 'omni_min'+tostr(iyear2)+chopr('0'+tostr(imonth2),2)+'.save'
files(2) = 'omni_min'+tostr(iyear3)+chopr('0'+tostr(imonth3),2)+'.save'

if files(0) eq files(1) then begin
   nfiles = nfiles - 1
   files = files(1:2)
endif else begin
   if files(1) eq files(2) then begin
      nfiles = nfiles - 1
      files = files(0:1)
   endif 
   endelse
if n_elements(dayold) eq 0 then dayold = 0
if n_elements(vars) eq 0 or  dayold ne day1 then begin
   reread = 1 
endif else begin
   reread = 'n'
   reread = ask('whether to reread files: ',reread)
   if strpos(reread, 'y') ge 0 then reread = 1 else reread = 0
endelse

if reread then begin
print, 'Reading files...'
   vars = ['Vx','Vy','Vz','Bx','By','Bz'];,'IMF Clock Angle','|Bz|','Bt','dPhi_mp/dt','Rho']
nvars = n_elements(vars)
ntimesmax = 150000
data = fltarr(nvars,ntimesmax)
rtime = dblarr(ntimesmax)

ntold = 0
nttotal = 0
for ifile = 0, nfiles-1 do begin
   restore,files(ifile)
   nt = n_elements(time)
   nttotal = nttotal + nt
   rtime(ntold:nttotal-1) = time
   data(0:2,ntold:nttotal-1) = velocity
if nvars gt 3 then begin
   data(3:5,ntold:nttotal-1) = magnetic
   cangle = atan(magnetic(1,*)/magnetic(2,*))*180/!pi
   locs = where(cangle lt 0)
   cangle(locs) = 360 + cangle(locs)
endif
   if nvars gt 6 then begin
   data(6,ntold:nttotal-1) = cangle;atan(magnetic(1,*)/magnetic(2,*))*180/!pi
   data(7,ntold:nttotal-1) = abs(magnetic(2,*))
   data(8,ntold:nttotal-1) = sqrt(magnetic(0,*)^2+magnetic(1,*)^2+magnetic(2,*)^2)
   data(9,ntold:nttotal-1) = sqrt(velocity(0,*)^2+velocity(1,*)^2+velocity(2,*)^2)^(4/3.) * $
                             (sqrt(magnetic(0,*)^2+magnetic(1,*)^2+magnetic(2,*)^2))^(2/3.) * $
                             (abs(sin(cangle*!pi/180/2.)))^(8/3.)
   data(10,ntold:nttotal-1) = density
endif
   ntold = nttotal
;sqrt(velocity(0,0)^2+velocity(1,0)^2+velocity(2,0)^2)^(4/3.) * $
;                             sqrt(magnetic(0,0)^2+magnetic(1,0)^2+magnetic(2,0)^2)^(2/3.) 0 $
;                             sin(atan(magnetic(1,0)/magnetic(2,0))/2.)^(8/3.)

endfor

data = data(*,0:nttotal-1)
rtime = rtime(0:nttotal-1)
locs = where(data(0,*) lt 99990) 
itimearr = intarr(6,nttotal)
for itime = 0L, nttotal - 1 do begin
   c_r_to_a, ta, rtime(itime)
   itimearr(*,itime) = ta
endfor


data = data(*,locs)
rtime = rtime(locs)

itimearr1 = [iyear1,imonth1,iday1,0,0,0]
itimearr2 = [iyear2,imonth2,iday2,0,0,0]
itimearr3 = [iyear3,imonth3,iday3,0,0,0]

c_a_to_r,itimearr1,rt1
c_a_to_r,itimearr2,rt2
c_a_to_r,itimearr3,rt3

blocs = where(rtime ge rt1 and rtime le rt1+7*24*3600.)

ivar = 0
bdata = data(ivar,blocs)
brtime = rtime(blocs)
ertime = brtime
nsecondsbase = 27*24*3600.
dsec = ndaysshift*24*3600.

ndaystest = 14 ;7 before and 7 after
nhourstest = ndaystest*24

nt = n_elements(brtime)
data_next = fltarr(nt,nhourstest)
t_next = lonarr(nt,nhourstest)
data_current = data_next
t_current = t_next
nlocs = intarr(nhourstest)   

c_cor = fltarr(2,nhourstest)
rms = fltarr(2,nhourstest)
for ihourshift = 0, nhourstest - 1 do begin

   nhoursshift = nhourstest/2. - nhourstest + ihourshift

   print, "Working on correlating "+ tostr(nhoursshift) 

;Confusing:  nsecondsbase is in general, 27 days
;nhoursshift is the amount of time to shift from there, 1 hour, 2
;hours, etc
;7 is the number of days, so we are looking for all the times between
;27 days + nhoursshift and 27 days + nhoursshift + 7days
elocs = where(rtime ge brtime(0)+nsecondsbase+nhoursshift*3600. and $
              rtime le brtime(0)+nsecondsbase+7*24.*3600.+nhoursshift*3600.)
edata = data(ivar,elocs)
ertime = rtime(elocs)
for itime = 0, nt - 1 do begin
    rt2 = brtime(itime) + nsecondsbase+nhoursshift*3600.
   mint = min(abs(rt2 - ertime),im)

    if abs(rt2 - ertime(im)) ge 3600/50. then begin
      t_next(itime,ihourshift) = -99999. 
   endif else begin
      t_next(itime,ihourshift) = ertime(im)
      data_next(itime,ihourshift) = reform(edata(0,im))

   endelse
endfor

;print, "dm: ",data_next(0:10,ihourshift)
locs = where(t_next(*,ihourshift) gt 0,nl)
nlocs(ihourshift) = nl
t_next(0:nl-1,ihourshift) = t_next(locs,ihourshift)
t_current(0:nl-1,ihourshift) = brtime(locs)
data_next(0:nl-1,ihourshift) = data_next(locs,ihourshift)
data_current(0:nl-1,ihourshift) = reform(bdata(0,locs))
c_cor(0,ihourshift) = (nhoursshift)
c_cor(1,ihourshift) = c_correlate(data_current(0:nl-1,ihourshift),data_next(0:nl-1,ihourshift),0)
rms(0,ihourshift) = nhoursshift
rms(1,ihourshift) = sqrt(mean((data_current(0:nl-1,ihourshift)-data_next(0:nl-1,ihourshift))^2)) / $
                    sqrt(mean(data_current(0:nl-1,ihourshift)^2))
endfor

endif

ppp = 3
space = 0.01
pos_space, ppp, space, sizes, ny = ppp

get_position, ppp, space, sizes, 0, pos, /rect
    pos(0) = pos(0)+.03
loadct,39
setdevice,'cross_c_'+chopr('0'+tostr(imonth1),2)+chopr('0'+tostr(iday1),2)+tostr(iyear1)+'.ps','p',5,.95
plot, c_cor(0,*)/24.,c_cor(1,*),xtitle=' ',xtickname=strarr(10)+' ',ytitle="Cross Correlation",$
pos=pos,thick=3,charsize=1.2,/noerase
xyouts,pos(0),pos(3)+.02,$
       "Week beginning "+chopr('0'+tostr(imonth1),2)+'/'+chopr('0'+tostr(iday1),2)+'/'+tostr(iyear1),/norm

get_position, ppp, space, sizes, 1, pos, /rect
    pos(0) = pos(0)+.03
plot,rms(0,*)/24.,rms(1,*),  xtitle='Day Offset (0 is exaclty 27 days out)',ytitle="RMS Average",$
pos=pos,thick=3,charsize=1.2,/noerase
  

  
  closedevice
dayold = day1
day1 = day1 + 7

endwhile
;
;
;
;stop



; ppp = 3
;  space = 0.01
;  pos_space, ppp, space, sizes, ny = ppp
;  
;  stime = t_current(0,ihourshift)
;  etime = max(t_current(*,ihourshift))
;  tc = t_current(0:nlocs(ihourshift)-1,ihourshift)
;  dc = data_current(0:nlocs(ihourshift)-1,ihourshift)
;  dn = data_next(0:nlocs(ihourshift)-1,ihourshift)
;
;  time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
;
;  maxi = max([dc,dn])
;  mini = min([dc,dn])
;
;  get_position, ppp, space, sizes, 0, pos, /rect
;  loadct,39
;  setdevice,'plot.ps','p',5,.95
;  plot,tc-stime,dc,xtitle = xtitle,ytitle='Solar Wind V!Dx!N',pos=pos,xtickname=xtickname,$
;       xminor=xminor,xtickv=xtickv,xticks=xtickn,yrange=[mini,maxi],ystyle=1
;  oplot,tc-stime,dn,color=220
;
;
;
;closedevice
end


