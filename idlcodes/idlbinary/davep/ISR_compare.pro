GetNewData = 'y'

f = findfile("ISR._*.dat")
file = f(0)
nlines_new = file_lines(file) - 45

;Setup an empty array the specifies the altitude bins in 5km bins
;between 100 and 800km
AltBins = intarr((800 - 100)/5.)
nAltBins = n_elements(AltBins)
for iAlt = 0, nAltBins - 1 do begin
    AltBins(iAlt) = ((iAlt*5) + 100)
endfor

AltCount = intarr(nAltBins)
if n_elements(nlines) eq 0 then nlines = 0
if nlines_new eq nlines then begin
    GetNewData = 'n'
       GetNewData = ask('whether to reread data',GetNewData)
   ; if (GetNewData eq 'n') then GetNewData = 0 else GetNewData = 1
endif
nlines = nlines_new

if (GetNewData eq 'y') then begin
    print, 'Getting GITM results...'  
    read_isrfile, file, data, nVars, Variables, nSatPos, iTimeArr,$
      iError,nDT
    if iError lt 0 then return
endif
gtt = fltarr(n_elements(itimearr(0,*)))
for itime = 0, n_elements(itimearr(0,*))-1 do begin
    c_a_to_r,itimearr(*,itime),temp
    gtt(itime) = temp
endfor
ialtvar = where(Variables eq 'Altitude') 

for iAlt = 0, nAltBins - 2 do begin
    for iTime = 0, nDT - 1 do begin
        loc = where(data(ialtvar,*,iTime) ge AltBins(iAlt) and $
                    data(ialtVar,*,iTime) lt AltBins(iAlt+1),count)
       if count gt 1 then begin
           count = 1
           loc = loc(0)
       endif
        AltCount(iAlt) = AltCount(iAlt) + count
    endfor
endfor

if n_elements(showcount) ne 0 then begin
    showcount = ask('Show alt bin counts (y/n)?' , showcount)
endif else showcount = 'y'

if showcount eq 'y' then begin
    for iAlt = 0, nAltBins - 2 do begin
        if altcount(ialt) gt 0 then begin
            print, ialt,') ' ,tostr(altbins(ialt)), ' - ', $
              tostr(altbins(ialt+1)),'    ', AltCount(iAlt)
        endif
    endfor
endif

if n_elements(WhichAlt) eq 0 then WhichAlt = 1
WhichAlt = fix(ask('Which alt range to plot: ',tostr(whichalt)))

print, '1) Electron Density'
print, '2) Electron Temperature'
print, '3) Ion Temperature'
print, '4) Line of sight ion velocity'

if n_elements(whichvar) eq 0 then whichvar = 1
whichvar = fix(ask('which variable to print: ',tostr(whichvar)))

case whichvar of
    1: begin
        plotvar = where(variables eq '[e-]')
        unit = '(m!E-3!N)'
    end
    2: begin
        plotvar = where(variables eq 'eTemperature')
        unit = '(K)'
    end
    3: begin
        plotvar = where(variables eq 'iTemperature')
        unit = '(K)'
    end
    4: begin
        plotvar = where(variables eq 'Vi')
        plotvar = plotvar(2)
        unit = '(m/s)'
    end
endcase
plotloc = intarr(AltCount(WhichAlt))
gitmValue = fltarr(AltCount(WhichAlt))
gitmTime = intarr(6,AltCount(WhichAlt))
totalcount = 0

gitmnmf2 = fltarr(nDT)
gitmhmf2 = fltarr(nDT)
	
for iTime = 0, nDT - 1 do begin
    gitmnmf2(iTime) = max(data(plotvar,*,iTime),inmf2)
    gitmhmf2(iTime) = data(ialtvar,inmf2,iTime)
;    print, gitmnmf2(itime), itimearr(*,itime)
    loc = where(data(ialtvar,*,iTime) ge AltBins(WhichAlt) and $
                data(ialtVar,*,iTime) lt AltBins(WhichAlt+1),count)
    
    if count gt 1 then begin
        count = 1
        loc = loc(0)
    endif
    if count gt 0 then begin
        gitmValue(totalcount) = data(plotvar,loc,iTime)
        gitmTime(*,totalcount) = iTimeArr(0:5,iTime) 
       endif
    totalcount = totalcount + count

endfor

stimearr = gitmTime(*,0)
etimearr = gitmTime(*,n_elements(gitmTime(0,*))-1)

