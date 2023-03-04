if n_elements(sitime) eq 0 then sitime = [2003,10,28,0, 0, 0] 
sitime = fix(strsplit(ask('date to plot: ', strjoin(tostr(sitime),' ')),/extract))
if n_elements(ndays) eq 0 then ndays = 1
ndays = fix(ask('number of days to plot: ',tostr(ndays)))
c_a_to_r,sitime,stime

bdoy = jday(sitime(0),sitime(1),sitime(2))

naltsmax = 100
nscansmax = 5000
altitude = fltarr(naltsmax,nscansmax)
o = altitude
n2 = o
o2 = o
t = o
msiso2 = o
rtime = dblarr(nscansmax)
day = intarr(nscansmax)
sza = fltarr(nscansmax)
lat = sza
lon=sza
iscan = 0
maxscans = 0
maxalts = 0
for iday = 0, ndays - 1 do begin
cyear = tostr(sitime(0))
cdoy = tostr(bdoy+iday)
cmonth = tostr(sitime(1))
cdt = fromjday(fix(cyear),fix(cdoy))
cday = tostr(cdt(1))
guvidir = '~/GUVI/'+strjoin([strmid(cyear,2,2),chopr('0'+cmonth,2),chopr('0'+cday,2)])+'/'

filelist = file_search(guvidir+'*_'+cyear+chopr('00'+cdoy,3)+'*.sav')
nfiles = n_elements(filelist)

for ifile = 0, nfiles - 1 do begin
    restore, filelist(ifile)

    nscans = n_elements(ndpsorbit.sec)
    nalts = n_elements(ndpsorbit(0).zm)
    if nalts gt maxalts then maxalts = nalts
    if nscans gt maxscans then maxscans = nscans

    for is = iscan, nscans + iscan - 1 do begin
        altitude(0:nalts-1,is) = ndpsorbit(is-iscan).zm
        o(0:nalts-1,is) = ndpsorbit(is-iscan).ox
        n2(0:nalts-1,is) = ndpsorbit(is-iscan).n2
        o2(0:nalts-1,is) = ndpsorbit(is-iscan).o2
        t(0:nalts-1,is) = ndpsorbit(is-iscan).t
        msiso2(0:nalts-1,is) = ndpsorbit(is-iscan).ox0

        tt = fromjday(fix(cyear),ndpsorbit(is-iscan).iyd)
        month = tt(0)
        day = tt(1)
        hour = fix(ndpsorbit(is-iscan).sec/3600.)
        min = fix((ndpsorbit(is-iscan).sec/3600. - hour)*60)
        sec = fix((((ndpsorbit(is-iscan).sec/3600. -hour)*60)-min)*60)
        itime = [fix(cyear),month,day,hour,min,sec]
        
        c_a_to_r,itime,rt
        rtime(is) = rt
        sza(is) = ndpsorbit(is-iscan).sza
        lat(is) = ndpsorbit(is-iscan).glat
        lon(is) = ndpsorbit(is-iscan).glong
        
    endfor
    iscan = is
endfor
endfor
nscans = iscan
altitude = altitude(0:maxalts-1,0:iscan-1)
o = o(0:maxalts-1,0:iscan-1)
n2 = n2(0:maxalts-1,0:iscan-1)
o2 = o2(0:maxalts-1,0:iscan-1)
t = t(0:maxalts-1,0:iscan-1)
msiso2 = msiso2(0:maxalts-1,0:iscan-1)
rtime = rtime(0:iscan-1)
lat = lat(0:iscan-1)
lon = lon(0:iscan-1)
locs = where(lon lt 0)
lon(locs) = 360+lon(locs)
data = fltarr(5,maxalts,nscans)
data(0,*,*) = o
data(1,*,*) = n2
data(2,*,*) = O2
data(3,*,*) = T
data(4,*,*) = msiso2

vars = ['O','N2','O2','T','MSIS_O2']
if n_elements(pvar) eq 0 then pvar = 0
display,vars
pvar = fix(ask('which variable to plot: ',tostr(pvar)))

alt = reform(altitude(*,0))
display,alt
if n_elements(palt1) eq 0 then palt1 = 0
if n_elements(palt2) eq 0 then palt2 = 0
palt1 = fix(ask('1st altitude to plot: ',tostr(palt1)))
palt2 = fix(ask('2nd altitude to plot: ',tostr(palt2)))

value = reform(data(pvar,*,*))
logo=alog10(value)
range = mm(logo)
mini = range(0)
maxi = range(1)
levels = findgen(31) * (range(1)-range(0)) / 30 + range(0)

stime = rtime(0)
etime = max(rtime)
c_a_to_r,sitime,stime
etime = stime + 24*3600.*ndays
time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn

