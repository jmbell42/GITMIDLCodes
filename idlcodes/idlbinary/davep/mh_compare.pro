;;;;;;;;;;;;; MILLSTONE STUFF ;;;;;;;;;;;;;;;;;;;;;;;;


GetNewData = 1

filelist_new = file_search("pfi*.bin")
nfiles_new = n_elements(filelist_new)

if n_elements(nfiles) gt 0 then begin
    if (nfiles_new eq nfiles) then default = 'n' else default='y'
    GetNewData = mklower(strmid(ask('whether to reread data',default),0,1))
    if (GetNewData eq 'n') then GetNewData = 0 else GetNewData = 1
endif

if (GetNewData) then begin
    print, 'Getting Millstone Data...'    
    readmh, filelist_new, mhdata, mhrtime, n_alts,datasize
endif

nFiles = n_elements(filelist_new)


 stime = min(mhrtime)
    etime = max(mhrtime)
    time_axis,  stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
    newtime = fltarr(n_alts,datasize)
    for i = 0, datasize - 1 do begin
        for j = 0, n_alts - 1 do begin
            newtime(j,i) = mhrtime(i)
        endfor
    endfor
   
    

;;;;;;;;;;;;;;;;; GITM STUFF ;;;;;;;;;;;;;;;;;;;;;;;
GetNewData = 1
fpi = 0
if n_elements(gitmdirectory) eq 0 then gitmdirectory = '~/Gitm/run/data/'
gitmdirectory = ask('GITM Directory: ',gitmdirectory)
gitmfiles = gitmdirectory + 'b0001_*.*ALL'
filelist_new = findfile(gitmfiles)
nfilesgitm_new = n_elements(filelist_new)

if n_elements(ngitmfiles) gt 0 then begin
    if (nfilesgitm_new eq ngitmfiles) then default = 'n' else default='y'
    GetNewData = mklower(strmid(ask('whether to reread data',default),0,1))
    if (GetNewData eq 'n') then GetNewData = 0 else GetNewData = 1
endif

if (GetNewData) then begin

    thermo_readsat, filelist_new, data, time, nTimes, Vars, nAlts, nSats, Files
    ngitmFiles = n_elements(filelist_new)

endif