gitmrtime = fltarr(altcount(whichalt))
for i = 0, n_elements(gitmTime(0,*)) -1 do begin
    c_a_to_r,gitmTime(*,i), ttime
    gitmrtime(i) = ttime
endfor

c_a_to_r, stimearr,stime
c_a_to_r, etimearr,etime

MHfl = findfile('mh*.dat')
nMHf = n_elements(MHfl)

    filetime = intarr(6)
for ifile = 1, nmhf-1 do begin
    filetime(0) = strmid(mhfl(ifile),6,4)
    filetime(1) = strmid(mhfl(ifile),2,2)
    filetime(2) = strmid(mhfl(ifile),4,2)
    c_a_to_r,filetime,frtime
    if frtime lt stime then sfile = ifile
    if frtime lt etime then efile = ifile
endfor
mhfilelist = mhfl(sfile:efile)
nmhfiles = n_elements(mhfilelist)
readmh,MHfilelist,MHdata,mhrtime,galts,datasize

if whichvar eq 1 then MHdata.VAR = 10^(MHdata.Var)
MHValue = fltarr(Altcount(whichalt))
MHTime = intarr(6,Altcount(whichalt))
altarray=MHdata.alts
vararray=MHdata.var
rtime = fltarr(AltCount(whichalt))
totalcount = 0

iTime = 0
while mhrtime(iTime) lt stime do begin
    iTime = iTime + 1
endwhile
if mhrtime(iTime-2) eq mhrtime(itime-1) then starti = iTime-2 else $
  starti = iTime-1 

mhstime = mhrtime(starti)

while mhrtime(iTime) lt etime do begin
    iTime = iTime + 1
endwhile

if mhrtime(iTime+1) eq mhrtime(itime) then endi = iTime+1 else endi = iTime 
mhetime = mhrtime(endi)

for iData = starti, endi do begin

    doaverage = 0
    inc = 0
    loc = where(MHdata(iData).Alts ge altbins(whichalt) and $
                MHdata(iData).Alts lt altbins(whichalt+1),count)

    if idata gt starti then begin
        if mhrtime(idata) eq mhrtime(idata-1) then begin
            if count ge 1 and oldcount ge 1 then begin
                totalcount = totalcount - 1
                doaverage = 1
            endif
        endif
    endif

    if count gt 0 then begin
        inc = 1
        if doaverage then begin
            MHValue(totalcount) = (total(MHdata(iData).Var(loc)) + $
                                   total(MHdata(iData-1).Var(oldloc)))/$
                                   (count+oldcount)
            MHTime(*,totalcount) = MHdata(iData).Time 
            rtime(totalcount) = mhrtime(iData)
        endif else begin
            MHValue(totalcount) = total(MHdata(iData).Var(loc))/count
            MHTime(*,totalcount) = MHdata(iData).Time 
            rtime(totalcount) = mhrtime(iData)
        endelse
    endif

    totalcount = totalcount + inc
    oldloc = loc
    oldcount = count
endfor

loc = where(MHvalue ne 0)
npts = n_elements(gitmvalue)

time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn

mintemp = min([min(gitmValue),min(MHValue)])
minv = mintemp - .3 * mintemp
maxtemp = max([max(gitmValue),max(MHValue)])
maxv = maxtemp + .25 * maxtemp

loadct, 0

