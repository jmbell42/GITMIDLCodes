GetNewData = 1

if n_elements(directorypert) eq 0 then directorypert = '.'
if n_elements(directorybase) eq 0 then directorybase = '.'
directorypert = ask('perturbation directory: ',directorypert)
directorybase = ask('base directory: ',directorybase)

filelist_newpert = findfile(directorypert+'/3DALL*.bin')
filelist_newbase = findfile(directorybase+'/3DALL*.bin')
nfiles_new = min([n_elements(filelist_newpert),n_elements(filelist_newbase)],smalldir)
locs = intarr(nfiles_new)


if n_elements(nfiles) gt 0 then begin
    if (nfiles_new eq nfiles) then default = 'n' else default = 'y'
    GetNewData = mklower(strmid(ask('whether to reread data',default),0,1))
    if (GetNewData eq 'n') then GetNewData = 0 else GetNewData = 1
endif

if n_elements(filename) eq 0 then begin
filename = filelist_newpert(0)
read_thermosphere_file, filename, nvars, nalts, nlats, nlons, $
  vars, data1, rb, cb, bl_cnt
lon = fltarr(nlons)
endif

for ivars = 0, nvars - 1 do print, ivars, ' ',vars(ivars)
if n_elements(ivar) eq 0 then ivar = 3
ivar = fix(ask('which variable to plot: ',tostr(ivar)))

alts = reform(data1(2,0,0,*))/1000.
for ialt = 0, nalts - 1 do print, ialt,'  ',alts(ialt)
if n_elements(ialt1) eq 0 then ialt1 = 0
if n_elements(ialt2) eq 0 then ialt2 = 0

ialt1 = fix(ask('first altitude to plot: ',tostr(ialt1)))
ialt2 = fix(ask('second altitude to plot: ',tostr(ialt2)))

if (GetNewData) then begin

   lenpert = strlen(directorypert) + 1+13
   lenbase = strlen(directorybase) + 1+13

   if smalldir eq 0 then begin
       for ifile = 0, nfiles_new-1 do begin
           locs(ifile) = where(strmid(filelist_newbase,lenbase) eq $
                               strmid(filelist_newpert(ifile),lenpert))
       endfor
       filelist1 = filelist_newpert
       filelist2 = filelist_newbase
   endif else begin
       for ifile = 0, nfiles_new-1 do begin
           locs(ifile) = where(strmid(filelist_newpert,lenpert) eq $
                               strmid(filelist_newbase(ifile),lenbase))
       endfor
       filelist1 = filelist_newbase
       filelist2 = filelist_newpert
   endelse

loc = where(locs ne -1)
nf = n_elements(locs)
rtime = fltarr(nf)
nfiles = nfiles_new
iTimeArray = intarr(6,nf)


