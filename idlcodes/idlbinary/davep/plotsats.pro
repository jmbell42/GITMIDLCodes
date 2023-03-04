if n_elements(sitime) eq 0 then sitime = [2003,11,2,17, 15, 0] 
sitime = fix(strsplit(ask('date to plot: ', strjoin(tostr(sitime),' ')),/extract))
if n_elements(nmins) eq 0 then nmins = 1
nmins = fix(ask('number of minutes to plot: ',tostr(nmins)))
c_a_to_r,sitime,stime

bdoy = jday(sitime(0),sitime(1),sitime(2))

naltsmax = 100
nscansmax = 5000
maxalts = 0
maxscans = 0
iscan = 0
rtime = dblarr(nscansmax)
day = intarr(nscansmax)

cyear = tostr(sitime(0))
cdoy = tostr(bdoy)
cmonth = tostr(sitime(1))
cdt = fromjday(fix(cyear),fix(cdoy))
cday = tostr(cdt(1))
guvidir = '~/GUVI/'+cyear+'/';+strjoin([strmid(cyear,2,2),chopr('0'+cmonth,2),chopr('0'+cday,2)])+'/'

filelist = file_search(guvidir+'*_'+cyear+chopr('00'+cdoy,3)+'*.sav')
nfiles = n_elements(filelist)
sza = fltarr(nscansmax)
lat = sza
lon=sza

for ifile = 0, nfiles - 1 do begin
    restore, filelist(ifile)

    nscans = n_elements(ndpsorbit.sec)
    nalts = n_elements(ndpsorbit(0).zm)
    if nalts gt maxalts then maxalts = nalts
    if nscans gt maxscans then maxscans = nscans

    for is = iscan, nscans + iscan - 1 do begin
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



nscans = iscan

rtime = rtime(0:iscan-1)
lat = lat(0:iscan-1)
lon = lon(0:iscan-1)
locs = where(lon lt 0)
lon(locs) = 360+lon(locs)

gtimes = where(rtime ge stime and rtime le stime+nmins*60)
plotguvi = 1
if gtimes(0) lt 0 then plotguvi = 0
if plotguvi then begin
    ngtimes = n_elements(gtimes)
    glat = lat(gtimes)
    glon = lon(gtimes)
gtime = rtime(gtimes)
gitime = intarr(6,ngtimes)

for itime = 0, ngtimes - 1 do begin
    c_r_to_a,ta,gtime(itime)
    gitime(*,itime) = ta
endfor

endif


hour = sitime(3,*) + sitime(4,*)/60.+sitime(5,*)/3600.
reread =  1
if n_elements(champfile) ne 0 then begin
reread = 0
reread = fix(ask("reread: ",tostr(reread)))
endif

if reread then begin
;----------CHAMP ---------------------------------------
champfile = '~/CHAMP/data/'+cyear+'/Den*_'+strmid(cyear,2,2)+'_'+cdoy+'.ascii'
fn = file_search(champfile)
read_champ, fn, rho, position,time,localtime
ctimes = where(time ge stime and time le stime+nmins*60)
nctimes = n_elements(ctimes)
clat=reform(position(1,ctimes))
clon = reform(position(0,ctimes))
citime = intarr(6,nctimes)
for itime = 0, nctimes - 1 do begin
    c_r_to_a,ta,time(itime)
    citime(*,itime) = ta

if clon(itime) lt 0 then clon(itime) = 360. + clon(itime)
endfor

;--------------------------------------------------------------
;-----------SABER---------------------------------------------------
date = cyear+chopr('0'+cmonth,2)+chopr('0'+cday,2)
read_saber,date,tdata,sz,btime,saltitude,latitude,longitude,svars
stimes = where(btime(0,*) ge stime and btime(0,*) le stime+nmins*60)
nstimes = n_elements(stimes)
slat = reform(latitude(0,stimes))
slon = reform(longitude(0,stimes))

