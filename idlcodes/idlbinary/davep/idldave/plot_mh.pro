
GetNewData = 1
fpi = 0

filelist_new = findfile("t*.3D*.save")
nfiles_new = n_elements(filelist_new)
if n_elements(nfiles) gt 0 then begin
    if (nfiles_new eq nfiles) then default = 'n' else default = 'y'
    GetNewData = mklower(strmid(ask('whether to reread data',default),0,1))
    if (GetNewData eq 'n') then GetNewData = 0 else GetNewData = 1
endif
mhfile = '~/Gitm/Runs/MillstoneHill/1029.dat'


;readmh, mhfile, mhtimearr, mhalts, mhelec
;n_mh = n_elements(mntimearr(0,*))
;mhrtime = fltarr(n_mh)
;for i = 0, n_mh - 1 do begin
;    c_a_to_r, mhtimearr(*,i),mhrtime(i)
;endfor

isFirstTime = 1

if (GetNewData) then begin
    nfiles = n_elements(filelist_new)
    sscoords = fltarr(2,nfiles)
    iTimeArray = intarr(6,nFiles)
    

    for iFile = 0, nFiles-1 do begin
        
        filename = filelist_new(iFile)
        
        print, 'Reading file ',filename
        
        read_thermosphere_file, filename, nvars, nalts, nlats, nlons, $
          vars, data, rb, cb, bl_cnt

        if iFile eq 0 then begin
            ssdata = fltarr(nvars,nfiles,nalts)
            realtime = fltarr(nfiles)
        endif

            if (strpos(filename,"save") gt 0) then begin
                
                fn = findfile(filename)
                if (strlen(fn(0)) eq 0) then begin
                    print, "Bad filename : ", filename
                    stop
                endif else filename = fn(0)
                
                l1 = strpos(filename,'.save')
                fn2 = strmid(filename,0,l1)
                len = strlen(fn2)
                l2 = l1-1
                while (strpos(strmid(fn2,l2,len),'.') eq -1) do l2 = l2 - 1
                l = l2 - 13
                year = fix(strmid(filename,l, 2))
                mont = fix(strmid(filename,l+2, 2))
                day  = fix(strmid(filename,l+4, 2))
                hour = float(strmid(filename, l+7, 2))
                minu = float(strmid(filename,l+9, 2))
                seco = float(strmid(filename,l+11, 2))
            endif else begin
                year = fix(strmid(filename,07, 2))
                mont = fix(strmid(filename,09, 2))
                day  = fix(strmid(filename,11, 2))
                hour = float(strmid(filename,14, 2))
                minu = float(strmid(filename,16, 2))
                seco = float(strmid(filename,18, 2))
            endelse
            
            itime = [year,mont,day,fix(hour),fix(minu),fix(seco)]
       
        
        iTimeArray(*,iFile) = itime
        iyear = year+2000
        stryear = strtrim(string(iyear),2)
        strmth = strtrim(string(mont),2)
        strday = strtrim(string(day),2)
        uttime = hour+minu/60.+seco/60./60.
        
        
        strdate = stryear+'-'+strmth+'-'+strday
       
        
        lonsun = 288.508
        latsun = 42.619
        degdiff = 10000.
        degdiffnew = 0.
        longdeg = data(0,*,0,0) * 180 / (!pi)

        if (isFirstTime) then begin
            for i = 0, nlons - 1 do begin
                if (longdeg(i) ge 0.0 and longdeg(i) le 360.0) then begin
                    degdiffnew = abs(longdeg(i) - lonsun)
                    if (degdiffnew lt degdiff) then begin
                        degdiff = degdiffnew
                        long_i = i
                    endif
                endif
            endfor

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
            isFirstTime = 0       
        endif

        
        sscoords(0,iFile) = long_i
        sscoords(1,iFile) = lat_i
     
        for i = 0, nAlts - 1 do begin
            ssdata(*,iFile,i) = data(*,sscoords(0,iFile),sscoords(1,iFile),i)
        endfor
        print, 'MH coordinates: ',ssdata(0,iFile,0)*180/!pi,' Long. ', ssdata(1,iFile,0)*180/!pi,' Lat.'
    endfor
endif

for i=0, nfiles-1 do begin
    c_a_to_r, iTimeArray(*,i),rtime
    realtime(i) = rtime
endfor

newtime = fltarr(nfiles,nalts)
for i = 0, nfiles - 1 do begin
    for j = 0, nalts - 1 do begin
        newtime(i,j) = realtime(i)
    endfor
endfor

stime = realtime(0)
etime = realtime(nfiles-1)

time_axis,stime, etime, btr, etr, xtickname,xtitle,xtickv,xminor,xtickn