;plot,rtime-stime,o(5,*),xtitle=xtitle,xtickname=xtickname,xticks=xtickn,$
;  xtickv=xtickv,xminor=xminor,ytitle=[O],xrange = [0,etr-btr]
time2d = fltarr(maxalts,iscan)
for ialt = 0, maxalts - 1 do begin
    time2d(ialt,*) = rtime
endfor
loadct,39

;addline = 1
;if addline then begin
;    if n_elements(nflares) eq 0 then nflares = 1
;    nflares = fix(ask('number of flares: ',tostr(nflares)))
;    
;        if n_elements(ftime) eq 0 then ftime = intarr(6,nflares)
;        rt = dblarr(nflares)
;    for iflare = 0, nflares -1 do begin
;        ftime(*,iflare) = fix(strsplit(ask('flare time '+tostr(iflare), strjoin(tostr(ftime(*,iflare)),' ')),/extract))
;        c_a_to_r,ftime,rt
;        rft(iflare) = rt
;    endfor
;endif
nflares = 2
 rft = dblarr(nflares)
ftime = [2005,1,15,22,40,0]
c_a_to_r,ftime,rt
rft(0) = rt
ftime = [2005,1,17,9,20,0]
c_a_to_r,ftime,rt
rft(1)=rt


file = 'guvi_'+vars(pvar)+'_'+cyear+chopr('0'+cmonth,2)+chopr('0'+cday,2)+'.ps'
setdevice,file,'p',5,.95
loadct, 39
ppp = 4
space = 0.03
pos_space, ppp, space, sizes, ny = ppp
get_position, ppp, space, sizes, 0, pos, /rect
get_position, ppp, space, sizes, 1, pos1, /rect
pos(0) = pos(0) + 0.1
pos(2) = pos(2) - .1
pos(1) = pos1(1)

szalocs = where(sza gt 0.001)
minsza = min(sza(szalocs))
locs = where(sza gt 0.001 and sza lt minsza+ 20)
contour,logo(*,locs),time2d(*,locs)-stime,altitude(*,locs),xrange =[0,etr],$
  xtickv=xtickv,xticks=xtickn,xminor=xminor,ytitle='Altitude',/fill,levels=levels,$
  pos=pos,xtickname = strarr(10) + ' '

for ifl = 0, nflares -1 do begin
    oplot, [rft(ifl)-1,rft(ifl)+1]-stime,[-1000,1000],linestyle = 2
endfor
title = 'Log['+vars(pvar)+']'
ctpos = pos
ctpos(0) = pos(2)+0.025
ctpos(2) = ctpos(0)+0.03
maxmin = [mini,maxi]
plotct, 255, ctpos, maxmin, title, /right


get_position, ppp, space, sizes, 2, pos, /rect

pos(0) = pos(0) + 0.1
pos(2) = pos(2) - .1
pos1 = pos
pos1(1) = (pos(1)+pos(3))/2+.01

plot,rtime(locs)-stime,value(palt2,locs),xtickv=xtickv,xticks=xtickn,xminor=xminor,$
  xrange=[0,etr],pos=pos1,ytitle='['+vars(pvar)+'] ('+tostr(alt(palt2))+' km)',/noerase,xtickname=strarr(10)+' ',psym = sym(1)
for ifl = 0, nflares -1 do begin
oplot, [rft(ifl)-1,rft(ifl)+1]-stime,[0,1e20],linestyle = 2
endfor

pos(3) = (pos(1)+pos(3))/2-.01

plot,rtime(locs)-stime,value(palt1,locs),xtickv=xtickv,xticks=xtickn,xminor=xminor,$
  xrange=[0,etr],pos=pos,ytitle='['+vars(pvar)+'] ('+tostr(alt(palt1)) +' km)',/noerase,xtickname=strarr(10)+' ',psym = sym(1)
for ifl = 0, nflares -1 do begin
oplot, [rft(ifl)-1,rft(ifl)+1]-stime,[0,1e20],linestyle = 2
endfor

get_position, ppp, space, sizes, 3, pos, /rect
pos(0) = pos(0) + 0.1
pos(2) = pos(2) - .1
plot,rtime(locs)-stime,sza(locs),xtitle=xtitle,xtickv=xtickv,xticks=xtickn,xminor=xminor,$
  xrange=[0,etr],pos=pos,ytitle='SZA',/noerase,xtickname=xtickname,psym = sym(4)
for ifl = 0, nflares -1 do begin
oplot, [rft(ifl)-1,rft(ifl)+1]-stime,[0,1e20],linestyle = 2
endfor

closedevice

end