daymax1 = fltarr(nfiles)
daymax2 = fltarr(nfiles)
nightmax1 = fltarr(nfiles)
nightmax2 = fltarr(nfiles)

    for iFile = 0, nf - 1 do begin
        
        filename1 = filelist1(loc(ifile))
        filename2 = filelist2(locs(ifile))

        print, 'Reading files ',filename1, ' and ',filename2
        
        read_thermosphere_file, filename1, nvars, nalts, nlats, nlons, $
          vars, data1, rb, cb, bl_cnt
    
         read_thermosphere_file, filename2, nvars, nalts, nlats, nlons, $
          vars, data2, rb, cb, bl_cnt
    
        
        if ifile eq 0 then begin
            daydata1 = fltarr(nfiles,nvars,nalts)
            nightdata1 = fltarr(nfiles,nvars,nalts)
            daydata2 = fltarr(nfiles,nvars,nalts)
            nightdata2 = fltarr(nfiles,nvars,nalts)
        endif

        fn = file_search(filename1)
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
        
        itime = [year,mont,day,fix(hour),fix(minu),fix(seco)]
        c_a_to_r,itime,rt
        rtime(ifile) = rt

        if year lt 50 then iyear = year + 2000 else iyear = year + 1900
        stryear = strtrim(string(iyear),2)
        strmth = strtrim(string(mont),2)
        strday = strtrim(string(day),2)
        uttime = hour+minu/60.+seco/60./60.
       
        strdate = stryear+'-'+strmth+'-'+strday
        
        daypos = fltarr(nlons,nlats)
        nightpos = fltarr(nlons,nlats)
        daycount = 0
        nightcount = 0
        tempdata1 = [0]
        tempdata2 = [0]
        
        for ilat = 0, nlats - 1 do begin
            for ilon = 0, nlons - 1 do begin
                lat = data1(1,0,ilat,0)*180/!pi
                lon = data1(0,ilon,0,0)*180/!pi
                if lon gt 180 then lon = 360. - lon
                zsun,strdate,uttime ,lat,lon,$
                  zenith,azimuth,solfac
                szaarr(ilon,ilat) = zenith
                
                if zenith lt 30 and abs(data1(1,0,ilat,0)*180/!pi) le 90. $
                  and data1(0,ilon,0,0)*180/!pi ge 0. and data1(0,ilon,0,0)*180/!pi le 360 $
                  then begin 
                    tempdata1 = [tempdata1,data1(0,ilon,ilat,0)]
                    tempdata2 = [tempdata2,data2(0,ilon,ilat,0)]
                    for ivars = 0, nvars - 1 do begin
                        daydata1(ifile,ivars,*) = daydata1(ifile,ivars,*)+data1(ivars,ilon,ilat,*) 
                        daydata2(ifile,ivars,*) = daydata2(ifile,ivars,*)+data2(ivars,ilon,ilat,*) 

                       ; if (ilat eq 36 and ivars eq 0) then begin
                       ;     print, ilon, ilat, ivars, ifile, data1(1,ilon,ilat,0)/!dtor, zenith
                       ; endif

                        if smalldir eq 0 then begin
                            tempavg1 = (daydata1(ifile,ivar,ialt1)-daydata2(ifile,ivar,ialt1))/$
                              daydata2(ifile,ivar,ialt1)
                            tempavg2 = (daydata1(ifile,ivar,ialt2)-daydata2(ifile,ivar,ialt2))/$
                              daydata2(ifile,ivar,ialt2)
                        endif else begin
                            tempavg1 = (daydata2(ifile,ivar,ialt1)-daydata1(ifile,ivar,ialt1))/$
                              daydata1(ifile,ivar,ialt1)
                            tempavg2 = (daydata2(ifile,ivar,ialt2)-daydata1(ifile,ivar,ialt2))/$
                              daydata1(ifile,ivar,ialt2)
                        endelse
                        if daymax1(ifile) lt tempavg1 then begin
                            daymax1(ifile) = tempavg1
                        endif
                        if daymax2(ifile) lt tempavg2 then begin
                            daymax2(ifile) = tempavg2
                        endif
                                                
                    endfor
                  
                      daycount = daycount + 1.
                  endif

                if zenith gt 150 and abs(data1(1,0,ilat,0)*180/!pi) le 90. $
                  and data1(0,ilon,0,0)*180/!pi ge 0. and data1(0,ilon,0,0)*180/!pi le 360 $
                  then begin
                    for ivars = 0, nvars - 1 do begin

                        if smalldir eq 0 then begin
                            tempavg1 = (nightdata1(ifile,ivar,ialt1)-nightdata2(ifile,ivar,ialt1))/nightdata2(ifile,ivar,ialt1)
                            tempavg2 = (nightdata1(ifile,ivar,ialt2)-nightdata2(ifile,ivar,ialt2))/nightdata2(ifile,ivar,ialt2)
                        endif else begin
                            tempavg1 = (nightdata2(ifile,ivar,ialt1)-nightdata1(ifile,ivar,ialt1))/nightdata1(ifile,ivar,ialt1)
                            tempavg2 = (nightdata2(ifile,ivar,ialt2)-nightdata1(ifile,ivar,ialt2))/nightdata1(ifile,ivar,ialt2)
                        endelse
                        if nightmax1(ifile) lt tempavg1 then begin
                            nightmax1(ifile) = tempavg1
                         endif
                        if daymax2(ifile) lt tempavg2 then begin
                            nightmax2(ifile) = tempavg2
                        endif

                        nightdata1(ifile,ivars,*) = nightdata1(ifile,ivars,*)+data1(ivars,ilon,ilat,*)
                        nightdata2(ifile,ivars,*) = nightdata2(ifile,ivars,*)+data2(ivars,ilon,ilat,*)
                    endfor
                      nightcount = nightcount + 1.
                  endif
            endfor
        endfor

        daydata1(ifile,*,*) = daydata1(ifile,*,*)/daycount
         nightdata1(ifile,*,*) = nightdata1(ifile,*,*)/nightcount
         daydata2(ifile,*,*) = daydata2(ifile,*,*)/daycount
         nightdata2(ifile,*,*) = nightdata2(ifile,*,*)/nightcount

        if smalldir eq 0 then begin
            daydiff = (daydata1 - daydata2)/daydata2*100
            nightdiff = (nightdata1 - nightdata2)/nightdata2*100
        endif else begin
            daydiff = (daydata2 - daydata1)/daydata1*100
            nightdiff = (nightdata2 - nightdata1)/nightdata1*100
        endelse
    endfor
   
