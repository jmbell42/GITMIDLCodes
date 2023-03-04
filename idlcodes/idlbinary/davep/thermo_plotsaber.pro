reread = 1
if (n_elements(gval) gt 0) then begin
    answer = ask('whether to re-read data','n')
    if (strpos(mklower(answer),'n') gt -1) then reread = 0
endif

if (reread) then begin

    if (n_elements(dir) eq 0) then dir = '.'
    dir = ask('GITM directory',dir)

    filelist = file_search(dir+'/sabe*.bin')
    
    file = filelist(0)
    length = strpos(file,'.bin')
    ls = length-13
    
    yr = strmid(file,ls,2)
    iYear = tostr(2000+fix(yr))
    iMonth = strmid(file,ls+2,2)
    iDay = strmid(file,ls+4,2)
    cday = iday

    ndays = 1
 thermo_readsat, filelist, data, time, nTimes, Vars, ngAlts, nSats, nTimes

  
    GitmAlts = reform(data(0,0,2,*))/1000.0
    GITMD = fltarr(5,ngalts,ntimes)
    GitmD(0,*,*) = transpose(reform(data(0,*,8,*)))
    GitmD(1,*,*) = transpose(reform(data(0,*,5,*)))
    GitmD(2,*,*) = transpose(reform(data(0,*,15,*)))
    GitmD(3,*,*) = transpose(reform(data(0,*,3,*)))
    GitmD(4,*,*) = transpose(reform(data(0,*,5,*)))
    gvars = strarr(5)
    gvars(0) = '[NO]'
    gvars(1) = '[O2]'
    gvars(2) = 'Temperature'
    gvars(3) = 'Rho'
    gvars(4) = '[O2]'
    
    GitmLons = reform(data(0,*,0,0))*180.0/!pi
    GitmLats = reform(data(0,*,1,0))*180.0/!pi

     itimearray = intarr(6,ntimes)    
     gsza = fltarr(ntimes)
    for itime =0, ntimes - 1 do begin
        c_r_to_a,ta,time(itime)
        itimearray(*,itime) = ta
        syear  = tostr(itimearray(0))
        smonth = chopr('0'+tostr(itimearray(1)),2)
        sday = chopr('0'+tostr(itimearray(2)),2)
        sdate = syear+'-'+smonth+'-'+sday
        ut = itimearray(3)+itimearray(4)/60.+itimearray(5)/3600.
        lat = gitmlats(itime)
        lon = gitmlons(itime)
        zsun,sdate,ut,lat,lon,zenith,azimuth,solfac
        gsza(itime) = zenith
    endfor
    c_r_to_a, itime, time(0)
    itime(3:5) = 0
    ndays = round((time(ntimes-1)-time(0))/3600. /24.)

    c_a_to_r, itime, basetime
    hour = (time/3600.0 mod 24.0) + fix((time-basetime)/(24.0*3600.0))*24.0
    localtime = (reform(GitmLons(*,0))/15.0 + hour) mod 24.0
    
    bdoy = jday(fix(iyear),fix(imonth),fix(cday))
    edoy = bdoy + ndays - 1
    iline = 0
    malts = 0
    for iday = 0, ndays -1 do begin
        doy = bdoy + iday
        td = fromjday(fix(iyear),doy)
        date = iyear+chopr('0'+tostr(td(0)),2)+chopr('0'+tostr(td(1)),2)
        print, 'Getting SABER data: '+date+' ...'
        read_saber,date,tdata,sz,stime,saltitude,svars
   
        if iday eq 0 then begin
            maxalts = 400
            maxlines  = 10000
            nvars = n_elements(svars)
            sdata = fltarr(nvars,maxalts,maxlines)
            salt = fltarr(maxalts,maxlines)
            sza = fltarr(maxlines)
            sabtime = fltarr(maxalts,maxlines)
        endif 

        nlines = n_elements(saltitude(0,*))
        nalts = n_elements(saltitude(*,0))
        
        sdata(*,0:nalts-1,iline:iline+nlines-1) = tdata
        sza(iline:iline+nlines-1) = sz
        salt(0:nalts-1,iline:iline+nlines-1) = saltitude
        sabtime(0:nalts-1,iline:iline+nlines-1) = stime
        iline = iline+nlines
        if nalts gt malts then malts = nalts
    endfor
    nlines = iline
    
    sdata = sdata(*,0:malts-1,0:nlines-1)
    salt = salt(0:malts-1,0:nlines-1)
    sza = sza(0:nlines-1)
    sabtime = sabtime(0:malts-1,0:nlines-1)
    times = intarr(nlines)
    
   for iline = 0, nlines-1 do begin
        dt =  sabtime(0,iline) - time
        loc = min(where(dt lt 0),imin)
        if loc gt 0 then begin
            minv = min([abs(dt(loc)),abs(dt(loc-1))],im)
            if im eq 1 then loc = loc-1
        endif
        if loc lt 0 then loc = ntimes-1
        
        times(iline) = loc

    endfor
    ntimes = nlines
    gitmd = gitmd(*,*,times)
    gitmlons = gitmlons(times)
    gitmlats = gitmlats(times)
    time = time(times)
    gsza = gsza(times)
