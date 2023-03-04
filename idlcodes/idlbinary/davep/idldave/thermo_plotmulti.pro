getnewdata = 1
getnewdirs = 1

if n_elements(ndirs_new) eq 0 then ndirs_new = 0
ndirs_new = fix(ask('number of directories: ',tostr(ndirs_new)))

if n_elements(ndirs_old) eq 0 then ndirs_old = 0
if ndirs_new eq ndirs_old then begin
    getnewdirs = 0
    getnewdirs = fix(ask('get new directories (0/1): ',tostr(getnewdirs)))
endif
ndirs_old = ndirs_new
ndirs = ndirs_new

if getnewdirs then begin
    directories = strarr(ndirs)
    not_done = 1

    for idir = 0, ndirs - 1 do begin

        directories(idir) = ask('directory name')
    endfor
endif

print, '0    Location'
print, '1    Average'
if n_elements(plottype) eq 0 then plottype = 0
plottype = fix(ask('which plot type: ',tostr(plottype)))
if n_elements(alldata) eq 0 then begin
    getnewdata = 1 
endif else begin
    getnewdata = 0
    getnewdata = fix(ask('read data (0,1): ',tostr(getnewdata)))
endelse

if plottype eq 0 then begin

    if getnewdata then begin
        if n_elements(whichlon) eq 0 then whichlon = 0
        whichlon = float(ask('which longitude: (0.0 for subsolar)', $ 
                             tostrf(whichlon)))
        
        if n_elements(whichlat) eq 0 then whichlat = 0
        whichlat = float(ask('which latitude: (0.0 for subsolar)', $
                             tostrf(whichlat)))
        
        for idir = 0, ndirs - 1 do begin
            fpi = 0
            nfiles = 1
            ifile = 0
            if idir eq 0 then begin
                filelist= file_search(directories(idir)+'/3DALL'+'*')
                tlen = strpos(filelist(0),'.bin') - 13
                cyear = strmid(filelist,tlen,2)
                cyears = tostr(2000+fix(cyear))
                cmons = strmid(filelist,tlen+2,2)
                cdays = strmid(filelist,tlen+4,2)
                chours = strmid(filelist,tlen+7,2)
                cmins = strmid(filelist,tlen+9,2)
                csecs = strmid(filelist,tlen+11,2)
                ctimes = cyears+'.'+cmons+'.'+cdays+' '+chours+':'+cmins+'.'+csecs
                display, ctimes
                
                if n_elements(whichtime) eq 0 then whichtime = 0
                whichtime = fix(ask("which time to plot: ",tostr(whichtime)))
                
                gettime = cyear(whichtime)+cmons(whichtime)+cdays(whichtime)+'_'+ $
                  chours(whichtime)+cmins(whichtime)+csecs(whichtime)
                filelist = file_search(directories(idir)+'/3D'+'*'+gettime+'*')
                
                ftypepos = strpos(filelist(0),'3D')+2 
                ftypes = strmid(filelist,ftypepos,3)
                
                display,ftypes
                if n_elements(filetype) eq 0 then filetype = 0
                filetype = fix(ask('which type to plot: ',tostr(filetype)))
                
                filename_base = '3D*'+ftypes(filetype)+'*'+gettime+'*.bin'
                
                sscoords = fltarr(2,nfiles)
                iTimeArray = intarr(6,nFiles)
            endif 

            filename = file_search(directories(idir)+'/'+filename_base)
            print, 'Reading file ',filename
            
            read_thermosphere_file, filename, nvars, nalts, nlats, nlons, $
              vars, data, rb, cb, bl_cnt
                
                
                if iFile eq 0 then begin
                    ssdata = fltarr(nvars,nfiles,nalts)
                    realtime = fltarr(nfiles)
                endif
                
                if (strpos(filename,"bin") gt 0) then begin
                    
                    fn = file_search(filename)
                    if (strlen(fn(0)) eq 0) then begin
                        print, "Bad filename : ", filename
                        stop
                    endif else filename = fn(0)
                    
                    l1 = strpos(filename,'.bin')
                    fn2 = strmid(filename,0,l1)
                    len = strlen(fn2)
                    l = len - 13
                    year = fix(strmid(filename,l, 2))
                    mont = fix(strmid(filename,l+2, 2))
                    day  = fix(strmid(filename,l+4, 2))
                    hour = float(strmid(filename, l+7, 2))
                    if ifile eq 0 then minu = 0 else minu = float(strmid(filename, l+9, 2))
                    seco = 0
                endif else begin
                    year = fix(strmid(filename,07, 2))
                    mont = fix(strmid(filename,09, 2))
                    day  = fix(strmid(filename,11, 2))
                    hour = float(strmid(filename,14, 2))
                    minu = 0
                    seco = 0
                endelse
                
                itime = [year,mont,day,fix(hour),fix(minu),fix(seco)]
                c_a_to_r, itime,rt
                realtime(ifile) = rt
                
                iTimeArray(*,iFile) = itime
                if year lt 50 then iyear = year + 2000 else iyear = year + 1900
                stryear = strtrim(string(iyear),2)
                strmth = strtrim(string(mont),2)
                strday = strtrim(string(day),2)
                uttime = hour+minu/60.+seco/60./60.
                
                
                strdate = stryear+'-'+strmth+'-'+strday
                zensun,strdate,uttime ,0,0,zenith,azimuth,solfac,$
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
                    ssdata(*,iFile,i) = $
                      (  rLon)*(  rLat)*data(*,loniL, latiL, i) + $
                      (1-rLon)*(  rLat)*data(*,loniH, latiL, i) + $
                      (  rLon)*(1-rLat)*data(*,loniL, latiH, i) + $
                      (1-rLon)*(1-rLat)*data(*,loniH, latiH, i)
                endfor
                
                print, 'Coordinates: ',ssdata(0,iFile,0)*180/!pi,' Long. ', $
                  ssdata(1,iFile,0)*180/!pi,' Lat.'

            if idir eq 0 then begin
                alldata = fltarr(ndirs,nvars,nfiles,nalts)
            endif 
            alldata(idir,*,*,*) = ssdata
        endfor
    endif        
