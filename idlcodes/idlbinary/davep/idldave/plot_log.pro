if n_elements(dir) eq 0 then dir = '.'
dir = ask('which directory contains log file: ',dir)

logfile = file_search(dir+'/log*.dat')
if n_elements(logfile) gt 1 then begin
   display, logfile
   if n_elements(whichlog) eq 0 then whichlog = 0
   whichlog = fix(ask('which log file to plot (-1 for all)',tostr(whichlog)))
   if whichlog gt 0 then begin
      logfile = logfile(whichlog)
   endif

endif
nfiles = n_elements(logfile)
temp = ' '
ntimes = 1e7*nfiles

rtime = dblarr(ntimes)
dt = fltarr(ntimes)

Tmin = fltarr(ntimes)
Tmax = fltarr(ntimes)
Tave = fltarr(ntimes)
Vmin = fltarr(ntimes)
Vmax = fltarr(ntimes)
Vave = fltarr(ntimes)
F107 = fltarr(ntimes)
F107A = fltarr(ntimes)
Bx = fltarr(ntimes)
By = fltarr(ntimes)
Bz = fltarr(ntimes)
Vx = fltarr(ntimes)
HPI = fltarr(ntimes)
itime = 0L
for ilog = 0, nfiles - 1 do begin
   close,55
   openr, 55,logfile(ilog)
   done = 0
   


while not done do begin
   readf,55,temp
   if strpos(temp,'#START') ge 0 then done = 1
endwhile
readf,55,temp


while not eof(55) do begin
   readf,55,temp
   t = strsplit(temp,/extract)
   year = t(1)
   mon = t(2)
   day = t(3)
   hour = t(4)
   min = t(5)
   sec = t(6)
   itimea = [year,mon,day,hour,min,sec]
   c_a_to_r,itimea,ta
   rtime(itime) = ta
   dt(itime) = t(8)
   tmin(itime)= t(9)
   tmax(itime)= t(10)
   tave(itime)= t(11)
   vmin(itime)= t(12)
   vmax(itime)= t(13)
   vave(itime)= t(14)
   f107(itime)= t(15)
   f107a(itime)= t(16)
   bx(itime)= t(17)
   by(itime)= t(18)
   bz(itime)= t(19)
   vx(itime)= t(20)
   hpi(itime)= t(21)

   itime = itime + 1
endwhile
close,55
endfor

ntimes = itime 
rtime = rtime(0:ntimes-1)
tmin =tmin(0:ntimes-1)
tave =tave(0:ntimes-1)
tmax = tmax(0:ntimes-1)
vmin = vmin(0:ntimes-1)
vave = vave(0:ntimes-1)
vmax = vmax(0:ntimes-1)

stime = rtime(0)
etime = max(rtime)

time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn

setdevice,'plot.ps','p',5,.95
ppp = 4
space = 0.15
pos_space, ppp, space, sizes

xrange = [0,etime-stime]

get_position, ppp, space, sizes, 0, pos, /rect

yrange = mm([tmin,tmax,tave])
plot,rtime-stime,tave,/nodata,yrange=yrange,xrange = xrange,charsize = 1.2,pos=pos,$
     ytitle = "Temperature",xtitle = xtitle,xtickname=xtickname,xtickv=xtickv,xticks=xtickn,$
     xminor=xminor,/noerase,ystyle=1

oplot,rtime-stime,tmin,thick=3,linestyle = 1
oplot,rtime-stime,tave,thick=3,linestyle = 0
oplot,rtime-stime,tmax,thick=3,linestyle = 2

;----------------------------------------------------------------------
get_position, ppp, space, sizes, 1, pos, /rect

yrange = mm([vmin,vmax,vave])
plot,rtime-stime,vave,/nodata,yrange=yrange,xrange = xrange,charsize = 1.2,pos=pos,$
     ytitle = "Vertical Velocity",xtitle = xtitle,xtickname=xtickname,xtickv=xtickv,xticks=xtickn,$
     xminor=xminor,/noerase,ystyle=1

oplot,rtime-stime,vmin,thick=3,linestyle = 1
oplot,rtime-stime,vave,thick=3,linestyle = 0
oplot,rtime-stime,vmax,thick=3,linestyle = 2


closedevice
end