if (nSats eq 1) then begin

    nPts = nTimes

    Alts = reform(data(0,0:nPts-1,2,0:nalts-1))/1000.0
    Lons = reform(data(0,0:nPts-1,0,0)) * 180.0 / !pi
    Lats = reform(data(0,0:nPts-1,1,0)) * 180.0 / !pi

    c_r_to_a, itime, time(0)
    itime(3:5) = 0
    c_a_to_r, itime, basetime
    hour = (time/3600.0 mod 24.0) + fix((time-basetime)/(24.0*3600.0))*24.0
    localtime = (Lons/15.0 + hour) mod 24.0
    
    angle = 23.0 * !dtor * $
      sin((jday(itime(0),itime(1),itime(2)) - jday(itime(0),3,21))*2*!pi/365.0)
    angle = 0
    sza =  acos(sin(angle)*sin(Lats*!dtor) + $
                cos(angle)*cos(Lats*!dtor) * $ 
                cos(!pi*(LocalTime-12.0)/12.0))

    t  = reform(data(0,0:nPts-1,4,0:nalts-1))

    ; o / n2 stuff
    o  = reform(data(0,0:nPts-1,5,0:nalts-1))
    o2 = reform(data(0,0:nPts-1,6,0:nalts-1))
    n2 = reform(data(0,0:nPts-1,7,0:nalts-1))
    n4s = reform(data(0,0:nPts-1,9,0:nalts-1))
    n = o + n2 + o2 + n4s
    k = 1.3807e-23
    mp = 1.6726e-27
    rho = o*mp*16 + o2*mp*32 + n2*mp*14
    data(0,0:nPts-1,3,0:nalts-1) = rho

    p = n*k*t
    oon  = o/n
    n2on = n2/n
    o2on = o2/n
    non = n4s/n

    oInt = fltarr(nPts)
    n2Int = fltarr(nPts)
    on2ratio = o/n2
    AltInt = fltarr(nPts)

    MaxValN2 = 1.0e21

    for i=0,nPts-1 do begin

        iAlt = nalts-1
        Done = 0
        while (Done eq 0) do begin
            dAlt = (Alts(i,iAlt)-Alts(i,iAlt-1))*1000.0
            n2Mid = (n2(i,iAlt) + n2(i,iAlt-1))/2.0
            oMid  = ( o(i,iAlt) +  o(i,iAlt-1))/2.0
            if (n2Int(i) + n2Mid*dAlt lt MaxValN2) then begin
                n2Int(i) = n2Int(i) + n2Mid*dAlt
                oInt(i)  =  oInt(i) +  oMid*dAlt
                iAlt = iAlt - 1
            endif else begin
                dAlt = (MaxValN2 - n2Int(i)) / n2Mid
                n2Int(i) = n2Int(i) + n2Mid*dAlt
                oInt(i)  =  oInt(i) +  oMid*dAlt
                AltInt(i) = Alts(i,iAlt) - dAlt/1000.0
                Done = 1
            endelse
        endwhile

    endfor

    re = 6372000.0
    r = re + Alts*1000.0
    g = 9.8 * (re/r)^2
    mp = 1.6726e-27
    k = 1.3807e-23
    mo = 16.0 * mp
    mo2 = mo*2.0

    t  = reform(data(0,0:nPts-1,4,0:nalts-1))

    o_scale_est  = k*t / (mo*g) / 1000.0
    o2_scale_est = k*t / (mo2*g) / 1000.0

    o_scale = o
    alogo = alog(o(*,1:nalts-1)/o(*,0:nalts-2))
    mini = 0.1
    loc = where(alogo ge -mini,count)
    if (count gt 0) then alogo(loc) = -mini
    o_scale(*,1:nalts-1) = - (Alts(*,1:nalts-1) - Alts(*,0:nalts-2))/$
      alogo
    o_scale(*,0) = o_scale(*,1)

    o2_scale = o2
    o2_scale(*,1:nalts-1) = -(Alts(*,1:nalts-1) - Alts(*,0:nalts-2))/$
      alog(o2(*,1:nalts-1)/o2(*,0:nalts-2))
    o2_scale(*,0) = o2_scale(*,1)

    d = Lats - Lats(0)
;    if (max(abs(d)) lt 1.0) then stationary = 1 else stationary = 0
    stationary = 1

    time2d = dblarr(nPts,nalts)
    for i=0,nPts-1 do time2d(i,*) = time(i)- time(0)
endif
;;;;;;;;;;; Plotting Stuff ;;;;;;;;;;;;;;;;;;;;;;;;

if (n_elements(whichvar) eq 0 ) then whichvar = 'ne'
whichvar = ask('Variable to plot (ne,ti,te,vi): ',whichvar)

case whichvar of
    'ne' : begin
        ivar = 19
        unit = '(m!E-3!N)'
    end
    'ti' : begin
        ivar = 21
        unit = '(K)'
    end
    'te' : begin
        ivar = 20
        unit = '(K)'
    end
    'vi' : begin
        ivar = 24
        unit = '(m/s)'
    end
endcase

;if ivar eq 19 then begin
;    mhdata.VAR = 10.^(mhdata.VAR)
;endif

vararray = mhdata.VAR
altarray = mhdata.ALTS

calcplot = 'n'
calcplot = ask('Recount? ',calcplot)

if calcplot eq 'y' then begin
    count = intarr(datasize)
    bincount = intarr(59)
    altbins = 100 + indgen(60)*5
    for i = 0, 58 do begin
        for j = 0, datasize - 1 do begin
            tgtemp = where(altarray(*,j) eq altarray(*,j) and $
                           altarray(*,j) gt altbins(i) and altarray(*,j) le $
                           altbins(i+1),tcount)
            count(j) = tcount
        endfor
        tgtemp = where(count gt 1,bc)    
        bincount(i) = bc
    endfor
    calcplot = 'no'
endif


for i = 0, 58 do begin
    print, '(',i,')  Alt range: ', altbins(i),' - ',altbins(i+1), $
      '  Count: ',bincount(i)
endfor

