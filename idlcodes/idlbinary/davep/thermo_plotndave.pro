GetNewData = 1

if n_elements(directory) eq 0 then directory = '.'
directory = ask('which directory: ',directory)

filelist_new = findfile(directory+'/3DALL*.bin')
filetype = 'bin'
if n_elements(filelist_new) le 1 then begin
    filelist_new = file_search(directory+'/*.3DALL.save')
    filetype = 'save'
endif
nfiles_new = n_elements(filelist_new)

if n_elements(nfiles) gt 0 then begin
    if (nfiles_new eq nfiles) then default = 'n' else default = 'y'
    GetNewData = mklower(strmid(ask('whether to reread data',default),0,1))
    if (GetNewData eq 'n') then GetNewData = 0 else GetNewData = 1
endif



if (GetNewData) then begin
    rtime = fltarr(nfiles_new)
    nfiles = n_elements(filelist_new)
    iTimeArray = intarr(6,nFiles)
       
    for iFile = 0, nFiles-1 do begin
        
        filename = filelist_new(iFile)
        
        print, 'Reading file ',filename
        
        read_thermosphere_file, filename, nvars, nalts, nlats, nlons, $
          vars, data, rb, cb, bl_cnt
    
        if ifile eq 0 then begin
            daydata = fltarr(nfiles,nvars,nalts)
            nightdata = fltarr(nfiles,nvars,nalts)
        endif

        fn = file_search(filename)
        if (strlen(fn(0)) eq 0) then begin
            print, "Bad filename : ", filename
            stop
        endif else filename = fn(0)
        
        if filetype eq 'bin' then begin
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
        endif 
        
        if filetype eq 'save' then begin
            l1 = strpos(filename,'.3DALL')
            fn2 = strmid(filename,0,l1)
            len = strlen(fn2)
            l = len - 13
            year = fix(strmid(filename,l, 2))
            mont = fix(strmid(filename,l+2, 2))
            day  = fix(strmid(filename,l+4, 2))
            hour = float(strmid(filename, l+7, 2))
            if ifile eq 0 then minu = 0 else minu = float(strmid(filename, l+9, 2))
            seco = 0
        endif

        itime = [year,mont,day,fix(hour),fix(minu),fix(seco)]
        c_a_to_r,itime,rt
        rtime(ifile) = rt
        if year lt 50 then iyear = year + 2000 else iyear = year + 1900
        stryear = strtrim(string(iyear),2)
        strmth = strtrim(string(mont),2)
        strday = strtrim(string(day),2)
        uttime = hour+minu/60.+seco/60./60.
       
        strdate = stryear+'-'+strmth+'-'+strday
        
        szaarr = fltarr(nlats,nlons)
        daypos = fltarr(nlons,nlats)
        nightpos = fltarr(nlons,nlats)
        daycount = 0
        nightcount = 0

        for ilat = 0, nlats - 1 do begin
            for ilon = 0, nlons - 1 do begin
                zsun,strdate,uttime ,data(1,0,ilat,0)*180/!pi,data(0,ilon,0,0)*180/!pi,$
                  zenith,azimuth,solfac
                szaarr(ilat,ilon) = zenith
                
                if zenith lt 30 and abs(data(1,0,ilat,0)*180/!pi) le 90. $
                  and data(0,ilon,0,0)*180/!pi ge 0. and data(0,ilon,0,0)*180/!pi le 360 $
                  then begin 
                    
                    for ivar = 0, nvars - 1 do begin
                        daydata(ifile,ivar,*) = daydata(ifile,ivar,*)+data(ivar,ilon,ilat,*)
                    endfor
                      daycount = daycount + 1.
                  endif

                if zenith gt 150 and abs(data(1,0,ilat,0)*180/!pi) le 90. $
                  and data(0,ilon,0,0)*180/!pi ge 0. and data(0,ilon,0,0)*180/!pi le 360 $
                  then begin
                    for ivar = 0, nvars - 1 do begin
                        nightdata(ifile,ivar,*) = nightdata(ifile,ivar,*)+data(ivar,ilon,ilat,*)
                    endfor
                      nightcount = nightcount + 1.
                endif
            endfor
        endfor
        
         daydata(ifile,*,*) = daydata(ifile,*,*)/daycount
         nightdata(ifile,*,*) = nightdata(ifile,*,*)/nightcount
        
    endfor
   
alts = reform(data(2,0,0,*))/1000.
stime = rtime(0)
etime = max(rtime)

time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn

endif

for ivars = 0, nvars - 1 do print, ivars, ' ',vars(ivars)
if n_elements(ivar) eq 0 then ivar = 3
ivar = fix(ask('which variable to plot: ',tostr(ivar)))

for ialt = 0, nalts - 1 do print, ialt,'  ',alts(ialt)
if n_elements(ialt1) eq 0 then ialt1 = 0
if n_elements(ialt2) eq 0 then ialt2 = 0