endif

display,svars
if n_elements(pvar) eq 0 then pvar = 0
pvar = fix(ask('which variable to plot: ', tostr(pvar)))

alt = findgen(11)*5+100
display,alt
if n_elements(palt1) eq 0 then palt1 = 0
if n_elements(palt2) eq 0 then palt2 = 0
palt1 = fix(ask('1st altitude to plot: ',tostr(palt1)))
palt2 = fix(ask('2nd altitude to plot: ',tostr(palt2)))
alocs1 = where(salt(*,0) ge alt(palt1)-2.5 and salt(*,0) lt alt(palt1)+2.5)
alocs2 = where(salt(*,0) ge alt(palt2)-2.5 and salt(*,0) lt alt(palt2)+2.5)

if n_elements(islog) eq 0 then islog = 'y'
islog = ask('whether to plot log: ',islog)

stime = time(0)
etime = max(time)
time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn

time2d = dblarr(ngalts,ntimes)
galts2d = time2d

stime2d = dblarr(nalts,nlines)

for itime = 0, ntimes-1 do begin
    time2d(*,itime) = time(itime)
    galts2d(*,itime) = gitmalts
endfor
nflares = 2
 rft = dblarr(nflares)
;ftime = [2003,11,02,17,15,0]
ftime = [2005,9,7,17,25,0]
c_a_to_r,ftime,rt
rft(0) = rt
;ftime = [2003,11,4,19,40,0]
ftime = [2005,9,9,19,35,0]
c_a_to_r,ftime,rt
rft(1)=rt



sval = reform(sdata(pvar,*,*))
gval = reform(gitmD(pvar,*,*))

xrange = [0,etr]
file = 'saber_'+svars(pvar)+'_'+iyear+imonth+cday+'.ps'
setdevice,file,'p',5,.95
loadct, 39
ppp = 9
space = 0.01
pos_space, ppp, space, sizes, ny = ppp
get_position, ppp, space, sizes, 0, pos, /rect
get_position, ppp, space, sizes, 1, pos1, /rect
pos(0) = pos(0) + 0.1
pos(2) = pos(2) - .1
pos(1) = pos1(1)
loadct, 39

locs = where(sval gt 0 and salt ge 100 and salt le 150)

talt = min(where(gitmalts gt 150))
if islog then begin
    svalp = alog10(sval)
    gvalp = alog10(gval)
endif else begin
    svalp = sval
    gvalp = gval
endelse
srange = mm(svalp(locs))
grange = mm(gvalp(0:talt-1,*))
slevels = findgen(31) * (srange(1)-srange(0)) / 30 + srange(0)
glevels = findgen(31) * (grange(1)-grange(0)) / 30 + grange(0)

yrange = [100,150]

contour,svalp,sabtime-stime,salt,xtickname=strarr(10)+' ',xticks=xtickn,xtickv=xtickv,$
  xminor=xminor,xrange=xrange,pos=pos,ytitle='Altitude',levels=slevels,$
  yrange=yrange,/noerase,/fill