if (n_elements(whichalt1) eq 0) then whichalt1 = 0
if (n_elements(whichalt2) eq 0) then whichalt2 = 0
whichalt1 = fix(ask('Bin to plot? ',tostr(whichalt1)))
whichalt2 = fix(ask('Bin to plot? ',tostr(whichalt2)))


 value = reform(data(0,0:nPts-1,iVar,0:nalts-1))

loadct, 0
setdevice,'plot.ps','p',5,.95

ppp = 5
space = 0.01
pos_space, ppp, space, sizes, ny = ppp



for ii = 0, 1 do begin
    if ii eq 0 then whichalt = whichalt1 else whichalt = whichalt2
    timesgood = where(altarray eq altarray and altarray gt altbins(whichalt) $
                      and altarray le altbins(whichalt+1))
    
    miny = min(vararray(timesgood)) - .01*min(vararray(timesgood))
    maxy = max(vararray(timesgood)) + .01* max(vararray(timesgood))
    
;;;;; Data - results comparision stuff ;;;;;;
    
    title = vars(ivar) + ' at ' + tostr(altbins(whichalt)) + ' km vs. time'
    
    
    d = abs((altbins(whichalt)+altbins(whichalt+1))/2- reform(Alts(0,*)))
    loc = where(d eq min(d))
    iAlt1 = loc(0)
    
    if ivar eq 19 then begin
        logvalue = alog10(value)
        v = reform(logvalue(*, iAlt1))
    endif else v = reform(value(*,iAlt1))
    newmhtime = mhrtime(fix(timesgood/93.))
    newvararray = vararray(timesgood)
    npts = n_elements(newmhtime)
    stime = newmhtime(0)
    etime = newmhtime(npts-1)
;;;;;;Statistics ;;;;;;;;;;;;;;;;;;;
    
    gitmcompi = intarr(n_elements(timesgood))
    for i = 0, n_elements(timesgood)-1 do begin
        timediff = abs(time - newmhtime(i))
        mintimediff = min(timediff,imindiff)
        gitmcompi(i) = imindiff
    endfor
    
    if ivar eq 19 then begin
        vardiff = (10^v(gitmcompi) - 10^newvararray)^2
        rmsdata = (mean((10^newvararray)^2))^.5
    endif else begin
        vardiff = (v(gitmcompi) - newvararray)^2
        rmsdata = (mean((newvararray)^2))^.5
    endelse
    rmserror = mean(vardiff)^.5
    
    print, 'RMS Error is: ',rmserror
    print, 'RMS/data(RMS): ',rmserror/rmsdata
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    yrange = [miny,maxy]
    if ivar eq 19 then title = 'log!D10!N' else title = ''
    if ivar eq 21 then yrange = [500,1500]
    
    
    get_position, ppp, space, sizes, ii, pos, /rect
    
    pos(0) = pos(0) + 0.1
    
    time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
    
    if ii eq 0 then begin
        plot,[min(newmhtime),max(newmhtime)]-stime,[0,12],/nodata,/noerase,$
          ytitle = title+vars(ivar)+' '+unit, yrange = yrange,$
          xtickname = strarr(10)+' ',pos = pos, xtickv = xtickv, xminor = xminor, $
          xticks = xtickn,xstyle = 1, ystyle = 1,charsize = 1.3
    endif 
    if ii eq 1 and ivar eq 19 then begin
        plot,[min(newmhtime),max(newmhtime)]-stime,[0,12],/nodata,/noerase,$
          ytitle = title+vars(ivar)+' '+unit, yrange = yrange,$
          xtickname = strarr(10)+' ',pos = pos, xtickv = xtickv, xminor = xminor, $
          xticks = xtickn,xstyle = 1, ystyle = 1,charsize = 1.3
    endif
    if ii eq 1 and ivar ne 19 then begin
        plot,[min(newmhtime),max(newmhtime)]-stime,[0,12],/nodata,/noerase,$
          ytitle = vars(ivar)+' '+unit, yrange = yrange,xtitle = xtitle,$
          xtickname = xtickname,pos = pos, xtickv = xtickv, xminor = xminor, $
          xticks = xtickn,xstyle = 1, ystyle = 1,charsize = 1.3
        legend,['MH data','GITM'],colors = [130,0],linestyle = [0,2],$
          pos=[.035,.6],/norm
    endif
    
    if ii eq 0 then xyouts, pos(2) + .04,pos(1)+.06, '155 KM', $
      orientation = 90, /normal
    if ii eq 1 then xyouts, pos(2) + .04,pos(1)+.06, '245 KM', $
      orientation = 90, /normal
    i = 0
    j = 1
    
    while j lt npts do begin
        if (newmhtime(j) - newmhtime(j-1) gt 25000.) then begin
            oplot, newmhtime(i:j-1)-stime, newvararray(i:j-1),$
              thick = 1,color=130
            loc = where(time gt newmhtime(i) and time lt newmhtime(j-1),count)
            if count gt 1 then begin
                loc = [loc, max(loc+1)]
                oplot, time(loc)-stime,v(loc), color = 0,linestyle=2
                  thick = 3
            endif
            i = j
        endif
        j = j+1
    endwhile