ialt1 = fix(ask('first altitude to plot: ',tostr(ialt1)))
ialt2 = fix(ask('second altitude to plot: ',tostr(ialt2)))

dayv1 = (daydata(*,ivar,ialt1))
dayv2 = (daydata(*,ivar,ialt2))
nightv1 = (nightdata(*,ivar,ialt1))
nightv2 = (nightdata(*,ivar,ialt2))

xrange = [0,etime - stime]
yranged1 = [.95*min(dayv1),1.05*max(dayv1)]
yranged2 = [.95*min(dayv2),1.05*max(dayv2)]
yrangen1 = [.95*min(nightv1),1.05*max(nightv1)]
yrangen2 = [.95*min(nightv2),1.05*max(nightv2)]

ppp = 4
space = 0.01
pos_space, ppp, space, sizes, ny = ppp
    
 get_position, ppp, space, sizes, 0, pos, /rect
pos(0) = pos(0) + .07
setdevice,'ave_'+tostr(itime(2))+'_day.ps','p',5,.95
plot, rtime-stime,/nodata, ytitle = vars(ivar), /noerase, $
          xtickname = strarr(10)+' ', xtickv = xtickv, xrange = xrange,$
          xminor = xminor, xticks = xtickn, xstyle = 1, pos = pos, $
          yrange = yranged1, ystyle = 1, thick = 3, charsize = 1.2

oplot,rtime-stime,dayv1
xyouts, pos(0)+.05,pos(3)-.03,'Dayside average at '+tostr(alts(ialt1))+ ' km',/norm

get_position, ppp, space, sizes, 1, pos, /rect
pos(0) = pos(0) + .07
plot, rtime-stime,/nodata, ytitle =vars(ivar), /noerase, $
          xtickname = strarr(10)+' ', xtickv = xtickv, xrange = xrange, $
          xminor = xminor, xticks = xtickn, xstyle = 1, pos = pos, $
          yrange = yranged2, ystyle = 1, thick = 3, charsize = 1.2

oplot,rtime-stime,dayv2
xyouts, pos(0)+.05,pos(3)-.03,'Dayside average at '+tostr(alts(ialt2))+ ' km',/norm

get_position, ppp, space, sizes, 2, pos, /rect
pos(0) = pos(0) + .07
plot, rtime-stime,/nodata, ytitle =vars(ivar), /noerase, $
          xtickname = strarr(10)+' ', xtickv = xtickv, xrange = xrange,$
          xminor = xminor, xticks = xtickn, xstyle = 1, pos = pos, $
          yrange = yrangen1, ystyle = 1, thick = 3, charsize = 1.2

oplot,rtime-stime,nightv1
xyouts, pos(0)+.05,pos(3)-.03,'Nightside average at '+tostr(alts(ialt1))+ ' km',/norm

get_position, ppp, space, sizes, 3, pos, /rect
pos(0) = pos(0) + .07
plot, rtime-stime,/nodata, ytitle = vars(ivar), /noerase, $
          xtickname = xtickname, xtickv = xtickv,xrange = xrange, $
          xminor = xminor, xticks = xtickn, xstyle = 1, pos = pos, $
          yrange = yrangen2, ystyle = 1, thick = 3, charsize = 1.2,xtitle=xtitle

oplot,rtime-stime,nightv2
xyouts, pos(0)+.05,pos(3)-.03,'Nightside average at '+tostr(alts(ialt2))+ ' km',/norm
closedevice

setdevice,'plot.ps','p',5,.95
ppp = 2
space = 0.01
pos_space, ppp, space, sizes, ny = ppp
    
get_position, ppp, space, sizes, 0, pos, /rect
pos(0) = pos(0) + .07
plot, rtime-stime,/nodata, ytitle = vars(ivar), /noerase, $
          xtickname = strarr(10)+' ', xtickv = xtickv, xrange = xrange,$
          xminor = xminor, xticks = xtickn, xstyle = 1, pos = pos, $
          yrange = [0,5], ystyle = 1, thick = 3, charsize = 1.2

oplot,rtime-stime,dayv1/nightv1
xyouts, pos(0)+.05,pos(3)-.03,'Dayside ave/nighside ave at '+tostr(alts(ialt1))+ ' km',/norm

get_position, ppp, space, sizes, 1, pos, /rect
pos(0) = pos(0) + .07

plot, rtime-stime,/nodata, ytitle = vars(ivar), /noerase, $
          xtickname = xtickname, xtickv = xtickv,xrange = xrange, $
          xminor = xminor, xticks = xtickn, xstyle = 1, pos = pos, $
          yrange = [0,5], ystyle = 1, thick = 3, charsize = 1.2,xtitle=xtitle

oplot,rtime-stime,dayv2/nightv2
xyouts, pos(0)+.05,pos(3)-.03,'Dayside ave/Nightside ave at '+tostr(alts(ialt2))+ ' km',/norm
xyouts, .85, .95,'F10.7 = 100',/norm
closedevice

end

