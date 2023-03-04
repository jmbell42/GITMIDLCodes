getdata = 1

if n_elements(plotdif) eq 0 then plotdif = 0
plotdif = fix(ask('plot difference (0/1): ',tostr(plotdif)))

if n_elements(dir) eq 0 then dir = ' '
dir = ask('directory: ',dir)

if plotdif then begin
    if n_elements(dir_base) eq 0 then dir_base = ' '
    dir_base = ask('base directory: ',dir_base)
endif

if n_elements(starttime) eq 0 then starttime =  '000101_0000'
starttime = ask('start time (yymmdd_hhmm): ',starttime)

if n_elements(endtime) eq 0 then endtime = '000101_0000'
endtime = ask('end time (yymmdd_hhmm): ',endtime)

if n_elements(interval) eq 0 then interval = 4
interval = fix(ask('how many files to skip: ',tostr(interval)))

plotave = 0
plotloc = 0
if n_elements(aveask) eq 0 then aveask = 0
aveask = fix(ask('plot location/global average/local average (0/1/2):' $
,tostr(aveask)))

if aveask eq 1 then plotave = 1
if aveask eq 2 then plotloc = 1

if not plotave then begin
    if not plotloc then begin
        if n_elements(latloc1) eq 0 then latloc1 = 0
        latloc1 = float(ask('latitude to plot: ',tostrf(latloc1)))
        
        if n_elements(lonloc1) eq 0 then lonloc1 = 0
        lonloc1 = float(ask('longitude to plot: ',tostrf(lonloc1)))
    endif else begin
        if n_elements(latloc1) eq 0 then latloc1 = 0
        latloc1 = float(ask('1st latitude to plot: ',tostrf(latloc1)))
        
        if n_elements(latloc2) eq 0 then latloc2 = 0
        latloc2 = float(ask('2nd latitude to plot: ',tostrf(latloc2)))
        
        if n_elements(lonloc1) eq 0 then lonloc1 = 0
        lonloc1 = float(ask('1st longitude to plot: ',tostrf(lonloc1)))

        if n_elements(lonloc2) eq 0 then lonloc2 = 0
        lonloc2 = float(ask('2nd longitude to plot: ',tostrf(lonloc2)))
    endelse
endif

filelist = file_search(dir+'/3DALL*')

starti = where(filelist eq dir+'/3DALL_t'+starttime+'00.bin')
endi = where(filelist eq dir+'/3DALL_t'+endtime+'00.bin' )

files = indgen(fix((endi - starti)/(interval))+1)*interval + starti(0)
nfiles = n_elements(files)

if plotdif then begin
    filelist_base = file_search(dir_base+'/3DALL*')
    starti_base = where(filelist_base eq $
                        dir_base+'/3DALL_t'+starttime+'00.bin')
    endi_base = where(filelist_base eq $
                      dir_base+'/3DALL_t'+endtime+'00.bin' )

    files_base = indgen(fix((endi_base - starti_base)/ $
                            (interval))+1)*interval + starti_base(0)
endif

filename = filelist(files(0))
read_thermosphere_file, filename, nvars, nalts, nlats, nlons, $
  vars, data, rb, cb, bl_cnt

alt = reform(data(2,*,*,*)) / 1000.0
lat = reform(data(1,*,*,*)) / !dtor
lon = reform(data(0,*,*,*)) / !dtor
alts = reform(data(2,0,0,2:nalts-3))/1000.0

if not plotave and not plotloc then begin
    latmin = min((abs(lat(0,*,0) - latloc1)),ilat)
    lonmin = min((abs(lon(*,0,0) - lonloc1)),ilon)
endif
if plotloc then begin
    latmin1 = min((abs(lat(0,*,0) - latloc1)),ilat1)
    lonmin1 = min((abs(lon(*,0,0) - lonloc1)),ilon1)
    latmin2 = min((abs(lat(0,*,0) - latloc2)),ilat2)
    lonmin2 = min((abs(lon(*,0,0) - lonloc2)),ilon2)
    nlontot = abs(ilon2-ilon1) + 1
    nlattot = abs(ilat2-ilat1) + 1
    if ilon2 lt ilon1 then begin
        l = ilon2
        ilon2 = ilon1
        ilon1 = l
    endif
    if ilat2 lt ilat1 then begin
        l = ilat2
        ilat2 = ilat1
        ilat1 = l
    endif
endif

time = intarr(nfiles,6)

for ivar = 0, nvars - 1 do print, ivar, vars(ivar)

if n_elements(var) eq 0 then var = 32
var = fix(ask('variable to plot: ',tostr(var)))


