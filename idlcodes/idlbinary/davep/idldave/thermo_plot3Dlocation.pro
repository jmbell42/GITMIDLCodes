if n_elements(compare) eq 0 then compare = 0
;if compare then compare = 'y' else compare = 'n'
;compare = ask('whether to compare two files ',compare)
;if strpos(compare,'y') ge 0 then compare = 1 else compare = 0

if n_elements(whichlon) eq 0 then whichlon = 0
whichlon = float(ask('which longitude: (0.0 for subsolar)', $ 
                     tostrf(whichlon)))

if n_elements(whichlat) eq 0 then whichlat = 0
whichlat = float(ask('which latitude: (0.0 for subsolar)', $
                     tostrf(whichlat)))

if n_elements(dir) eq 0 then dir = '.'
dir = ask('which directory to plot',dir)
if compare then begin
   if n_elements(basedir) eq 0 then basedir = '.'
   basedir = ask('which base directory to plot',basedir)
   
   filelist_new = findfile(dir+'/3D*.bin')
   basefilelist_new = findfile(basedir+'/3D*.bin')
   nfiles_new = n_elements(filelist_new)
   nbasefiles_new = n_elements(basefilelist_new)
   if nfiles_new ne nbasefiles_new then begin
      print,'the number of files in those two directories are not equal'
      print,'stopping...'
      stop
   endif
endif else begin
   filelist_new = findfile(dir+'/3D*.bin')
   nfiles_new = n_elements(filelist_new)
endelse
getnewdata = 1
if n_elements(nfiles) gt 0 then begin
    if (nfiles_new eq nfiles) then default = 'n' else default = 'y'
    GetNewData = mklower(strmid(ask('whether to reread data',default),0,1))
    if (GetNewData eq 'n') then GetNewData = 0 else GetNewData = 1
endif

if n_elements(latold) eq 0 then begin
    latold = 0.0
    lonold = 0.0
endif

if whichlat ne latold or whichlon ne lonold then begin
    print, 'Coordinates not the same as previous run, recalculating... '
    GetNewData = 1
endif

display,filelist_new
if n_elements(file) eq 0 then file = ''
file = ask('which file to plot',file)
if compare then   nfiles = 2 else nfiles = 1

if (GetNewData) then begin
   sscoords = fltarr(2,nfiles)
   iTimeArray = intarr(6,nfiles)

    for iFile = 0, nFiles-1 do begin
       if compare and ifile gt 0 then filename = basefilelist_new(file) else $
          filename =filelist_new(file)
        
        print, 'Reading file ',filename
        
        read_thermosphere_file, filename, nvars, nalts, nlats, nlons, $
          vars, data, rb, cb, bl_cnt
     
        if iFile eq 0 then begin
            ssdata = fltarr(nvars,nfiles,nalts)
            realtime = fltarr(nfiles)
        endif
                       
        iTimeArray(*,iFile) = get_gitm_time(filename)
        stryear = tostr(itimearray(0,ifile))
        strmth = chopr('0'+tostr(itimearray(1,ifile)),2)
        strday = chopr('0'+tostr(itimearray(2,ifile)),2)
        uttime = itimearray(3,ifile)+itimearray(4,ifile)/60.+itimearray(5,ifile)/60./60.
        
        
        strdate = stryear+'-'+strmth+'-'+strday
        strdate = strdate(0)
        zsun,strdate,uttime ,0,0,zenith,azimuth,solfac,$
          lonsun=lonsun,latsun=latsun
               
        if lonsun lt 0.0 then lonsun = 360.0 - abs(lonsun)
                       
        if (whichlon ne 0.0) then lonsun = whichlon
        if (whichlat ne 0.0) then latsun = whichlat

        longdeg = data(0,*,0,0) * 180 / (!pi)
        degdiff = 10000.
        degdiffnew = 0.
        

        for i = 0, nlons - 1 do begin
            if (longdeg(i) ge 0.0 and longdeg(i) le 360.0) then begin
                degdiffnew = abs(longdeg(i) - lonsun)
                if (degdiffnew lt degdiff) then begin
                    degdiff = degdiffnew
                    long_i = i
                endif
            endif
        endfor
               
        if longdeg(long_i) lt lonsun then begin
            loniL = long_i
            loniH = long_i + 1
        endif else begin
            loniL = long_i - 1
            loniH = long_i
        endelse
        rlon = 1.0- (lonsun - longdeg(loniL))/(longdeg(loniH)-longdeg(loniL))

        
        latdeg = data(1,0,*,0) * 180 / (!pi)
        degdiffl = 10000.
        degdifflnew = 0.
        for i = 0, nlats - 1 do begin
            if (latdeg(i) ge -90.0 and latdeg(i) le 90.0) then begin
                degdifflnew = abs(latdeg(i) - latsun)
                if (degdifflnew lt degdiffl) then begin
                    degdiffl = degdifflnew
                    lat_i = i

                endif
            endif
        endfor
        
        if latdeg(lat_i) lt latsun then begin
            latiL = lat_i
            latiH = lat_i + 1
        endif else begin
            latiL = lat_i - 1
            latiH = lat_i
        endelse
        rlat = 1.0- (latsun - latdeg(latiL))/(latdeg(latiH)-latdeg(latiL))

        sscoords(0,iFile) = long_i
        sscoords(1,iFile) = lat_i
        
        for i = 0, nAlts - 1 do begin
            for j = 0, nvars - 1 do begin
            ssdata(j,iFile,i) = $
              (  rLon)*(  rLat)*data(j,loniL, latiL, i) + $
              (1-rLon)*(  rLat)*data(j,loniH, latiL, i) + $
              (  rLon)*(1-rLat)*data(j,loniL, latiH, i) + $
              (1-rLon)*(1-rLat)*data(j,loniH, latiH, i)
            endfor
        endfor

        print, 'Coordinates: ',ssdata(0,iFile,0)*180/!pi,' Long. ', ssdata(1,iFile,0)*180/!pi,' Lat.'
     endfor
 endif