if n_elements(oplot1d) eq 0 then oplot1d ='n'
oplot1d = ask('over plot 1d results? (y/n)',oplot1d)
if n_elements(nels) eq 0 then nels = -1
if oplot1d eq 'y' then begin
    
    if n_elements(dir) eq 0 then dir = '~/Gitm/run/data/'
    dir = ask('GITM Directory: ',dir)
    if n_elements(data1d) ne nels then begin
        get_isr1d,dir, data1d,alts1d,lons,lats,time1d,vars1d,nalts1d,nsats1d,npts1d
        
        for i = 0, n_elements(vars1d)-1 do begin
            vars1d(i) = strtrim(vars1d(i),2)
        endfor
    endif
    nels = n_elements(data1d)
    case whichvar of
        1: var = where(vars1d eq '[e-]')
        2: var = where(vars1d eq 'eTemperature')
        3: var = where(vars1d eq 'iTemperature')
        4: begin
            var = where(vars1d eq 'Vi')
            var = var(2)
        end
    endcase
    
    value = reform(data1d(0,0:nPts1d-1,var,0:nalts1d-1))
    
    d = abs((altbins(whichalt)+altbins(whichalt+1))/2- reform(Alts1d(0,*)))
    loc = where(d eq min(d))
    iAlt1 = loc(0)
    
    if whichvar eq 1 then begin
        logvalue = alog10(value)
        v = reform(logvalue(*, iAlt1))
        v = 10.^v
    endif else v = reform(value(*,iAlt1))
    it = 0
    while time1d(it) lt stime do begin
        it = it + 1
    endwhile
    
    start1di = it -1
    stime1d = time1d(start1di)
    
    while time1d(it) lt etime do begin
        it = it + 1
    endwhile
    
    end1di = it
    etime1d= time1d(end1di)
    
    v = v(start1di:end1di)
    tm = time1d(start1di:end1di)
    ta = intarr(6,end1di-start1di+1)
    for i = start1di, end1di do begin
        rt = time1d(i)
        c_r_to_a,taa,rt
        ta(*,i-start1di) = taa
    endfor
    
    
endif


setdevice, '3dplot.ps','p',5,.95

ppp = 5
space = 0.01
pos_space, ppp, space, sizes, ny = ppp

get_position, ppp, space, sizes, 0, pos, /rect
    
    pos(0) = pos(0) + 0.1

;plot, gitmrtime - stime, gitmValue,  xtickname = xtickname, $
;  xtickv = xtickv, xminor = xminor, xticks = xtickn, xstyle = 1, $
;  ystyle = 1, thick = 3, charsize = 1.2,xtitle = xtitle,$
;  ytitle = Variables(plotvar),pos=pos, yrange = [minv,maxv]
;
;oplot, rtime(loc)-stime,MHValue(loc),color = 254

;if Variables(plotvar) eq '[e-]' then title = 'log!D10!N' else title = ''


;plot, [min(gitmrtime),max(gitmrtime)]-stime,[0,10],/nodata,/noerase,$

plot, [1284027648,1284328960]-stime,[0,10],/nodata,/noerase,$
  ytitle = Variables(plotvar)+' '+unit,xtickname = xtickname, $
  xtickv = xtickv, xminor = xminor, xticks = xtickn, xstyle = 1, $
  ystyle = 1,  charsize = 1.2,xtitle = xtitle,$
  pos=pos, yrange = [minv,maxv]

i = 0
j = 1

while j lt npts do begin
    if (gitmrtime(j) - gitmrtime(j-1) gt 25000.) then begin
        oplot, gitmrtime(i:j-1)-stime, gitmValue(i:j-1),$
          thick = 3,linestyle=1
        
        if oplot1d eq 'y' then begin
            
            ll = where(tm gt rtime(i) and tm lt rtime(j-1),count)
        
            if count gt 1 then begin
                ll = [ll,max(ll+1)]
                oplot, tm(ll)-stime,v(ll),thick = 3, linestyle = 2
                
            endif
        endif
        ploc = where(rtime gt gitmrtime(i) and rtime lt gitmrtime(j-1)$
                     ,count)
        if count gt 1 then begin
            ploc = [ploc,max(ploc+1)]
            oplot, rtime(ploc) - stime, mhValue(ploc), thick = 3,color=130
            
        endif

        i = j
    endif
    j = j + 1
endwhile

oplot, gitmrtime(i:j-1)-stime, gitmValue(i:j-1),$
  thick = 3,linestyle=1
oplot, rtime(i:j-1)-stime, mhValue(i:j-1),$
  thick = 3,color = 130

if oplot1d eq 'y' then begin
    ll = where(tm gt rtime(i) and tm lt rtime(j-1),count)
    
    ll = [ll,max(ll+1)]
    oplot, tm(ll)-stime,v(ll),thick = 3, linestyle = 2

    legend,['3D GITM','1D GITM','MH data'],colors = [0,0,130],pos=[.8,pos(1)-.005],linestyle $
      =[1,2,0],/norm
    xyouts, pos(2) + .04,pos(1)+.06, tostr(altbins(whichalt))+'km', $
      orientation = 90, /normal
endif else begin
    legend,['GITM','MH data'],colors = [0,130],pos=[.8,pos(1)-.005],linestyle $
      =[1,0],/norm
    xyouts, pos(2) + .04,pos(1)+.06, tostr(altbins(whichalt))+'km', $
      orientation = 90, /normal
