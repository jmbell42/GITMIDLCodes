if n_elements(date1new) eq 0 then date1new = ''
date1new = ask('date (yyyy-mm-dd): ',date1new)
if n_elements(ndays) eq 0 then ndays = 1
ndays = fix(ask('number of days: ',tostr(ndays)))

date1 = date1new
iyear1 = fix(strmid(date1,0,4))
imonth1 = fix(strmid(date1,5,2))
iday1n = fix(strmid(date1,8,2))

;iyear2 = fix(strmid(date2,0,4))
;imonth2 = fix(strmid(date2,5,2))
;iday2 = fix(strmid(date2,8,2))

reread = 1
if n_elements(iday1) eq 0 then iday1 = 0

if iday1n ne iday1 then begin
    reread = 1  
endif else begin
    if (n_elements(NOVMRss) gt 0) then begin
        answer = ask('whether to re-read data','n')
        if (strpos(mklower(answer),'n') gt -1) then reread = 0
    endif
endelse

iday1 = iday1n
if (reread) then begin
    nhaloeMax = 1000
    naltsmax = 100
    novmr = fltarr(2,naltsmax,nhaloeMax)
    temperature = fltarr(2,naltsmax,nhaloemax)

    altitude = fltarr(2,naltsmax,nhaloeMax)
    latitude = fltarr(2,nhaloeMax)
    longitude = fltarr(2,nhaloeMax)
    rtime  = dblarr(2,nhaloeMax)
    isr = 0
    iss = 1
    temp = ' '
    line = 0L
    nalts = 0
    itime = -1  
    nfiles = 1
    for iday = 0, ndays - 1 do begin

        year = strmid(date1,0,4)
        month = strmid(date1,5,2)
        day = tostr(strmid(date1,8,2) + iday)
        daysinm = d_in_m(fix(year),fix(month))
        if day gt daysinm then begin
            day = '01'
            month = tostr(month+1)
        endif
        
        haloedir = '~/UARS/HALOE/'+year+'/'
        cdate = year+month
        filename = 'HALOE*_SR_'+cdate+'.txt'
        
        close,5
        openr, 5, filename
        while not eof(5) do begin
            readf, 5, temp
            
            if strpos(temp,'Lat') ge 0 then begin
                t = strsplit(temp,/extract)
                if fix(strmid(t(0),0,2) eq fix(day)) then date = 1 else date = 0
            endif
            
            if date then begin
                if strpos(temp,'Lat') ge 0 then begin
                    itime = itime + 1
                    
                    strtime = t(1)
                    latitude(isr,itime) = float(strmid(temp,25,6))
                    longitude(isr,itime) =float(strmid(temp,36,5))
                    ut = strsplit(strtime,":",/extract)
                    hour = fix(ut(0))
                    min = fix(ut(1))
                    sec = fix(ut(2))
                    
                    itimearr = [fix(year),fix(month),fix(day),hour,min,sec]
                    c_a_to_r,itimearr,rt
                    rtime(isr,itime) = rt
                    if n_elements(ialt) eq 0 then ialt = 0
                    if ialt gt nalts then nalts = ialt
                    ialt = 0
                    
                    readf,5,temp
                endif else begin

                    t = strsplit(temp,/extract)
                    altitude(isr,ialt,itime) = float(t(0))
                    ttemp = t(1)
                    temperature(isr,ialt,itime) = float(strmid(ttemp,9))
                    novmr(isr,ialt,itime) = t(2)
                    
                    ialt = ialt + 1
                endelse
            endif
        endwhile
        close,5
     endfor
     ntimes_sr = itime+1
