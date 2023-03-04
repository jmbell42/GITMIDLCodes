;champ = 0
reread = 1
if (n_elements(GitmDensity) gt 0) then begin
    answer = ask('whether to re-read data','n')
    if (strpos(mklower(answer),'n') gt -1) then reread = 0
endif

if n_elements(ndirs) eq 0 then ndirs = 1
ndirs = fix(ask('number of directories: ',tostr(ndirs)))


if (n_elements(dir) eq 0) then dir = strarr(ndirs)
for idir = 0, ndirs - 1 do begin
    dir(idir) = ask('directory',dir(idir))
endfor

if reread then begin
for idir = 0, ndirs - 1 do begin
    filelist = file_search(dir(idir)+'/cham*.bin')
    
    file = filelist(0)
    length = strpos(file,'.bin')
    ls = length-13
    
    yr = strmid(file,ls,2)
    iYear = tostr(2000+fix(yr))
    iMonth = strmid(file,ls+2,2)
    iDay = strmid(file,ls+4,2)

    doy = jday(fix(iyear), fix(imonth), fix(iday))

    
    thermo_readsat, filelist, data, time, nTimes, Vars, nAlts, nSats, nTimes

    itimearray = intarr(6,ntimes)
    nvars = n_elements(vars)
    if idir eq 0 then begin
        GitmAlts = fltarr(ndirs,nalts)
        GitmRho = fltarr(ndirs,ntimes,nalts)
        GitmLons = fltarr(ndirs,ntimes,nalts)
        GitmLats = fltarr(ndirs,ntimes,nalts)


        ChampDensity    = fltarr(nTimes)
        GitmDensity     = fltarr(ndirs,nTimes)
        GitmDensityHigh = fltarr(ndirs,nTimes)
        GitmDensityLow  = fltarr(ndirs,nTimes)

        c_r_to_a, itime, time(0)
        itime(3:5) = 0
        ndays = round((time(ntimes-1)-time(0))/3600. /24.)
        
      
    endif

    GitmAlts(idir,*) = data(0,0,2,*)/1000.0
    GitmRho(idir,*,*)  = data(0,*,3,*)
    GitmLons(idir,*,*) = data(0,*,0,*)*180.0/!pi
    GitmLats(idir,*,*) = data(0,*,1,*)*180.0/!pi

    c_a_to_r, itime, basetime
    hour = (time/3600.0 mod 24.0) + fix((time-basetime)/(24.0*3600.0))*24.0
    localtime = (reform(GitmLons(*,0))/15.0 + hour) mod 24.0

endfor
endif

    champdir = '~/CHAMP/data/'+tostr(iyear)+'/'
    ChampAltitude   = fltarr(nTimes)
    ChampLons   = fltarr(nTimes)

    nChampMax = 100000L
    ChampPosition = fltarr(3,nChampMax)
    ChampTime  = dblarr(nChampMax)
    MassDensity = fltarr(nChampMax)
    ChampWind = fltarr(nChampMax)
    ChampLocalTime=fltarr(nChampMax)
    t = ' '
    line = 0L

    for cday = 0, ndays - 1 do begin
        doys = doy + cday
        champ_file_a = champdir+'Density_3deg_'+yr+'_'+ $
          chopr('00'+tostr(doys),3)+'.ascii'
   ;     champ_file_w = champdir+'Wind_3deg_'+yr+'_'+tostr(doys)+'.ascii'
        
        close,/all
        openr,1,champ_file_a
    ;    openr,2,champ_file_w
        readf,1,t
        readf,1,t
    ;    readf,2,t

        while (not eof(1)) do begin
            readf,1,t
            tarr = strsplit(t,/extract)
            year = fix(tarr(0))
            day = fix(tarr(1))
            seconds = float(tarr(2))
            lat =float(tarr(4))
            long = float(tarr(5))
            height = float(tarr(6))
            chlocaltime = float(tarr(7))
            density = float(tarr(8))
            density400 = float(tarr(9))
            density410 =float(tarr(10))

            itime = [Year, 1, Day, 0,0,0]
            c_a_to_r, iTime, BaseTime

            ChampTime(line) = seconds+ basetime
            ChampPosition(0,line) = long
            ChampPosition(1,line) = lat
            ChampPosition(2,line) = height
            MassDensity(line) = density
            ChampLocalTime(line) = chlocaltime