;;;;;;;;;;;;;;;;This stuff is for comparing average values;;;;;;;;;;;;;;;;
avgarr = fltarr(28,2)
tarr = avgarr
minarr = avgarr
maxarr = avgarr
for ist = 1, 28 do begin

    ftime = [2005,09,ist,0,0,0]
    ltime = [2005,09,ist+1,0,0,0]
    
    c_a_to_r,ftime,frt
    c_a_to_r,ltime,lrt
    
    locs = where(newmhtime gt frt and newmhtime lt lrt)
    mhmax = max(newvararray(locs),imax)
    tmax = newmhtime(locs(imax))
    glocs = where(time ge frt and time le lrt)
    gmax = max(v(glocs),imax)
    gtmax = time(glocs(imax))
    c_r_to_a,mht,tmax
    c_r_to_a,gtt,gtmax

    avgarr(ist-1,*) = [mean(newvararray(locs)),mean(v(glocs))]
    tarr(ist-1,*) = [mht(3),gtt(3)]
    minarr(ist-1,*) = [min(newvararray(locs)),min(v(glocs))]
    maxarr(ist-1,*) = [max(newvararray(locs)),max(v(glocs))]
endfor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

endfor



;;; Hm-F2 stuff ;;;;
default = 'n'
if ivar eq 19 then default = 'y'

if default eq 'y' then begin
    donmf2 = 'n'
    donmf2 = ask('Do nmf2? ',donmf2)
    
    
    
    
    if donmf2 then begin
        tgcount = intarr(datasize)
        for j = 0, datasize - 1 do begin
            tgtemp2 = where(altarray(*,j) eq altarray(*,j) and $
                            altarray(*,j) gt 200 and altarray(*,j) le $
                            400 ,tcount)
            tgcount(j) = tcount 
        endfor
        
        hmf2times = where(tgcount gt 10)
        nptshm = n_elements(hmf2times)
        nmmhtime = mhrtime(hmf2times)
        nmf2 =fltarr(nptshm)
        hmf2 =fltarr(nptshm)
        
        for i = 0, n_elements(hmf2times)-1 do begin
            nmf2(i) = max(vararray(*,hmf2times(i)),ihmf2)
            hmf2(i) = altarray(ihmf2,hmf2times(i))
        endfor
        
        gitmnmf2 = fltarr(n_elements(time))
        gitmhmf2 = fltarr(n_elements(time))
        
        for i = 0, n_elements(time)-1 do begin
            gitmnmf2(i) = max(alog10(value(i,*)),igitmhmf2)
            gitmhmf2(i) = alts(i,igitmhmf2)
        endfor
        
get_position, ppp, space, sizes, 2, pos, /rect