for ifl = 0, nflares -1 do begin
    oplot, [rft(ifl)-1,rft(ifl)+1]-stime,[0,6e20],linestyle = 2
endfor

ctpos = pos
if islog eq 'y' then title = 'Log '+svars(pvar) else title = svars(pvar)
ctpos(0) = pos(2)+0.025
ctpos(2) = ctpos(0)+0.03
maxmin = srange
plotct, 255, ctpos, maxmin, title, /right

get_position, ppp, space, sizes, 2, pos, /rect
get_position, ppp, space, sizes, 3, pos1, /rect
pos(0) = pos(0) + 0.1
pos(2) = pos(2) - .1
pos(1) = pos1(1)

contour,gvalp,time2d-stime,galts2d,xtickname=strarr(10)+' ',xticks=xtickn,xtickv=xtickv,$
  xminor=xminor,xrange=xrange,pos=pos,ytitle='Altitude',levels=glevels,$
  yrange=yrange,/noerase,/fill
for ifl = 0, nflares -1 do begin
    oplot, [rft(ifl)-1,rft(ifl)+1]-stime,[0,6e20],linestyle = 2
endfor

ctpos = pos
if islog eq 'y' then title = 'Log '+gvars(pvar) else title = gvars(pvar)
ctpos(0) = pos(2)+0.025
ctpos(2) = ctpos(0)+0.03
maxmin = grange
plotct, 255, ctpos, maxmin, title, /right

gp = fltarr(ntimes)
;gsz = fltarr(ntimes)
for itime = 0, ntimes - 1 do begin
    loc = min(where(GitmAlts gt alt(palt2)))
     
      x = (alt(palt2) - GitmAlts(loc-1)) / $
          (GitmAlts(loc) - GitmAlts(loc-1))

      if pvar eq 0 or pvar eq 1 or pvar eq 3 or pvar eq 4 then $
        gp(iTime) = exp((1.0 - x) * alog(GitmD(pvar,loc-1,iTime)) + $
                         (      x) * alog(GitmD(pvar,loc,iTIme))) $
      else $
        gp(iTime) = (1.0 - x) * (GitmD(pvar,loc-1,iTime)) + $
                         (      x) * (GitmD(pvar,loc,iTIme))

      
  endfor

get_position, ppp, space, sizes, 4, pos, /rect
pos(0) = pos(0) + 0.1
pos(2) = pos(2) - .1

szamin = min(sza) 
sp2 = fltarr(nlines)
for iline = 0, nlines - 1 do begin
        sp2(iline) = mean(sval(alocs1,iline))
endfor

szlcs = where(sza lt szamin+20)   
    
yrange = mm(sp2(szlcs))
yrange(0) = .9*yrange(0)
yrange(1) = 1.1*yrange(1)
yrange(0) = 0
plot,sabtime(0,szlcs)-stime,sp2(szlcs),psym=sym(1),xtickv=xtickv,xticks=xtickn,$
  xtickname=strarr(10)+' ',xminor=xminor,ytitle = svars(pvar)+'!C('+tostr(alt(palt1))+' km)',/noerase,symsize=.5,$
  pos=pos,ystyle=8,yrange = yrange,xrange=xrange
for ifl = 0, nflares -1 do begin
    oplot, [rft(ifl)-1,rft(ifl)+1]-stime,[0,6e20],linestyle = 2
endfor

yrange = mm(gp(szlcs))
yrange(0) = .9*yrange(0)
yrange(1) = 1.1*yrange(1)
axis,yaxis=1,yrange=yrange,ystyle=1,ytitle=gvars(pvar),/save
oplot,time(szlcs)-stime,gp(szlcs),psym=sym(5),symsize=.5,color=60

for itime = 0, ntimes - 1 do begin
    loc = min(where(GitmAlts gt alt(palt1)))
     
      x = (alt(palt1) - GitmAlts(loc-1)) / $
          (GitmAlts(loc) - GitmAlts(loc-1))

      if pvar eq 0 or pvar eq 1 or pvar eq 3 or pvar eq 4 then $
        gp(iTime) = exp((1.0 - x) * alog(GitmD(pvar,loc-1,iTime)) + $
                         (      x) * alog(GitmD(pvar,loc,iTIme))) $
      else $
        gp(iTime) = (1.0 - x) * (GitmD(pvar,loc-1,iTime)) + $
                         (      x) * (GitmD(pvar,loc,iTIme))

      
  endfor