stime = rtime(0)
etime = max(rtime)

time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn

endif

dayv1 = (daydiff(*,ivar,ialt1))
dayv2 = (daydiff(*,ivar,ialt2))
nightv1 = (nightdiff(*,ivar,ialt1))
nightv2 = (nightdiff(*,ivar,ialt2))

xrange = [0,etime - stime]
yranged1 = [.95*min(dayv1),1.05*max(dayv1)]
yranged2 = [.95*min(dayv2),1.05*max(dayv2)]
yrangen1 = [.95*min(nightv1),1.05*max(nightv1)]
yrangen2 = [.95*min(nightv2),1.05*max(nightv2)]

ppp = 4
space = 0.01
pos_space, ppp, space, sizes, ny = ppp
    
 get_position, ppp, space, sizes, 0, pos, /rect
setdevice,'avecomp_'+tostr(itime(2))+'_day.ps','p',5,.95
plot, rtime-stime,/nodata, ytitle = strmid(vars(ivar),0,4) + ' % diff', /noerase, $
          xtickname = strarr(10)+' ', xtickv = xtickv, xrange = xrange,$
          xminor = xminor, xticks = xtickn, xstyle = 1, pos = pos, $
          yrange = yranged1, ystyle = 1, thick = 3, charsize = 1.2

oplot,rtime-stime,dayv1
oplot,rtime-stime,daymax1,linestyle = 2
xyouts, pos(0)+.05,pos(3)-.03,'Dayside average at '+tostr(alts(ialt1))+ ' km',/norm

get_position, ppp, space, sizes, 1, pos, /rect
plot, rtime-stime,/nodata, ytitle = strmid(vars(ivar),0,4) + ' % diff', /noerase, $
          xtickname = strarr(10)+' ', xtickv = xtickv, xrange = xrange, $
          xminor = xminor, xticks = xtickn, xstyle = 1, pos = pos, $
          yrange = yranged2, ystyle = 1, thick = 3, charsize = 1.2

oplot,rtime-stime,dayv2
oplot,rtime-stime,daymax2,linestyle = 2
xyouts, pos(0)+.05,pos(3)-.03,'Dayside average at '+tostr(alts(ialt2))+ ' km',/norm

get_position, ppp, space, sizes, 2, pos, /rect
plot, rtime-stime,/nodata, ytitle = strmid(vars(ivar),0,4) + ' % diff', /noerase, $
          xtickname = strarr(10)+' ', xtickv = xtickv, xrange = xrange,$
          xminor = xminor, xticks = xtickn, xstyle = 1, pos = pos, $
          yrange = yrangen1, ystyle = 1, thick = 3, charsize = 1.2

oplot,rtime-stime,nightv1
oplot,rtime-stime,nightmax1,linestyle = 2
xyouts, pos(0)+.05,pos(3)-.03,'Nightside average at '+tostr(alts(ialt1))+ ' km',/norm

get_position, ppp, space, sizes, 3, pos, /rect
plot, rtime-stime,/nodata, ytitle =  strmid(vars(ivar),0,4) + ' % diff', /noerase, $
          xtickname = xtickname, xtickv = xtickv,xrange = xrange, $
          xminor = xminor, xticks = xtickn, xstyle = 1, pos = pos, $
          yrange = yrangen2, ystyle = 1, thick = 3, charsize = 1.2,xtitle=xtitle

oplot,rtime-stime,nightv2
oplot,rtime-stime,nightmax2,linestyle = 2

xyouts, pos(0)+.05,pos(3)-.03,'Nightside average at '+tostr(alts(ialt2))+ ' km',/norm
closedevice

maxd = max(dayv2,imaxd)
maxn = max(nightv2,imaxn)

maxdtime = rtime(imaxd)
maxntime = rtime(imaxn)

responcetime = (maxntime-maxdtime)/3600.

print, 'Time delay at nightside: ',tostr(floor(responcetime)), ' hours ', $
  tostr((responcetime-floor(responcetime))*60), ' minutes ' 

c_r_to_a,itmday,maxdtime
c_r_to_a,itmnight,maxntime

end