pos(0) = pos(0) + 0.1

        i = 0
        j = 1
        ;setdevice,'othernm-f2.ps','l',5,.95    
        title = 'Nm-F2'
        yrange = [min(nmf2) - .01*min(nmf2),max(nmf2)+.01*max(nmf2)]
        
        plot,[min(nmmhtime),max(nmmhtime)]-stime,[0,12],/nodata,/noerase,$
          ytitle = 'log!D10!N'+vars(ivar)+' '+unit, yrange = yrange,pos = pos,$
          xtickname = strarr(10)+' ', xtickv = xtickv, xminor = xminor, $
          xticks = xtickn,xstyle = 1, ystyle = 1,charsize = 1.3
        while j lt nptshm do begin
            btdiff = nmmhtime(j) - nmmhtime(j-1)
            if (nmmhtime(j) - nmmhtime(j-1) gt 25000.) then begin
                
                oplot, nmmhtime(i:j-1)-stime, nmf2(i:j-1),thick = 1,color = 130
                loc = where(time gt nmmhtime(i) and time lt nmmhtime(j-1),count)
                if count gt 1 then begin
                    oplot, time(loc)-stime,gitmnmf2(loc), color = 0,$
                      linestyle=2, thick = 3
                endif
                i = j
            endif
            j = j+1
        endwhile
        xyouts, pos(2) + .04,pos(1)+.06, 'NmF2', $
          orientation = 90, /normal      


;;;;;;;;;;;;;;;;;;;STATS;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 gitmcompi = intarr(n_elements(gitmnmf2))
    for i = 0, n_elements(gitmnmf2)-1 do begin
        timediff = abs(time - nmmhtime(i))
        mintimediff = min(timediff,imindiff)
        gitmcompi(i) = imindiff
    endfor
    
    if ivar eq 19 then begin
        vardiff = (10^gitmnmf2(gitmcompi) - 10^nmf2)^2
        rmsdata = (mean((10^nmf2)^2))^.5
    endif else begin
        vardiff = (gitmnmf2(gitmcompi) - nmf2)^2
        rmsdata = (mean((nmf2)^2))^.5
    endelse
    rmserror = mean(vardiff)^.5
    
    print, 'RMS Error is of NMF2: ',rmserror
    print, 'RMS/data(RMS) of NMF2: ',rmserror/rmsdata
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_position, ppp, space, sizes, 3, pos, /rect

pos(0) = pos(0) + 0.1
        i = 0
        j = 1
        ;setdevice,'otherhm-f2.ps','l',5,.95    
        title = 'Hm-F2'
        yrange = [150,400]
        plot,[min(nmmhtime),max(nmmhtime)]-stime,[0,12],/nodata,/noerase,$
          ytitle = 'Altitude (km)', xtitle = xtitle,yrange = yrange,$
          xtickname = xtickname, xtickv = xtickv, xminor = xminor, $
          xticks = xtickn,xstyle = 1, ystyle = 1,charsize = 1.3,pos=pos
        while j lt nptshm do begin
            if (nmmhtime(j) - nmmhtime(j-1) gt 25000.) then begin
                oplot, nmmhtime(i:j-1)-stime, hmf2(i:j-1)$
                  ,thick = 1,color=130
                loc = where(time gt nmmhtime(i) and time lt nmmhtime(j-1),count)
                if count gt 1 then begin
                    oplot, time(loc)-stime,gitmhmf2(loc), color = 0,$
                      thick = 3,linestyle=2
                endif
                i = j
            endif
            j = j+1
        endwhile

        xyouts, pos(2) + .04,pos(1)+.06, 'HmF2', $
          orientation = 90, /normal
        legend,['MH data','GITM'],colors = [130,0],linestyle = [0,2],$
          pos=[.035,.2],/norm
       hcomp = intarr(n_elements(nmmhtime))
       for i = 0, n_elements(nmmhtime)-1 do begin
           htdiff = abs(time - nmmhtime(i))
           minhtdiff = min(htdiff,imindiff)
           hcomp(i) = imindiff
       endfor 
       hdiff = gitmhmf2(hcomp) - hmf2
       hdiffmean = mean(hdiff)
       ndiff = abs(10^gitmnmf2(hcomp)-10^nmf2)/(10^gitmnmf2(hcomp))
       ndiffmean = mean(ndiff)