;---------------------------------------------------------------------------
endif
;Get Subsolar point
zdate = cyear+'-'+chopr('0'+cmonth,2)+'-'+chopr('0'+cday,2)
ztime = hour(0)
ztime = 0
zlat = 0
zlon = 0
;stop
zsun,zdate,ztime,zlat,zlon,zenith,azimuth,solfac,latsun=latsun,lonsun=lonsun
;
setdevice,'plot.ps','p',5,.95

sdate = zdate+' hour(0)'
plat = 90
plon = lonsun
  pos = [.1,.52,.65,.95]
                !p.position = pos
; map_set, plat,plon,/ortho,title='Satellite location at '+sdate+$
;                  ' UT',pos=pos,/noborder,/cont
 ;plots,[0,360],[70,50],thick = 2
ut = hour(0)
utrot = ut*15.0
minlat = 0
if plotguvi then begin
    loc = where(glat ge minlat)
    gx = (90.0 - glat(loc))*cos((glon(loc)+utrot)*!pi/180.-!pi/2.)
    gy = (90.0 - glat(loc))*sin((glon(loc)+utrot)*!pi/180-!pi/2.)
endif

loc = where(clat ge minlat)
if loc(0) ge 0 then begin
    cx = (90.0 - clat(loc))*cos((clon(loc)+utrot)*!pi/180.-!pi/2.)
    cy = (90.0 - clat(loc))*sin((clon(loc)+utrot)*!pi/180-!pi/2.)
endif else begin
    cx = [-1000,-1000]
    cy = [-1000,-1000]
endelse

loc = where(slat ge minlat)
sx = (90.0 - slat(loc))*cos((slon(loc)+utrot)*!pi/180.-!pi/2.)
sy = (90.0 - slat(loc))*sin((slon(loc)+utrot)*!pi/180-!pi/2.)

mr = 90-minlat
etime = stime+nmins*60
c_r_to_a,eitime,etime
plot, [-mr, mr], [-mr, mr], pos=pos, $
  xstyle=5, ystyle=5,/nodata,/noerase, $
  title= 'Satellite location at '+cyear+' '+chopr('0'+cmonth,2)+' '+chopr('0'+cday,2)+$
  '!C'+tostr(sitime(3))+':'+$
 chopr('0'+tostr(sitime(4)),2)+'-'+tostr(eitime(3))+':'+chopr('0'+tostr(eitime(4)),2)+'!C North'

if plotguvi then oplot,gx,gy,psym=1
oplot,cx,cy,psym=2
oplot,sx,sy,psym=4

xyouts,sx(0)-10,sy(0)-5,'S',/data



plotmlt,mr

pos = [.1,.01,.65,.43]
minlat = 0
if plotguvi then begin
    loc = where(glat le minlat)
    gx = (90.0 + glat(loc))*cos((glon(loc)+utrot)*!pi/180.-!pi/2.)
    gy = (90.0 + glat(loc))*sin((glon(loc)+utrot)*!pi/180-!pi/2.)
endif

loc = where(clat le minlat)
cx = (90.0 + clat(loc))*cos((clon(loc)+utrot)*!pi/180.-!pi/2.)
cy = (90.0 + clat(loc))*sin((clon(loc)+utrot)*!pi/180-!pi/2.)

loc = where(slat le minlat)
sx = (90.0 + slat(loc))*cos((slon(loc)+utrot)*!pi/180.-!pi/2.)
sy = (90.0 + slat(loc))*sin((slon(loc)+utrot)*!pi/180-!pi/2.)

mr = 90-minlat
plot, [-mr, mr], [-mr, mr], pos=pos, $
  xstyle=5, ystyle=5,/nodata,/noerase, $
  title= 'South'

if plotguvi then oplot,gx,gy,psym=1
oplot,cx,cy,psym=2
oplot,sx,sy,psym=4
xyouts,cx(0)+5,cy(0)-0,'S',/data
xyouts,gx(0)+5,gy(0)+5,'S',/data

plotmlt,mr

legend,['GUVI','Champ','Saber'],psym=[1,2,4],box=0,pos=[.8,.9],$
  /norm

closedevice
end
