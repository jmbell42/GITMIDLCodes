;PRO plotgoes,date

oplotf107 = 0
if n_elements(date) eq 0 then date = '0'
if n_elements(ndays) eq 0 then ndays = 0
date = ask('date to plot [yyyymmdd]: ',date)
if n_elements(ndays) eq 0 then ndays = 1
ndays = fix(ask('number of days to plot: ',tostr(ndays)))
;ndays = 2

year = fix(strmid(date,0,4))
month = strmid(date,4,2)

filelist = findfile('~/UpperAtmosphere/GOES/'+tostr(year)+'/data/A*'+month+'.TXT')
file = filelist(0)

ifile = 0

;finddate = strmid(date,0,4)
;filenotfound = 1
;
;while filenotfound do begin
;    filedate = strmid(filelist(ifile),4,4)
;    if filedate eq finddate then begin
;        filenotfound = 0
;        file = filelist(ifile)
;    endif
;    ifile = ifile + 1
;    if ifile gt nfiles then begin
;        print, 'Cant find file!!! '
;        stop
;    endif
;endwhile

headerlines = 26
nlines = ndays*24.*60/5.

iTimeArray = intarr(6,nlines)
rtime = fltarr(nlines)
XL = fltarr(nlines)
XS = fltarr(nlines)
close,5
openr, 5, file
temp = ''
inHeader = 1

for iline = 0, 25 do begin
    readf, 5, temp
    
    t = strsplit(temp,/extract)
    if strtrim(temp(0),2) eq 'YYMMDD' then begin
        Variables = strsplit(temp,/extract)
    endif
endfor

notdate = 1
while notdate do begin
    readf, 5, temp
    t = strsplit(temp,/extract)
    if t(0) eq strmid(date,2,6) then notdate = 0
endwhile

yymmdd = t(0)
hhmm = t(1)

y = fix(strmid(yymmdd,0,2))
m = fix(strmid(yymmdd,2,2))
d = fix(strmid(yymmdd,4,2))
h = fix(strmid(hhmm,0,2))
mn = fix(strmid(hhmm,2,2))

if y gt 10 then y = 1900+y else y = 2000+y

iTimeArray(*,0) = [y,m,d,h,mn,0]

XL(0) = float(t(3))
XS(0) = float(t(4))

taa = itimearray(*,0)
c_a_to_r, taa,rt
rtime(0) = rt

for iline = 1L, nlines - 1 do begin
    readf,5, temp
    t = strsplit(temp,/extract)
    yymmdd = t(0)
    hhmm = t(1)
    y = fix(strmid(yymmdd,0,2))
    m = fix(strmid(yymmdd,2,2))
    d = fix(strmid(yymmdd,4,2))
    h = fix(strmid(hhmm,0,2))
    mn = fix(strmid(hhmm,2,2))
    
    if y gt 10 then y = 1900+y else y = 2000+y
    
    iTimeArray(*,iline) = [y,m,d,h,mn,0]

    XL(iline) = float(t(3))
    XS(iline) = float(t(4))

    taa = itimearray(*,iline)
    c_a_to_r, taa,rt
    rtime(iline) = rt
    
endfor
close, 5

stime = rtime(0)
etime = rtime(nlines-1)+200.0
close,1
if oplotf107 then begin
   f107file = '~/GITM2/srcData/f107.txt'
   openr,1,f107file
   started = 0
   t = ' '
   while not started do begin
      readf,1,t
      if strpos(t,'#yyyy') ge 0 then started = 1
   endwhile

   ftime = dblarr(15000)
   f107 = fltarr(15000)
   itime = 0
   while not eof(1) do begin
      readf,1,t
      temp = strsplit(t,/extract)
      year = strmid(temp(0),0,4)
      mon = strmid(temp(0),5,2)
      day = strmid(temp(0),8,2)
      itimearr = fix([year,mon,day,'0','0','0'])
      c_a_to_r,itimearr,rt
      ftime(itime) = rt
      f107(itime) = float(temp(2))
      itime = itime + 1
   endwhile
nftimes = itime - 1
ftime = ftime(0:nftimes-1)
f107 = f107(0:nftimes-1)

close,1


   locs = where(ftime ge stime and ftime le etime)
   ftime = ftime(locs)
   f107 = f107(locs)

endif
time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn

title = 'goes_'+strtrim(date,2)+'.ps'
;title = 'plot.ps'
setdevice, title,'p',5,.95

pos = [.05,.05,.5,.3]
loc = where(XL ne 32700.0)

XL = alog10(XL)
XS = alog10(XS)
loadct,39
if oplotf107 then ystyle = 8 else ystyle=1
plot, rtime(loc) - stime, XL(loc), /nodata, xtickname = xtickname, $
  xtickv = xtickv, xminor = xminor, xticks = xtickn, xstyle = 1, $
  ystyle = ystyle, thick = 3, charsize = 1.2,xtitle = xtitle,$
  ytitle = 'GOES Flux (log!D10!N W/m!U2!N)' ,pos=pos,yrange = [-9.0,-2.5]
oplot,rtime(loc) - stime, XL(loc),color = 254,thick = 3
;oplot,rtime(loc) - stime, XS(loc),color = 70,thick =3
xyouts,etime-stime+2500.,-5.65,'C'
xyouts,etime-stime+2500.,-4.65,'M'
xyouts,etime-stime+2500.,-3.65,'X'

loadct,0
oplot,[0,etime-stime],[-6,-6],linestyle=2,color=130
oplot,[0,etime-stime],[-5,-5],linestyle=2,color=130
oplot,[0,etime-stime],[-4,-4],linestyle=2,color=130


if oplotf107 then begin
loadct,39
   axis,yaxis=1,yrange=[70,300],ystyle=1,ytitle='F!D10.7!N (W/m!U2!N/Hz!U-1!N)',/save
   oplot,ftime-stime,f107,color=70,thick=3
   legend,['GOES','F10.7'],color=[254,70],linestyle=[0,0],box=0,pos=[2000,275],/data
endif


m = max(xl(loc),im)
rtm = rtime(loc(im))
c_r_to_a,ta,rtm

ptime = rtm-3600.
tdm = min(where(rtime(loc)-ptime ge 0))

print, 'Maximum flux is: ', tostrf(m), ' at time: ', ta
print, 'Flux 1 hour before is: ', tostrf(XL(loc(tdm)))
closedevice

end
    
