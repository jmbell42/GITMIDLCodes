binbykp = 1
dt = 15. ;minutes

nMax = 20000
radardir = '/ifs1/Gitm/Radars/'
radars = file_search(radardir+'*')
display,radars
close,5
if n_elements(iradarfile) eq 0 then iradarfile = 0
iradarfile = fix(ask("radar file to plot: ",tostr(iradarfile)))

radarfile = file_search(radars(iradarfile)+'/*.txt')
if n_elements(radarfile) gt 0 then radarfile = radarfile(0)

len = strpos(radars(iradarfile),'/',/reverse_search)+1
whichfile = strmid(radars(iradarfile),len,4)
filelist = file_search(whichfile+'*.txt')
display, filelist
nfiles = n_elements(filelist)
if n_elements(ifile) eq 0 then ifile = 0
ifile = fix(ask("which file to plot: ",tostr(ifile)))

len = strpos(filelist(ifile),'_',/reverse_search)+1
l2 = strpos(filelist(ifile),'.',/reverse_search)

sea = strmid(filelist(ifile),len,l2-len)

;len = strmid
;sea = strmid(filelist(ifile),l,3)
if sea eq 'fall' then sea = 'Fall'
if sea eq 'spring' then sea = 'Spring'
if sea eq 'summer' then sea = 'Summer'
if sea eq 'winter' then sea = 'Winter'


temp = ' '
ntimes = 24.*60/dt
gtime = intarr(3,ntimes)
gdata = fltarr(4,ntimes)
gseasons = strarr(ntimes)
fn = filelist(ifile)

openr, 5, fn
readf, 5, temp

itime = 0
while not eof(5) do begin
    readf, 5, temp
    arr = strsplit(temp,/extract)
    gtime(*,itime) = arr(0:2)
    gdata(*,itime) = arr(3:*)
    itime = itime + 1
endwhile

close,5
openr, 5, radarfile
radtime = intarr(6,nMax)
raddata = fltarr(2,nMax)
KP = intarr(nMax)
seasons = strarr(nMax)
itime = 0
while not eof(5) do begin
    readf, 5, temp
    arr = strsplit(temp,/extract)
    year = fix(arr(0))
    doy = fix(arr(1))
    
    if doy gt 365 then begin
        doy = doy - 365
        year = year + 1
    endif
    ut = float(arr(2))
    hour = fix(ut)
    min = fix((ut - hour)*60.0)
    sec = fix((((ut - hour)*60.0)-min)*60.0)

    if year lt 2000 then year = 2000 + year

    date = fromjday(year,doy)
    it =[year,date(0),date(1),hour,min,sec] 
    kpt = get_kpvalue(it)
    case strtrim(kpt,2) of
       '0-': kpbin = 1
       '0' : kpbin = 1
       '0+': kpbin = 1
       '1-': kpbin = 1
       '1' : kpbin = 2
       '1+': kpbin = 2
       '2-': kpbin = 2
       '2' : kpbin = 3
       '2+': kpbin = 3
       '3-': kpbin = 3
       else:  kpbin = 4
       
    endcase 

    kp(itime) = kpbin

    c_a_to_r,it, rt
    radtime(*,itime) = [year,date(0),date(1),hour,min,sec]
    raddata(0,itime) = arr(3)
    raddata(1,itime) = arr(4)
    seasons(itime) = season(doy)

    itime = itime + 1

endwhile

locs = where(seasons eq sea)
radtime = reform(radtime(*,locs))
raddata = reform(raddata(*,locs))

nradtimes = n_elements(radtime(0,*))
radd = fltarr(4,ntimes)
radt = fltarr(ntimes)
for itime = 0, ntimes - 1 do begin
    hour = gtime(0,itime)
    mins = gtime(1,itime)
    lmin = mins - 7
    hmin = mins + 7

    if lmin lt 0 then lmin = 0
    if hmin gt 60 then hmin = 60

    radhours = where(radtime(3,*) eq hour)
    radmins = where(radtime(4,radhours) ge lmin and radtime(4,radhours) le hmin)
    

   radts = reform(radtime(*,radhours(radmins)))
    radd(0,itime) = mean(raddata(0,radhours(radmins)))
    radd(1,itime) = stddev(raddata(0,radhours(radmins)))
    radd(2,itime) = mean(raddata(1,radhours(radmins)))
    radd(3,itime) = stddev(raddata(1,radhours(radmins)))
    c_a_to_r,[2007,3,20,hour,mins,0],rt
    radt(itime) = rt
    
 endfor



title = whichfile+'_'+sea+'.ps'
setdevice,title,'p',5,.95
ppp = 4
space = 0.01
pos_space, ppp, space, sizes, ny = ppp
get_position, ppp, space, sizes, 0, pos0, /rect
get_position, ppp, space, sizes, 1, pos1, /rect
pos0(0) = pos0(0) + .1
pos1(0) = pos1(0) + .1
stime = 0
etime = 24*3601.
time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
xtickv = [0.0,21600.0,43200.0,64800.0,86400.0]
xtickn = 4
xtickname=['00','06','12','18','24']
loadct,39

xtitle = sea+' UT Hours'
xrange = [stime,etime]
yrange = [0,1e12]

plot,radt-radt(0),gdata(0,*),/nodata,xrange=xrange,yrange=yrange,xstyle=1,ystyle=1,$
  xtickname=strarr(10)+' ',xtickv=xtickv,xticks=xtickn,xminor=xminor,ytitle='NmF2 (m!U-3!N)',/noerase,$
  pos=pos0,charsize = 1.2
oplot, radt - radt(0),gdata(0,*),thick=3
oplot, radt - radt(0),radd(0,*),color = 254,thick=3

loadct,0
errplot,radt-radt(0),gdata(0,*)-gdata(1,*),gdata(0,*)+gdata(1,*),color=120
errplot,radt-radt(0),radd(0,*)-radd(1,*),radd(0,*)+radd(1,*),color=120

loadct,39
legend,['GITM',strupcase(whichfile)],color=[0,254],box=0,linestyle=0,pos=[pos0(2)-.2,pos0(3)-.02],/norm,$
  thick=3


yrange = [100,500]
plot,radt-radt(0),/nodata,xrange=xrange,yrange=yrange,xstyle=1,ystyle=1,$
  xtickname=xtickname,xtickv=xtickv,xticks=xtickn,xminor=xminor,ytitle='HmF2 (km)',/noerase,$
  pos=pos1,xtitle=xtitle,charsize = 1.2
oplot, radt - radt(0),gdata(2,*),thick=3
oplot, radt - radt(0),radd(2,*),color = 254,thick=3

loadct,0
errplot,radt-radt(0),gdata(2,*)-gdata(3,*),gdata(2,*)+gdata(3,*),color=120
errplot,radt-radt(0),radd(2,*)-radd(3,*),radd(2,*)+radd(3,*),color=120

closedevice


rmsavgn = sqrt(mean((gdata(0,*)-radd(0,*))^2))/sqrt(mean(radd(0,*)^2))
rmsavgh = sqrt(mean((gdata(1,*)-radd(1,*))^2))/sqrt(mean(radd(1,*)^2))
ccn = c_correlate(gdata(0,*),radd(0,*),0,/double)
cch = c_correlate(gdata(2,*),radd(2,*),0,/double)

print, "NRMS NmF2: ",rmsavgn, " CC NmF2: ", ccn
print, "NRMS HmF2: ",rmsavgh, " CC HmF2: ", cch

end