;            ChampWind(line) = wind
           
            line = line + 1
        endwhile
        
        close,1,2
    endfor


    for iTime = 0, nTimes-1 do begin
        c_r_to_a,ta,time(itime)
        itimearray(*,itime) = ta
        dt = abs(time(iTime)-ChampTime)
        loc = where(dt eq min(dt))

        i = loc(0)
  
        ChampDensity(iTime)  = MassDensity(i)/1.e-12;*0.7
        ChampAltitude(iTime) = ChampPosition(2,i)
        ChampLons(iTime) = ChampPosition(0,i)

        for idir = 0, ndirs - 1 do begin
            
            loc = where(GitmAlts(idir,*) gt ChampAltitude(iTime))
            i = loc(0)
            x = (ChampAltitude(iTime) - GitmAlts(idir,i-1)) / $
              (GitmAlts(idir,i) - GitmAlts(idir,i-1))
            GitmDensity(idir,iTime) = exp((1.0 - x) * alog(GitmRho(idir,iTime,i-1)) + $
                                     (      x) * alog(GitmRho(idir,iTIme,i)))
            
            h = (GitmAlts(idir,i+1) - GitmAlts(idir,i-1))/2.0
            
;        print, ChampAltitude(iTime), ChampDensity(iTime), GitmDensity(iTime)/1.0e-12, $
;          (1.0 - x)*GitmAlts(i-1)+x*GitmAlts(i)
            
            loc = where(GitmAlts(idir,*) gt ChampAltitude(iTime)+h)
            i = loc(0)
            x = ((ChampAltitude(iTime)+h) - GitmAlts(idir,i-1)) / $
              (GitmAlts(idir,i) - GitmAlts(idir,i-1))

            GitmDensityHigh(idir,iTime) = (1.0 - x) * GitmRho(idir,iTime,i-1) + $
              (      x) * GitmRho(idir,iTIme,i)
       
            
            loc = where(GitmAlts(idir,*) gt ChampAltitude(iTime)-h)
            i = loc(0)
            x = ((ChampAltitude(iTime)-h) - GitmAlts(idir,i-1)) / $
              (GitmAlts(idir,i) - GitmAlts(idir,i-1))
            GitmDensityLow(idir,iTime) = (1.0 - x) * GitmRho(idir,iTime,i-1) + $
              (      x) * GitmRho(idir,iTIme,i)


        endfor
    endfor

    GitmDensity = GitmDensity*1.0e12
    ChampLocalTime = ChampLocalTime(0:nTimes-1)

  GitmAve  = fltarr(ndirs,nTimes)
  ChampAve = fltarr(nTimes)

      for iTime = 0, nTimes-1 do begin
          for idir = 0, ndirs - 1 do begin          
              loc = where(abs(time-time(iTime)) lt 45.0*60.0, count)
              if (count gt 0) then begin
                  GitmAve(idir,iTime) = mean(GitmDensity(idir,loc))
              endif

          endfor
          ChampAve(iTime) = mean(ChampDensity(loc))
      endfor

maxrho = fltarr(ndirs)
minrho = fltarr(ndirs)
for idir = 0, ndirs - 1 do begin
    maxrho(idir) = max(gitmave(idir,*),im)
    minrho(idir) = min(gitmave(idir,im-(6*24)))
endfor
yrange = mm([ChampDensity,max(GITMDensity),min(GITMDensity)])
yrange = [0.0,20.0]

ppp = 2
space = 0.1
pos_space, ppp, space, sizes, ny = ppp
    
get_position, ppp, space, sizes, 0, pos1, /rect
pos1(0) = pos1(0) + 0.05
pos1(2) = pos1(2) - 0.05

get_position, ppp, space, sizes, 1, pos2, /rect
pos2(0) = pos2(0) + 0.05
pos2(2) = pos2(2) - 0.05