nalts = n_elements(data(0,0,0,*))
nalts = nalts - 2

alt = reform(ssdata(2,0,0:nalts-1))/1000.
latold = whichlat
lonold = whichlon

for i=0, nfiles-1 do begin
    c_a_to_r, iTimeArray(*,i),rtime
    realtime(i) = rtime
endfor

display, vars
if n_elements(npvars) eq 0 then npvars = 1
npvars = fix(ask('how many vars to plot',tostr(npvars)))
if (n_elements(iVar) ne npvars) then iVar = intarr(npvars) + 3
for i = 0, npvars - 1 do begin
   ivar(i) = fix(ask('var '+tostr(i),tostr(ivar(i))))
endfor

if not compare then begin
   if n_elements(ylog) eq 0 then ylog = 'n'
   ylog = ask('whether to plot log',ylog)
endif else begin
   ylog = 'n'
endelse

nVars = n_elements(Vars)

pos = [.1,.1,.9,.55]
pos1 = pos
pos2 = pos
pos1(1) = pos(3) + .02
pos1(3) = pos1(1) + .2
pos2(1) = pos(3) + .22
pos2(3) = pos2(1) + .2
  cl = findgen(npvars)*(245/(npvars))+245/(npvars)
  cl(0) = 0
  

    loadct, 39
    c_r_to_a,ta,rtime(0)
    tostrtime,ta,strtime
;    title = '1D profile at '+strtime
    title = 'Dayside ionosphere profile on 12/24/2002'

    if compare then begin
       ssval = (ssdata(ivar(0),0,0:nalts-1) - ssdata(ivar(0),1,0:nalts-1)) /$
               ssdata(ivar(0),1,0:nalts-1)*100.0
       nfiles = 1
    endif else begin
       if ylog eq 'y' then  ssval = alog10(reform(ssdata(ivar(0),0,0:nalts-1))) else $
          ssval = reform(ssdata(ivar(0),0,0:nalts-1))
    endelse
    n = reform(ssdata(4,0,*))+reform(ssdata(5,0,*))+ $
      reform(ssdata(6,0,*))+ $
      reform(ssdata(7,0,*))+reform(ssdata(8,0,*))
    k = 1.38065e-23
    t = reform(ssdata(15,0,*))
    p = n*k*t
    nco2 =alog10(reform(SSdata(4,0,2:nalts-3)))
    no2 = alog10(reform(SSdata(8,0,2:nalts-3)))
    no = alog10(reform(ssdata(6,0,2:nalts-3)))
    nn2 = alog10(reform(ssdata(7,0,2:nalts-3)))
    nar = alog10(reform(ssdata(9,0,2:nalts-3)))
    nco = alog10(reform(ssdata(5,0,2:nalts-3)))