endif

if plottype eq 1 then begin
    if getnewdata then begin
        for idir = 0, ndirs - 1 do begin
            fpi = 0
            nfiles = 1
            ifile = 0
            
            if idir eq 0 then begin
                filelist= file_search(directories(idir)+'/3DALL'+'*')
                tlen = strpos(filelist(0),'.bin') - 13
                cyear = strmid(filelist,tlen,2)
                cyears = tostr(2000+fix(cyear))
                cmons = strmid(filelist,tlen+2,2)
                cdays = strmid(filelist,tlen+4,2)
                chours = strmid(filelist,tlen+7,2)
                cmins = strmid(filelist,tlen+9,2)
                csecs = strmid(filelist,tlen+11,2)
                ctimes = cyears+'.'+cmons+'.'+cdays+' '+chours+':'+cmins+'.'+csecs
                display, ctimes
                
                if n_elements(whichtime) eq 0 then whichtime = 0
                whichtime = fix(ask("which time to plot: ",tostr(whichtime)))
                
                gettime = cyear(whichtime)+cmons(whichtime)+cdays(whichtime)+'_'+ $
                  chours(whichtime)+cmins(whichtime)+csecs(whichtime)
                filelist = file_search(directories(idir)+'/3D'+'*'+gettime+'*')
                
                ftypepos = strpos(filelist(0),'3D')+2 
                ftypes = strmid(filelist,ftypepos,3)
                
                display,ftypes
                if n_elements(filetype) eq 0 then filetype = 0
                filetype = fix(ask('which type to plot: ',tostr(filetype)))
                
                filename_base = '3D*'+ftypes(filetype)+'*'+gettime+'*.bin'
                sscoords = fltarr(2,nfiles)
                iTimeArray = intarr(6,nFiles)
                realtime = fltarr(nfiles)
            endif
            
            filename = file_search(directories(idir)+'/'+filename_base)
            
            print, 'Reading file ',filename

            read_thermosphere_file, filename, nvars, nalts, nlats, nlons, $
              vars, data, rb, cb, bl_cnt
            
                
            ssdata = fltarr(nvars,nfiles,nalts)
                            
                if (strpos(filename,"bin") gt 0) then begin
                    
                    fn = file_search(filename)
                    if (strlen(fn(0)) eq 0) then begin
                        print, "Bad filename : ", filename
                        stop
                    endif else filename = fn(0)
                    
                    l1 = strpos(filename,'.bin')
                    fn2 = strmid(filename,0,l1)
                    len = strlen(fn2)
                    l = len - 13
                    year = fix(strmid(filename,l, 2))
                    mont = fix(strmid(filename,l+2, 2))
                    day  = fix(strmid(filename,l+4, 2))
                    hour = float(strmid(filename, l+7, 2))
                    if ifile eq 0 then minu = 0 else minu = float(strmid(filename, l+9, 2))
                    seco = 0
                endif else begin
                    year = fix(strmid(filename,07, 2))
                    mont = fix(strmid(filename,09, 2))
                    day  = fix(strmid(filename,11, 2))
                    hour = float(strmid(filename,14, 2))
                    minu = 0
                    seco = 0
                endelse
                
                itime = [year,mont,day,fix(hour),fix(minu),fix(seco)]
                c_a_to_r, itime,rt
                realtime(ifile) = rt
                
                iTimeArray(*,iFile) = itime
                if year lt 50 then iyear = year + 2000 else iyear = year + 1900
                
            ;    locs = where(abs(data(1,0,*,0)*180/!pi) gt 60 and abs(data(1,0,*,0)*180/!pi) $
            ;                 lt 90.1)
                
                for ivar = 0, nvars - 1 do begin
                    for ialt = 0, nalts - 1 do begin
                        ssdata(ivar,ifile,ialt) = mean(data(ivar,*,*,ialt))
                    endfor
                endfor
                
                if idir eq 0 then begin
                    alldata = fltarr(ndirs,nvars,nfiles,nalts)
                endif 
            alldata(idir,*,*,*) = ssdata
        endfor
    endif