endelse

vectime = [2005,09,10,0,0,0]
c_a_to_r,vectime,vt1
vectime = [2005,09,11,0,0,0]
c_a_to_r,vectime,vt2
vectime = [2005,09,09,18,0,0]
c_a_to_r,vectime,vt3
vectime = [2005,09,10,18,0,0]
c_a_to_r,vectime,vt4
vectime = [2005,09,10,22,0,0]
c_a_to_r,vectime,vt5
vectime = [2005,09,11,22,0,0]
c_a_to_r,vectime,vt6

vt1 = vt1-stime
vt2 = vt2-stime
vt3 = vt3-stime
vt4 = vt4-stime
vt5 = vt5-stime
vt6 = vt6-stime
plotstr = 0
if plotstr eq 1 then begin
  plots,[vt3,vt3+1],[0,1.08e12]
  plots,[vt4,vt4+1],[0,1.08e12]
  plots,[vt5,vt5+1],[0,1.08e12]
  plots,[vt6,vt6+1],[0,1.08e12]
    
   ; plots,[vt1,vt2],[5e11,5e11]
   
  ;plots,[vt3,vt3+1],[0,4.25e11]
  ;plots,[vt4,vt4+1],[0,4.25e11]
  ;plots,[vt3,vt4],[4.25e11,4.25e11],linestyle = 2
  ;
  ;plots,[vt5,vt5+1],[0,4.25e11]
  ;plots,[vt6,vt6+1],[0,4.25e11]
  ;plots,[vt5,vt6],[4.25e11,4.25e11],linestyle = 2
  ;
  ;xyouts,vt1+1000,4.35e11,"O/N!D2!N - Fig. 10"
  ;xyouts,vt5+20000,4.35e11,"O/N!D2!N - Fig. 11"
;    xyouts,vt1+24000,5.1e11,"V!Di!N - Fig. 11"
endif

;;;;;;Statistics;;;;;;;;;;;;;;;;;;;;;;;
diff3d = (gitmvalue - mhvalue)^2
cc3d = c_correlate(gitmvalue,mhvalue,0,/double)

if oplot1d eq 'y' then begin
    igitm1dcomp = intarr(n_elements(rtime))
    mintimediff = igitm1dcomp
    for i = 0, n_elements(rtime) - 1 do begin
        timediff = abs(tm - rtime(i))
        mintimediff(i) = min(timediff,imindiff)
        igitm1dcomp(i) = imindiff
    endfor
    cc1d = c_correlate(v(igitm1dcomp),mhvalue,0,/double)
    print, 'Cross correlation 3d: ', cc3d, '  1d: ', cc1d
endif


rms3d = mean(diff3d)^.5
standardd = stddev(gitmvalue-mhvalue)
if oplot1d eq 'y' then begin
    comp1d = [0]
    compval = comp1d
    clocs = compval
    locs1d = clocs
c2=0
    for j = 0, n_elements(rtime) - 2 do begin
        if rtime(j+1) - rtime(j) gt 25000. then begin
            c1= j
            for i=0, n_elements(v)-1 do begin
                
                if tm(i) gt rtime(c2) and tm(i) le rtime(c1) then begin
                    compval = [compval,min(abs(tm(i)-rtime),comploc)]
                    comp1d = [comp1d,(v(i)-mhvalue(comploc))^2]
                    clocs = [clocs,comploc]
                    locs1d = [locs1d,i]
                endif
            endfor
            c2 = c1+1
        endif
    endfor
    stand1d = stddev(comp1d^.5)   
    rms1d = (mean(comp1d))^.5
endif

rmsdata = (mean(mhvalue^2))^.5

if oplot1d eq 'y' then begin
print, 'RMS Error is  (3d, 1d):',rms3d,rms1d
print, 'RMS/data(RMS) (3d, 1d): ',rms3d/rmsdata,rms1d/rmsdata
endif else begin
    print, 'RMS Error is: ',rms3d
    print, 'RMS/data(RMS): ',rms3d/rmsdata
endelse


;;; Hm-F2 stuff ;;;;
default = 'n'
if whichvar eq 1 then default = 'y'