stime = min(time)
etime = max(time)
time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn

p = strpos(dir(0),'/')
if p eq -1 then p = strlen(dir(0))
run = strmid(dir(0),0,p)

psfile_ave = 'compare_'+run+'_ave.ps'

if strmid(dir(0),0,1) eq 'C' then names = ['Conduction 1','Conduction 2','Conduction 3']
if strmid(dir(0),0,1) eq 'E' then names = ['Eddy 1','Eddy 2','Eddy 3']
if strmid(dir(0),0,1) eq 'N' then names = ['N!D2!N Diss 1','N!D2!N Diss 2','N!D2!N Diss 3']
if strmid(dir(0),0,1) eq 'O' then names = $
  ['O!D2!U+!N Recombine 1','O!D2!U+!N Recombine 2','O!D2!U+!N Recombine 3 ']
if strmid(dir(0),0,2) eq 'ND' then names = ['NO Diffusion 1','NO Diffusion 2']
if strmid(dir(0),0,2) eq 'NC' then names = ['NO Cooling 1','NO Cooling 2','NO Cooling 3']
if strmid(dir(0),0,2) eq 'NO' then names = ['NO!U+!N Recombine 1','NO!U+!N Recombine 2']
if strmid(dir(0),0,1) eq 'T' then names = ['Thermopause 1','Thermopause 2','Thermopause 3']
;--------------------------------------------------------------------
; Ave
;--------------------------------------------------------------------
    
    setdevice, psfile_ave, 'p', 5
    
    plot, time-stime, ChampAve, yrange = yrange, pos = pos1, $
      xtickname = xtickname, xtitle = xtitle, xtickv = xtickv, $
      xminor = xminor, xticks = xtickn, xstyle = 1, charsize = 1.2, $
      ytitle = 'Mass Density (10!E-12!N kg/m!E3!N)',   $
      thick = 5,linestyle = 3,ystyle = 1

    for idir = 0, ndirs - 1 do begin
        oplot, time-stime, GitmAve(idir,*), linestyle = idir, thick = 3
    endfor    
    
  
    
    rmse = sqrt(mean((ChampAve-gitmave)^2))
    rmsd = sqrt(mean((ChampAve)^2))
    nrms = rmse/rmsd * 100.0
    
    peakpercent = (maxrho-minrho)/minrho*100.0
    peakdiff = (maxrho-minrho)
    strstat = strarr(ndirs)
    
    for idir = 0, ndirs - 1 do begin
       strstat(idir) =  '    Base to peak: '+string(peakpercent(idir),format = '(f5.1)')+'% ('+$
         string(peakdiff(idir),format = '(f4.1)')+'kg/m!U-3!N Diff)'

;       strstat(idir) =  string(peakpercent(idir),format = '(f5.1)')+'% ('+$
;         string(peakdiff(idir),format = '(f4.1)')+'kg/m!U-3!N)'
       
    endfor
    names = [names,'Champ']
    names(0:ndirs-1) = names(0:ndirs-1)  + strstat
     pos = [pos1(0)+.01,pos1(3) - .005]
     if ndirs eq 3 then begin
         legend,names,linestyle=[indgen(ndirs),4],box=0,$
           pos =pos,/norm,charsize=1.1,thick=[2,2,2,4]
     endif
     
     if ndirs eq 2 then begin
         legend,names,linestyle=[indgen(ndirs),4],box=0,$
           pos =pos,/norm,charsize=1.1,thick=[2,2,4]
     endif

;    pos = [pos1(2)+.01,pos1(3) - .005]
;    legend, strstat,box=0,$
;      pos =pos,/norm,charsize=1.1,/right
    pdif = mean((ChampAve-gitmave)/ChampAve) * 100.0
    
    srms = +' (nRMS: '+string(nrms,format = '(f5.1)')+'%, '
    srms = srms+string(pdif,format = '(f5.1)')+'% Difference)'
    
   

;    oplot, [t1,t2], max(yrange-max(yrange)/2) - [2.0,2.0], thick = 3
;    xyouts, pos(0)+.4,pos(1)-.02, srms,/norm
    
    
    closedevice



end
