reread = 1
if (n_elements(GitmNO) gt 0) then begin
    answer = ask('whether to re-read data','n')
    if (strpos(mklower(answer),'n') gt -1) then reread = 0
endif


if (reread) then begin

    if (n_elements(dir) eq 0) then dir = '.'
    dir = ask('gitm directory',dir)
    filelist = file_search(dir+'/snoe*.bin')

    file = filelist(0)
    length = strpos(file,'.bin')
    ls = length-13
    
    yr = strmid(file,ls,2)
    iYear = tostr(2000+fix(yr))
    iMonth = strmid(file,ls+2,2)
    iDay = strmid(file,ls+4,2)
    
    snoedir = '/data6/Data/SNOE/'+tostr(iyear)+'/'
    doy = jday(fix(iyear), fix(imonth), fix(iday))
    ndays = 1

    thermo_readsat, filelist, data, gtime, nTimes, Vars, nAlts, nSats, nTimes

    itimearray = intarr(6,ntimes)
    GitmAlts = reform(data(0,0,2,*))/1000.0
    GitmNO  = reform(data(0,*,8,*))
    GitmLons = reform(data(0,*,0,*))*180.0/!pi
    GitmLats = reform(data(0,*,1,*))*180.0/!pi

    c_r_to_a, itime, gtime(0)
    itime(3:5) = 0
    ndays = round((gtime(ntimes-1)-gtime(0))/3600. /24.)
    c_a_to_r, itime, basetime
    hour = (gtime/3600.0 mod 24.0) + fix((gtime-basetime)/(24.0*3600.0))*24.0
    localtime = (reform(GitmLons(*,0))/15.0 + hour) mod 24.0
    days = intarr(ndays)
    months = intarr(ndays)
    oldday = 0
    iday = 0
    for itime = 0L, ntimes - 1 do begin
        c_r_to_a, ta, gtime(itime)
        itimearray(*,itime) = ta

        if oldday ne itimearray(2,itime) then begin
            if iday eq ndays then begin
                ndays = ndays + 1
                days = [days,0]
            endif
            days(iday) = itimearray(2,itime)
            months(iday) = itimearray(1,itime)
            iday = iday + 1
           
        endif
        oldday = itimearray(2,itime)
        
    endfor

        
 

    for cday = 0, ndays - 1 do begin
        trold = 0
        today = days(cday)
        advanced = 0
        
        day = days(cday)
        month = months(cday)
        read_snoe, iyear, month, day, noden, slats, slons, salts, sut, nsorbs, nslats,julday
        nsorbs = nsorbs - 1
        nsalts = n_elements(salts(0,*))
        npts = nsorbs*nslats*ndays
        if cday eq 0 then begin
            SnoeLats = fltarr(ndays,nsorbs,nslats)
            SnoeLons = fltarr(ndays,nsorbs,nslats)
            SnoeNO = fltarr(ndays,nsorbs,nslats,nsalts)
            SnoeTime  = dblarr(ndays,nsorbs,nslats)
            SnoeLocalTime=fltarr(ndays,nsorbs,nslats)
            SnoeAlts = fltarr(ndays,nsorbs,nsalts)
            srtime = dblarr(ndays,nsorbs,nslats)
        endif
        
        SnoeNO(cday,*,*,*) = noden(0:nsorbs-1,*,*)
        SnoeLats(cday,*,*) = slats(0:nsorbs-1,*)
        SnoeLons(cday,*,*) = slons(0:nsorbs-1,*)
        SnoeAlts(cday,*,*) = salts(0:nsorbs-1,*)

        SnoeTime(cday,*,*) = sut(0:nsorbs-1,*)

        for iorb = 0, nsorbs - 1 do begin
            for ilat = 0, nslats-1 do begin      
                hour = fix(snoetime(cday,iorb,ilat)/3600.)
                min = fix((snoetime(cday,iorb,ilat)/3600.-hour)*60.)
                sec =fix(((snoetime(cday,iorb,ilat)/3600.-hour)*60.-min)*60) 
                c_a_to_r,[iyear,months(cday),today,hour,min,sec],tr
                if snoetime(cday,iorb,ilat) lt 0 then tr = -999
                if tr lt trold and not advanced and snoetime(cday,iorb,ilat) gt 0 then begin
                    today = today + 1
                    advanced = 1
                    c_a_to_r,[iyear,months(cday),today,hour,min,sec],tr
                endif
                
                srtime(cday,iorb,ilat) = tr
               
            endfor
        endfor
    endfor
endif

