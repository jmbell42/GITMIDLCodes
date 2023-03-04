oplotf107 = 0
if n_elements(date) eq 0 then date = '0'
if n_elements(ndays) eq 0 then ndays = 0

date = ask('date to plot [yymmdd]: ',date)
if n_elements(ndays) eq 0 then ndays = 1
ndays = fix(ask('number of days to plot: ',tostr(ndays)))
year = fix(strmid(date,0,2))
if year gt 50 then year = 1900 + year else year = 2000 + year
month = strmid(date,2,2)
day = strmid(date,4,2)
istime = fix([year,month,day,0,0,1])
c_a_to_r,istime,stime

etime = stime+ndays*24.*3600.
c_r_to_a,ietime,etime

nmonths = 12*(ietime(0)-istime(0)) + ietime(1) - istime(1)

reread = 1
if n_elements(XL) gt 0 then begin
reread = 0
reread = fix(ask('whether to reread',tostr(reread)))
endif

if reread then begin
    headerlines = 26
    nlines = ndays*24L*60./5.
rtime =dblarr(nlines)
XL = fltarr(nlines)
XS = fltarr(nlines)

iyear = fix(year)
iline = 0L
curmonth = month - 1

for imonth = 0, nmonths - 1 do begin
   curmonth = curmonth + 1
   if (curmonth ne 1 and curmonth mod 13 eq 0) then begin
      iyear = iyear + 1
      curmonth = 1
   endif
   print, 'Working on: ',+tostr(iyear)+'/'+chopr('0'+tostr(curmonth),2)
      filelist = findfile('~/UpperAtmosphere/GOES/'+tostr(iyear)+'/data/A*'+chopr('0'+tostr(curmonth),2)+'.TXT')
   file = filelist(0)
   close,5
   openr, 5, file
   temp = ''
   
   notdate = 1
   while notdate do begin
      readf, 5, temp
      if strpos(temp,'YYMMDD') ge 0 then begin
         notdate = 0
         readf,5,temp
      endif

   endwhile
nd = d_in_m(iyear,curmonth)
nlines = nd * 1440./5.
while not eof(5) do begin
    readf,5, temp
    if strlen(temp) gt 5 then begin
       t = strsplit(temp,/extract)
       yymmdd = t(0)
       hhmm = t(1)
       y = fix(strmid(yymmdd,0,2))
       m = fix(strmid(yymmdd,2,2))
       d = fix(strmid(yymmdd,4,2))
       h = fix(strmid(hhmm,0,2))
       mn = fix(strmid(hhmm,2,2))
       
       if y gt 10 then y = 1900+y else y = 2000+y
       
       it = [y,m,d,h,mn,0]
       
       XL(iline) = float(t(3))
       XS(iline) = float(t(4))
       
       c_a_to_r, it,rti
       rtime(iline) = rti
;if iline gt 0 then begin
;   if rtime(iline) - rtime(iline-1) ne 5*60 then stop
;endif

       iline = iline + 1
    endif

endwhile

close, 5

endfor


;loc = where(rtime gt 0)
;flux = flux(loc)
;rtime = rtime(loc)

pos = [.05,.05,.95,.3]
loc = where(XL ne 32700.0)

flux = alog10(XL(loc))
time = rtime(loc)

endif
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
endif

stime = rtime(0)
etime = max(rtime)

if oplotf107 then begin
   locs = where(ftime ge stime and ftime le etime)
   ftime = ftime(locs)
   f107 = f107(locs)
endif

time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
;xtitle = 'Oct 01 to 31, 2003'
title = 'plot.ps'
setdevice, title,'p',5,.95
minsmooth = 60.
width = minsmooth/5.
sflux = smooth(flux,width,/nan)

loadct,39
xrange=[0,etr-btr]
plot, time - stime, sflux, /nodata, xtickname = xtickname, $
  xtickv = xtickv, xminor = xminor, xticks = xtickn, xstyle = 1, $
  ystyle = 1, thick = 3, charsize = 1.2,xtitle = xtitle,$
  ytitle = 'GOES Flux (log!D10!N W/m!U2!N)' ,pos=pos,yrange = [-8,-3],xrange = xrange
oplot,rtime(loc) - stime, sflux,color = 254,thick = 3,min_value=-9
;oplot,rtime(loc) - stime, XS(loc),color = 70,thick =3
loadct,0
oplot,[0,etime-stime],[-6,-6],linestyle=2,color=130
oplot,[0,etime-stime],[-5,-5],linestyle=2,color=130
oplot,[0,etime-stime],[-4,-4],linestyle=2,color=130
xyouts,100000.,-5.75,'C'
xyouts,100000.,-4.75,'M'
xyouts,100000.,-3.75,'X'
if oplotf107 then begin
   axis,yaxis=1,yrange=[50,300],ystyle=1,ytitle='F!D10.7!N (W/m!U2!N/Hz!U-1!N)',/save
   oplot,ftime-stime,f107,color=70,thick=3
endif




closedevice

end