profile = fltarr(nfiles,nalts-4)

if plotdif then profile_base = fltarr(nfiles,nalts-4)

for ifile = 0, nfiles-1 do begin
    filename = filelist(files(ifile))
    
    print, 'Working on file: ', filename, '...'
  
    read_thermosphere_file, filename, nvars, nalts, nlats, nlons, $
      vars, data, rb, cb, bl_cnt

    if plotdif then begin
        filename_base = filelist_base(files_base(ifile))
        read_thermosphere_file, filename_base, nvars, nalts, $
          nlats, nlons, vars, data_base, rb, cb, bl_cnt
    endif

    if plotave then begin
        for ialt = 0, nalts-5 do begin
            profile(ifile,ialt) = $
              mean(data(var,2:nlons-3,2:nlats-3,ialt+2)) 
        endfor
    endif else begin
        if plotloc then begin
            for i = ilon1, ilon2 do begin
                for j = ilat1, ilat2 do begin
                    profile(ifile,*) = profile(ifile,*) + $
                      data(var,i,j,2:nalts-3)
                endfor
            endfor
            profile(ifile,*) = $
              profile(ifile,*)/float(nlontot*nlattot)
        endif else begin
            profile(ifile,*) = data(var,ilon,ilat,2:nalts-3)
        endelse
    endelse

    if plotdif then begin
        if plotave then begin
            for ialt = 0, nalts - 5 do begin
                profile_base(ifile,ialt) = $
                  mean(data_base(var,2:nlons-3,2:nlats-3,ialt+2)) 
            endfor
        endif else begin
            if plotloc then begin
                for i = ilon1, ilon2 do begin
                    for j = ilat1, ilat2 do begin
                        profile_base(ifile,*) = $
                          profile_base(ifile,*) + data_base(var,i,j,2:nalts-3)
                    endfor
                endfor
                profile_base(ifile,*) = $
                  profile_base(ifile,*)/float(nlontot*nlattot)
            endif else begin
                profile_base(ifile,*) = data_base(var,ilon,ilat,2:nalts-3)
            endelse
        endelse
    endif 
        

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
       
     time(ifile,*) = [year,mont,day,fix(hour),fix(minu),fix(seco)]
endfor    

nlinesperplot = nfiles 

yrange = [100,700]

iviu = where(vars eq 'V!Di!N(up)')
ivie = where(vars eq 'V!Di!N(east)')
ivin = where(vars eq 'V!Di!N(north)')
ivnu = where(vars eq 'V!Dn!N(up)')

if plotdif then begin

    if var eq iviu or var eq ivin or var eq ivie then begin
         profdiff = (profile - profile_base)
         xtitlediff = vars(var)+' Diff'
    endif else begin
        
        profdiff = (profile - profile_base)/profile_base * 100.0 
        
        xtitlediff = vars(var)+' % Diff'
        profile_basep = alog10(profile_base)
    endelse
endif 

if var eq 32 then begin
       
    if plotdif then begin        
        hmf2 = fltarr(nfiles,5) - 5000
        val = fltarr(nfiles,5) - 5000
        for ifile = 0, nfiles -1 do begin
            temp1 = max(profile(ifile,*),imax1)
            temp2 = max(profile_base(ifile,*),imax2)
            hmf2(ifile,0) =  (alts(imax1)-alts(imax2))/alts(imax2) * 100
        
            val(ifile,0) = $
              (max(profile(ifile,*)) - max(profile_base(ifile,*)))/ $
              max(profile_base(ifile,*)) * 100.0
            yrangediff = mm(hmf2(*,0))
            yrangediff = $
              [yrangediff(0) - abs(.1*yrangediff(0)),$
               yrangediff(1) + abs(.05*yrangediff(1))]
            if yrangediff(0) eq 0 and yrangediff(1) eq 0 then $
              yrangediff = [-1,1]
            xrangediff = mm(val(*,0))
            xrangediff = $
              [xrangediff(0) - abs(.1*xrangediff(0)),$
               xrangediff(1) + abs(.05*xrangediff(1))]
        endfor

        xtitlediff = 'N!Dm!NF!D2!N % Diff'
        ytitlediff = 'H!Dm!NF!D2!N (km) %Diff'

    endif

    profilep = alog10(profile)

    xtitle = 'log!D10!N '+vars(var) + ' m!U-3!N' 
    xtitled = vars(var) + ' % Difference'
endif else begin
    profilep = profile
;    xrange = mm(profilep)
    xtitle = vars(var)

    if plotdif then xrangediff = mm(profdiff)
    
    