meant = fltarr(ndays,nsorbs)
for iday = 0, ndays - 1 do begin
    for iorb = 0, nsorbs - 1 do begin
        thistime = reform(SnoeTime(iday,iorb,*))
        locs = where(thistime ne -999)
        meant(iday,iorb) = mean(thistime)
    endfor
endfor

if n_elements(palt) eq 0 then palt = 0
display,snoealts(0,0,*)
palt = fix(ask('which altitude to plot for lat-time plot: ',tostr(palt)))

if n_elements(plat) eq 0 then plat = 0
display,SnoeLats(0,0,*)
plat = fix(ask('which altitude to plot for alt-time plot: ',tostr(plat)))


;for lat-time contours we need no(nlats,ntimes)
SnoeNOlat = fltarr(nsorbs*ndays,nslats)
SnoeNOalt = fltarr(nsorbs*ndays,nsalts)
SnoeTl = fltarr(nsorbs*ndays,nslats)
SnoeTa = fltarr(nsorbs*ndays,nsalts)
SnoeLat = fltarr(nsorbs*ndays,nslats)
SnoeAlt = fltarr(nsorbs*ndays,nsalts)
isnoe = 0
stimefound = 0
for iday = 0, ndays - 1 do begin
    trold = 0
    today = days(iday)
    advanced = 0
    for iorb = 0, nsorbs - 1 do begin
        snoenolat(isnoe,*) = snoeno(iday,iorb,*,palt)
        snoenoalt(isnoe,*) = snoeno(iday,iorb,plat,*)
        
        hour = fix(meant(iday,iorb)/3600.)
        min = fix((meant(iday,iorb)/3600.-hour)*60.)
        sec =fix(((meant(iday,iorb)/3600.-hour)*60.-min)*60) 
        c_a_to_r,[iyear,months(iday),today,hour,min,sec],tr
        for ilat = 0, nslats-1 do begin
            
            if not stimefound and snoetime(iday,iorb,ilat) gt 0 then begin
                stimefound = 1
                stime = tr
            endif
           
            if tr lt trold and not advanced and snoetime(iday,iorb,ilat) gt 0 then begin
                today = today + 1
                advanced = 1
                c_a_to_r,[iyear,months(iday),today,hour,min,sec],tr
            endif
            SnoeTl(isnoe,ilat) = tr
            trold = tr
            SnoeLat(isnoe,ilat) = SnoeLats(iday,iorb,ilat)
         
        endfor
        SnoeTa(isnoe,*) = tr

        for ialt = 0, nsalts - 1 do begin
            SnoeAlt(isnoe,ialt) = SnoeAlts(iday,iorb,ialt)
        endfor
        isnoe = isnoe + 1
    endfor
endfor

;sloc =  min(where(snoeTime gt 0))
c_r_to_a,ta,stime
c_a_to_r,[ta(0),ta(1),ta(2),0,0,0],stime
etime = max(SnoeTl)

ntimes = n_elements(SnoeTl)
itimearr = intarr(6,ntimes)
itime = 0L


for iorb = 0, nsorbs*ndays - 1 do begin
    for ilat = 0, nslats - 1 do begin
        c_r_to_a,ta,SnoeTl(iorb,ilat)
        itimearr(*,itime) = ta
        itime = itime + 1

    endfor
endfor

;;;; GITM stuff
GITMNOlat = fltarr(nsorbs*ndays,nslats)
GITMNOalt = fltarr(nsorbs*ndays,nsalts)
GITMlat = fltarr(nsorbs*ndays,nslats)
GITMlon = fltarr(nsorbs*ndays,nslats)
timeold = -999
ipt = 0
for iday = 0, ndays - 1 do begin
    for iorb = 0, nsorbs - 1 do begin
        for ilat = 0, nslats - 1 do begin
            lat = snoelats(iday,iorb,ilat)
            lon = snoelons(iday,iorb,ilat)
            time = srtime(iday,iorb,ilat)
            
            if time ne -999 then begin
                minsec = min(abs(srtime(iday,iorb,ilat) - gtime),imin)
                alth = min(where(gitmalts - snoealts(iday,iorb,palt) gt 0))
                altl = alth - 1
                r = (gitmalts(alth) - snoealts(iday,iorb,palt))/ $
                  (gitmalts(alth)-gitmalts(altl))
                
                GITMNOlat(ipt,ilat) = GITMNO(imin,alth) - $
                  r*(GITMNO(imin,alth) - GITMNO(imin,altl))
                GITMlat(ipt,ilat) = GITMlats(imin,0)
                GITMlon(ipt,ilat) = GITMlons(imin,0)
                if ilat eq plat then begin
                    for ialt = 0, nsalts - 1 do begin
                        alt = snoealts(iday,iorb,ialt)
                        
                        if alt ge 100.0 then begin
                            alth = min(where(gitmalts - alt gt 0))
                            altl = alth - 1
                            r = (gitmalts(alth) - alt)/ $
                              (gitmalts(alth)-gitmalts(altl))
                            GITMNOalt(ipt,ialt) =  GITMNO(imin,alth) - $
                              r*(GITMNO(imin,alth) - GITMNO(imin,altl))

                        endif else begin
                            GITMNOalt(ipt,ialt) = 0.0
                        endelse
                    endfor
                endif
            endif else begin
                
                GITMNOlat(ipt,ilat) = 0.0
            endelse
        endfor
        ipt = ipt + 1
    endfor
