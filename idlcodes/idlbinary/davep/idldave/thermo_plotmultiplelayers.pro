pro thermo_plotmultiplelayers,nslices,ialts,nvars,sel,nfiles, $
                yeslog, nolog,nalts,nlats,nlons,yeswrite_cnt,$
                polar,npolar,MinLat,showgridyes,	  $
                plotvectoryes,vi_cnt,vn_cnt,cf,	  $
                cursor_cnt,data,alt,lat,lon,	  $
                xrange,yrange,smini,smaxi,	  $
                filename,vars, psfile, mars, colortable, itime



if mars then begin
  file = '~/idl/marsflat.jpg'
   read_jpeg, file, image
   nx = n_elements(image(0,*,0))
   ny = n_elements(image(0,0,*))
   new_image = fltarr(nx,ny)
                                ;We usually plot with 0 lon in the
                                ;middle, but the jpeg as 0 lon on the right...
for i=nx/2, nx-1 do begin
   new_image(i-nx/2,0:ny-1)  = image(2,i,*)
   new_image(i,0:ny-1)  = image(2,i-nx/2,*)
endfor
endif

if (n_elements(colortable) eq 0) then colortable = 'mid'
if (strlen(colortable) eq 0) then colortable = 'mid'

if (n_elements(logplot) eq 0) then logplot = yeslog

if (min(data(sel,*,*,*)) lt 0.0) then begin
  logplot = 0
  yeslog = 0
  nolog = 1
endif


tempdata=fltarr(nslices,nlons,nlats)
for i = 0, nslices -1 do begin
  tempdata(i,*,*) = data(sel,*,*,ialts(i))
endfor
maxminall = mm(tempdata)
;if (n_elements(iTime) eq 0) then begin

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
        if (strpos(filename,"bin") gt 0) then begin
            l1 = strpos(filename,'.bin')
            fn2 = strmid(filename,0,l1)
            len = strlen(fn2)
            l2 = l1-1
            l = l1 - 13
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
    endelse

    itime = [year,mont,day,fix(hour),fix(minu),fix(seco)]

;endif

c_a_to_s, itime, stime
c_a_to_r,itime,rtime

ut = itime(3) + itime(4)/60.0 + itime(5)/3600.0

;Get Subsolar point
zdate = tostr(year(0)+2000)+'-'+chopr('0'+tostr(mont(0)),2)+'-'+chopr('0'+tostr(day(0)),2)
ztime = fix(hour)+fix(minu)/60.+fix(seco)/3600.
zlat = 0
zlon = 0

zsun,zdate,ztime,zlat,zlon,zenith,azimuth,solfac,latsun=latsun,lonsun=lonsun
;
nLons = n_elements(lon(*,0,0))
localtime = fltarr(nlons)

for ilon = 0, nlons - 1 do begin
   localtime(ilon) = convert_time(rtime,lon(ilon,0,0))
endfor

locs = where(localtime lt 0,il)
if il gt 0 then localtime(locs) = 0.0

mr = 1090

setdevice,psfile,'p',5,0.95
plotdumb
;if not ortho then variable = strcompress(vars(sel),/remove) $
;  else variable = vars(sel)
variable = vars(sel)
;  makect,'wyr'

 makect,'mid'
;makect, colortable
;loadct, 0
;makect,'grey'
clevels = findgen(31)/30 * 253.0 + 1.0

 xstyle = 1
 ystyle = 1



 xrange=[0,360]
 yrange=[-90,90]

 xtitle='Longitude (deg)'
 ytitle='Latitude (deg)'

if nslices lt 3 then ppp = 3 else ppp = nslices

space = 0.01
pos_space, ppp, space, sizes, ny = ppp

for jslice = 0, nslices - 1 do begin
islice = nslices - 1 - jslice
selset = ialts(islice)
  loc = where(lat(0,*,0) ge -200 and abs(lat(0,*,0)) lt 200.0)
datatoplot=reform(data(sel,*,loc,selset))

maxi=maxminall(1)
mini=maxminall(0)

 x=reform(lon(*,loc,selset))
 y=reform(lat(*,loc,selset))

 ygrids = n_elements(loc)
    xgrids = nlons
    location = string(alt(0,0,selset),format='(f5.1)')+' km'

if n_elements(smini) eq 0 then smini = '0.0'
if n_elements(smaxi) eq 0 then smaxi = '0.0'

if (float(smini) ne 0 or float(smaxi) ne 0) then begin
    mini = float(smini)
    maxi = float(smaxi)
    mini = mini(0)
    maxi = maxi(0)
endif else begin
    mini = mini(0)
    maxi = maxi(0)
    r = (maxi-mini)*0.05
    mini = mini - r
    maxi = maxi + r
    if (logplot) then begin
        if (maxi gt 0.0) then maxi = alog10(maxi)
        if (mini gt 0.0) then mini = alog10(mini)
        if (maxi-mini gt 8) then begin
            mini = maxi-8
            print, "Limiting minimum..."
        endif
    endif 
endelse

if mini eq maxi then maxi=mini*1.01+1.0
levels = findgen(31)/30.0*(maxi-mini) + mini
loc = where(datatoplot lt levels(1), count)
if (count gt 0) then datatoplot(loc) = levels(1)

 if (logplot) then begin
        loc = where(datatoplot lt max(datatoplot)*1e-8,count)
        if (count gt 0) then datatoplot(loc) = max(datatoplot)*1e-8
        datatoplot = alog10(datatoplot)
    endif