;---- SUNSET ------------------
itime = -1
ialt = 0
 for iday = 0, ndays - 1 do begin

        year = strmid(date1,0,4)
        month = strmid(date1,5,2)
        day = tostr(strmid(date1,8,2) + iday)
        daysinm = d_in_m(fix(year),fix(month))
        if day gt daysinm then begin
            day = '01'
            month = tostr(month+1)
        endif
        
        haloedir = '~/UARS/HALOE/'+year+'/'
        cdate = year+month
        filename = 'HALOE*_SS_'+cdate+'.txt'
        
        close,5
        openr, 5, filename
        while not eof(5) do begin
            readf, 5, temp
            
            if strpos(temp,'Lat') ge 0 then begin
                t = strsplit(temp,/extract)
                if fix(strmid(t(0),0,2) eq fix(day)) then date = 1 else date = 0
            endif
            
            if date then begin
                if strpos(temp,'Lat') ge 0 then begin
                    itime = itime + 1
                    
                    strtime = t(1)
                    latitude(iss,itime) = float(strmid(temp,25,6))
                    longitude(iss,itime) =float(strmid(temp,36,5))
                    ut = strsplit(strtime,":",/extract)
                    hour = fix(ut(0))
                    min = fix(ut(1))
                    sec = fix(ut(2))
                    
                    itimearr = [fix(year),fix(month),fix(day),hour,min,sec]
                    c_a_to_r,itimearr,rt
                    rtime(iss,itime) = rt
                    if n_elements(ialt) eq 0 then ialt = 0
                    if ialt gt nalts then nalts = ialt
                    ialt = 0
                    
                    readf,5,temp
                endif else begin

                    t = strsplit(temp,/extract)
                    altitude(iss,ialt,itime) = float(t(0))
                    ttemp = t(1)
                    temperature(iss,ialt,itime) = float(strmid(ttemp,9))
                    novmr(iss,ialt,itime) = t(2)
                    
                    ialt = ialt + 1
                endelse
            endif
        endwhile
        close,5
     endfor
     ntimes_ss = itime+1
 endif
if ntimes_ss eq ntimes_sr then ntimes=ntimes_ss else $
  ntimes=max([ntimes_sr,ntimes_ss])

altitude = altitude(*,0:nalts-1,0:ntimes-1)
temperature = temperature(*,0:nalts-1,0:ntimes-1)
novmr = novmr(*,0:nalts-1,0:ntimes-1)
rtime = rtime(*,0:ntimes-1)
longitude = longitude(*,0:ntimes-1)
latitude = latitude(*,0:ntimes-1)

loadct, 39
;---Sunrise -----------
setdevice,'plot.ps','p',5,.95
ppp = 2
space = 0.03
pos_space, ppp, space, sizes, ny = ppp
get_position, ppp, space, sizes, 0, pos, /rect
pos(0) = pos(0) + 0.1
pos(2) = pos(2) - .1

vmrrise = (reform(novmr(0,*,*)))
locs = where(vmrrise gt 0)
range = mm(vmrrise(locs))

levels = findgen(31) * (range(1)-range(0)) / 30 + range(0)
stime = rtime(0,0)
etime = max(rtime(0,*))
time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn

time2d = fltarr(nalts,ntimes)
for ialt = 0, nalts - 1 do begin
    time2d(ialt,*) = rtime(0,*)
endfor
yrange = [90,140]
contour,vmrrise,time2d-stime,altitude(0,*,*),/fill,/follow,$
  levels=levels,yrange=yrange,xrange = xrange,pos=pos,xstyle=1,$
  xtickname = strarr(10)+ ' ',xtickv=xtickv,xticks=xtickn,xminor=xminor,$
  charsize = 1.3,ytitle='Altitude',/noerase,ystyle = 1

ctpos = pos
title = 'NO Volume Mixing Ratio (sunrise)'
ctpos(0) = pos(2)+0.025
ctpos(2) = ctpos(0)+0.03
maxmin = range
plotct, 255, ctpos, maxmin, title, /right

;---Sunset -----------

get_position, ppp, space, sizes, 1, pos, /rect
pos(0) = pos(0) + 0.1
pos(2) = pos(2) - .1

vmrset = (reform(novmr(1,*,*)))
locs = where(vmrset gt 0)

range = mm(vmrset(locs))

levels = findgen(31) * (range(1)-range(0)) / 30 + range(0)
stime = rtime(1,0)
etime = max(rtime(1,*))
time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn

time2d = fltarr(nalts,ntimes)
for ialt = 0, nalts - 1 do begin
    time2d(ialt,*) = rtime(1,*)
endfor
yrange = [90,140]
contour,vmrset,time2d-stime,altitude(1,*,*),/fill,/follow,$
  levels=levels,yrange=yrange,xrange = xrange,pos=pos,xstyle=1,$
  xtickname = xtickname,xtickv=xtickv,xticks=xtickn,xminor=xminor,$
  charsize = 1.3,xtitle=xtitle,ytitle='Altitude',/noerase,ystyle = 1

ctpos = pos
title = 'NO Volume Mixing Ratio (sunset)'
ctpos(0) = pos(2)+0.025
ctpos(2) = ctpos(0)+0.03
maxmin = range
plotct, 255, ctpos, maxmin, title, /right
closedevice
end
                
               