endif

;for i=0, nfiles-1 do begin
;    c_a_to_r, iTimeArray(*,i),rtime
;    realtime(i) = rtime
;endfor

stime = realtime(0)
etime = max(realtime)

time_axis,stime, etime, btr, etr, xtickname,xtitle,xtickv,xminor,xtickn

display, vars
if (n_elements(pvar) eq 0) then pvar = 3
nVars = n_elements(Vars)
pvar = fix(ask('variable to plot',tostr(pvar)))

plotalt = 0
plotprof = 0
display,['Fixed Altitude','Profile']
if n_elements(plott) eq 0 then plott = -1
plott = fix(ask('which plot type (-1 for all): ',tostr(plott)))
if plott eq -1 then begin
    plotalt=1
    plotprof=1
endif 
if plott eq 0 then plotalt = 1
if plott eq 1 then plotprof = 1

if plotalt then begin
pos = [.1,.1,.9,.35]
pos1 = pos
pos2 = pos
pos3 = pos
pos1(1) = pos(3) + .02
pos1(3) = pos1(1) + .2
pos2(1) = pos(3) + .22
pos2(3) = pos2(1) + .2
pos3(1) = pos(3) + .42
pos3(3) = pos3(1) + .2

if (n_elements(iAlt1) eq 0) then iAlt1 = 5
if (n_elements(iAlt2) eq 0) then iAlt2 = 25
if (n_elements(iAlt3) eq 0) then iAlt3 = 36
    
for i=0,nalts-1 do print, tostr(i)+'. '+string(alldata(0,2,0,i)/1000)
iAlt1 = fix(ask('1st altitude to plot',tostr(iAlt1)))
iAlt2 = fix(ask('2nd altitude to plot',tostr(iAlt2)))
iAlt3 = fix(ask('3rd altitude to plot',tostr(iAlt3)))

yrange1 = [min(alldata(*,pvar,*,iAlt1)),max(alldata(*,pvar,*,iAlt1))]
yrange2 = [min(alldata(*,pvar,*,iAlt2)),max(alldata(*,pvar,*,iAlt2))]
yrange3 = [min(alldata(*,pvar,*,iAlt3)),max(alldata(*,pvar,*,iAlt3))]

if n_elements(ptitle) eq 0 then ptitle = 'plot.ps'
ptitle = ask('Filename to plot to',ptitle)
setdevice, ptitle,'p',5,.95
loadct, 39

colors = intarr(ndirs)
fac = (254-10)/float(ndirs-1)
for idir = 0, ndirs - 1 do begin
    colors(idir) = idir*fac+10
endfor
;title = 'Time Evolution of '+ strtrim(vars(pvar),2) 

xrange = [0,etime-stime]
ntimes = n_elements(realtime)
plot,[stime,etime-stime],yrange1, /nodata, color = 1, background = 255,xrange = xrange,$
   yrange = yrange1,xtickname = xtickname,xtitle = xtitle, xminor = xminor, $
   charsize = 1.2,xticks = xtickn,xtickv = xtickv,$
  ytitle = vars(pvar)+' ('+tostr(data(2,0,0,ialt1)/1000)+' km)',$
  pos = pos1,/noerase,xstyle = 1,ystyle = 2