if default eq 'y' then begin
        donmf2 = 'y'
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
        nmmhitime = intarr(6,nptshm)
        for i = 0, nptshm - 1 do begin
            c_r_to_a,at,nmmhtime(i)
            nmmhitime(*,i) = at
        endfor

        for i = 0, n_elements(hmf2times)-1 do begin
            nmf2(i) = max(vararray(*,hmf2times(i)),ihmf2)
            hmf2(i) = altarray(ihmf2,hmf2times(i))
        endfor
        
        ;gitmnmf2 = fltarr(n_elements(gitmrtime))
        ;gitmhmf2 = fltarr(n_elements(gitmrtime))
        
        ;for i = 0, n_elements(gitmrtime)-1 do begin
        ;    gitmnmf2(i) = max(alog10(data(plotvar,*,i),igitmhmf2)
        ;    gitmhmf2(i) = data(ialtvar,igitmhmf2)
        ;endfor
        

restore,'idlsave.dat'
get_position, ppp, space, sizes, 2, pos, /rect

pos(0) = pos(0) + 0.1

        i = 0
        j = 1
        ;setdevice,'othernm-f2.ps','l',5,.95    
        title = 'Nm-F2'
        yrange = [min(nmf2) - .6*min(nmf2),max(nmf2)+.3*max(nmf2)]
        
        plot,[1284027648,1284328960]-stime,[0,12],/nodata,/noerase,$
          ytitle = vars1d(var)+' '+unit, yrange = yrange,pos = pos,$
          xtickname = strarr(10)+' ', xtickv = xtickv, xminor = xminor, $
          xticks = xtickn,xstyle = 1, ystyle = 1,charsize = 1.3
        while j lt nptshm do begin
            btdiff = nmmhtime(j) - nmmhtime(j-1)
            if (nmmhtime(j) - nmmhtime(j-1) gt 25000.) then begin
                
                oplot, nmmhtime(i:j-1)-stime, nmf2(i:j-1),psym = psym ,$
                  symsize = symsize,thick = 3,color=130
                loc = where(gtt gt nmmhtime(i) and gtt lt nmmhtime(j-1),count)
                loc2 = where(gtime1d gt nmmhtime(i) and $
                             gtime1d lt nmmhtime(j-1))
                if count gt 1 then begin
                    oplot, gtt(loc)-stime,gitmnmf2(loc), color = 0,$
                      psym = psym, symsize= symsize,$
                      thick = 3,linestyle=1
                    oplot,gtime1d(loc2)-stime,10^gitmnmf21d(loc2),color=0,$
                      thick=3,linestyle=2
                endif
                i = j
            endif
            j = j+1
        endwhile
        
        oplot, nmmhtime(i:j-1)-stime, nmf2(i:j-1),psym = psym ,$
          thick=3,color=130
        loc = where(gtt gt nmmhtime(i) and gtt lt nmmhtime(j-1) $
                    and gitmnmf2 gt 1.5e11,count)
        oplot, gtt(loc)-stime,gitmnmf2(loc),$
          thick = 3,linestyle=1
        loc2 = where(gtime1d gt nmmhtime(i) and $
                     gtime1d lt nmmhtime(j-1))
        oplot,gtime1d(loc2)-stime,10^gitmnmf21d(loc2),linestyle=2,$
          thick=3

        xyouts, pos(2) + .04,pos(1)+.07, 'NmF2', $
          orientation = 90, /normal      
        
;;;;;;;;;;;;;;;;;;;STATS;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
        tdiff1 = abs(gtt - nmmhtime(0))
        tdiff2 = abs(gtt - nmmhtime(n_elements(nmmhtime)-1))
        d1 = min(tdiff1,id1)
        d2 = min(tdiff2,id2)
        
        
        gitmnmf2t = gitmnmf2(id1:id2)
        gttt = gtt(id1:id2)
        gitmcompi = intarr(n_elements(gitmnmf2t))
       
        for i = 0, n_elements(gitmnmf2t)-1 do begin
            timediff = abs(gttt(i) - nmmhtime)
            mintimediff = min(timediff,imindiff)
            gitmcompi(i) = imindiff
        endfor
        
        vardiff = (gitmnmf2t - nmf2(gitmcompi))^2
        rmsdata = (mean((nmf2(gitmcompi))^2))^.5
        
        rmserror = mean(vardiff)^.5
        
        print, 'RMS Error is of NMF2: ',rmserror
        print, 'RMS/data(RMS) of NMF2: ',rmserror/rmsdata
        
        
        diff3d = (gitmnmf2t - nmf2(gitmcompi))^2
        cc3d = c_correlate(gitmnmf2t,nmf2(gitmcompi),0,/double)
        
        if oplot1d eq 'y' then begin
            igitm1dcomp = intarr(n_elements(nmmhtime))
            mintimediff = igitm1dcomp
            for i = 0, n_elements(nmmhtime) - 1 do begin
                timediff = abs(gtime1d - nmmhtime(i))
                mintimediff(i) = min(timediff,imindiff)
                igitm1dcomp(i) = imindiff
            endfor
            cc1d = c_correlate(gitmnmf21d(igitm1dcomp),nmf2,0,/double)
            print, 'Cross correlation NmF2 3d: ', tostrf(cc3d), '  1d: '$
              , tostrf(cc1d)
endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        get_position, ppp, space, sizes, 3, pos, /rect
        
        pos(0) = pos(0) + 0.1
        i = 0
        j = 1
        
        title = 'Hm-F2'
        yrange = [150,500]
        plot,[1284027648,1284328960]-stime,[0,12],/nodata,/noerase,$
          ytitle = 'Altitude (km)', xtitle = xtitle,yrange = yrange,$
          xtickname = xtickname, xtickv = xtickv, xminor = xminor, $
          xticks = xtickn,xstyle = 1, ystyle = 1,charsize = 1.3,pos=pos
        
        while j lt nptshm do begin
            if (nmmhtime(j) - nmmhtime(j-1) gt 25000.) then begin
                oplot, nmmhtime(i:j-1)-stime, hmf2(i:j-1)$
                  ,thick = 3,color=130
                loc = where(gtt gt nmmhtime(i) and gtt lt nmmhtime(j-1),count)
                loc2 = where(gtime1d gt nmmhtime(i) and $
                             gtime1d lt nmmhtime(j-1))
                 if count gt 1 then begin
                    oplot, gtt(loc)-stime,gitmhmf2(loc),$
                      thick = 3,linestyle=1
                    oplot,gtime1d(loc2)-stime,gitmhmf21d(loc2),$
                      linestyle=2,thick=3
                endif
                i = j
            endif
            j = j+1
        endwhile
        
        oplot, nmmhtime(i:j-1)-stime, hmf2(i:j-1),psym = psym ,$
          thick=3,color=130
        loc = where(gtt gt nmmhtime(i) and gtt lt nmmhtime(j-1) $
                    and gitmnmf2 gt 1.5e11,count)
        oplot, gtt(loc)-stime,gitmhmf2(loc),$
          thick = 3,linestyle=1
        loc2 = where(gtime1d gt nmmhtime(i) and $
                     gtime1d lt nmmhtime(j-1))
        oplot,gtime1d(loc2)-stime,gitmhmf21d(loc2),$
          linestyle=2,thick=3

        xyouts, pos(2) + .04,pos(1)+.07, 'HmF2', $
          orientation = 90, /normal
        
        if oplot1d eq 'y' then begin
            legend,['3D GITM','1D GITM','MH data'],colors = [0,0,130],$
              pos=[.8,pos(1)-.005],linestyle $
              =[1,2,0],/norm
        endif else begin
            legend,['GITM','MH data'],colors = [0,130],$
              pos=[.8,pos(1)-.005],linestyle $
              =[2,0],/norm
        endelse
        
;;;;;;;;;;;;;;STATS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        gitmhmf2t = gitmhmf2(id1:id2)
        diff3d = (gitmhmf2t - hmf2(gitmcompi))^2
        cc3d = c_correlate(gitmhmf2t,hmf2(gitmcompi),0,/double)
        
        if oplot1d eq 'y' then begin
            cc1d = c_correlate(gitmhmf21d(igitm1dcomp),hmf2,0,/double)
            print, 'Cross correlation HmF2 3d: ', tostrf(cc3d), '  1d: '$
              , tostrf(cc1d)
        endif
        hcomp = intarr(n_elements(nmmhtime))
        for i = 0, n_elements(nmmhtime)-1 do begin
            htdiff = abs(gttt - nmmhtime(i))
            minhtdiff = min(htdiff,imindiff)
            hcomp(i) = imindiff
        endfor 
        hdiff = gitmhmf2(hcomp) - hmf2
        hdiffmean = mean(hdiff)
        ndiff = abs(10^gitmnmf2t(hcomp)-10^nmf2)/(10^gitmnmf2(hcomp))
        ndiffmean = mean(ndiff)
    endif
endif

closedevice


end

