timeresolution = 10 ;minutes!
nensembles = 6
  meantime = 12*60*60.

  if n_elements(date) eq 0 then date = ' '
  date = ask('beginning date of simulation: (yyyymmdd)',date)

  if n_elements(numdays) eq 0 then numdays = '1'
  numdays = fix(ask('number of days: ',tostr(numdays)))

  iyear2 = strmid(date,0,4)
  imonth2 = strmid(date,4,2)
  iday2 = strmid(date,6,2)

  day2 = jday(iyear2,imonth2,iday2)
    day1 = day2 - 27

  day2 = jday(iyear2,imonth2,iday2)
   day1 = day2 - 27

  leapyear = isleapyear(iyear2)
  if leapyear then ndays = 366 else ndays = 365

  if day1 le 0 then begin
     iyear1 = iyear2 - 1
     ly = isleapyear(iyear1)
     if ly then day1 = 366 + day1 else day1 = 365 + day1
  endif else begin
    iyear1 = iyear2
endelse
    
time1 = fromjday(iyear1,day1)
imonth1 = time1(0)
iday1 = time1(1)

nfiles = 2
files = strarr(nfiles)
files(0) = 'omni_min'+tostr(iyear1)+chopr('0'+tostr(imonth1),2)+'.save'
files(1) = 'omni_min'+tostr(iyear2)+chopr('0'+tostr(imonth2),2)+'.save'

if files(0) eq files(1) then begin
   nfiles = nfiles - 1
   files = files(1:2)
endif

if n_elements(vars) eq 0 then begin
   reread = 1 
endif else begin
   reread = 'n'
   reread = ask('whether to reread files: ',reread)
   if strpos(reread, 'y') ge 0 then reread = 1 else reread = 0
endelse

if reread then begin
print, 'Reading files...'
   vars = ['Vx','Vy','Vz','Bx','By','Bz','IMF Clock Angle','|Bz|','Bt','dPhi_mp/dt']
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
   data(3:5,ntold:nttotal-1) = magnetic
   cangle = atan(magnetic(1,*)/magnetic(2,*))*180/!pi
   locs = where(cangle lt 0)
   cangle(locs) = 360 +cangle(locs)
   data(6,ntold:nttotal-1) = cangle;atan(magnetic(1,*)/magnetic(2,*))*180/!pi
   data(7,ntold:nttotal-1) = abs(magnetic(2,*))
   data(8,ntold:nttotal-1) = sqrt(magnetic(0,*)^2+magnetic(1,*)^2+magnetic(2,*)^2)
   data(9,ntold:nttotal-1) = sqrt(velocity(0,*)^2+velocity(1,*)^2+velocity(2,*)^2)^(4/3.) * $
                             (sqrt(magnetic(0,*)^2+magnetic(1,*)^2+magnetic(2,*)^2))^(2/3.) * $
                             (abs(sin(cangle*!pi/180/2.)))^(8/3.)
   ntold = nttotal
;sqrt(velocity(0,0)^2+velocity(1,0)^2+velocity(2,0)^2)^(4/3.) * $
;                             sqrt(magnetic(0,0)^2+magnetic(1,0)^2+magnetic(2,0)^2)^(2/3.) 0 $
;                             sin(atan(magnetic(1,0)/magnetic(2,0))/2.)^(8/3.)

endfor


data = data(*,0:nttotal-1)
rtime = rtime(0:nttotal-1)
locs = where(data(0,*) lt 99990) 

data = data(*,locs)
rtime = rtime(locs)

itimearr1 = [iyear1,imonth1,iday1,0,0,0]
itimearr2 = [iyear2,imonth2,iday2,0,0,0]

c_a_to_r,itimearr1,rt1
c_a_to_r,itimearr2,rt2

locs = where(rtime ge rt1 and rtime le rt2)
data = data(*,locs)
rtime = rtime(locs)

nt = n_elements(rtime)
;solrot = 27.2753*24*3600.
solrot = 26.24*24*3600.

smoothed = fltarr(nvars,nt)
ctime = ceil(meantime / 2.)
for itime = 0L, nt -1 do begin
   time = rtime(itime)
   if (time - rtime(0) ge ctime and $
       rtime(nt-1) - time ge ctime) then begin
      
      locs = where(rtime ge time-ctime and rtime lt time+ctime)
      for itype = 0, nvars - 1 do begin
         smoothed(itype,itime) = mean(data(itype,locs))
      endfor
  endif
  
   if (time - rtime(0) lt  ctime) then begin
      
      locs = where(time ge rtime(0) and time lt rtime(0) + ctime)
      for itype = 0, nvars - 1 do begin
         smoothed(itype,itime) = mean(data(itype,locs))
      endfor
   endif

   if (rtime(nt - 1) - time lt ctime ) then begin
        
      locs = where(time le rtime(nt-1) and time gt rtime(nt-1) - ctime)
      for itype = 0, nvars - 1 do begin
         smoothed(itype,itime) = mean(data(itype,locs))
      endfor

   endif
endfor
endif

meandata = fltarr(nvars)
meansmooth = fltarr(nvars)
sigmadata = fltarr(nvars)
sigmasmooth = fltarr(nvars)

for itype = 0, nvars - 1 do begin
    meandata(itype) = mean(data(itype,*))
    meansmooth(itype) = mean(smoothed(itype,*))
    sigmadata(itype) = stdev(data(itype,*))
    sigmasmooth (itype)= stdev(smoothed(itype,*))
endfor

ntimes = numdays * 24 *60 / timeresolution

for itime = 0, ntimes do begin
    time = rt2 + itime * timeresolution * 60.
    prevtime = time - solrot
 
    
    



end