get_position, ppp, space, sizes, 5, pos, /rect
pos(0) = pos(0) + 0.1
pos(2) = pos(2) - .1

szamin = min(sza) 
sp2 = fltarr(nlines)
for iline = 0, nlines - 1 do begin
        sp2(iline) = mean(sval(alocs2,iline))
endfor

szlcs = where(sza lt szamin+20)
yrange = mm(sp2(szlcs))
yrange(0) = .9*yrange(0)
yrange(1) = 1.1*yrange(1)
yrange(0) = 0
plot,sabtime(0,szlcs)-stime,sp2(szlcs),psym=sym(1),xtickv=xtickv,xticks=xtickn,$
  xtickname=strarr(10)+' ',xminor=xminor,ytitle = svars(pvar)+'!C('+tostr(alt(palt2))+ ' km)',/noerase,symsize=.5,$
  pos=pos,ystyle=8,yrange= yrange,xrange=xrange
for ifl = 0, nflares -1 do begin
    oplot, [rft(ifl)-1,rft(ifl)+1]-stime,[0,6e20],linestyle = 2
endfor

yrange = mm(gp(szlcs))
yrange(0) = .9*yrange(0)
yrange(1) = 1.1*yrange(1)
axis,yaxis=1,yrange=yrange,ystyle=1,ytitle=gvars(pvar),/save
oplot,time(szlcs)-stime,gp(szlcs),psym=sym(5),symsize=.5,color=60

get_position, ppp, space, sizes, 6, pos, /rect
pos(0) = pos(0) + 0.1
pos(2) = pos(2) - .1

plot,sabtime(0,szlcs)-stime,sza(szlcs),psym=sym(1),xtickv=xtickv,xticks=xtickn,$
  xtickname=strarr(10)+' ',xminor=xminor,ytitle = 'SZA',/noerase,symsize=.5,$
  pos=pos,xrange=xrange
legend,['SABER'],psym=[sym(1)],color=[0],box=0,$
  pos = [pos(2)+.006,pos(3)-.04],  /norm,symsize=.5
legend,['GITM'],psym=[sym(5)],color=[60],box=0,$
  pos = [pos(2)+.006,pos(3)-.06],  /norm,symsize=.5
for ifl = 0, nflares -1 do begin
    oplot, [rft(ifl)-1,rft(ifl)+1]-stime,[0,6e20],linestyle = 2
endfor

readdst,iyear,dst,dsttime
dlocs = where(dsttime ge stime and dsttime le etime)
get_position, ppp, space, sizes, 7, pos, /rect
pos(0) = pos(0) + 0.1
pos(2) = pos(2) - .1
plot,dsttime(dlocs)-stime,dst(dlocs),ytitle='Dst (nT)',/noerase,pos=pos,$
  xtickv=xtickv,xticks=xtickn,xrange=xrange,$
  xtickname=strarr(10)+' ',xminor=xminor,yrange = [-200,100]
for ifl = 0, nflares -1 do begin
    oplot, [rft(ifl)-1,rft(ifl)+1]-stime,[-600,600],linestyle = 2
endfor


readkp,iyear,kp,kptime
klocs = where(kptime ge stime and kptime le etime)
get_position, ppp, space, sizes, 8, pos, /rect
pos(0) = pos(0) + 0.1
pos(2) = pos(2) - .1
plot,kptime(klocs)-stime,kp(klocs),ytitle='Kp',/noerase,pos=pos,$
  xtickv=xtickv,xticks=xtickn,xrange=xrange,$
  xtickname=xtickname,xminor=xminor,xtitle=xtitle,yrange = [0,9]
for ifl = 0, nflares -1 do begin
    oplot, [rft(ifl)-1,rft(ifl)+1]-stime,[0,6e20],linestyle = 2
endfor

closedevice


end
        