;    setdevice,'tempnm-f2.ps','l',5,.95    
;    title = 'Nm-F2'
;    plot, mhrtime(hmf2times)-stime, nmf2,xtitle = xtitle,$
;      xtickname = xtickname, xtickv = xtickv, xminor = xminor, $
;      xticks = xtickn,xstyle = 1, ystyle = 1,charsize = 1.3,$
;      ytitle = vars(ivar),title = title,yrange = [10.5,12.5]
;    oplot, time-stime, gitmnmf2, color = 254
;    closedevice
;    
;    setdevice,'temphm-f2.ps','l',5,.95    
;    title = 'Hm-F2'
;    plot, mhrtime(hmf2times)-stime, hmf2,xtitle = xtitle,$
;      xtickname = xtickname, xtickv = xtickv, xminor = xminor, $
;      xticks = xtickn,xstyle = 1, ystyle = 1,charsize = 1.3,$
;      ytitle = 'Altitude of F2',title = title,yrange = [150,500]
;    oplot, time-stime, gitmhmf2, color = 254
;    closedevice

gitmnmf21d = gitmnmf2
gitmhmf21d = gitmhmf2
gtime1d = time
save,gitmnmf21d,gitmhmf21d,gtime1d
endif

endif 
closedevice


end



;nmf2 = fltarr((mhrtime(n_elements(mhrtime)-1) - mhrtime(0))/$
;              (60*60*24.))
;hmf2 = fltarr((mhrtime(n_elements(mhrtime)-1) - mhrtime(0))/$
;              (60*60*24.))
;mtime = fltarr((mhrtime(n_elements(mhrtime)-1) - mhrtime(0))/$
;              (60*60*24.))
;
;i = 0
;mhtime0 = mhrtime(hmf2times(0))
;for j = 0, n_elements(nmf2)-1 do begin
;    while mhrtime(hmf2times(i)) - mhtime0 lt (24.*60*60) do begin
;        nmtemp = max(vararray(*,hmf2times(i)),h)
;        if nmf2(j) lt nmtemp then begin
;            nmf2(j) = nmtemp
;            mtime(j) = mhrtime(hmf2times(i))
;            hmf2(j) = altarray(h,hmf2times(i))
;        endif
;        i = i + 1
;    endwhile
;    mhtime0 = mhrtime(hmf2times(i))
;endfor
;    
;
;gitmnmf2 = fltarr((time(n_elements(time)-1) - time(0))/$
;              (60*60*24.))
;gitmhmf2 = fltarr((time(n_elements(time)-1) - time(0))/$
;              (60*60*24.))
;gtime = fltarr((time(n_elements(time)-1) - time(0))/$
;              (60*60*24.)) 
;i=0
;gtime0 = time(0)
;for j = 0, n_elements(gitmnmf2) - 1 do begin
;    while time(i) - gtime0 lt (24.*60*60) do begin
;        gnmtemp = max(value(i,*),h)
;        if gitmnmf2(j) lt gnmtemp then begin
;            gitmnmf2(j) = gnmtemp
;            gtime(j) = time(i)
;            gitmhmf2(j) = alts(i,h)
;        endif
;        i = i + 1
;    endwhile
;    gtime0 = time(i-1)
;endfor
;
;
; setdevice,'nmf2.ps','l',5,.95    
; title = 'NmF2'
; plot, mtime-stime, nmf2,xtitle = xtitle,$
;   xtickname = xtickname, xtickv = xtickv, xminor = xminor, $
;   xticks = xtickn,xstyle = 1, ystyle = 1,charsize = 1.3,$
;   ytitle = vars(ivar),title = title,yrange = [11,12.5]
; oplot, gtime-stime, gitmnmf2, color = 254
;legend,['MH data','GITM'],colors = [0,254], psym = psym
; closedevice
;
; setdevice,'hmf2.ps','l',5,.95    
; title = 'HmF2'
; plot, mtime-stime, hmf2,xtitle = xtitle,$
;   xtickname = xtickname, xtickv = xtickv, xminor = xminor, $
;   xticks = xtickn,xstyle = 1, ystyle = 1,charsize = 1.3,$
;   ytitle = 'Altitude of F2',title = title,yrange = [150,400]
; oplot, gtime-stime, gitmhmf2, color = 254
;legend,['MH data','GITM'],colors = [0,254], psym = psym 
;closedevice