endelse
ytitle = 'Altitude (km)'
xrange = mm(profilep)
xrange = [xrange(0) * .9,xrange(1) * 1.05]
;xrange = [9,11.5]
setdevice,'prof.ps','p',5,.95

loadct, 39
ppp = 4
space = 0.05
pos_space, ppp, space, sizes

get_position, ppp, space, sizes, 0, pos, /rect

colors = indgen(nlinesperplot)*(220 - 10)/(nlinesperplot-1) + 10

plot, profilep(0,*), alts, /nodata, xrange = xrange, yrange = yrange, $
  charsize = 1.2, xtitle = xtitle, xstyle = 1, $
  ytitle = ytitle,/noerase, pos = pos, $
  ytickname = ytickname,ystyle = 1

;symlines = fltarr(nlinesperplot*2,2)
;symlines(*,1) = -5000
;symlines(0,0) = profilep(0,31)
;symlines(1,0) = profilep(1,34)
;symlines(2,0) = profilep(2,38)
;symlines(3,0) = profilep(3,43)
;symlines(4,0) = profilep(4,45)
;symlines(5,0) = profile_basep(0,32)
;symlines(6,0) = profile_basep(1,37)
;symlines(7,0) = profile_basep(2,44)
;symlines(8,0) = profile_basep(3,44)
;symlines(9,0) = -5000
;symalts = fltarr(nlinesperplot*2,2)
;symalts(*,1) = -5000
;symalts(0,0) = alts(31)
;symalts(1,0) = alts(34)
;symalts(2,0) = alts(38)
;symalts(3,0) = alts(43)
;symalts(4,0) = alts(45)
;symalts(5,0) = alts(32)
;symalts(6,0) = alts(37)
;symalts(7,0) = alts(44)
;symalts(8,0) = alts(44)
;symalts(9,0) = alts(49)


syms = intarr(nlinesperplot)
for iline = 0, nlinesperplot - 1 do begin
    syms(iline) = sym(iline)
    oplot, profilep(iline,*), alts, color = colors(iline), thick = 3
    oplot, profile_basep(iline,*), alts, color = colors(iline), thick = 3, $
      linestyle = 2
   ; oplot, symlines(iline,*), symalts(iline,*), psym=syms(iline)
   ; oplot, symlines(iline+5,*), symalts(iline+5,*), psym=syms(iline)
endfor

lsyms = syms*(-1)
legend,[tostr(time(0:nlinesperplot-1,3))+'UT'],$
  color = colors, linestyle = 0, $
  thick = 3, box = 0, pos = [pos(2) - .2,pos(1) + .1],/norm

if plotdif then begin
    get_position, ppp, space, sizes, 1, pos, /rect
    
    plot, profilep(0,*), alts, /nodata, xrange = xrange, yrange = yrange, $
      charsize = 1.2, xtitle = xtitle, xstyle = 1, $
      /noerase, pos = pos, $
      ytickname = strarr(10) + ' ',ystyle = 1
    
    for iline = 0, nlinesperplot - 1 do begin
        oplot, profile_basep(iline,*), alts, color = colors(iline), thick = 3
    endfor
    
  
     get_position, ppp, space, sizes, 2, pos, /rect
     pos(1) = pos(1) -.05
     pos(3) = pos(3) -.05
     plot,profdiff(0,*), alts, /nodata, xrange = xrangediff, $
       yrange = yrange, $
       charsize = 1.2, xtitle = xtitled, xstyle = 1, $
       ytitle = ytitle,/noerase, pos = pos, $
       ytickname = ytickname,ystyle = 1
    
    for iline = 0, nlinesperplot - 1 do begin
        oplot, profdiff(iline,*), alts, color = colors(iline), thick = 3
    endfor

    if var eq 32 then begin
        get_position, ppp, space, sizes, 3, pos, /rect
        pos(1) = pos(1) -.05
        pos(3) = pos(3) -.05
        plot, val(0,*), alts, /nodata, xrange = xrangediff, yrange = yrangediff, $
          charsize = 1.2, xtitle = xtitlediff, xstyle = 1, $
          /noerase, pos = pos,ytickname = strarr(10) + ' ', $
          ystyle = 1
        axis, xrangediff(1),yaxis=1,ytitle = ytitlediff
        
        for iline = 0, nlinesperplot - 1 do begin
            oplot, val(iline,*), Hmf2(iline,*), $
              psym = 2, symsize = 3, color = colors(iline), thick = 3
        endfor
    endif else begin
      ;  for iline = 0, nlinesperplot - 1 do begin
      ;      oplot, val(iline,*), alts, $
      ;        color = colors(iline), thick = 3 
      ;  endfor
    endelse

endif


closedevice
        



end