display, vars
if (n_elements(iVar) eq 0) then iVar = 3
nVars = n_elements(Vars)
print, tostr(nVars),  ".  O/N2"
print, tostr(nVars+1),".  O/Nt"
print, tostr(nVars+2),".  O2/Nt"
print, tostr(nVars+3),".  N2/Nt"
print, tostr(nVars+4),".  N4S/Nt"
print, tostr(nVars+5),".  O Scale Height"
print, tostr(nVars+6),".  O2 Scale Height"
print, tostr(nVars+7),".  Pressure"
vars = [vars,'O/N!D2!N', 'O/Nt', 'O!D2!N/Nt', 'N!D2!N/Nt', $
        'N(!U4!DS)/Nt', $
        'O Scale Height','O2 Scale Height', $
        'Pressure']
iVar = fix(ask('variable to plot',tostr(iVar)))
if n_elements(alog) eq 0 then alog = 'n'
alog = ask('alog10 plot? (y/n)',alog)

pos = [.1,.1,.9,.9]

loadct, 39

setdevice,'plot.ps','l',5,.95
if(alog eq 'y') then begin
    mini = fix(ask('Plot min: (0.0 for automatic)'))
    maxi = fix(ask('Plot max: (0.0 for automatic)'))
    if mini eq 0.0 then mini = min(alog10(ssdata(iVar,*,*)))
    if maxi eq 0.0 then maxi = max(alog10(ssdata(iVar,*,*)))
levels = findgen(31) * (maxi-mini) / 30 + mini
    title = 'alog10 of '+vars(ivar)+' at Millstone Hill'
    contour, alog10(ssdata(iVar,*,*)),newtime,ssdata(2,*,*)/1000,/fill,levels=levels, xtitle = xtitle, xminor = xminor,xtickname=xtickname,xticks=xtickn,$
      xstyle = 1, charsize = 1.2,pos=pos,yrange = [0,800],title='Vertical Profile at Millstone Hill'

endif else begin
    mini = fix(ask('Plot min: (0.0 for automatic)'))
    maxi = fix(ask('Plot max: (0.0 for automatic)'))
    if mini eq 0.0 then mini = min(ssdata(iVar,*,*))
    if maxi eq 0.0 then maxi = max(ssdata(iVar,*,*))
levels = findgen(31) * (maxi-mini) / 30 + mini
    title = vars(ivar)+' at Millstone Hill'
    contour, ssdata(iVar,*,*),newtime,ssdata(2,*,*)/1000,/fill,levels=levels, xtitle = xtitle, xminor = xminor,xtickname=xtickname,xticks=xtickn,$
      xstyle = 1, charsize = 1.2,pos=pos,yrange = [0,800],title='Vertical Profile at Millstone Hill'
endelse

ctpos = pos
    ctpos(0) = pos(2)+0.025
    ctpos(2) = ctpos(0)+0.03
    maxmin = [mini,maxi]
    plotct, 255, ctpos, maxmin, title, /right

closedevice
;stop
;
;if (n_elements(iAlt) eq 0) then iAlt = 12
;for i=0,nalts-1 do print, tostr(i)+'. '+string(data(2,0,0,i)/1000)
;iAlt = fix(ask('which altitude to plot',tostr(iAlt)))
;yrange = [min(ssdata(iVar,*,iAlt))-.2*min(ssdata(iVar,*,iAlt)),max(ssdata(iVar,*,iAlt))+.1*max(ssdata(iVar,*,iAlt))]
;
;;iarr = intarr(n_mh)
;;for i = 0, n_mh - 1 do begin
;;    for j = 0, n_elements(n_elements(mhalts(*,i)) do begin
;;        if mhalts(j,i) - data(2,0,0,iAlt) lt jold then jold = j
;;        else goto, endj
;;    endfor
;;    endj:
;    
;
;if n_elements(ptitle) eq 0 then ptitle = 'plot.ps'
;ptitle = ask('Filename to plot to',ptitle)
;setdevice, ptitle,'l',5,.95
;
;title = 'Time Evolution of '+ strtrim(vars(ivar),2) + ' at Millstone Hill ('+strtrim(string(fix(data(2,0,0,iAlt)/1000.)),2)+'km)'
;pos = [.1,.1,.8,.8]
;plot,realtime-stime, /nodata, color = 1, background = 255,$
;  xtickname = xtickname, xtitle = xtitle, xminor = xminor,xtickv = xtickv,$
;  xticks = xtickn, xstyle = 1, charsize = 1.2, ytitle = vars(iVar),$
;  yrange = yrange, pos = pos, title = title
;oplot,realtime-stime, ssdata(iVar,*,iAlt),color = 30 
;
;;print max and min on graph
;maxstr = 'maximum: '+strtrim(string(max(ssdata(iVar,*,iAlt))),2)
;minstr = 'minimum: '+strtrim(string(min(ssdata(iVar,*,iAlt))),2)
;xyouts,0.83,.5,maxstr,charsize = 1.,/normal
;xyouts,.83,.47,minstr,/normal,charsize=1.
;closedevice
;
end