endfor      

time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
locs = where(snoenolat gt 1)
locsg = where(gitmnolat gt 1)
minv = min([snoenolat(locs),gitmnolat(locsg)],max=maxv)

locs = where(snoenolat gt 1 and snoetl gt 0 and snoelat gt 0)
 levels = findgen(31) * (maxv-minv) / 30 + minv

setdevice,'plot.ps','l',5,.95
ppp = 2
space = 0.02
pos_space, ppp, space, sizes, ny = ppp

get_position, ppp, space, sizes, 0, pos, /rect
pos(0) = pos(0) + 0.05
pos(2) = pos(2) - 0.05

get_position, ppp, space, sizes, 1, pos2, /rect
pos2(0) = pos2(0) + 0.05
pos2(2) = pos2(2) - 0.05
 loadct, 39
contour, snoenolat,SnoeTl-stime,SnoeLat,/fill,  $
  levels = levels,xtickv=xtickv,xtickname = strarr(10) + ' ',$
  xticks=xtickn,xminor=xminor,ytitle='Latitude',$
  title='NO Density at '+chopl(tostr(SnoeAlt(0,palt)),5)+' km',$
  charsize=1.2,xrange = [0,etime-stime],pos = pos,/noerase,ystyle=1,xstyle=1
  
contour, GITMnolat,snoeTl-stime,snoelat,/fill,  $
  levels = levels, xtitle=xtitle,xtickv=xtickv,xtickname = xtickname,$
  xticks=xtickn,xminor=xminor,ytitle='Latitude',$
  charsize=1.2,xrange = [0,etime-stime],pos = pos2,/noerase,ystyle=1,xstyle=1

ctpos = [pos(2)+0.01,pos(1),pos(2)+0.03,pos(3)]
maxmin = mm(levels)
title = 'SNOE [NO] #/m!U3!N'
plotct,254,ctpos,maxmin,title,/right,color=color

ctpos = [pos2(2)+0.01,pos2(1),pos2(2)+0.03,pos2(3)]
maxmin = mm(levels)
title = 'GITM [NO] #/m!U3!N'
plotct,254,ctpos,maxmin,title,/right,color=color


plotdumb


locs = where(snoenoalt gt 1)
locsg = where(gitmnoalt gt 1)
minv = min([snoenoalt(locs),gitmnoalt(locsg)],max=maxv)

locs = where(snoenoalt gt 1 and snoetl gt 0 and snoealt gt 0)
 levels = findgen(31) * (maxv-minv) / 30 + minv
contour, snoenoalt,SnoeTa-stime,SnoeAlt,/fill,  $
  levels = levels,xtickv=xtickv,xtickname = strarr(10) + ' ',$
  xticks=xtickn,xminor=xminor,ytitle='Altitude',$
  title='NO Density at '+chopl(tostr(SnoeLat(0,plat)),5)+'!Uo!N Latitude',$
  charsize=1.2,xrange = [0,etime-stime],pos = pos,/noerase,ystyle=1,xstyle=1,yrange = [100,150]
  
contour, GITMnoalt,snoeTa-stime,snoealt,/fill,  $
  levels = levels, xtitle=xtitle,xtickv=xtickv,xtickname = xtickname,$
  xticks=xtickn,xminor=xminor,ytitle='Altitude',$
  charsize=1.2,xrange = [0,etime-stime],pos = pos2,/noerase,ystyle=1,xstyle=1,yrange = [100,150]

ctpos = [pos(2)+0.01,pos(1),pos(2)+0.03,pos(3)]
maxmin = mm(levels)
title = 'SNOE [NO] #/m!U3!N'
plotct,254,ctpos,maxmin,title,/right,color=color

ctpos = [pos2(2)+0.01,pos2(1),pos2(2)+0.03,pos2(3)]
maxmin = mm(levels)
title = 'GITM [NO] #/m!U3!N'
plotct,254,ctpos,maxmin,title,/right,color=color


closedevice

end