;  Alter yrange to focus on UATM:
;   yrange = mm(alt)
    yrange = [100,250]
    if n_elements(minv) eq 0 then begin
       minv = 0
       maxv = 0
    endif
    minv = float(ask('minimum val to plot (0 for auto): ', tostrf(minv)))
    maxv = float(ask('maximum val to plot (0 for auto): ', tostrf(maxv)))
    
    if minv eq 0 then mini = min(ssval) else mini = minv
    if maxv eq 0 then maxi = max(ssval) else maxi = maxv
    xrange2 = [mini,maxi]
if n_elements(minm) eq 0 then begin
       minm = 0
       maxm = 0
    endif
    minm = float(ask('minimum mom to plot (0 for auto): ', tostrf(minm)))
    maxm = float(ask('maximum mom to plot (0 for auto): ', tostrf(maxm)))
    
    if minm eq 0 then minmom = min(ssval) else minmom = minm
    if maxm eq 0 then maxmom = max(ssval) else maxmom = maxm
    xrange = [minmom,maxmom]

    ppp = 4
    space = 0.05
    pos_space, ppp, space, sizes

    if n_elements(ptitle) eq 0 then ptitle = 'plot.ps'
    ptitle = ask('Filename to plot to',ptitle)
    setdevice, ptitle,'p',5,.95
    get_position, ppp, space, sizes, 0, pos, /rect
    if npvars eq 1 then xtitle = vars(ivar) else xtitle = 'Log(Density (m!U-3!N)'
    plot,ssval,alt,ytitle='Altitude',xtitle=xtitle,pos = pos,thick=3,color=0,$
         yrange=[100,250],ystyle=1,xrange=xrange2,xstyle=1

    if npvars gt 1 then begin
       for i = 1, npvars - 1 do begin
          if compare then begin
             ssval = (ssdata(ivar(i),0,0:nalts-1) - ssdata(ivar(i),1,0:nalts-1)) /$
                     ssdata(ivar(i),1,0:nalts-1)*100.0
          endif else begin
             if ylog eq 'y' then  ssval = alog10(reform(ssdata(ivar(i),0,0:nalts-1))) else $
                ssval = reform(ssdata(ivar(i),0,0:nalts-1))
          endelse
          oplot,ssval,alt,thick=3,color = cl(i)
       endfor
       
       legend,vars(ivar),colors=cl,linestyle=0,thick=3,pos = [pos(2)-.2,pos(3)-.03],/norm,$
              box = 0
    endif
    closedevice

    ppp = 9
    space = 0.05
    pos_space, ppp, space, sizes,ny = 3
    setdevice, 'pressure.ps','p',5,.95
    get_position, ppp, space, sizes, 0, pos, /rect
    plot,t,alt,ytitle='Altitude',xtitle='Temperature',pos = pos,thick=3,color=0,$
         yrange=yrange,ystyle=1,xrange=[80,350],xstyle=1
    
   

 get_position, ppp, space, sizes, 1, pos, /rect
    plot,p,alt,xtitle='Pressure',pos = pos,thick=3,color=0,$
         yrange=yrange,ystyle=1,xstyle=1,ytickname=strarr(10)+' ',/noerase,/xlog,$
         xrange = [1e-8,1e4]
    
loadct,39
cl = get_colors(6)
get_position, ppp, space, sizes, 2, pos, /rect
    plot,p,alt,xtitle='Log (Density #/m!U3!N)',pos = pos,thick=3,color=0,$
         yrange=yrange,ystyle=1,xstyle=1,ytickname=strarr(10)+' ',/noerase,$
         xrange = [8,19],/nodata
oplot, nco2,alt,color = cl(0),thick=3
 oplot, nco,alt,color = cl(1),thick=3
 oplot, no2,alt,color = cl(2),thick=3
 oplot, no,alt,color = cl(3),thick=3
 oplot, nn2,alt,color = cl(4),thick=3
 oplot, nar,alt,color = cl(5),thick=3

legend,['CO2','CO','O2','O','N2','Ar'],color=cl,box=0,pos = [pos(2)-.175,pos(3)-.01],/norm,$
       linestyle=0
closedevice




    closedevice
 end