for idir = 0, ndirs - 1 do begin
    oplot,realtime-stime, alldata(idir,pvar,*,iAlt1),color = colors(idir),$
      thick=3
endfor

plot,[stime,etime-stime],yrange2, /nodata, color = 1, background = 255,xrange = xrange,$
   yrange = yrange2, xtickname = strarr(10)+' ', xticks = xtickn, xminor = xminor,$
  xstyle = 1, charsize = 1.2,$
  ytitle = vars(pvar)+' ('+tostr(data(2,0,0,ialt2)/1000)+' km)',$
  xtickv=xtickv,ystyle=2,$
 pos = pos2,/noerase

for idir = 0, ndirs - 1 do begin
    oplot,realtime-stime, alldata(idir,pvar,*,iAlt2),color = colors(idir),$
      thick=3
endfor

plot,[stime,etime-stime],yrange3, /nodata, color = 1, background = 255,xrange = xrange,$
   yrange = yrange3, xtickname = strarr(10)+' ', xticks = xtickn, xminor = xminor,$
  xstyle = 1, charsize = 1.2,$
  ytitle = vars(pvar)+' ('+tostr(data(2,0,0,ialt3)/1000)+' km)',$
  xtickv=xtickv,ystyle=2,$
 pos = pos3,/noerase

for idir = 0, ndirs - 1 do begin
    oplot,realtime-stime, alldata(idir,pvar,*,iAlt3),color = colors(idir),$
      thick=3
endfor


legend,directories,colors=colors,pos = [.05,.3],/norm,linestyle = fltarr(ndirs),box=0,thick=3
closedevice
endif


if plotprof then begin
    ppp = 2
    space = 0.01
    pos_space, ppp, space, sizes, ny = ppp
    value = fltarr(ndirs,nalts-4)
    
    if n_elements(plotlog) eq 0 then plotlog = 0
    plotlog = fix(ask('whether to plot log: ',tostr(plotlog)))
    
   
    if n_elements(proftitle) eq 0 then proftitle = 'profile.ps'
    proftitle = ask('filename to plot to',proftitle)
    if (nFiles gt 1) then begin
        p = strpos(proftitle,'.ps')
        if (p gt -1) then psfile = strmid(proftitle,0,p-3)
        proftitle = psfile+'_'+chopr('00'+tostr(iFile),4)+'.ps'
    endif


    setdevice, proftitle,'p',5,.95
    loadct,39
     plotdirs = findgen(ndirs)
    nplotdirs = n_elements(plotdirs)
    plotcolors = findgen(nplotdirs)*(254-10)/(nplotdirs-1.)+10

    loc = 0
    
     if plotlog then begin
        for idir = 0, ndirs - 1 do begin
            value(idir,*) = alog10(alldata(plotdirs(idir),pvar,loc,2:nalts-3))
        endfor
    endif else begin
        for idir = 0, ndirs - 1 do begin
            value(idir,*) = alldata(plotdirs(idir),pvar,loc,2:nalts-3)
        endfor
    endelse

   
    xrange = mm(value)
    yrange = [100,500]

    get_position, ppp, space, sizes, 0, pos1,/rect
    plot, xrange, yrange,/nodata,color = 1, background = 255, xrange = xrange, $
      yrange = yrange,ytitle = 'Altitude',charsize = 1.2,/noerase,$
      pos=pos1,xtickname=strarr(10)+ ' '


    for idir = 0, nplotdirs - 1 do begin
        oplot, value(idir,*), $
          alldata(plotdirs(idir),2,loc,2:nalts-3)/1000.,thick = 3,$
          color = plotcolors(idir)
    endfor

    yrange = [100,200]
;    xrange = [0,1500]
    get_position, ppp, space, sizes, 1, pos2, /rect
    plot, xrange, yrange,/nodata,color = 1, background = 255, xrange = xrange, $
      yrange = yrange, xtitle = vars(pvar),ytitle = 'Altitude',charsize = 1.2,$
      ystyle = 1,/noerase,pos=pos2

     for idir = 0, nplotdirs - 1 do begin
        oplot, value(idir,*), $
          alldata(plotdirs(idir),2,loc,2:nalts-3)/1000.,thick = 3,$
          color = plotcolors(idir)
    endfor

    legend, directories(plotdirs),colors = plotcolors,pos=[pos1(0)+.05,pos1(3)-.08],$
      linestyle=fltarr(nplotdirs),box = 0,$
      thick = 3,/norm
closedevice
endif
       


end