get_position, ppp, space, sizes, jslice, pos,/rect
locx = where(x(*,0) ge   0.0 and x(*,0) le 360.0,nx)
locy = where(y(0,*) ge -90.0 and y(0,*) le  90.0,ny)
d2 = fltarr(nx,ny)
x2 = fltarr(nx,ny)
y2 = fltarr(nx,ny)
for i=nx/2, nx-1 do begin
   d2(i-nx/2,0:ny-1)  = datatoplot(locx(i),locy)
   x2(i-nx/2,0:ny-1)  = x(locx(i),locy)
   y2(i-nx/2,0:ny-1)  = y(locx(i),locy)
   d2(i,0:ny-1)  = datatoplot(locx(i-nx/2),locy)
   x2(i,0:ny-1)  = x(locx(i-nx/2),locy)
   y2(i,0:ny-1)  = y(locx(i-nx/2),locy)
endfor



plotsubsolar = 0
plotlines = 0
maxt = (max(datatoplot))
linelevels = findgen(9) * .3*2. / 8 - .3

;findgen(31)/30 * 253.0 + 1.0
linestyle = intarr(9)
linestyle(0:4) = 1
linestyle(5:8) = 0

charsize = 1.2
plotsyms = 0
plotbox = 0
nsyms = 1
symlats = 22.5
symlons = 292.5

 if jslice eq 0 then begin
 pos(1) = pos(1) -.25
 zvalue = .8
 endif
 if jslice eq 1 then begin
 pos(3) = pos(3)+.125
 pos(1) = pos(1) -.125
 endif
 if jslice eq 2 then begin
    pos(3) = pos(3)+.25
    pos(1) = pos(1) 
 endif
pos(2) = pos(2)-.1
;pos=fltarr(6)
;pos(0) = 0.2
;pos(2) = 0.99
;pos(1) = .01
;pos(3) = .99
;pos(4) = 2
;pos(5) = 2
;if jslice eq 0 then begin
;zvalue = 1
;endif
;if jslice eq 1 then begin
;zvalue = .6
;endif
;if jslice eq 2 then begin
;zvalue=.4
;endif

zvalue=1
loc = where(d2 gt max(levels(n_elements(levels)-2)),count)
if (count gt 0) then d2(loc) = max(levels(n_elements(levels)-2))

if jslice eq 0  then begin
   if not mars then begin
      title = variable+' at '+$
              strmid(stime,0,15)+' UT'
   endif else begin
      title = variable + ' on '+ strmid(stime,0,10)
   endelse
endif else begin
   title = ' '
endelse

surface,d2,x2,y2,color=300,/save,/noerase,pos=pos

if not mars then map_set,/cont,title=title,/t3d,/noerase,zvalue=zvalue,pos=pos else $
                             map_set,charsize = charsize,/t3d,/noerase,zvalue=zvalue,pos=pos,title=title

contour,d2, x2, y2,/noerase,$
        levels=levels,xstyle=xstyle,ystyle=ystyle,$
        xrange=xrange,yrange=yrange,$
        c_colors=clevels,pos=pos,background=1,$
        xtitle=xtitle,ytitle=ytitle,/cell_fill,charsize=charsize,/t3d,zvalue=zvalue,/over

 
xyouts,pos(0),pos(3)-.18,location,charsize=1.2,/norm

if not mars then begin
   map_continents, color = 0
endif  else begin
 
   contour, new_image(*,*), levels = [150], pos = pos, /noerase, $
            xstyle =5, ystyle=5, color = 0, thick=1.5,/t3d,zvalue=zvalue,xtitle=xtitle,ytitle=ytitle
endelse
  

if jslice eq 2 then begin
   axis,xaxis=0,xticks = 4,xtickn = [180,270,0,90,180], $
   charsize = charsize,/t3d,/data
xyouts,.57,.41,'Deg Longitude',/norm,charsize=1.2
endif

if jslice eq 1 then begin
 ;pos2 = fltarr(6)
 ;pos2(0) = pos(2)+0.025
 ;pos2(2) = pos2(0)+0.03
 ;pos2(1) = pos(1)
 ;pos2(3) = pos(3)
 ;pos2(4) = 1
 ;pos2(5) = 1
pos2 = [.95,.53,.98,.98] 
  ncolors=254
   maxmin = mm(levels)
   maxi = max(maxmin)
   mini = min(maxmin)
   nlevels = findgen(29)/28.0*(maxi-mini) + mini
 
   clevels = (ncolors-1)*findgen(29)/28.0 + 1
   
   array = findgen(10,ncolors-1)
   for i=0,9 do $
      array(i,*) = findgen(ncolors-1)/(ncolors-2)*(maxi-mini) + mini
   
   plot, maxmin, /noerase, pos = pos2, 			$
         xstyle=5,ystyle=5, /nodata,charsize=0.9
   if (pos(3)-pos(1) lt 0.1) then yt = 1 else yt = 0
   axis, 1, ystyle=1, /nodata, ytitle = ' ', yax=1, 	$
         charsize=0.9, color = 0, yticks = yt
  contour, array, /noerase, /cell_fill, xstyle = 5, ystyle = 5, $
           levels = nlevels, c_colors = clevels, pos=pos2
   plot, maxmin, /noerase, pos = pos2, 			$
         xstyle=5,ystyle=1, /nodata, 				$
         ytickname = strarr(10) + ' ', yticklen = 0.25, color = color_in
   
   plot, [0,9], [0,ncolors], /noerase, pos = pos2, $
         xstyle=5,ystyle=5, /nodata
 
endif
endfor


closedevice

end